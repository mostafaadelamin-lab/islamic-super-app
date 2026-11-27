// Islamic videos for the website: the trusted channels' feed and video search (see ../lib/videos-core.mjs).
// Browsers cannot read YouTube's feeds or results page (no CORS), so this small function does it server-side.
import sources from "../lib/reel-sources.json" with { type: "json" };
import { buildFeed, channelReels, searchChannels, searchVideos } from "../lib/videos-core.mjs";

const FEED_TTL = 3 * 60 * 60 * 1000;
const SEARCH_TTL = 60 * 60 * 1000;
const cache = new Map();

async function get(url) {
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": "Mozilla/5.0 (rattil-videos)", "Accept-Language": "ar,en;q=0.8" },
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) return null;
    return (await res.text()).slice(0, 3_000_000);
  } catch {
    return null;
  }
}

async function cached(key, ttl, make, keep = () => true) {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < ttl) return hit.value;
  const value = await make();
  if (!keep(value)) return value;
  cache.set(key, { at: Date.now(), value });
  if (cache.size > 300) cache.delete(cache.keys().next().value);
  return value;
}

const json = (body, seconds) =>
  Response.json(body, {
    headers: {
      "Cache-Control": `public, max-age=${Math.min(seconds, 600)}`,
      "Netlify-CDN-Cache-Control": `public, s-maxage=${seconds}, stale-while-revalidate=86400`,
    },
  });

async function handler(req) {
  const url = new URL(req.url);
  const feedSources = sources.feed ?? [];
  if (url.pathname.endsWith("/reels/feed")) {
    const body = await cached(
      "feed-r",
      FEED_TTL,
      () => buildFeed(feedSources, get),
      (b) => b.items.length > 0,
    );
    return json(body, 3 * 60 * 60);
  }
  if (url.pathname.endsWith("/reels/channel")) {
    const id = url.searchParams.get("id") ?? "";
    const body = await cached(
      `ch-r:${id}`,
      FEED_TTL,
      () => channelReels(id, get),
      (b) => b != null && b.items.length > 0,
    );
    if (body == null) return Response.json({ error: "bad channel" }, { status: 400 });
    return json(body, 3 * 60 * 60);
  }
  const q = url.searchParams.get("q") ?? "";
  if (url.pathname.endsWith("/channels/search")) {
    try {
      const body = await cached(`cs-r:${q.trim().toLowerCase()}`, SEARCH_TTL, () => searchChannels(q, get));
      return json(body, 60 * 60);
    } catch {
      return Response.json({ error: "unreachable" }, { status: 502 });
    }
  }
  const trusted = new Set(
    [...feedSources, ...(sources.suggested ?? [])].map((s) => s.channelId).filter(Boolean),
  );
  try {
    const body = await cached(`q-r:${q.trim().toLowerCase()}`, SEARCH_TTL, () => searchVideos(q, get, trusted));
    return json(body, 60 * 60);
  } catch {
    return Response.json({ error: "unreachable" }, { status: 502 });
  }
}

export default handler;

export const config = {
  path: ["/api/v1/reels/feed", "/api/v1/reels/channel", "/api/videos/search", "/api/channels/search"],
  method: "GET",
};
