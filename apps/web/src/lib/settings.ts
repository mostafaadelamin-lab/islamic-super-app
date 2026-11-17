import { tokens } from "@/generated/tokens";
import { createStore } from "./store";
import { isLocale, type Locale } from "./i18n";
import type { ClockStyle } from "./time";
import { clampAdjustment, METHOD_IDS, PRAYER_KEYS, type Adjustments } from "./prayer";

export type ThemePref = "system" | "light" | "dark";
/**
 * Colour style (owner 2026-11-15): "emerald" or "madinah". Since 1.2.8 (owner 2026-11-17) «ليل المدينة» is the
 * default. A palette saved before 1.2.8 (no paletteV) is dropped once, so every visitor starts on the new default;
 * a style picked after that is kept.
 */
export type PalettePref = keyof typeof tokens.palettes;
export const PALETTES = Object.keys(tokens.palettes) as PalettePref[];
export const DEFAULT_PALETTE = tokens.defaultPalette as PalettePref;
const isPalette = (v: unknown): v is PalettePref =>
  typeof v === "string" && (PALETTES as string[]).includes(v);
export const FONT_MIN = tokens.fontSize.quranMin;
export const FONT_MAX = tokens.fontSize.quranMax;
export const FONT_DEFAULT = tokens.fontSize.quran;

export interface Preferences {
  locale: Locale | null;
  theme: ThemePref;
  palette: PalettePref;
  fontSize: number;
  translation: boolean;
  /** 24 h or 12 h clock for prayer times. */
  clock: ClockStyle;
  /** Days added to the Umm al-Qura Hijri date to match the locally announced date (moon sighting). */
  hijriOffset: number;
  /** 2 = the palette was saved under the 1.2.8 default (see PalettePref). */
  paletteV: 2;
}
export const DEFAULT_PREFS: Preferences = {
  locale: null,
  theme: "system",
  palette: DEFAULT_PALETTE,
  fontSize: FONT_DEFAULT,
  translation: false,
  clock: "24",
  hijriOffset: 0,
  paletteV: 2,
};

export const HIJRI_OFFSET_MAX = 2;
export function clampHijriOffset(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return 0;
  return Math.min(HIJRI_OFFSET_MAX, Math.max(-HIJRI_OFFSET_MAX, Math.round(n)));
}

export function clampFontSize(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return FONT_DEFAULT;
  return Math.min(FONT_MAX, Math.max(FONT_MIN, Math.round(n)));
}

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

export function sanitizePrefs(raw: unknown): Preferences {
  const r = isObj(raw) ? raw : {};
  return {
    locale: isLocale(r.locale) ? r.locale : null,
    theme: r.theme === "light" || r.theme === "dark" ? r.theme : "system",
    palette: r.paletteV === 2 && isPalette(r.palette) ? r.palette : DEFAULT_PALETTE,
    fontSize: r.fontSize === undefined ? FONT_DEFAULT : clampFontSize(r.fontSize),
    translation: r.translation === true,
    clock: r.clock === "12" ? "12" : "24",
    hijriOffset: clampHijriOffset(r.hijriOffset ?? 0),
    paletteV: 2,
  };
}

export const prefsStore = createStore<Preferences>("rattil.prefs", DEFAULT_PREFS, sanitizePrefs);

export interface CustomLocation {
  lat: number;
  lng: number;
  tz: string;
}
export interface PrayerPrefs {
  cityId: string;
  custom: CustomLocation | null;
  method: string | null; // null = city default
  asr: "standard" | "hanafi";
  adjustments: Adjustments;
}
export const DEFAULT_PRAYER: PrayerPrefs = {
  cityId: "c26",
  custom: null,
  method: null,
  asr: "standard",
  adjustments: {},
};

export function sanitizePrayer(raw: unknown): PrayerPrefs {
  const r = isObj(raw) ? raw : {};
  const adj: Adjustments = {};
  if (isObj(r.adjustments)) {
    for (const k of PRAYER_KEYS) {
      const v = r.adjustments[k];
      if (typeof v === "number" && v !== 0) adj[k] = clampAdjustment(v);
    }
  }
  let custom: CustomLocation | null = null;
  if (isObj(r.custom)) {
    const { lat, lng, tz } = r.custom;
    if (typeof lat === "number" && typeof lng === "number" && typeof tz === "string")
      custom = { lat, lng, tz };
  }
  return {
    cityId: typeof r.cityId === "string" ? r.cityId : DEFAULT_PRAYER.cityId,
    custom,
    method: typeof r.method === "string" && METHOD_IDS.includes(r.method) ? r.method : null,
    asr: r.asr === "hanafi" ? "hanafi" : "standard",
    adjustments: adj,
  };
}

export const prayerStore = createStore<PrayerPrefs>("rattil.prayer", DEFAULT_PRAYER, sanitizePrayer);

export interface LastRead {
  surah: number;
  ayah: number;
  page: number | null;
  at: number;
}
export function sanitizeLastRead(raw: unknown): LastRead | null {
  if (!isObj(raw)) return null;
  const { surah, ayah, page, at } = raw;
  if (typeof surah !== "number" || typeof ayah !== "number" || surah < 1 || surah > 114 || ayah < 1)
    return null;
  return {
    surah,
    ayah,
    page: typeof page === "number" && page >= 1 && page <= 604 ? page : null,
    at: typeof at === "number" ? at : 0,
  };
}
export const lastReadStore = createStore<LastRead | null>("rattil.lastRead", null, sanitizeLastRead);
