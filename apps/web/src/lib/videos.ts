/**
 * Islamic videos: search (through the site's own function, /api/videos/search, see netlify/functions/videos.mjs)
 * and the viewer's search history, kept only in this browser.
 */
import { withBase } from "./base-path";
import { createStore } from "./store";

/** Same-origin API of the hosted site (Netlify Functions); also serves the trusted channels' feed. */
export const VIDEO_API = (): string => withBase("/api");

export interface VideoHit {
  ref: string;
  title: string;
  channel: string | null;
  channelId: string | null;
  duration: string | null;
  trusted: boolean;
}

const YT_ID = /^[A-Za-z0-9_-]{11}$/;

export function sanitizeHits(raw: unknown): VideoHit[] {
  const items = (raw as { items?: unknown } | null)?.items;
  if (!Array.isArray(items)) return [];
  return items
    .filter((h): h is VideoHit => {
      const x = h as Partial<VideoHit> | null;
      return (
        typeof x?.ref === "string" && YT_ID.test(x.ref) && typeof x.title === "string" && x.title.length > 0
      );
    })
    .map((h) => ({
      ref: h.ref,
      title: h.title,
      channel: typeof h.channel === "string" ? h.channel : null,
      channelId: typeof h.channelId === "string" ? h.channelId : null,
      duration: typeof h.duration === "string" ? h.duration : null,
      trusted: h.trusted === true,
    }));
}

export async function searchVideos(query: string, fetchImpl: typeof fetch): Promise<VideoHit[]> {
  const q = query.trim();
  if (!q) return [];
  const res = await fetchImpl(`${VIDEO_API()}/videos/search?${new URLSearchParams({ q }).toString()}`, {
    headers: { Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`video search: HTTP ${res.status}`);
  const body = (await res.json()) as { schema?: string };
  if (body.schema !== "video-search.v1") throw new Error("video search: unexpected schema");
  return sanitizeHits(body);
}

export const HISTORY_MAX = 20;

/** The viewer's past searches, newest first (this browser only). */
export const videoHistoryStore = createStore<string[]>("rattil.videos.history", [], (raw) =>
  Array.isArray(raw)
    ? raw.filter((v): v is string => typeof v === "string" && v.trim().length > 0).slice(0, HISTORY_MAX)
    : [],
);

export function addToHistory(list: readonly string[], query: string): string[] {
  const q = query.trim().replace(/\s+/g, " ");
  if (!q) return [...list];
  return [q, ...list.filter((x) => x.toLowerCase() !== q.toLowerCase())].slice(0, HISTORY_MAX);
}

export const thumbUrl = (ref: string): string => `https://i.ytimg.com/vi/${ref}/mqdefault.jpg`;
export const watchUrl = (ref: string): string => `https://www.youtube.com/watch?v=${ref}`;
export const embedVideoUrl = (ref: string): string =>
  `https://www.youtube-nocookie.com/embed/${ref}?${new URLSearchParams({ autoplay: "1", playsinline: "1", rel: "0", modestbranding: "1" }).toString()}`;
