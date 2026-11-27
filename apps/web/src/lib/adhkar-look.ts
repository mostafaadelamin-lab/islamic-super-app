/**
 * «إعدادات الأذكار» (owner 2026-11-27, same as the app): the adhkar pages' background (our own colours),
 * tashkeel on/off (display only) and the text size. Kept in this browser only.
 */
import { createStore } from "./store";

export const ADHKAR_BGS = ["", "night", "azure", "emerald", "sand", "sky", "lavender", "sunset"] as const;
export type AdhkarBg = (typeof ADHKAR_BGS)[number];
export const SCALE_MIN = 0.8;
export const SCALE_MAX = 1.8;

export interface AdhkarLook {
  bg: AdhkarBg;
  tashkeel: boolean;
  scale: number;
}
export const DEFAULT_LOOK: AdhkarLook = { bg: "", tashkeel: true, scale: 1 };

export function sanitizeLook(raw: unknown): AdhkarLook {
  const r = typeof raw === "object" && raw !== null ? (raw as Record<string, unknown>) : {};
  const bg = (ADHKAR_BGS as readonly unknown[]).includes(r.bg) ? (r.bg as AdhkarBg) : "";
  const scale =
    typeof r.scale === "number" && Number.isFinite(r.scale)
      ? Math.min(SCALE_MAX, Math.max(SCALE_MIN, r.scale))
      : 1;
  return { bg, tashkeel: r.tashkeel !== false, scale };
}

export const adhkarLookStore = createStore<AdhkarLook>("rattil.adhkarLook", DEFAULT_LOOK, sanitizeLook);

const HARAKAT = /[ً-ٰٟۖ-ۭ]/g;
const QURAN = /﴿[^﴾]*﴾/g;

/** The dhikr as shown: without tashkeel when turned off. Quran verses (﴿ ﴾) keep theirs; the text never changes. */
export function dhikrShown(text: string, tashkeel: boolean): string {
  if (tashkeel) return text;
  let out = "";
  let at = 0;
  for (const m of text.matchAll(QURAN)) {
    out += text.slice(at, m.index).replace(HARAKAT, "") + m[0];
    at = m.index + m[0].length;
  }
  return out + text.slice(at).replace(HARAKAT, "");
}
