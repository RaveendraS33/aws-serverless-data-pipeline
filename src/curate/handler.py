import json
import logging
from datetime import UTC, datetime
from urllib.parse import unquote_plus

import boto3
import pandas as pd

from common.config import required_env
from common.s3paths import curated_prefix

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")


def epoch_ms_to_timestamp(value):
    if value is None:
        return pd.NaT
    return datetime.fromtimestamp(value / 1000, tz=UTC)


def feature_to_record(feature: dict) -> dict:
    props = feature.get("properties") or {}
    geometry = feature.get("geometry") or {}
    coordinates = geometry.get("coordinates") or [None, None, None]
    event_time = epoch_ms_to_timestamp(props.get("time"))
    updated_time = epoch_ms_to_timestamp(props.get("updated"))
    dt = event_time.strftime("%Y-%m-%d") if pd.notna(event_time) else None

    return {
        "event_id": feature.get("id"),
        "event_time": event_time,
        "updated_time": updated_time,
        "mag": props.get("mag"),
        "magtype": props.get("magType"),
        "place": props.get("place"),
        "longitude": coordinates[0],
        "latitude": coordinates[1],
        "depth_km": coordinates[2],
        "type": props.get("type"),
        "tsunami": props.get("tsunami"),
        "sig": props.get("sig"),
        "alert": props.get("alert"),
        "status": props.get("status"),
        "url": props.get("url"),
        "net": props.get("net"),
        "dt": dt,
    }


def records_from_geojson(payload: dict) -> list[dict]:
    return [feature_to_record(feature) for feature in payload.get("features", [])]


def deduplicate(records: list[dict]) -> pd.DataFrame:
    df = pd.DataFrame.from_records(records)
    if df.empty:
        return df
    df = df.dropna(subset=["event_id", "dt"])
    df = df.sort_values(["event_id", "updated_time"]).drop_duplicates("event_id", keep="last")
    return df


def ordered_columns() -> list[str]:
    return [
        "event_id",
        "event_time",
        "updated_time",
        "mag",
        "magtype",
        "place",
        "longitude",
        "latitude",
        "depth_km",
        "type",
        "tsunami",
        "sig",
        "alert",
        "status",
        "url",
        "net",
        "dt",
    ]


def merge_existing_partitions(wr, df: pd.DataFrame, bucket: str) -> pd.DataFrame:
    existing_frames = []
    partitions = sorted(df["dt"].dropna().unique().tolist())

    for dt in partitions:
        partition_path = f"s3://{bucket}/{curated_prefix(dt)}"
        try:
            existing = wr.s3.read_parquet(path=partition_path, dataset=True)
        except wr.exceptions.NoFilesFound:
            logger.info("No existing curated data at %s", partition_path)
            continue
        existing_frames.append(existing)

    if existing_frames:
        df = pd.concat([*existing_frames, df], ignore_index=True)

    df = df[ordered_columns()]
    return df.sort_values(["event_id", "updated_time"]).drop_duplicates("event_id", keep="last")


def write_curated(df: pd.DataFrame, bucket: str, database: str, table: str):
    import awswrangler as wr

    if df.empty:
        logger.info("No curated records to write")
        return {"rows": 0, "partitions": []}

    df = merge_existing_partitions(wr, df, bucket)
    partitions = sorted(df["dt"].dropna().unique().tolist())
    path = f"s3://{bucket}/curated/earthquakes/"

    wr.s3.to_parquet(
        df=df,
        path=path,
        dataset=True,
        mode="overwrite_partitions",
        database=database,
        table=table,
        partition_cols=["dt"],
        compression="snappy",
        schema_evolution=True,
    )
    logger.info("Wrote %s records to %s partitions: %s", len(df), path, partitions)
    return {"rows": len(df), "partitions": partitions}


def load_s3_json(bucket: str, key: str) -> dict:
    response = s3.get_object(Bucket=bucket, Key=key)
    return json.loads(response["Body"].read().decode("utf-8"))


def s3_records(event: dict) -> list[tuple[str, str]]:
    records = []
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])
        records.append((bucket, key))
    return records


def lambda_handler(event, context):
    target_bucket = required_env("DATA_BUCKET")
    database = required_env("GLUE_DATABASE")
    table = required_env("GLUE_TABLE")

    all_records = []
    touched_prefixes = set()
    for bucket, key in s3_records(event):
        payload = load_s3_json(bucket, key)
        all_records.extend(records_from_geojson(payload))

    df = deduplicate(all_records)
    if not df.empty:
        touched_prefixes = {curated_prefix(dt) for dt in df["dt"].dropna().unique()}

    result = write_curated(df, target_bucket, database, table)
    result["touched_prefixes"] = sorted(touched_prefixes)
    return result
