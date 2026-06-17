import json
import logging
import urllib.parse
import urllib.request
from datetime import UTC, datetime, timedelta

import boto3

from common.config import USGS_QUERY_URL, required_env
from common.obs import log_json
from common.s3paths import raw_key

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")


def build_usgs_url(now: datetime) -> str:
    end_time = now.astimezone(UTC)
    start_time = end_time - timedelta(minutes=65)
    query = urllib.parse.urlencode(
        {
            "format": "geojson",
            "starttime": start_time.isoformat().replace("+00:00", "Z"),
            "endtime": end_time.isoformat().replace("+00:00", "Z"),
        }
    )
    return f"{USGS_QUERY_URL}?{query}"


def fetch_geojson(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": "aws-serverless-data-pipeline"})
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.loads(response.read().decode("utf-8"))


def lambda_handler(event, context):
    run_id = getattr(context, "aws_request_id", None)
    bucket = required_env("DATA_BUCKET")
    now = datetime.now(UTC)
    url = build_usgs_url(now)

    try:
        payload = fetch_geojson(url)
    except Exception as exc:
        # Fail loud: log structured, then re-raise so the invocation is retried
        # and ultimately dead-lettered (the scheduler target's dead_letter_config
        # in infra/eventbridge.tf) rather than lost.
        log_json(logger, "ingest_error", run_id=run_id, error=str(exc))
        raise

    feature_count = len(payload.get("features", []))
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    key = raw_key(now, int(now.timestamp() * 1000))

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=body,
        ContentType="application/geo+json",
    )
    log_json(
        logger,
        "ingest_run",
        run_id=run_id,
        feature_count=feature_count,
        bucket=bucket,
        key=key,
    )
    return {"bucket": bucket, "key": key, "feature_count": feature_count, "run_id": run_id}
