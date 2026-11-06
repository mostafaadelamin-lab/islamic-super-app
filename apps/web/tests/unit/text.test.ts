// @vitest-environment node
import { readRepoJson } from "../repo";
import { normalizeArabic, queryLength, SearchIndex } from "@/lib/search";
import { RENDER_MAP, renderQuranText } from "@/lib/quran-render";
import { localizeDigits, toArabicIndic } from "@/lib/digits";
import { dictionaries, dirOf, isLocale, t, translate } from "@/lib/i18n";
import { href, switchLocalePath } from "@/lib/locale-path";

const norm = readRepoJson<{ vectors: { in: string; out: string }[] }>(
  "packages/shared-schemas/search-normalization.json",
);
const render = readRepoJson<{ map: Record<string, string> }>("packages/shared-schemas/quran-render.json");
const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");

describe("search normalisation", () => {
  it.each(norm.vectors.map((v) => [v.in, v.out] as const))("vector %j", (input, out) => {
    expect(normalizeArabic(input)).toBe(out);
  });
  it("counts letters after normalisation", () => {
    expect(queryLength("ٱلۡ")).toBe(2);
    expect(queryLength("َ ")).toBe(0);
  });
});

describe("SearchIndex", () => {
  const index = new SearchIndex(quran.surahs.map((s) => s.ayahs));
  it("indexes all 6236 ayahs", () => {
    expect(index.size).toBe(6236);
  });
  it("is diacritic-insensitive and returns original text", () => {
    const r = index.search("الحمد لله رب");
    expect(r.results.map((x) => `${x.s}:${x.a}`)).toContain("1:2");
    const hit = r.results.find((x) => x.s === 1 && x.a === 2);
    expect(hit?.text).toBe(quran.surahs[0]?.ayahs[1]);
    // query with full diacritics finds the same ayah
    const r2 = index.search("ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ");
    expect(r2.results.map((x) => `${x.s}:${x.a}`)).toContain("1:2");
  });
  it("ta marbuta / hamza variants match", () => {
    expect(index.search("رحمة").total).toBeGreaterThan(50);
    expect(index.search("اياك نعبد").results[0]).toMatchObject({ s: 1, a: 5 });
  });
  it("limits results but reports the total", () => {
    const r = index.search("الله", 10);
    expect(r.results).toHaveLength(10);
    expect(r.total).toBeGreaterThan(1000);
  });
  it("rejects queries shorter than 2 letters", () => {
    expect(index.search("ا")).toEqual({ total: 0, results: [] });
    expect(index.search("   ")).toEqual({ total: 0, results: [] });
  });
  it("returns nothing for unknown words", () => {
    expect(index.search("xyz").total).toBe(0);
  });
});

describe("display-only render map", () => {
  it("uses the shared map", () => {
    expect(RENDER_MAP).toEqual(render.map);
    expect(Object.keys(RENDER_MAP)).toHaveLength(3);
  });
  it("maps KFGQPC open-tanween code points to Amiri Quran ones and nothing else", () => {
    expect(renderQuranText("ٖٗٞ")).toBe("ࣰࣱࣲ");
    const s = "قَيِّمٗا لِّيُنذِرَ";
    expect(renderQuranText(s)).toBe(s.replace("ٗ", "ࣰ"));
    expect(renderQuranText("abc")).toBe("abc");
  });
  it("is a pure function (canonical text stays unchanged)", () => {
    const original = quran.surahs[17]?.ayahs[1] as string;
    const copy = String(original);
    renderQuranText(original);
    expect(original).toBe(copy);
  });
  it("canonical content never contains the display code points", () => {
    for (const s of quran.surahs) for (const a of s.ayahs) expect(/[ࣰ-ࣲ]/.test(a)).toBe(false);
  });
  it("search normalisation of rendered and canonical text agrees", () => {
    const a = quran.surahs[17]?.ayahs[1] as string;
    expect(normalizeArabic(renderQuranText(a))).toBe(normalizeArabic(a));
  });
});

describe("digits", () => {
  it("converts to Arabic-Indic", () => {
    expect(toArabicIndic(1234567890)).toBe("١٢٣٤٥٦٧٨٩٠");
    expect(toArabicIndic("12:05")).toBe("١٢:٠٥");
    expect(localizeDigits(42, "en")).toBe("42");
    expect(localizeDigits(42, "ar")).toBe("٤٢");
  });
});

describe("i18n", () => {
  it("ar and en have identical key sets", () => {
    expect(Object.keys(dictionaries.ar).sort()).toEqual(Object.keys(dictionaries.en).sort());
  });
  it("placeholders are the same in both languages", () => {
    const ph = (s: string): string[] => (s.match(/\{\w+\}/g) ?? []).sort();
    for (const k of Object.keys(dictionaries.en)) {
      expect(ph(dictionaries.ar[k] as string), k).toEqual(ph(dictionaries.en[k] as string));
    }
  });
  it("translates with interpolation and falls back to the key", () => {
    expect(t("en", "quran.ayahCount", { count: 7 })).toBe("7 ayahs");
    expect(t("ar", "quran.ayahCount", { count: "٧" })).toBe("٧ آية");
    expect(t("en", "missing.key")).toBe("missing.key");
    expect(translate({ a: "{x} and {y}" }, "a", { x: 1 })).toBe("1 and {y}");
  });
  it("locale helpers", () => {
    expect(isLocale("ar")).toBe(true);
    expect(isLocale("fr")).toBe(false);
    expect(dirOf("ar")).toBe("rtl");
    expect(dirOf("en")).toBe("ltr");
  });
  it("switches locale paths", () => {
    expect(switchLocalePath("/ar/surah/2/", "en")).toBe("/en/surah/2/");
    expect(switchLocalePath("/en", "ar")).toBe("/ar/");
    expect(switchLocalePath("/", "en")).toBe("/en/");
    expect(switchLocalePath("/xx/a", "ar")).toBe("/ar/");
    expect(href("ar")).toBe("/ar/");
    expect(href("en", "/page/3/")).toBe("/en/page/3/");
  });
});
