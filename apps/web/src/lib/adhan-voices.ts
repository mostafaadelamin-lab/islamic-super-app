/**
 * Muezzin recordings for the adhan, openly licensed (Wikimedia Commons) and served by the site itself. The Fajr adhan ("as-salatu khayrun min an-nawm") has its own recording, chosen
 * separately. Sources: apps/mobile/assets/audio/ADHAN_AUDIO.md.
 * Same rules as apps/mobile/lib/domain/adhan_voices.dart.
 */
import { withBase } from "./base-path";

export interface AdhanVoice {
  /** Stable id kept in the settings. */
  id: string;
  nameAr: string;
  nameEn: string;
  /** Mosque / city / country words, may be empty. */
  place: string;
  /** A Fajr adhan (with "as-salatu khayrun min an-nawm"). */
  fajr: boolean;
  /** Bundled: path under public/. */
  file?: string;
  /** Author, source and licence when the licence asks for credit. */
  credit?: string;
}

export const BUNDLED_ADHAN_VOICES: readonly AdhanVoice[] = [
  {
    id: "haram",
    nameAr: "أذان المسجد الحرام بمكة المكرمة",
    nameEn: "Adhan of the Grand Mosque, Makkah",
    place: "مكة المكرمة",
    fajr: false,
    file: "/audio/adhan_haram.mp3",
    credit: '"Adhan, Great Mosque of Mecca - Jan 21, 2013", Seyfula Islam, Wikimedia Commons, CC BY 3.0',
  },
  {
    id: "madinah",
    nameAr: "أذان المسجد النبوي بالمدينة المنورة",
    nameEn: "Adhan of the Prophet's Mosque, Madinah",
    place: "المدينة المنورة",
    fajr: false,
    file: "/audio/adhan_madinah.mp3",
    credit: '"Call to prayer from the prophet\'s mosque", ejaz215, Wikimedia Commons, CC BY 3.0',
  },
  {
    id: "fakhry",
    nameAr: "صباح فخري",
    nameEn: "Sabah Fakhri",
    place: "حلب، سوريا",
    fajr: false,
    file: "/audio/adhan_fakhry.mp3",
    credit: '"Call to prayer by Sabah Fakhry", Wikimedia Commons, public domain',
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
    nameAr: "عاقب عزيز",
    nameEn: "Aaqib Azeez",
    place: "",
    fajr: false,
    file: "/audio/adhan_v2.mp3",
    credit: '"The Adhan - Muslim Call to Prayer - Aaqib Azeez", Atcovi, Wikimedia Commons, CC BY-SA 4.0',
  },
  {
    id: "haram_fajr",
    nameAr: "أذان الفجر (المركز الإسلامي في مالمو)",
    nameEn: "Fajr adhan (Islamic Center, Malmö)",
    place: "",
    fajr: true,
    file: "/audio/adhan_haram_fajr.mp3",
    credit: '"Eid al-Fitr Fajr azan at Malmö Mosque - 19 August 2012", Islamic Center Malmö, Wikimedia Commons, CC BY 3.0',
  },
];

export const DEFAULT_ADHAN_VOICE = "haram";
export const DEFAULT_FAJR_VOICE = "haram_fajr";

export function bundledAdhanVoice(id: unknown): AdhanVoice | undefined {
  return BUNDLED_ADHAN_VOICES.find((v) => v.id === id);
}

/** Whether `id` names one of the bundled, openly licensed voices (the earlier downloadable collection was removed). */
export function isAdhanVoiceId(id: unknown): id is string {
  return typeof id === "string" && bundledAdhanVoice(id) !== undefined;
}

/** What the audio element plays for a voice id (unknown ids get the default voice). */
export function adhanVoiceSrc(id: string, fajr = false): string {
  const b = bundledAdhanVoice(id);
  if (b?.file) return withBase(b.file);
  return withBase(bundledAdhanVoice(fajr ? DEFAULT_FAJR_VOICE : DEFAULT_ADHAN_VOICE)!.file!);
}

/** Every muezzin the site offers. */
export function loadAdhanCatalog(): Promise<AdhanVoice[]> {
  return Promise.resolve([...BUNDLED_ADHAN_VOICES]);
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
