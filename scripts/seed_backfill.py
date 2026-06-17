from __future__ import annotations

import json
from datetime import UTC, datetime, timedelta
from pathlib import Path


def main():
    now = datetime.now(UTC)
    features = []
    for index in range(5):
        event_time = now - timedelta(hours=index)
        epoch_ms = int(event_time.timestamp() * 1000)
        features.append(
            {
                "id": f"seed-{index}",
                "properties": {
                    "mag": 1.5 + index,
                    "place": f"Seed event {index}",
                    "time": epoch_ms,
                    "updated": epoch_ms,
                    "magType": "ml",
                    "type": "earthquake",
                    "tsunami": 0,
                    "sig": 100 + index,
                    "alert": None,
                    "status": "reviewed",
                    "url": "https://earthquake.usgs.gov/",
                    "net": "us",
                },
                "geometry": {"coordinates": [-122.0 - index, 37.0 + index, 10.0]},
            }
        )

    path = Path("sample_usgs_geojson.json")
    path.write_text(json.dumps({"type": "FeatureCollection", "features": features}, indent=2))
    print(f"Wrote {path}")


if __name__ == "__main__":
    main()
