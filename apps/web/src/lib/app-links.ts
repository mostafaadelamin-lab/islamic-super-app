/** Public links set by the owner (packages/shared-schemas/app-links.json); null = not set, hide the button. */
import linksJson from "@/generated/app-links.json";
import { createStore } from "./store";

export interface AppLinks {
  contactEmail: string | null;
  website: string | null;
  playStore: string | null;
  appStore: string | null;
}
const str = (v: unknown): string | null => (typeof v === "string" && v.trim() !== "" ? v : null);
const raw = linksJson as Record<string, unknown>;
export const APP_LINKS: AppLinks = {
  contactEmail: str(raw.contactEmail),
  website: str(raw.website),
  playStore: str(raw.playStore),
  appStore: str(raw.appStore),
};

/** Days with a visit before the one-time "share Rattil" suggestion appears. */
export const SHARE_PROMPT_AFTER_DAYS = 5;

export interface SharePromptState {
  /** Distinct days the site was opened (counted until the prompt has been answered). */
  days: string[];
  done: boolean;
}
export const sharePromptStore = createStore<SharePromptState>(
  "rattil.sharePrompt",
  { days: [], done: false },
  (r: unknown): SharePromptState => {
    const o = typeof r === "object" && r !== null ? (r as Record<string, unknown>) : {};
    const days = Array.isArray(o.days) ? o.days.filter((d): d is string => typeof d === "string") : [];
    return { days: days.slice(-SHARE_PROMPT_AFTER_DAYS), done: o.done === true };
  },
);

/** Records today's visit; true when the suggestion should show now. */
export function visit(s: SharePromptState, today: string): { next: SharePromptState; show: boolean } {
  if (s.done) return { next: s, show: false };
  const days = s.days.includes(today) ? s.days : [...s.days, today].slice(-SHARE_PROMPT_AFTER_DAYS);
  return { next: { days, done: false }, show: days.length >= SHARE_PROMPT_AFTER_DAYS };
}

/** What is shared for "share the app": a short line and the site's own address. */
export function shareAppData(text: string, origin: string): ShareData {
  return { title: "Rattil wa Salli — رتّل وصلِّ", text, url: APP_LINKS.website ?? origin };
}
