# app13_hk_weather

HKO OCF hourly temperature forecast for Hong Kong Observatory (HKO). Includes a Flutter app and a GitHub Pages dashboard.

- **Live dashboard:** https://drowldev.github.io/app13_hk_weather/
- **Data source:** `https://maps.weather.gov.hk/ocf/dat/HKO.xml` (JSON)

## Flutter app

```bash
flutter pub get
flutter run
```

The app is locked to station **HKO** and auto-loads temperature points on launch.

## GitHub Pages auto-refresh

Workflow [`.github/workflows/update-hko-pages.yml`](.github/workflows/update-hko-pages.yml) fetches HKO data and deploys [`docs/`](docs/) on:

- push to `main`
- cron (every ~5 minutes UTC, best-effort)
- manual / API triggers (below)

## Manual kick-start (refresh now)

### Option A — GitHub Actions page (bookmark)

Open and click **Run workflow**:

https://github.com/DrOwlDev/app13_hk_weather/actions/workflows/update-hko-pages.yml

### Option B — GitHub CLI

```bash
gh workflow run "Update HKO Temperature Pages" --repo DrOwlDev/app13_hk_weather
```

### Option C — REST API (`workflow_dispatch`)

Requires a PAT with `actions:write`:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/DrOwlDev/app13_hk_weather/actions/workflows/346652068/dispatches \
  -d '{"ref":"main"}'
```

### Option D — REST API (`repository_dispatch`)

Requires a PAT with `repo` scope:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/DrOwlDev/app13_hk_weather/dispatches \
  -d '{"event_type":"refresh-hko"}'
```

### Option E — One-click browser URL (Cloudflare Worker proxy)

Deploy the worker in [`workers/hko-refresh-proxy/`](workers/hko-refresh-proxy/) (see its README), then set `refreshProxyUrl` in [`docs/config.json`](docs/config.json):

```json
{
  "refreshProxyUrl": "https://YOUR-WORKER.workers.dev/refresh?key=YOUR_SECRET"
}
```

Kick-start URL (open in browser):

```
https://YOUR-WORKER.workers.dev/refresh?key=YOUR_SECRET
```

The live dashboard **Trigger data refresh** button uses this proxy when configured; otherwise it opens the GitHub Actions page.

## Local fetch

```bash
python scripts/fetch_hko_ocf.py
python scripts/fetch_hko_ocf.py --dry-run
```

## Tests

```bash
flutter test
```
