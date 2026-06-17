from datetime import UTC, datetime

import pytest

from src.common.config import USGS_QUERY_URL, required_env
from src.common.s3paths import curated_prefix, raw_key, utc_dt_hour


def test_required_env_returns_value(monkeypatch):
    monkeypatch.setenv("SOME_VAR", "value")
    assert required_env("SOME_VAR") == "value"


def test_required_env_raises_when_missing(monkeypatch):
    monkeypatch.delenv("MISSING_VAR", raising=False)
    with pytest.raises(RuntimeError):
        required_env("MISSING_VAR")


def test_usgs_query_url_is_fdsn_endpoint():
    assert USGS_QUERY_URL.endswith("/fdsnws/event/1/query")


def test_raw_key_layout():
    now = datetime(2026, 6, 17, 9, 5, tzinfo=UTC)
    key = raw_key(now, 1781699100000)
    assert key == "raw/source=usgs/dt=2026-06-17/hour=09/quakes_1781699100000.geojson"


def test_curated_prefix():
    assert curated_prefix("2026-06-17") == "curated/earthquakes/dt=2026-06-17/"


def test_utc_dt_hour_converts_to_utc():
    dt, hour = utc_dt_hour(datetime(2026, 6, 17, 23, 30, tzinfo=UTC))
    assert dt == "2026-06-17"
    assert hour == "23"
