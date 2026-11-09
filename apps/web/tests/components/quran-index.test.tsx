import { describe, expect, it } from "vitest";
import { fireEvent, render, screen, within } from "@testing-library/react";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { filterQuarters, juzOfAyah, QUARTERS, quarterBadge, QuranIndex } from "@/components/QuranIndex";

const quran = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../content/quran/dist/quran.v1.json"), "utf8"),
) as { surahs: { ayahs: string[] }[] };

describe("QuranIndex data", () => {
  it("has 240 quarters, 8 per juz, 4 per hizb", () => {
    expect(QUARTERS).toHaveLength(240);
    expect(QUARTERS.filter((q) => q.juz === 30)).toHaveLength(8);
    expect(QUARTERS.filter((q) => q.hizb === 60)).toHaveLength(4);
  });

  it("matches the printed Mushaf index for the first quarters of al-Baqarah", () => {
    const head = QUARTERS.slice(0, 8).map((q) => [quarterBadge(q, "en"), q.start.join(":"), q.page]);
    expect(head).toEqual([
      ["1", "1:1", 1],
      ["1/4", "2:26", 5],
      ["2/4", "2:44", 7],
      ["3/4", "2:60", 9],
      ["2", "2:75", 11],
      ["1/4", "2:92", 14],
      ["2/4", "2:106", 17],
      ["3/4", "2:124", 19],
    ]);
  });

  it("opening words are copied verbatim from the canonical text", () => {
    for (const q of QUARTERS) {
      const ayah = quran.surahs[q.start[0] - 1]!.ayahs[q.start[1] - 1]!.replace(/^۞\s*/, "");
      expect(ayah.startsWith(q.opening)).toBe(true);
      expect(q.opening.length).toBeGreaterThan(0);
    }
  });

  it("groups surahs by the juz where they start", () => {
    expect([1, 2, 3, 4, 5].map((n) => juzOfAyah([n, 1]))).toEqual([1, 1, 3, 4, 6]);
  });

  it("filters quarters by hizb number, page, surah name and words", () => {
    expect(filterQuarters("2").map((q) => q.n)).toEqual([5, 6, 7, 8]);
    expect(filterQuarters("البقرة").every((q) => q.start[0] === 2)).toBe(true);
    expect(filterQuarters("الكهف").length).toBeGreaterThan(0);
  });
});

describe("QuranIndex component", () => {
  it("shows surahs under juz headers and switches to quarters", () => {
    render(<QuranIndex locale="ar" />);
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("فهرس السور");
    const list = screen.getByTestId("surah-list");
    expect(list.querySelectorAll("li")).toHaveLength(114);
    expect(within(list).getAllByRole("heading", { level: 2 })[0]).toHaveTextContent("الجزء الأول");
    const baqarah = screen.getAllByTestId("surah-open")[1]!;
    expect(baqarah).toHaveTextContent("سورة البقرة");
    expect(baqarah).toHaveTextContent("الصفحة ٢ - آياتها ٢٨٦ - مدنية");
    expect(baqarah).toHaveAttribute("href", "/ar/page/2/");

    fireEvent.click(screen.getByTestId("qidx-tab-quarters"));
    const quarters = screen.getByTestId("quarter-list");
    expect(quarters.querySelectorAll("li")).toHaveLength(240);
    const second = screen.getAllByTestId("quarter-open")[1]!;
    expect(second).toHaveTextContent("١/٤");
    expect(second).toHaveTextContent("سورة البقرة: ٢٦ - الصفحة ٥");
    expect(second).toHaveAttribute("href", "/ar/page/5/");

    fireEvent.change(screen.getByTestId("qidx-search"), { target: { value: "الكهف" } });
    expect(screen.getAllByTestId("quarter-open").every((a) => a.textContent?.includes("الكهف"))).toBe(true);
    fireEvent.click(screen.getByRole("button", { name: "مسح البحث" }));
    expect(screen.getAllByTestId("quarter-open")).toHaveLength(240);
  });
});
