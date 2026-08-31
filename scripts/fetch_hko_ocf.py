#!/usr/bin/env python3
"""Fetch HKO OCF temperature forecast and write docs/data.json."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path

STATION_ID = "HKO"
API_URL = f"https://maps.weather.gov.hk/ocf/dat/{STATION_ID}.xml"
DEFAULT_OUTPUT = Path(__file__).resolve().parent.parent / "docs" / "data.json"
HK_TZ = timezone(timedelta(hours=8))


def parse_forecast_hour(value: str) -> datetime:
    if len(value) != 10:
        raise ValueError(f"Expected YYYYMMDDHH, got {value!r}")
    return datetime(
        int(value[0:4]),
        int(value[4:6]),
        int(value[6:8]),
        int(value[8:10]),
        tzinfo=HK_TZ,
    )


def fetch_ocf_payload() -> dict:
    request = urllib.request.Request(
        API_URL,
        headers={"User-Agent": "app13-hk-weather/1.0"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def build_output(payload: dict) -> dict:
    points = []
    for entry in payload.get("HourlyWeatherForecast", []):
        temperature = entry.get("ForecastTemperature")
        forecast_hour = entry.get("ForecastHour")
        if temperature is None or not forecast_hour:
            continue
        forecast_time = parse_forecast_hour(str(forecast_hour))
        points.append(
            {
                "forecastTime": forecast_time.strftime("%Y-%m-%dT%H:%M:%S"),
                "temperatureC": float(temperature),
            }
        )

    return {
        "stationCode": payload.get("StationCode", STATION_ID),
        "fetchedAt": datetime.now(HK_TZ).isoformat(timespec="seconds"),
        "lastModified": payload.get("LastModified"),
        "modelTime": payload.get("ModelTime"),
        "temperaturePoints": points,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch HKO OCF temperature data.")
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Output JSON path (default: docs/data.json)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print JSON to stdout instead of writing a file",
    )
    args = parser.parse_args()

    try:
        payload = fetch_ocf_payload()
        output = build_output(payload)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ValueError) as error:
        print(f"Failed to fetch HKO forecast: {error}", file=sys.stderr)
        return 1

    serialized = json.dumps(output, indent=2, ensure_ascii=False)
    if args.dry_run:
        print(serialized)
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(f"{serialized}\n", encoding="utf-8")
    print(f"Wrote {len(output['temperaturePoints'])} points to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
