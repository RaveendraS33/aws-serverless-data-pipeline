from datetime import UTC, datetime

from src.ingest.handler import build_usgs_url


def test_build_usgs_url_uses_65_minute_window():
    now = datetime(2026, 6, 17, 12, 0, tzinfo=UTC)
    url = build_usgs_url(now)

    assert "format=geojson" in url
    assert "starttime=2026-06-17T10%3A55%3A00Z" in url
    assert "endtime=2026-06-17T12%3A00%3A00Z" in url
