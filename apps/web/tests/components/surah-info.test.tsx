import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { render, screen } from "@testing-library/react";
import { SurahInfo } from "@/components/SurahInfo";
import { surahMeta } from "@/lib/pages";
import type { SurahInfoData } from "@/lib/server/content";

const all = (
  JSON.parse(readFileSync("../mobile/assets/content/surah-info.v1.json", "utf8")) as {
    surahs: SurahInfoData[];
  }
).surahs;
const info = (n: number): SurahInfoData => all.find((s) => s.n === n)!;

describe("SurahInfo (the app's surah card)", () => {
  it("shows place, order, ayah count, introduction and reasons for revelation verbatim", () => {
    const i = info(2);
    render(<SurahInfo locale="ar" meta={surahMeta(2)!} info={i} />);
    const box = screen.getByTestId("surah-info");
    expect(box.textContent).toContain("عن السورة وأسباب نزولها");
    expect(box.textContent).toContain("مدنية");
    expect(box.textContent).toContain("٢٨٦");
    expect(box.textContent).toContain("أسباب النزول");
    const firstIntro = i.intro!.split("\n").find((p) => p.trim())!;
    expect(box.textContent).toContain(firstIntro);
  });
  it("says so when there is no data", () => {
    render(<SurahInfo locale="ar" meta={surahMeta(1)!} info={null} />);
    expect(screen.getByTestId("surah-info").textContent).toContain("المعلومات غير متاحة");
  });
  it("has no Microsoft Word / HTML / CSS leftovers in any surah card or al-Wahidi entry (app + web share this file)", () => {
    const junk = /mso-|Mso[A-Z]|Style Definitions|font-family|Calibri|X-NONE|EN-US|AR-SA|<!--|<\/?[a-z][^>]*>|\[if |endif\]|^(Normal|0|false|true)$|جدول عادي/m;
    const bad: string[] = [];
    for (const s of all as (SurahInfoData & { wahidi?: { ayah: number; text: string }[] })[]) {
      for (const k of ["type", "order", "intro", "purposes", "asbab"] as const) {
        const v = (s as unknown as Record<string, string | undefined>)[k] ?? "";
        if (junk.test(v)) bad.push(`${s.n}.${k}`);
      }
      for (const w of s.wahidi ?? []) if (junk.test(w.text)) bad.push(`${s.n}:${w.ayah}`);
    }
    expect(bad).toEqual([]);
  });
});
