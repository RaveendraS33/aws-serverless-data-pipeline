from datetime import UTC, datetime


def utc_dt_hour(value: datetime) -> tuple[str, str]:
    utc_value = value.astimezone(UTC)
    return utc_value.strftime("%Y-%m-%d"), utc_value.strftime("%H")


def raw_key(now: datetime, epoch_ms: int) -> str:
    dt, hour = utc_dt_hour(now)
    return f"raw/source=usgs/dt={dt}/hour={hour}/quakes_{epoch_ms}.geojson"


def curated_prefix(dt: str) -> str:
    return f"curated/earthquakes/dt={dt}/"
