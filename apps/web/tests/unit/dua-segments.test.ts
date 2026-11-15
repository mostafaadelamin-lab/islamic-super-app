import { describe, expect, it } from "vitest";
import { duaParts } from "@/lib/dua-segments";
import dalil from "@/generated/dalil-hajj.json";

const duas = (s: string): string[] =>
  duaParts(s)
    .filter((p) => p.dua)
    .map((p) => p.text);

describe("dua shading in Hajj & Umrah steps (owner 2026-11-15)", () => {
  it("never changes the text", () => {
    for (const s of [...dalil.umrah, ...dalil.hajj])
      expect(
        duaParts(s)
          .map((p) => p.text)
          .join(""),
      ).toBe(s);
  });

  it("finds the talbiya, the Quran passages and the words to say on Safa", () => {
    expect(duas(dalil.umrah[0]!)).toEqual([expect.stringMatching(/^\[لبيك اللهم لبيك/)]);
    expect(duas(dalil.umrah[1]!)[0]).toMatch(/^﴿رَبَّنَا آتِنَا.*\[البقرة: ٢٠١\]$/);
    const safa = duas(dalil.umrah[2]!);
    expect(safa).toHaveLength(3);
    expect(safa[1]).toMatch(/^\(لا إله إلا الله وحده لا شريك له/);
    expect(safa[2]).toMatch(/^\(لا إله إلا الله وحده أنجز وعده/);
  });

  it("leaves explanations and names alone", () => {
    expect(duas("وقل: «بسم الله، والله أكبر».")).toEqual(["«بسم الله، والله أكبر»"]);
    expect(duas("تقرأ فيهما «الكافرون» و«الإخلاص»")).toEqual([]);
    expect(duas("يُسنّ للرجل الاضطباع (كشف الكتف الأيمن)")).toEqual([]);
    expect(duas("أشهر الحج (من أول شهر شوال)")).toEqual([]);
  });
});
