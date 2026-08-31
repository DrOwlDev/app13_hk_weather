/**
 * Cloudflare Worker: one-click browser URL to trigger HKO Pages refresh.
 *
 * Deploy with wrangler (see README.md). Set secrets:
 *   GITHUB_TOKEN  - PAT with repo scope (repository_dispatch)
 *   REFRESH_SECRET - optional query key (?key=...) to block public abuse
 *
 * Kick-start URL (after deploy):
 *   https://YOUR-WORKER.workers.dev/refresh?key=YOUR_REFRESH_SECRET
 */

const REPO = "DrOwlDev/app13_hk_weather";
const DISPATCH_EVENT = "refresh-hko";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    if (url.pathname !== "/refresh") {
      return json({ error: "Not found" }, 404);
    }

    if (env.REFRESH_SECRET && url.searchParams.get("key") !== env.REFRESH_SECRET) {
      return json({ error: "Unauthorized" }, 401);
    }

    if (!env.GITHUB_TOKEN) {
      return json({ error: "GITHUB_TOKEN not configured" }, 500);
    }

    const response = await fetch(`https://api.github.com/repos/${REPO}/dispatches`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "Content-Type": "application/json",
        "User-Agent": "hko-refresh-proxy",
      },
      body: JSON.stringify({ event_type: DISPATCH_EVENT }),
    });

    if (!response.ok) {
      const detail = await response.text();
      return json({ error: "GitHub dispatch failed", detail }, response.status);
    }

    return json(
      {
        ok: true,
        message: "Update HKO Temperature Pages workflow triggered",
        repo: REPO,
        event_type: DISPATCH_EVENT,
      },
      202,
    );
  },
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
