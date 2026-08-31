#!/usr/bin/env python3
"""Fetch HKO OCF temperature forecast and write docs/data.json."""

from __future__ import annotations

import argparse
import csv
import io
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path

STATION_ID = "HKO"
OBSERVED_STATION_NAME = "HK Observatory"
API_URL = f"https://maps.weather.gov.hk/ocf/dat/{STATION_ID}.xml"
MAXMIN_URL = (
    "https://data.weather.gov.hk/weatherAPI/hko_data/"
    "regional-weather/latest_since_midnight_maxmin.csv"
)
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


def parse_observation_time(value: str) -> datetime:
    if len(value) != 12:
        raise ValueError(f"Expected YYYYMMDDHHMN, got {value!r}")
    return datetime(
        int(value[0:4]),
        int(value[4:6]),
        int(value[6:8]),
        int(value[8:10]),
        int(value[10:12]),
        tzinfo=HK_TZ,
    )


def parse_temperature(value: str) -> tuple[float | None, bool]:
    text = value.strip()
    if text in ("N/A", ""):
        return None, False
    incomplete = text.endswith("*")
    if incomplete:
        text = text[:-1]
    return float(text), incomplete


def fetch_observed_since_midnight() -> dict:
    request = urllib.request.Request(
        MAXMIN_URL,
        headers={"User-Agent": "app13-hk-weather/1.0"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        body = response.read().decode("utf-8-sig")

    for row in csv.reader(io.StringIO(body)):
        if len(row) < 4 or row[1] != OBSERVED_STATION_NAME:
            continue
        max_temp, max_incomplete = parse_temperature(row[2])
        min_temp, min_incomplete = parse_temperature(row[3])
        return {
            "observationTime": row[0],
            "maxTemperatureC": max_temp,
            "minTemperatureC": min_temp,
            "stationName": OBSERVED_STATION_NAME,
            "provisional": True,
            "incompleteData": max_incomplete or min_incomplete,
        }

    raise ValueError(f"Station {OBSERVED_STATION_NAME!r} not found in max/min CSV")


def fetch_ocf_payload() -> dict:
    request = urllib.request.Request(
        API_URL,
        headers={"User-Agent": "app13-hk-weather/1.0"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def build_output(payload: dict, observed: dict | None = None) -> dict:
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

    output = {
        "stationCode": payload.get("StationCode", STATION_ID),
        "fetchedAt": datetime.now(HK_TZ).isoformat(timespec="seconds"),
        "lastModified": payload.get("LastModified"),
        "modelTime": payload.get("ModelTime"),
        "temperaturePoints": points,
    }
    if observed is not None:
        output["observedSinceMidnight"] = observed
    return output


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
        try:
            observed = fetch_observed_since_midnight()
        except (urllib.error.URLError, TimeoutError, ValueError) as error:
            print(f"Warning: could not fetch observed min/max: {error}", file=sys.stderr)
            observed = None
        output = build_output(payload, observed)
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
    if output.get("observedSinceMidnight"):
        obs = output["observedSinceMidnight"]
        print(
            f"Observed since midnight: min {obs.get('minTemperatureC')}°C, "
            f"max {obs.get('maxTemperatureC')}°C"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
