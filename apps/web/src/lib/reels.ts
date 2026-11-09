/** Curated Islamic reels: videos stay on YouTube / Instagram and play through the platforms' official embeds. */
import bundle from "@/generated/reels.json";
import { createStore } from "./store";

export type ReelPlatform = "youtube" | "instagram";
/** Owner policy: Quran recitation, religious lessons, and advice/admonitions in line with the Quran and Sunnah. */
export const REEL_CATEGORIES = ["recitation", "lesson", "admonition"] as const;
export interface Reel {
  id: string;
  platform: ReelPlatform;
  ref: string;
  url: string;
  title: { ar: string; en: string };
  speaker: { ar: string; en: string } | null;
  category: (typeof REEL_CATEGORIES)[number];
  source: string | null;
  status: "approved" | "pending";
  reviewer: string | null;
  reviewedAt: string | null;
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
    if (x.status !== "approved" && x.status !== "pending") return false;
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
}
export const reelsPrefsStore = createStore<ReelsPrefs>("rattil.reels", { reviewer: false }, (raw) => ({
  reviewer: (raw as Partial<ReelsPrefs> | null)?.reviewer === true,
}));
