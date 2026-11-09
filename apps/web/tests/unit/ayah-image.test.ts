import { CARD_WIDTH, cardHeight, wrapLines } from "@/lib/ayah-image";

/** Every character is one unit wide, so widths are easy to reason about. */
const measure = (s: string): number => s.length;
const NARROW = 9;
const MIN_CARD = CARD_WIDTH;
const MANY_LINES = 30;

describe("ayah image", () => {
  it("wraps words greedily without splitting a word", () => {
    expect(wrapLines("aaa bbb ccc ddd", NARROW, measure)).toEqual(["aaa bbb", "ccc ddd"]);
    expect(wrapLines("  a   b  ", NARROW, measure)).toEqual(["a b"]);
    expect(wrapLines("averyveryverylongword x", NARROW, measure)).toEqual(["averyveryverylongword", "x"]);
    expect(wrapLines("", NARROW, measure)).toEqual([]);
  });

  it("keeps the text unchanged apart from line breaks", () => {
    const ayah = "ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ";
    expect(wrapLines(ayah, NARROW, measure).join(" ")).toBe(ayah);
  });

  it("is at least square and grows with long ayahs", () => {
    expect(cardHeight(1)).toBe(MIN_CARD);
    expect(cardHeight(MANY_LINES)).toBeGreaterThan(MIN_CARD);
  });
});
