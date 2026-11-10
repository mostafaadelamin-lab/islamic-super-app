/**
 * Muezzin recordings for the adhan. A few are served by the site itself; the rest of the owner's chosen
 * collection (public/data/adhan-catalog.json, built by tools/adhan_catalog.py) is streamed from its
 * source when chosen. The Fajr adhan ("as-salatu khayrun min an-nawm") has its own recording, chosen
 * separately. Sources: apps/mobile/assets/audio/ADHAN_AUDIO.md.
 * Same rules as apps/mobile/lib/domain/adhan_voices.dart.
 */
import { withBase } from "./base-path";

export interface AdhanVoice {
  /** Stable id kept in the settings: a bundled name, or "iw" + remoteId. */
  id: string;
  nameAr: string;
  nameEn: string;
  /** Mosque / city / country words, may be empty. */
  place: string;
  /** A Fajr adhan (with "as-salatu khayrun min an-nawm"). */
  fajr: boolean;
  /** Bundled: path under public/. */
  file?: string;
  /** From the collection: the recording's id there. */
  remoteId?: number;
  /** Author, source and licence when the licence asks for credit. */
  credit?: string;
}

export const BUNDLED_ADHAN_VOICES: readonly AdhanVoice[] = [
  {
    id: "haram",
    nameAr: "محمد رمضان سعد (الحرم المكي)",
    nameEn: "Mohamed Ramadan Saad (Makkah Haram)",
    place: "",
    fajr: false,
    file: "/audio/adhan_haram.mp3",
  },
  {
    id: "haram_fajr",
    nameAr: "حمد الدغريري (فجر الحرم المكي)",
    nameEn: "Hamad Al-Daghriri (Fajr, Makkah Haram)",
    place: "",
    fajr: true,
    file: "/audio/adhan_haram_fajr.mp3",
  },
  {
    id: "v1",
    nameAr: "صوت هادئ",
    nameEn: "Calm voice",
    place: "",
    fajr: false,
    file: "/audio/adhan.mp3",
    credit: '"Beautiful adhan", Adam-synagda, Wikimedia Commons, CC0',
  },
  {
    id: "v2",
    nameAr: "صوت أقصر",
    nameEn: "Shorter voice",
    place: "",
    fajr: false,
    file: "/audio/adhan_v2.mp3",
    credit: '"The Adhan - Muslim Call to Prayer - Aaqib Azeez", Atcovi, Wikimedia Commons, CC BY-SA 4.0',
  },
];

export const DEFAULT_ADHAN_VOICE = "haram";
export const DEFAULT_FAJR_VOICE = "haram_fajr";
/**
 * A collection id: matches "iw426698", rejects "iw" and "../x".
 * https://regex101.com/?regex=%5Eiw(%5Cd%7B1%2C9%7D)%24&testString=iw426698%0Aiw%0A..%2Fx
 */
const REMOTE_ID_RE = /^iw(\d{1,9})$/;

export function bundledAdhanVoice(id: unknown): AdhanVoice | undefined {
  return BUNDLED_ADHAN_VOICES.find((v) => v.id === id);
}

/** Whether `id` names a bundled voice or a recording of the collection. */
export function isAdhanVoiceId(id: unknown): id is string {
  return typeof id === "string" && (bundledAdhanVoice(id) !== undefined || REMOTE_ID_RE.test(id));
}

export function remoteAdhanId(id: string): number | null {
  const m = REMOTE_ID_RE.exec(id);
  return m ? Number(m[1]) : null;
}

/** What the audio element plays for a voice id (unknown ids get the default voice). */
export function adhanVoiceSrc(id: string, fajr = false): string {
  const b = bundledAdhanVoice(id);
  if (b?.file) return withBase(b.file);
  const remote = remoteAdhanId(id);
  if (remote !== null) return `https://audio.islamweb.net/audio/downloadmp3.php?audioid=${remote}`;
  return withBase(bundledAdhanVoice(fajr ? DEFAULT_FAJR_VOICE : DEFAULT_ADHAN_VOICE)!.file!);
}

interface CatalogEntry {
  id: number;
  muezzin: string;
  place?: string;
  fajr?: boolean;
}

export function voiceFromCatalog(j: CatalogEntry): AdhanVoice {
  return {
    id: `iw${j.id}`,
    nameAr: j.muezzin,
    nameEn: j.muezzin,
    place: j.place ?? "",
    fajr: j.fajr === true,
    remoteId: j.id,
  };
}

let catalog: Promise<AdhanVoice[]> | null = null;

async function fetchCatalog(): Promise<AdhanVoice[]> {
  try {
    const r = await fetch(withBase("/data/adhan-catalog.json"));
    const raw = r.ok ? ((await r.json()) as CatalogEntry[]) : [];
    return [...BUNDLED_ADHAN_VOICES, ...raw.map(voiceFromCatalog)];
  } catch {
    catalog = null; // try again next time
    return [...BUNDLED_ADHAN_VOICES];
  }
}

/** Bundled voices first, then the collection (fetched once). */
export function loadAdhanCatalog(): Promise<AdhanVoice[]> {
  catalog ??= fetchCatalog();
  return catalog;
}

const HARAKA_FIRST = 0x064b; // fathatan
const HARAKA_LAST = 0x0652; // sukun
const LETTER_FOLD: Readonly<Record<string, string>> = { "أ": "ا", "إ": "ا", "آ": "ا", "ة": "ه", "ى": "ي" };

/** Folds Arabic letter variants and drops diacritics so a search finds a name however it is typed. */
export function normalizeArabic(s: string): string {
  let out = "";
  for (const ch of s) {
    const code = ch.codePointAt(0) ?? 0;
    if (code >= HARAKA_FIRST && code <= HARAKA_LAST) continue;
    out += LETTER_FOLD[ch] ?? ch;
  }
  return out.toLowerCase();
}
