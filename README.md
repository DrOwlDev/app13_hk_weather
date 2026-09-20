# app13_hk_weather

HKO OCF hourly temperature forecast for Hong Kong Observatory (HKO). Flutter app.

- **Data source:** `https://maps.weather.gov.hk/ocf/dat/HKO.xml` (JSON)

## Flutter app

```bash
flutter pub get
flutter run
```

The app is locked to station **HKO** and auto-loads temperature points on launch.

## Local fetch

```bash
python scripts/fetch_hko_ocf.py
python scripts/fetch_hko_ocf.py --dry-run
```

## Tests

```bash
flutter test
```
