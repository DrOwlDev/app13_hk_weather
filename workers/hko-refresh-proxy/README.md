# HKO refresh proxy (Cloudflare Worker)

Browser-friendly kick-start URL for the GitHub Actions workflow.

## Setup

1. Install [Wrangler](https://developers.cloudflare.com/workers/wrangler/install-and-update/).
2. From this directory:

```bash
cd workers/hko-refresh-proxy
wrangler login
wrangler secret put GITHUB_TOKEN    # PAT with repo scope
wrangler secret put REFRESH_SECRET  # optional shared key for ?key=
wrangler deploy
```

3. Copy your worker URL (e.g. `https://hko-refresh-proxy.YOUR.workers.dev/refresh?key=YOUR_SECRET`).
4. Set `refreshProxyUrl` in [`docs/config.json`](../../docs/config.json) to that URL (without query string; the dashboard appends `?key=` if configured separately — or embed the full URL including `?key=` in `refreshProxyUrl`).

## Kick-start URL

After deploy:

```
https://YOUR-WORKER.workers.dev/refresh?key=YOUR_REFRESH_SECRET
```

Opening this URL in a browser triggers `repository_dispatch` → **Update HKO Temperature Pages**.

## Security

- Never commit `GITHUB_TOKEN` to git.
- Use `REFRESH_SECRET` so random visitors cannot trigger your workflow.
- Do not expose the PAT in the public dashboard; only the worker holds it.
