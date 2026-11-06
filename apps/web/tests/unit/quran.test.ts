// @vitest-environment node
import { createHash } from "node:crypto";
import { readRepoJson } from "../repo";
import {
  ayahsOnPage,
  isValidAyah,
  isValidPage,
  JUZ,
  juzForPage,
  pageDef,
  pageForAyah,
  PAGE_COUNT,
  PAGES,
  parsePageInput,
  surahMeta,
  SURAHS,
} from "@/lib/pages";

interface Quran {
  surahs: { n: number; ayahCount: number; ayahs: string[]; en: string[]; nameAr: string }[];
}
interface Integrity {
  allAyahsSha256: string;
  ayahCount: number;
  ayahCounts: number[];
  pageCount: number;
  surahCount: number;
  surahSha256: string[];
}
const quran = readRepoJson<Quran>("content/quran/dist/quran.v1.json");
const integrity = readRepoJson<Integrity>("content/quran/dist/integrity.v1.json");
const reference = readRepoJson<{
  ayahCounts: number[];
  madinahPageSpotChecks: { page: number; start: [number, number]; end: [number, number] }[];
}>("tests/vectors/quran-reference.json");
const sha256 = (s: string): string => createHash("sha256").update(s, "utf8").digest("hex");

describe("Quran integrity", () => {
  it("has 114 surahs and 6236 ayahs", () => {
    expect(quran.surahs).toHaveLength(114);
    expect(quran.surahs.reduce((n, s) => n + s.ayahs.length, 0)).toBe(6236);
    expect(integrity.surahCount).toBe(114);
    expect(integrity.ayahCount).toBe(6236);
  });
  it("ayah counts match the independent reference", () => {
    expect(quran.surahs.map((s) => s.ayahs.length)).toEqual(reference.ayahCounts);
    expect(quran.surahs.map((s) => s.ayahCount)).toEqual(reference.ayahCounts);
    expect(integrity.ayahCounts).toEqual(reference.ayahCounts);
    expect(SURAHS.map((s) => s.ayahCount)).toEqual(reference.ayahCounts);
    expect(quran.surahs.every((s) => s.en.length === s.ayahs.length)).toBe(true);
  });
  it("allAyahsSha256 matches", () => {
    let all = "";
    for (const s of quran.surahs) s.ayahs.forEach((text, i) => (all += `${s.n}|${i + 1}|${text}\n`));
    expect(sha256(all)).toBe(integrity.allAyahsSha256);
  });
  it("every surahSha256 matches", () => {
    expect(integrity.surahSha256).toHaveLength(114);
    quran.surahs.forEach((s, i) =>
      expect(sha256(s.ayahs.join("\n")), `surah ${s.n}`).toBe(integrity.surahSha256[i]),
    );
  });
  it("surah metadata used by the web app mirrors the content file", () => {
    SURAHS.forEach((m, i) => {
      expect(m.n).toBe(i + 1);
      expect(m.nameAr).toBe(quran.surahs[i]?.nameAr);
    });
  });
});

describe("Madinah page boundaries", () => {
  it("has 604 pages and 30 juz", () => {
    expect(PAGE_COUNT).toBe(604);
    expect(integrity.pageCount).toBe(604);
    expect(JUZ).toHaveLength(30);
  });
  it("pages are contiguous and cover all 6236 ayahs exactly once", () => {
    let total = 0;
    let prevEnd: [number, number] | null = null;
    for (const p of PAGES) {
      const refs = ayahsOnPage(p.page);
      total += refs.length;
      if (prevEnd) {
        const [s, a] = prevEnd;
        const count = reference.ayahCounts[s - 1] as number;
        const expectedStart = a < count ? [s, a + 1] : [s + 1, 1];
        expect(p.start, `page ${p.page}`).toEqual(expectedStart);
      } else {
        expect(p.start).toEqual([1, 1]);
      }
      prevEnd = p.end;
    }
    expect(prevEnd).toEqual([114, 6]);
    expect(total).toBe(6236);
  });
  it.each(reference.madinahPageSpotChecks.map((c) => [c.page, c] as const))("spot check page %i", (_p, c) => {
    expect(pageDef(c.page).start).toEqual(c.start);
    expect(pageDef(c.page).end).toEqual(c.end);
  });
  it("pageForAyah finds the page for every ayah", () => {
    expect(pageForAyah(1, 1)).toBe(1);
    expect(pageForAyah(2, 5)).toBe(2);
    expect(pageForAyah(2, 6)).toBe(3);
    expect(pageForAyah(114, 6)).toBe(604);
    for (const p of [1, 50, 300, 604]) for (const [s, a] of ayahsOnPage(p)) expect(pageForAyah(s, a)).toBe(p);
  });
  it("juzForPage", () => {
    expect(juzForPage(1)).toBe(1);
    expect(juzForPage(21)).toBe(1);
    expect(juzForPage(22)).toBe(2);
    expect(juzForPage(604)).toBe(30);
  });
  it("validates pages and ayahs", () => {
    expect(isValidPage(1)).toBe(true);
    expect(isValidPage(604)).toBe(true);
    expect(isValidPage(0)).toBe(false);
    expect(isValidPage(605)).toBe(false);
    expect(isValidPage(1.5)).toBe(false);
    expect(() => pageDef(0)).toThrow(RangeError);
    expect(isValidAyah(1, 7)).toBe(true);
    expect(isValidAyah(1, 8)).toBe(false);
    expect(isValidAyah(115, 1)).toBe(false);
    expect(surahMeta(115)).toBeUndefined();
  });
  it.each([
    ["1", 1],
    [" 604 ", 604],
    ["٣٠٠", 300],
    ["0", null],
    ["605", null],
    ["-1", null],
    ["1.5", null],
    ["abc", null],
    ["", null],
    ["1e2", null],
  ] as const)("parsePageInput(%j) = %j", (input, expected) => {
    expect(parsePageInput(input)).toBe(expected);
  });
});
