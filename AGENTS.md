## Learned User Preferences

- Use HKO OCF station only; do not expose a station picker or multi-station support unless asked.
- GitHub Pages dashboard chart and data table should use the same filtered time window.
- Chart x-axis should span from now minus 1 hour through 1:00 AM on today plus 2 days (local time).
- Dashboard chart should show blue vertical lines at each local midnight (00:00) within the visible x-axis window.
- Prefer official HKO observed CSV for since-midnight min/max when the chart date matches the CSV observation date.
- Wants manual kick-start URLs or options to trigger the GitHub Actions data refresh workflow.
- Started with data-layer-only Flutter scope; chart visualization lives on GitHub Pages, not in the Flutter app.
- Prefer parsing the HKO OCF JSON API endpoint over scraping the website chart.

## Learned Workspace Facts

- Flutter app `app13_hk_weather` fetches HKO hourly temperature forecasts from `https://maps.weather.gov.hk/ocf/dat/HKO.xml` (JSON despite `.xml` extension).
- GitHub repo is `DrOwlDev/app13_hk_weather`; live dashboard at https://drowldev.github.io/app13_hk_weather/.
- Flutter app is locked to `kStationId = 'HKO'` in `lib/constants.dart` and auto-fetches on launch.
- GitHub Pages site in `docs/` uses Chart.js for a red-line temperature chart and reads `docs/data.json`.
- `.github/workflows/update-hko-pages.yml` refreshes data on push, staggered ~5-minute cron, `workflow_dispatch`, and `repository_dispatch` (`refresh-hko`).
- Manual refresh options are documented in README; optional Cloudflare Worker at `workers/hko-refresh-proxy/` enables a one-click browser URL.
- Data fetch script `scripts/fetch_hko_ocf.py` fetches OCF forecast and HKO observed since-midnight min/max (`latest_since_midnight_maxmin.csv`) into `docs/data.json`.
- Chart time window in `docs/index.html` uses `getChartTimeWindow()` (now − 1h → today + 2 days at 01:00) and `filterPointsByWindow()`.
- Chart midnight lines use a custom `midnightLines` Chart.js plugin in `docs/index.html`.
- Observed summary table derives chart date from the first visible forecast point; shows since-midnight min/max, forecasted min/max (vs remaining forecast hours on chart date), and Locked/Not Locked status.
