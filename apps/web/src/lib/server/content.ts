import "server-only";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { SurahInfoData } from "../surah-info";
import { resolvePage, type MushafLinesFile, type ResolvedPage } from "../mushaf";

interface QuranSurah {
  n: number;
  nameAr: string;
  nameEn: string;
  translit: string;
  revelation: string;
  ayahCount: number;
  ayahs: string[];
  en: string[];
}
interface QuranFile {
  surahs: QuranSurah[];
}

let cache: QuranFile | null = null;
function quran(): QuranFile {
  if (!cache) {
    const file = join(process.cwd(), "../../content/quran/dist/quran.v1.json");
    cache = JSON.parse(readFileSync(file, "utf8")) as QuranFile;
  }
  return cache;
}

export function surahAyahs(n: number): string[] {
  const s = quran().surahs[n - 1];
  if (!s) throw new RangeError(`surah ${n}`);
  return s.ayahs;
}

export function ayahText(s: number, a: number): string {
  const t = surahAyahs(s)[a - 1];
  if (t === undefined) throw new RangeError(`ayah ${s}:${a}`);
  return t;
}

let linesCache: MushafLinesFile | null = null;
function mushafLines(): MushafLinesFile {
  if (!linesCache) {
    const file = join(process.cwd(), "../../content/quran/dist/mushaf-lines.v1.json");
    linesCache = JSON.parse(readFileSync(file, "utf8")) as MushafLinesFile;
  }
  return linesCache;
}

/** A Mushaf page resolved against the canonical text at build time (for the static HTML of the route). */
export function mushafPage(page: number): ResolvedPage {
  const raw = mushafLines().pages[page - 1];
  if (!raw || raw.page !== page) throw new RangeError(`mushaf page ${page}`);
  return resolvePage(raw, ayahText);
}

/** The app's surah card data (apps/mobile/assets/content/surah-info.v1.json, verbatim from a published source). */
export type { SurahInfoData };
let infoCache: SurahInfoData[] | null = null;
export function surahInfo(n: number): SurahInfoData | null {
  if (!infoCache) {
    const file = join(process.cwd(), "../mobile/assets/content/surah-info.v1.json");
    infoCache = (JSON.parse(readFileSync(file, "utf8")) as { surahs: SurahInfoData[] }).surahs;
  }
  return infoCache.find((s) => s.n === n) ?? null;
}
