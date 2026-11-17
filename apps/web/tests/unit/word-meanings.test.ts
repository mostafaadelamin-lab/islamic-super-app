import { readFileSync } from "node:fs";
import { gunzipSync } from "node:zlib";
import { join } from "node:path";
import { readRepoJson } from "../repo";
import { SURAHS } from "@/lib/pages";
import {
  loadMeanings,
  meaningsEntry,
  meaningsUrl,
  resetMeaningsForTests,
  type MeaningsFile,
} from "@/lib/word-meanings";

const source = readRepoJson<{
  schema: string;
  id: string;
  nameAr: string;
  wordCount: number;
  surahs: string[][][][];
}>("content/word-meanings/dist/siraj.v1.json");
const generated = (s: number): MeaningsFile =>
  JSON.parse(
    readFileSync(join(__dirname, "../../public/data/meanings/siraj", `${s}.json`), "utf8"),
  ) as MeaningsFile;
const ok = (body: unknown): Response => new Response(JSON.stringify(body), { status: 200 });

describe("Word meanings (السراج في بيان غريب القرآن)", () => {
  it("has one list per ayah of every surah", () => {
    expect(source.schema).toBe("word-meanings.v1");
    expect(source.nameAr).toBe("السراج في بيان غريب القرآن");
    expect(source.surahs.map((x) => x.length)).toEqual(SURAHS.map((m) => m.ayahCount));
    expect(source.surahs.flat(2)).toHaveLength(source.wordCount);
    expect(source.wordCount).toBeGreaterThan(6000);
  });

  it("is copied word for word from the upstream dump (book 491)", () => {
    const up = JSON.parse(
      gunzipSync(
        readFileSync(
          join(
            __dirname,
            "../../../../content/word-meanings/upstream/quranpedia-meanings-2026-11-14.json.gz",
          ),
        ),
      ).toString("utf8"),
    ) as {
      data: {
        surah: number;
        ayah: number;
        meanings: { book_info: { id: number }; words: { text: string; meaning: string }[] }[];
      }[];
    };
    let n = 0;
    for (const row of up.data) {
      for (const m of row.meanings) {
        if (m.book_info.id !== 491) continue;
        const ours = source.surahs[row.surah - 1]![row.ayah - 1]!;
        expect(ours).toEqual(m.words.map((w) => [w.text.trim(), w.meaning.trim()]));
        n += ours.length;
      }
    }
    expect(n).toBe(source.wordCount);
  });

  it("per-surah files are the stored entries", () => {
    SURAHS.forEach((m) => expect(generated(m.n)).toEqual(source.surahs[m.n - 1]));
  });

  it("explains al-Nas 114:4", () => {
    const bare = (w: string): string => w.replace(/[\u064B-\u0652\u0670]/g, "");
    const words = meaningsEntry(generated(114), 114, 4).map(([w]) => bare(w));
    expect(words).toEqual(["الوسواس", "الخناس"]);
  });

  it("rejects refs outside the Quran", () => {
    expect(() => meaningsUrl(0)).toThrow(RangeError);
    expect(() => meaningsEntry(generated(1), 1, 8)).toThrow(RangeError);
  });

  it("loads a page's ayahs across surahs and skips ayahs without words", async () => {
    resetMeaningsForTests();
    const fetchImpl = vi.fn(async (url: RequestInfo | URL) => {
      const s = Number(String(url).match(/(\d+)\.json$/)![1]);
      return ok(generated(s));
    });
    const refs: [number, number][] = [
      [113, 5],
      [114, 1],
      [114, 4],
    ];
    const got = await loadMeanings(refs, fetchImpl as unknown as typeof fetch);
    expect(fetchImpl).toHaveBeenCalledTimes(2);
    expect(got.every((x) => x.words.length > 0)).toBe(true);
    expect(got.map((x) => x.ref)).toContainEqual([114, 4]);
  });
});
