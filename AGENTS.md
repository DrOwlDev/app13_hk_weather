## Learned User Preferences

- Use HKO OCF station only; do not expose a station picker or multi-station support unless asked.
- Prefer official HKO observed CSV for since-midnight min/max when the chart date matches the CSV observation date.
- Started with data-layer-only Flutter scope; do not add a GitHub Pages dashboard or GitHub Actions unless asked.
- Prefer parsing the HKO OCF JSON API endpoint over scraping the website chart.

## Learned Workspace Facts

- Flutter app `app13_hk_weather` fetches HKO hourly temperature forecasts from `https://maps.weather.gov.hk/ocf/dat/HKO.xml` (JSON despite `.xml` extension).
- GitHub repo is `DrOwlDev/app13_hk_weather`.
- Flutter app is locked to `kStationId = 'HKO'` in `lib/constants.dart` and auto-fetches on launch.
- GitHub Pages (`docs/`), the Pages deploy workflow, and the Cloudflare refresh proxy were removed.
- Data fetch script `scripts/fetch_hko_ocf.py` can write a local JSON snapshot (default `docs/data.json`) of the OCF forecast, HKO observed since-midnight min/max, latest 1-minute temperature, and webcam timestamps. It is not deployed.
