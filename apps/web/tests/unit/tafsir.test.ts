import { readFileSync } from "node:fs";
import { join } from "node:path";
import { readRepoJson } from "../repo";
import { SURAHS } from "@/lib/pages";
import {
  loadTafsir,
  loadTafsirSurah,
  resetTafsirForTests,
  stepRef,
  tafsirEntry,
  tafsirUrl,
} from "@/lib/tafsir";

const source = readRepoJson<{ schema: string; nameAr: string; surahs: string[][] }>(
  "content/tafsir/dist/muyassar.v1.json",
);
/** The per-surah file written by scripts/prepare-content.mjs. */
const generated = (s: number): string[] =>
  JSON.parse(
    readFileSync(join(__dirname, "../../public/data/tafsir/muyassar", `${s}.json`), "utf8"),
  ) as string[];
const ok = (body: unknown): Response => new Response(JSON.stringify(body), { status: 200 });

describe("Tafsir al-Muyassar data", () => {
  it("the source has one entry per ayah of every surah", () => {
    expect(source.schema).toBe("tafsir.v1");
    expect(source.nameAr).toBe("التفسير الميسر");
    expect(source.surahs.map((x) => x.length)).toEqual(SURAHS.map((m) => m.ayahCount));
    expect(source.surahs.flat()).toHaveLength(6236);
  });

  it("per-surah files are the stored entries, unmodified", () => {
    SURAHS.forEach((m) => expect(generated(m.n)).toEqual(source.surahs[m.n - 1]));
  });

  it("maps s:a to the stored text (2:255, 112:1, 113:1, 114:6)", () => {
    expect(tafsirEntry(generated(2), 2, 255)).toBe(source.surahs[1]![254]);
    expect(tafsirEntry(generated(112), 112, 1)).toBe(source.surahs[111]![0]);
    expect(tafsirEntry(generated(113), 113, 1)).toBe(source.surahs[112]![0]);
    expect(tafsirEntry(generated(114), 114, 6)).toBe(source.surahs[113]![5]);
  });

  it("rejects out-of-range ayahs, unknown surahs and files that do not match the Quran", () => {
    expect(() => tafsirEntry(generated(1), 1, 0)).toThrow(RangeError);
    expect(() => tafsirEntry(generated(1), 1, 8)).toThrow(RangeError);
    expect(() => tafsirEntry(generated(2), 2, 287)).toThrow(RangeError);
    expect(() => tafsirEntry([], 115, 1)).toThrow(RangeError);
    expect(() => tafsirEntry(["only one"], 1, 1)).toThrow(/does not match/);
    expect(() => tafsirUrl(0)).toThrow(RangeError);
    expect(() => tafsirUrl(115)).toThrow(RangeError);
    expect(tafsirUrl(2)).toBe("/data/tafsir/muyassar/2.json");
  });

  it("previous/next ayah across surah boundaries", () => {
    expect(stepRef(1, 1, -1)).toBeNull();
    expect(stepRef(1, 7, 1)).toEqual([2, 1]);
    expect(stepRef(2, 1, -1)).toEqual([1, 7]);
    expect(stepRef(2, 255, 1)).toEqual([2, 256]);
    expect(stepRef(9, 129, 1)).toEqual([10, 1]);
    expect(stepRef(113, 1, -1)).toEqual([112, 4]);
    expect(stepRef(114, 6, 1)).toBeNull();
    expect(stepRef(2, 300, 1)).toBeNull();
  });
});

describe("loading tafsir files", () => {
  beforeEach(() => resetTafsirForTests());

  it("fetches a surah once and returns verbatim entries", async () => {
    const fetchImpl = vi.fn(() => Promise.resolve(ok(generated(112))));
    await expect(loadTafsir(112, 1, fetchImpl)).resolves.toBe(source.surahs[111]![0]);
    await expect(loadTafsir(112, 4, fetchImpl)).resolves.toBe(source.surahs[111]![3]);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
    expect(fetchImpl).toHaveBeenCalledWith("/data/tafsir/muyassar/112.json");
  });

  it("forgets failures so that a retry fetches again", async () => {
    const fetchImpl = vi
      .fn<(url: string) => Promise<Response>>()
      .mockRejectedValueOnce(new TypeError("offline"))
      .mockResolvedValueOnce(new Response("", { status: 404 }))
      .mockResolvedValueOnce(ok(generated(1)));
    await expect(loadTafsirSurah(1, fetchImpl as unknown as typeof fetch)).rejects.toThrow("offline");
    await expect(loadTafsirSurah(1, fetchImpl as unknown as typeof fetch)).rejects.toThrow(/404/);
    await expect(loadTafsir(1, 7, fetchImpl as unknown as typeof fetch)).resolves.toBe(source.surahs[0]![6]);
    expect(fetchImpl).toHaveBeenCalledTimes(3);
  });

  it("rejects unknown surahs and ayahs without fetching", async () => {
    const fetchImpl = vi.fn(() => Promise.resolve(ok(generated(1))));
    expect(() => loadTafsirSurah(115, fetchImpl)).toThrow(RangeError);
    await expect(loadTafsir(1, 9, fetchImpl)).rejects.toThrow(RangeError);
    expect(fetchImpl).toHaveBeenCalledTimes(1); // only for the valid surah
  });
});
