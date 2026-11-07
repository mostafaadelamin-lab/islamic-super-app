import { readRepoJson } from "../repo";
import {
  canonicalWords,
  clampPage,
  fitFontSize,
  isCentredPage,
  lookupFrom,
  pageAyahRefs,
  pageSurahs,
  resolveLine,
  resolvePage,
  swipeTarget,
  type MushafLinesFile,
  type ResolvedPage,
  type Segment,
} from "@/lib/mushaf";
import { RENDER_MAP, renderQuranText } from "@/lib/quran-render";
import { ayahsOnPage } from "@/lib/pages";

const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");
const lines = readRepoJson<MushafLinesFile>("content/quran/dist/mushaf-lines.v1.json");
const canonical = quran.surahs.map((s) => s.ayahs);
const lookup = lookupFrom(canonical);
const all: ResolvedPage[] = lines.pages.map((p) => resolvePage(p, lookup));
const segments = (p: ResolvedPage): Segment[] =>
  p.lines.flatMap((l) => (l.kind === "text" ? l.segments : []));

/** Inverse of the display map (the map is a bijection on three code points). */
const UNMAP = Object.fromEntries(Object.entries(RENDER_MAP).map(([k, v]) => [v, k]));
const unrender = (s: string): string => [...s].map((c) => UNMAP[c] ?? c).join("");

describe("Mushaf line layout (15-line Madinah)", () => {
  it("has 604 pages: pages 1–2 with 8 lines, every other page with 15", () => {
    expect(lines.pages).toHaveLength(604);
    lines.pages.forEach((p, i) => {
      expect(p.page).toBe(i + 1);
      expect(p.lines).toHaveLength(isCentredPage(p.page) ? 8 : 15);
    });
  });

  it("every ayah is rebuilt exactly from its segments — only canonical words, in order, nothing else", () => {
    const rebuilt = new Map<string, string[]>();
    for (const p of all) {
      for (const g of segments(p)) {
        const k = `${g.s}:${g.a}`;
        rebuilt.set(k, [...(rebuilt.get(k) ?? []), unrender(g.text)]);
      }
    }
    let count = 0;
    canonical.forEach((ayahs, si) =>
      ayahs.forEach((text, ai) => {
        count++;
        expect(rebuilt.get(`${si + 1}:${ai + 1}`)?.join(" ")).toBe(text);
      }),
    );
    expect(count).toBe(6236);
    expect(rebuilt.size).toBe(6236);
  });

  it("each rendered segment is the display map applied to canonical words w0..w1, and nothing else", () => {
    for (const raw of lines.pages) {
      for (const l of raw.lines) {
        if (l.k !== "text") continue;
        const r = resolveLine(l, lookup);
        if (r.kind !== "text") throw new Error("kind");
        l.g.forEach(([s, a, w0, w1, end], i) => {
          const words = canonical[s - 1]![a - 1]!.split(" ").slice(w0, w1).join(" ");
          expect(r.segments[i]).toEqual({ s, a, text: renderQuranText(words), end: end === 1 });
        });
      }
    }
  });

  it("applies the display glyph map only to the rendered string (open tanween)", () => {
    const withMark = segments(all[292]!).find((g) => unrender(g.text) !== g.text); // page 293, al-Kahf
    expect(withMark).toBeDefined();
    expect(withMark!.text).toMatch(/[ࣰ-ࣲ]/);
    expect(withMark!.text).not.toMatch(/[ٖٗٞ]/);
    // the canonical text still has the KFGQPC code points
    expect(canonical[withMark!.s - 1]![withMark!.a - 1]).toMatch(/[ٖٗٞ]/);
  });

  it("ayah-end markers: exactly one per ayah, on its last segment", () => {
    const ends = all.flatMap((p) => segments(p).filter((g) => g.end));
    expect(ends).toHaveLength(6236);
    for (const p of all) {
      for (const g of segments(p)) {
        const words = canonical[g.s - 1]![g.a - 1]!.split(" ");
        if (g.end) expect(unrender(g.text).split(" ").at(-1)).toBe(words.at(-1));
      }
    }
  });

  it("basmala lines show al-Fatihah 1:1 (display-mapped) and precede ayah 1 of every surah but 1 and 9", () => {
    const basmalas = all.flatMap((p) => p.lines.filter((l) => l.kind === "basmala"));
    expect(basmalas).toHaveLength(112);
    for (const b of basmalas) {
      if (b.kind !== "basmala") throw new Error("kind");
      expect(b.text).toBe(renderQuranText(canonical[0]![0]!));
      expect([1, 9]).not.toContain(b.s);
    }
    const bands = all.flatMap((p) => p.lines.filter((l) => l.kind === "sura"));
    expect(bands).toHaveLength(114);
  });

  it("the ayahs on each page match the Madinah page boundaries (pages.v1.json)", () => {
    for (const p of all) expect(pageAyahRefs(p)).toEqual(ayahsOnPage(p.page));
    expect(pageSurahs(all[603]!)).toEqual([112, 113, 114]);
    expect(pageSurahs(all[0]!)).toEqual([1]);
  });

  it("rejects word ranges outside the ayah and unknown ayahs", () => {
    expect(() => canonicalWords("a b c", 2, 4)).toThrow(RangeError);
    expect(() => canonicalWords("a b c", 1, 1)).toThrow(RangeError);
    expect(canonicalWords("a b c", 1, 3)).toBe("b c");
    expect(() => lookup(115, 1)).toThrow(RangeError);
    expect(() => lookup(1, 8)).toThrow(RangeError);
  });
});

describe("page turning", () => {
  it("RTL (Arabic): swiping right turns forward, left goes back", () => {
    expect(swipeTarget(120, 360, 10, "rtl")).toBe(11);
    expect(swipeTarget(-120, 360, 10, "rtl")).toBe(9);
  });
  it("LTR (English): swiping left turns forward", () => {
    expect(swipeTarget(-120, 360, 10, "ltr")).toBe(11);
    expect(swipeTarget(120, 360, 10, "ltr")).toBe(9);
  });
  it("short drags snap back unless they are a fast fling", () => {
    expect(swipeTarget(30, 360, 10, "rtl")).toBeNull();
    expect(swipeTarget(30, 360, 10, "rtl", 0.9)).toBe(11);
    expect(swipeTarget(10, 360, 10, "rtl", 2)).toBeNull(); // a tap, not a fling
    expect(swipeTarget(70, 1000, 10, "rtl")).toBeNull(); // < 18% of a wide page
  });
  it("stays within 1..604", () => {
    expect(swipeTarget(200, 360, 604, "rtl")).toBeNull();
    expect(swipeTarget(-200, 360, 1, "rtl")).toBeNull();
    expect(swipeTarget(200, 360, 603, "rtl")).toBe(604);
  });
  it("clampPage and fitFontSize", () => {
    expect(clampPage(0)).toBe(1);
    expect(clampPage(605)).toBe(604);
    expect(clampPage(12.6)).toBe(13);
    expect(clampPage(Number.NaN)).toBe(1);
    expect(fitFontSize([300, 320, 310], 20, 300)).toBeCloseTo(18.75);
    expect(fitFontSize([], 20, 300)).toBe(20);
    expect(fitFontSize([10], 20, 1000)).toBe(64);
    expect(fitFontSize([1000], 20, 100)).toBe(8);
  });
});
