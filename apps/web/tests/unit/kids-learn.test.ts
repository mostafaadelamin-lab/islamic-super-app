import { existsSync } from "node:fs";
import { join } from "node:path";
import { LEARN, bookById, onShelf, shelfKey } from "@/lib/kids-learn";
import {
  bookPageUrl,
  levelCount,
  readCardCounts,
  readMemorized,
  todayKey,
  writeCardCounts,
  writeMemorized,
} from "@/lib/kids-learn-store";
import { t } from "@/lib/i18n";

const PUBLIC = join(__dirname, "../../public");

describe("kids learning corner", () => {
  it("600 hadith in four contiguous levels, no private-use glyphs", () => {
    expect(LEARN.hadith).toHaveLength(600);
    const lv = LEARN.hadithLevels;
    expect(lv.map((l) => l.level)).toEqual([1, 2, 3, 4]);
    expect(lv[0]?.from).toBe(1);
    expect(lv.at(-1)?.to).toBe(600);
    expect(lv.reduce((a, l) => a + levelCount(l), 0)).toBe(600);
    for (const h of LEARN.hadith) {
      expect(h.trim().length).toBeGreaterThan(0);
      expect(/[-]/.test(h)).toBe(false);
    }
  });

  it("every shelf has books with a bundled cover and a translated title", () => {
    for (const s of LEARN.shelves) {
      expect(onShelf(s).length).toBeGreaterThan(0);
      expect(t("ar", shelfKey(s))).not.toBe(shelfKey(s));
      expect(t("en", shelfKey(s))).not.toBe(shelfKey(s));
    }
    for (const b of LEARN.books) {
      expect(existsSync(join(PUBLIC, "kids/covers", `${b.id}.webp`))).toBe(true);
      expect(bookPageUrl(LEARN.booksBase, b, 1)).toBe(`https://rattilwasalli.com/kids-books/${b.id}/1.webp`);
    }
    expect(bookById(LEARN.books[0]!.id)).toBe(LEARN.books[0]);
  });

  it("adhkar cards as text: 19 adhkar with the cards' own counts", () => {
    expect(LEARN.cardAdhkar.map((c) => c.n)).toEqual(Array.from({ length: 19 }, (_, i) => i + 1));
    for (const c of LEARN.cardAdhkar) {
      expect(c.text.length).toBeGreaterThan(5);
      expect(/[\uE000-\uF8FF]/.test(c.text)).toBe(false);
      expect(c.m + c.e).toBeGreaterThan(0);
    }
    expect(LEARN.cardAdhkar[8]).toMatchObject({ m: 0, e: 1 });
  });

  it("steps: the book's text with our own 3D pictures, all bundled", () => {
    expect(LEARN.wudu.filter((s) => s.pic)).toHaveLength(9);
    expect(LEARN.salah.filter((s) => s.pic)).toHaveLength(12);
    for (const s of [...LEARN.wudu, ...LEARN.salah]) {
      expect(s.title.trim()).not.toBe("");
      expect(s.text.trim()).not.toBe("");
      if (s.pic) expect(existsSync(join(PUBLIC, "kids/steps", `${s.pic}.webp`))).toBe(true);
    }
    expect(LEARN.salah.at(-1)?.ayah).toContain("الْقَيُّومُ");
  });

  it("memorised hadith and today's cards are kept in this browser", () => {
    writeMemorized(new Set([3, 1]));
    expect([...readMemorized()]).toEqual([1, 3]);
    writeCardCounts({ m1: 1 });
    expect(readCardCounts()).toEqual({ m1: 1 });
    expect(todayKey(new Date(2026, 10, 20))).toBe("2026-11-20");
  });
});
