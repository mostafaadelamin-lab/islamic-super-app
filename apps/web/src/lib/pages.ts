import pagesJson from "@/generated/pages.json";
import surahMetaJson from "@/generated/surah-meta.json";

export type Ref = [number, number];
export interface PageDef {
  page: number;
  start: Ref;
  end: Ref;
}
export interface JuzDef {
  juz: number;
  page: number;
  start: Ref;
}
export interface SurahMeta {
  n: number;
  nameAr: string;
  nameEn: string;
  translit: string;
  revelation: "meccan" | "medinan";
  ayahCount: number;
}

export const SURAHS: readonly SurahMeta[] = surahMetaJson as SurahMeta[];
export const PAGES: readonly PageDef[] = (pagesJson as unknown as { pages: PageDef[] }).pages;
export const JUZ: readonly JuzDef[] = (pagesJson as unknown as { juz: JuzDef[] }).juz;
export const PAGE_COUNT = PAGES.length;

const cmp = (a: Ref, b: Ref): number => a[0] - b[0] || a[1] - b[1];

export function isValidPage(p: unknown): p is number {
  return typeof p === "number" && Number.isInteger(p) && p >= 1 && p <= PAGE_COUNT;
}

/** Parses user input for "go to page"; returns null if not an integer in 1..604. */
export function parsePageInput(raw: string): number | null {
  const s = raw.trim().replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660));
  if (!/^\d+$/.test(s)) return null;
  const n = Number(s);
  return isValidPage(n) ? n : null;
}

export function pageDef(p: number): PageDef {
  if (!isValidPage(p)) throw new RangeError(`page ${p} out of range`);
  return PAGES[p - 1] as PageDef;
}

export function pageForAyah(surah: number, ayah: number): number {
  let lo = 0;
  let hi = PAGES.length - 1;
  const ref: Ref = [surah, ayah];
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (cmp((PAGES[mid] as PageDef).start, ref) <= 0) lo = mid;
    else hi = mid - 1;
  }
  return lo + 1;
}

export function juzForPage(p: number): number {
  let j = 1;
  for (const z of JUZ) if (z.page <= p) j = z.juz;
  return j;
}

/** All [surah, ayah] references on a page, in order. */
export function ayahsOnPage(p: number): Ref[] {
  const { start, end } = pageDef(p);
  const out: Ref[] = [];
  let [s, a] = start;
  while (cmp([s, a], end) <= 0) {
    out.push([s, a]);
    const count = (SURAHS[s - 1] as SurahMeta).ayahCount;
    if (a < count) a++;
    else {
      s++;
      a = 1;
    }
  }
  return out;
}

export function surahMeta(n: number): SurahMeta | undefined {
  return SURAHS[n - 1];
}

export function isValidAyah(surah: number, ayah: number): boolean {
  const m = SURAHS[surah - 1];
  return !!m && Number.isInteger(ayah) && ayah >= 1 && ayah <= m.ayahCount;
}
