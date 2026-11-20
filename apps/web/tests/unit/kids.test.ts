vi.mock("server-only", () => ({}));
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { KIDS, kidsSeries } from "@/lib/kids";
import { ruqyahPassages } from "@/lib/server/ruqyah";
import { isValidAyah } from "@/lib/pages";

const PAGES = 604;
const AYAHS = 6236;

describe("kids section and ruqyah", () => {
  it("ruqyah verses are valid references and duas carry their source text", () => {
    for (const r of [KIDS.ruqyah, KIDS.ruqyahKids]) {
      for (const i of r.items) {
        if (i.t === "q") {
          expect(isValidAyah(i.s, i.from) && isValidAyah(i.s, i.to)).toBe(true);
          expect(i.to).toBeGreaterThanOrEqual(i.from);
        } else {
          expect(i.text.length).toBeGreaterThan(10);
        }
      }
    }
    expect(KIDS.ruqyah.full?.url).toMatch(/^https:\/\//);
  });

  it("passages hold the ayah texts, with the basmala before a whole surah (not al-Fatiha)", () => {
    const ps = ruqyahPassages(KIDS.ruqyahKids.items);
    const ikhlas = ps.find((p) => p.s === 112);
    expect(ikhlas?.ayahs).toHaveLength(4);
    expect(ikhlas?.basmala).toBeTruthy();
    const fatiha = ruqyahPassages(KIDS.ruqyah.items).find((p) => p.s === 1);
    expect(fatiha?.basmala).toBeUndefined();
  });

  it("series: prophets, stories; every episode has a url", () => {
    expect(kidsSeries("kids-prophets")?.episodes.length).toBeGreaterThan(20);
    expect(KIDS.series.filter((s) => s.group === "stories").length).toBeGreaterThan(0);
    for (const s of KIDS.series) for (const e of s.episodes) expect(e.url).toMatch(/^https:\/\//);
    expect(KIDS.teacher.reciters).toContain("Minshawy_Teacher_128kbps");
  });

  it("the modern prophets' series are published YouTube videos (checked: no prophet's face)", () => {
    for (const id of ["kids-prophets-new", "kids-prophets-3d"]) {
      const s = kidsSeries(id);
      expect(s?.group).toBe("prophets");
      expect(s?.episodes.length).toBeGreaterThanOrEqual(5);
      for (const e of s?.episodes ?? []) expect(e.youtube).toMatch(/^[\w-]{11}$/);
    }
  });
});

describe("printed Mushaf pages", () => {
  it("every ayah of the Quran ends exactly once, in order, across the 604 pages", () => {
    let ends = 0;
    let last: [number, number] = [0, 0];
    for (let p = 1; p <= PAGES; p++) {
      const raw = readFileSync(join(__dirname, "../../public/data/printed", `${p}.json`), "utf8");
      const page = JSON.parse(raw) as { lines: unknown[] };
      expect(page.lines.length).toBeLessThanOrEqual(15);
      for (const line of page.lines) {
        if (!Array.isArray(line) || typeof line[0] === "string") continue;
        for (const w of line as [number, number, string, number][]) {
          const before = last[0] < w[0] || (last[0] === w[0] && last[1] <= w[1]);
          expect(before).toBe(true);
          last = [w[0], w[1]];
          if (w[3] === 1) ends++;
        }
      }
    }
    expect(ends).toBe(AYAHS);
  });
});
