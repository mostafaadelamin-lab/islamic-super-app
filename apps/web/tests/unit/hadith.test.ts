import { createHash } from "node:crypto";
import { readRepoJson } from "../repo";
import { normalizeArabic } from "@/lib/search";
import {
  chunkOf,
  HADITH,
  HADITH_BOOKS,
  hadithBook,
  hadithFavStore,
  loadRange,
  parseKey,
  sanitizeFavourites,
  searchBook,
  SEARCH_LIMIT,
  toggleFavourite,
} from "@/lib/hadith";

interface Chunk {
  book: string;
  from: number;
  ahadith: string[];
}
const chunk = (book: string, k: number): Chunk =>
  readRepoJson<Chunk>(`content/hadith/dist/${book}/${k}.json`);

/** fetch() served from content/hadith/dist, counting requests. */
function serveFromRepo(): { calls: string[] } {
  const calls: string[] = [];
  vi.stubGlobal("fetch", (url: string) => {
    calls.push(url);
    const m = /\/data\/hadith\/([a-z]+)\/(\d+)\.json$/.exec(url)!;
    return Promise.resolve(new Response(JSON.stringify(chunk(m[1]!, Number(m[2])))));
  });
  return { calls };
}

afterEach(() => vi.unstubAllGlobals());

describe("hadith books (Open-Hadith-Data)", () => {
  it("lists the nine books with the counts and pinned source", () => {
    expect(HADITH_BOOKS.map((b) => b.id)).toEqual([
      "bukhari",
      "muslim",
      "abudawud",
      "tirmidhi",
      "nasai",
      "ibnmajah",
      "malik",
      "ahmad",
      "darimi",
    ]);
    expect(hadithBook("bukhari")!.count).toBe(7008);
    expect(hadithBook("ahmad")!.count).toBe(26363);
    expect(HADITH.source.commit).toBe("1515f6cba21efed20d8916bf55acef1dffa0d2d5");
    expect(HADITH.source.licence).toContain("ODbL");
    expect(HADITH.reviewStatus).toBe("pending");
  });

  it("text files are exactly the source text (sha-256 of every book matches the build record)", () => {
    for (const b of HADITH_BOOKS) {
      const texts: string[] = [];
      for (let k = 0; k < b.chunks; k++) {
        const c = chunk(b.id, k);
        expect(c.book).toBe(b.id);
        expect(c.from).toBe(k * HADITH.chunkSize + 1);
        texts.push(...c.ahadith);
      }
      expect(texts).toHaveLength(b.count);
      expect(createHash("sha256").update(texts.join("\n")).digest("hex")).toBe(b.textSha256);
    }
  });

  it("finds the part file for a number and loads a range across two parts", async () => {
    expect(chunkOf(1)).toBe(0);
    expect(chunkOf(500)).toBe(0);
    expect(chunkOf(501)).toBe(1);
    const { calls } = serveFromRepo();
    const b = hadithBook("malik")!;
    const r = await loadRange(b, 495, 505);
    expect(r.map((h) => h.n)).toEqual([495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505]);
    expect(r[0]!.text).toBe(chunk("malik", 0).ahadith[494]);
    expect(r[6]!.text).toBe(chunk("malik", 1).ahadith[0]);
    expect(await loadRange(b, b.count + 1, b.count + 5)).toEqual([]);
    const last = await loadRange(b, b.count - 1, b.count + 10);
    expect(last.map((h) => h.n)).toEqual([b.count - 1, b.count]);
    expect(calls.every((u) => u.includes("/data/hadith/malik/"))).toBe(true);
  });

  it("searches a book ignoring diacritics and stops at the limit", async () => {
    serveFromRepo();
    const b = hadithBook("bukhari")!;
    const progress: number[] = [];
    const hits = await searchBook(b, "انما الاعمال بالنيات", (d) => progress.push(d));
    expect(hits[0]!.n).toBe(1);
    expect(normalizeArabic(hits[0]!.text)).toContain("بالنيات");
    expect(progress).toEqual(Array.from({ length: b.chunks }, (_, i) => i + 1));
    expect(await searchBook(b, "   ")).toEqual([]);
    expect(await searchBook(b, "الله")).toHaveLength(SEARCH_LIMIT);
  });

  it("favourites: valid keys only, toggled and kept", () => {
    expect(parseKey("bukhari:1")!.n).toBe(1);
    expect(parseKey("bukhari:7009")).toBeNull();
    expect(parseKey("bukhari:0")).toBeNull();
    expect(parseKey("nope:1")).toBeNull();
    expect(sanitizeFavourites({ keys: ["muslim:2", "muslim:2", "x", 3, "darimi:99999"] })).toEqual({
      keys: ["muslim:2"],
    });
    expect(sanitizeFavourites(null)).toEqual({ keys: [] });
    localStorage.clear();
    hadithFavStore.reload();
    toggleFavourite("bukhari", 1);
    toggleFavourite("muslim", 5);
    hadithFavStore.reload();
    expect(hadithFavStore.get().keys).toEqual(["muslim:5", "bukhari:1"]);
    toggleFavourite("bukhari", 1);
    expect(hadithFavStore.get().keys).toEqual(["muslim:5"]);
  });
});
