/** Curated Islamic reels: videos stay on YouTube / Instagram and play through the platforms' official embeds. */
import bundle from "@/generated/reels.json";
import sourcesBundle from "@/generated/reel-sources.json";
import { createStore } from "./store";

export type ReelPlatform = "youtube" | "instagram";
/** Owner policy (2026-11-27, supersedes 2026-11-09): Quran recitation only; lessons and admonitions were removed. */
export const REEL_CATEGORIES = ["recitation"] as const;
/** Reciter groups: Egypt's golden generation, imams of the Makkah Haram, of the Prophet's Mosque, famous reciters. */
export const REEL_GROUPS = ["golden", "makkah", "madinah", "famous"] as const;
export type ReelGroup = (typeof REEL_GROUPS)[number];
/** Tabs of the full-screen player (owner 2026-11-27): «الكل · أئمة الحرمين · الجيل الذهبي المصري · بث مباشر». */
export const PLAYER_TABS = ["all", "haramain", "golden", "live"] as const;
/** Chips on the videos page. */
export const HOME_TABS = ["all", "haramain", "golden", "famous", "saved"] as const;
export type ReelTab = "all" | "haramain" | "golden" | "famous" | "live" | "saved";

/** Does a reciter of [group] belong to [tab]? Channels the viewer added (no group) show under «الكل» only. */
export function inTab(group: string | null | undefined, tab: ReelTab): boolean {
  if (tab === "all") return true;
  if (tab === "haramain") return group === "makkah" || group === "madinah";
  return group === tab;
}
export interface Reel {
  id: string;
  platform: ReelPlatform;
  ref: string;
  url: string;
  title: { ar: string; en: string };
  speaker: { ar: string; en: string } | null;
  category: (typeof REEL_CATEGORIES)[number];
  source: string | null;
  status: "approved" | "pending" | "auto";
  reviewer: string | null;
  reviewedAt: string | null;
  /** Trusted channel an automatic reel came from (owner approved the channel once, 2026-11-09). */
  sourceId?: string | null;
  published?: string | null;
  /** The reciter group of the channel (see REEL_GROUPS). */
  group?: string | null;
}

export interface ReelSource {
  id: string;
  /** UC… id, or absent when the owner gave an @handle (resolved by the API). */
  channelId?: string;
  handle?: string;
  name: { ar: string; en: string };
  category: (typeof REEL_CATEGORIES)[number];
  group?: string | null;
}

/** An official live stream from the Haramain. */
export interface LiveChannel {
  id: string;
  channelId: string;
  place: "makkah" | "madinah";
  name: { ar: string; en: string };
  /** The 24/7 live video (owner 2026-11-28: the channel-level embed showed "unavailable" for Makkah). */
  videoId?: string;
}

const CHANNEL_RE = /^UC[A-Za-z0-9_-]{22}$/;
export const LIVE_CHANNELS: readonly LiveChannel[] = (
  ((sourcesBundle as { live?: unknown }).live as Partial<LiveChannel>[] | undefined) ?? []
).filter(
  (l): l is LiveChannel =>
    typeof l?.channelId === "string" &&
    CHANNEL_RE.test(l.channelId) &&
    (l.place === "makkah" || l.place === "madinah") &&
    typeof l.name?.ar === "string",
);

/** The reciters shipped with the site (the feed's sources once loaded take over). */
export const BUNDLED_SOURCES: readonly ReelSource[] = sanitizeSources(
  (sourcesBundle as { sources?: unknown }).sources,
);

/** "#quran", "#shorts" …: hashtags at any place in a YouTube title. */
const HASHTAG = /#[^\s#]+/gu;
/** Runs of white space (collapsed to one space after the hashtags are cut). */
const SPACES = /\s+/gu;

/** The title to show: hashtags removed (owner 2026-11-28); the original if nothing else is left. */
export function cleanTitle(title: string): string {
  const out = title.replace(HASHTAG, " ").replace(SPACES, " ").trim();
  return out === "" ? title : out;
}

/** A YouTube video id: 11 characters of letters, digits, "-" and "_". */
const LIVE_VIDEO_ID = /^[A-Za-z0-9_-]{11}$/;

/** The live video's YouTube page (the "open on YouTube" link). */
export function liveWatchUrl(l: LiveChannel): string {
  return l.videoId !== undefined && LIVE_VIDEO_ID.test(l.videoId)
    ? `https://www.youtube.com/watch?v=${l.videoId}`
    : `https://www.youtube.com/channel/${l.channelId}/live`;
}

export function liveEmbedUrl(l: LiveChannel, origin?: string): string {
  const video = l.videoId !== undefined && LIVE_VIDEO_ID.test(l.videoId) ? l.videoId : null;
  const q = new URLSearchParams({
    ...(video ? {} : { channel: l.channelId }),
    autoplay: "1",
    mute: "1",
    playsinline: "1",
    rel: "0",
    modestbranding: "1",
    ...(origin ? { origin } : {}),
  });
  return `https://www.youtube-nocookie.com/embed/${video ?? "live_stream"}?${q.toString()}`;
}

const YT_ID = /^[A-Za-z0-9_-]{11}$/;
const IG_CODE = /^[A-Za-z0-9_-]{5,40}$/;

/** Only well-formed items from the bundle; anything else is dropped rather than embedded. */
export function sanitizeReels(raw: unknown): Reel[] {
  const items = (raw as { items?: unknown })?.items;
  if (!Array.isArray(items)) return [];
  return items.filter((r): r is Reel => {
    if (typeof r !== "object" || r === null) return false;
    const x = r as Partial<Reel>;
    if (x.status !== "approved" && x.status !== "pending" && x.status !== "auto") return false;
    if (x.status === "auto" && typeof x.sourceId !== "string") return false;
    if (!REEL_CATEGORIES.includes(x.category as never)) return false;
    if (typeof x.ref !== "string") return false;
    if (x.platform === "youtube") return YT_ID.test(x.ref);
    if (x.platform === "instagram") return IG_CODE.test(x.ref);
    return false;
  });
}

export const REELS: readonly Reel[] = sanitizeReels(bundle);

/** Approved reels for everyone; reviewers also see pending ones (shown with a "not reviewed" banner). */
export function visibleReels(all: readonly Reel[], reviewer: boolean): Reel[] {
  return all.filter((r) => r.status === "approved" || (reviewer && r.status === "pending"));
}

/** Instagram's official embed page needs no app or token; it cannot autoplay, so the viewer taps play. */
export function embedUrl(r: Reel, origin?: string): string {
  if (r.platform === "instagram") return `https://www.instagram.com/reel/${r.ref}/embed/`;
  const q = new URLSearchParams({
    autoplay: "1",
    mute: "1",
    playsinline: "1",
    loop: "1",
    playlist: r.ref,
    rel: "0",
    modestbranding: "1",
    ...(origin ? { origin } : {}),
  });
  return `https://www.youtube-nocookie.com/embed/${r.ref}?${q.toString()}`;
}

export function posterUrl(r: Reel): string | null {
  return r.platform === "youtube" ? `https://i.ytimg.com/vi/${r.ref}/hqdefault.jpg` : null;
}

export interface ReelsPrefs {
  reviewer: boolean;
  /** Trusted channels this viewer chose to hide. */
  hidden: string[];
}
export const reelsPrefsStore = createStore<ReelsPrefs>(
  "rattil.reels",
  { reviewer: false, hidden: [] },
  (raw) => {
    const r = raw as Partial<ReelsPrefs> | null;
    return {
      reviewer: r?.reviewer === true,
      hidden: Array.isArray(r?.hidden) ? r.hidden.filter((h): h is string => typeof h === "string") : [],
    };
  },
);

/** Mixes channels so none fills the feed: each channel newest first, one per channel in turn, no duplicates. */
export function mixReels(perSource: readonly (readonly Reel[])[]): Reel[] {
  const queues = perSource
    .filter((q) => q.length > 0)
    .map((q) => [...q].sort((a, b) => (b.published ?? "").localeCompare(a.published ?? "")));
  const seen = new Set<string>();
  const out: Reel[] = [];
  const longest = Math.max(0, ...queues.map((q) => q.length));
  for (let i = 0; i < longest; i++) {
    for (const q of queues) {
      const r = q[i];
      if (r && !seen.has(r.id)) {
        seen.add(r.id);
        out.push(r);
      }
    }
  }
  return out;
}

/** Automatic reels from the API (browsers cannot read YouTube's feeds directly), cached for 3 hours. */
export interface ReelsFeedCache {
  at: number;
  base: string;
  items: Reel[];
  sources: ReelSource[];
}
export const FEED_MAX_AGE_MS = 3 * 60 * 60 * 1000;
// ".r": recitation-only feed (owner 2026-11-27); older caches with lessons are dropped.
export const reelsFeedStore = createStore<ReelsFeedCache | null>("rattil.reels.feed.r", null, (raw) => {
  const r = raw as Partial<ReelsFeedCache> | null;
  if (!r || typeof r.at !== "number" || typeof r.base !== "string") return null;
  return {
    at: r.at,
    base: r.base,
    items: sanitizeReels({ items: r.items }).filter((x) => x.status === "auto"),
    sources: sanitizeSources(r.sources),
  };
});

export function sanitizeSources(raw: unknown): ReelSource[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((s): s is ReelSource => {
    const x = s as Partial<ReelSource> | null;
    return (
      typeof x?.id === "string" &&
      (typeof x.channelId === "string" || typeof x.handle === "string") &&
      typeof x.name?.ar === "string" &&
      REEL_CATEGORIES.includes(x.category as never)
    );
  });
}

/** Fetches GET {base}/v1/reels/feed; throws when the server cannot be reached. */
export async function fetchReelsFeed(
  base: string,
  fetchImpl: typeof fetch,
  now: number,
): Promise<ReelsFeedCache> {
  const res = await fetchImpl(`${base.replace(/\/+$/, "")}/v1/reels/feed`, {
    headers: { Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`reels feed: HTTP ${res.status}`);
  const body = (await res.json()) as { schema?: string; items?: unknown; sources?: unknown };
  if (body.schema !== "reels-feed.v1") throw new Error("reels feed: unexpected schema");
  return {
    at: now,
    base,
    items: sanitizeReels({ items: body.items }).filter((x) => x.status === "auto"),
    sources: sanitizeSources(body.sources),
  };
}

/** Recitations the viewer saved (this browser only), newest saved first. */
export const SAVED_MAX = 200;
export const savedReelsStore = createStore<Reel[]>("rattil.reels.saved", [], (raw) =>
  sanitizeReels({ items: raw }).slice(0, SAVED_MAX),
);

export function toggleSaved(r: Reel): boolean {
  let now = false;
  savedReelsStore.set((list) => {
    if (list.some((x) => x.ref === r.ref)) return list.filter((x) => x.ref !== r.ref);
    now = true;
    return [r, ...list].slice(0, SAVED_MAX);
  });
  return now;
}
