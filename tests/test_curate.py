from datetime import UTC, datetime

import pandas as pd

from src.curate.handler import deduplicate, feature_to_record


def feature(event_id: str, updated_ms: int, mag: float = 2.5):
    return {
        "id": event_id,
        "properties": {
            "mag": mag,
            "place": "10 km S of Example",
            "time": 1781697600000,
            "updated": updated_ms,
            "magType": "ml",
            "type": "earthquake",
            "tsunami": 0,
            "sig": 100,
            "alert": None,
            "status": "reviewed",
            "url": "https://example.com",
            "net": "us",
        },
        "geometry": {"coordinates": [-122.1, 37.2, 8.5]},
    }


def test_feature_to_record_maps_geojson():
    record = feature_to_record(feature("abc", 1781697700000))

    assert record["event_id"] == "abc"
    assert record["longitude"] == -122.1
    assert record["latitude"] == 37.2
    assert record["depth_km"] == 8.5
    assert record["dt"] == "2026-06-17"


def test_deduplicate_keeps_latest_updated_time():
    older = feature_to_record(feature("same", 1781697600000, mag=1.0))
    newer = feature_to_record(feature("same", 1781697800000, mag=4.0))

    df = deduplicate([older, newer])

    assert len(df) == 1
    assert df.iloc[0]["mag"] == 4.0
    assert df.iloc[0]["updated_time"] == pd.Timestamp(
        datetime.fromtimestamp(1781697800000 / 1000, tz=UTC)
    )
