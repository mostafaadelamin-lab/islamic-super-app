/**
 * Quranic stories, from trusted sources only (owner rule: no story text written by us):
 *  - Verse stories: each story is its Quranic verse ranges, shown as the Mushaf text, recited with the app's
 *    reciters (everyayah.com) and explained with Tafsir al-Muyassar.
 *  - Narrated series: audio-only episodes by a named narrator (Sheikh al-Sha'rawi's "Stories of the
 *    Prophets"), streamed from their source. Users hear only episodes a named reviewer approved; reviewer
 *    mode also lists pending ones, with a banner.
 */
import bundle from "@/generated/stories.json";
import { isValidAyah } from "./pages";

export const STORY_CATEGORIES = ["prophets", "others"] as const;
export type StoryCategory = (typeof STORY_CATEGORIES)[number];
export type Range = readonly [number, number, number];

export interface Story {
  id: string;
  category: StoryCategory;
  title: { ar: string; en: string };
  segments: Range[];
  ayahCount: number;
  status: "approved" | "pending";
  reviewer: string | null;
  reviewedAt: string | null;
}

export interface Episode {
  id: string;
  title: { ar: string; en: string };
  url: string;
  durationSec: number | null;
  /** The verse story with the same subject, if any. */
  story: string | null;
  status: "approved" | "pending";
  reviewer: string | null;
}

export interface Series {
  id: string;
  title: { ar: string; en: string };
  narrator: { ar: string; en: string };
  source: string;
  sourceUrl: string | null;
  licence: string;
  episodes: Episode[];
}

const ID = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const AUDIO = /\.(mp3|m4a|aac|ogg|opus)$/i;

function validRange(r: unknown): r is Range {
  if (!Array.isArray(r) || r.length !== 3 || !r.every((x) => Number.isInteger(x))) return false;
  const [s, a, b] = r as [number, number, number];
  return a <= b && isValidAyah(s, a) && isValidAyah(s, b);
}

const reviewed = (x: { status?: unknown }): boolean => x.status === "approved" || x.status === "pending";

/** Only well-formed stories whose verse ranges exist in the Quran; anything else is dropped. */
export function sanitizeStories(raw: unknown): Story[] {
  const items = (raw as { items?: unknown })?.items;
  if (!Array.isArray(items)) return [];
  return items.filter((x): x is Story => {
    if (typeof x !== "object" || x === null) return false;
    const st = x as Partial<Story>;
    if (typeof st.id !== "string" || !ID.test(st.id) || !reviewed(st)) return false;
    if (!STORY_CATEGORIES.includes(st.category as StoryCategory)) return false;
    if (typeof st.title?.ar !== "string" || !st.title.ar.trim()) return false;
    return Array.isArray(st.segments) && st.segments.length > 0 && st.segments.every(validRange);
  });
}

/** An https link to an audio file, nothing else (no javascript:, data:, pages...). */
export function isAudioUrl(url: unknown): url is string {
  if (typeof url !== "string") return false;
  try {
    const u = new URL(url);
    return u.protocol === "https:" && !!u.hostname && AUDIO.test(u.pathname);
  } catch {
    return false;
  }
}

/** Well-formed series with their well-formed episodes; series left without episodes are dropped. */
export function sanitizeSeries(raw: unknown): Series[] {
  const list = (raw as { series?: unknown })?.series;
  if (!Array.isArray(list)) return [];
  return list.flatMap((x): Series[] => {
    if (typeof x !== "object" || x === null) return [];
    const se = x as Partial<Series>;
    if (typeof se.id !== "string" || !ID.test(se.id) || typeof se.narrator?.ar !== "string") return [];
    if (typeof se.title?.ar !== "string" || typeof se.licence !== "string" || !se.licence.trim()) return [];
    const episodes = (Array.isArray(se.episodes) ? se.episodes : []).filter(
      (e): e is Episode =>
        typeof e === "object" &&
        e !== null &&
        typeof e.id === "string" &&
        ID.test(e.id) &&
        reviewed(e) &&
        typeof e.title?.ar === "string" &&
        isAudioUrl(e.url),
    );
    return episodes.length ? [{ ...(se as Series), episodes }] : [];
  });
}

export const STORIES: readonly Story[] = sanitizeStories(bundle);
export const SERIES: readonly Series[] = sanitizeSeries(bundle);

export function storyById(id: string, all: readonly Story[] = STORIES): Story | undefined {
  return all.find((s) => s.id === id);
}

/** Approved episodes for everyone; reviewers also get pending ones. */
export function visibleEpisodes(se: Series, reviewer: boolean): Episode[] {
  return se.episodes.filter((e) => e.status === "approved" || (reviewer && e.status === "pending"));
}

export function storiesByCategory(
  all: readonly Story[] = STORIES,
): { category: StoryCategory; items: Story[] }[] {
  return STORY_CATEGORIES.map((category) => ({
    category,
    items: all.filter((s) => s.category === category),
  })).filter((g) => g.items.length > 0);
}

export const minutes = (sec: number | null): number | null =>
  sec ? Math.max(1, Math.round(sec / 60)) : null;

/** Episode videos on YouTube by episode id (same as the app's stories_screen.dart storyVideos). Empty since
 *  2026-11-26: Sheikh Nabil al-Awadi's series and videos were removed (owner); al-Sha'rawi's audio replaced them. */
export const STORY_VIDEOS: Readonly<Record<string, string>> = {};
