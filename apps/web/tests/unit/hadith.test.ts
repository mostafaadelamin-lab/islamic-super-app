import { createHash } from "node:crypto";
import { readRepoJson } from "../repo";
import { normalizeArabic } from "@/lib/search";
import {
  chunkOf,
  HADITH,
  HADITH_BOOKS,
  hadithBook,
  hadithFavStore,
  findRef,
  loadRange,
  loadRefs,
  migrateHadithFavourites,
  parseKey,
  refLabel,
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
    const f = /\/data\/hadith\/([a-z]+)\/(refs|from-alamiyya)\.json$/.exec(url);
    if (f) return Promise.resolve(new Response(JSON.stringify(readRepoJson(`content/hadith/dist/${f[1]}/${f[2]}.json`))));
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
    // Bukhari and Muslim: the sunnah.com copy (owner 2026-11-26), with sunnah.com numbers.
    expect(hadithBook("bukhari")!.count).toBe(7277);
    expect(hadithBook("muslim")!.count).toBe(7459);
    expect(hadithBook("bukhari")!.refs).toBe(true);
    expect(hadithBook("muslim")!.numbering).toBe("sunnah.com");
    expect(hadithBook("abudawud")!.refs).toBeUndefined();
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
    expect(hits[0]!.ref).toBe("1");
    expect(normalizeArabic(hits[0]!.text)).toContain("بالنيات");
    expect(progress).toEqual(Array.from({ length: b.chunks }, (_, i) => i + 1));
    expect(await searchBook(b, "   ")).toEqual([]);
    expect(await searchBook(b, "الله")).toHaveLength(SEARCH_LIMIT);
  });

  it("favourites: valid keys only, toggled and kept", () => {
    expect(parseKey("bukhari:1")!.n).toBe(1);
    expect(parseKey("bukhari:7278")).toBeNull();
    expect(parseKey("bukhari:0")).toBeNull();
    expect(parseKey("nope:1")).toBeNull();
    expect(sanitizeFavourites({ keys: ["muslim:2", "muslim:2", "x", 3, "darimi:99999"] })).toEqual({
      keys: ["muslim:2"],
    });
    expect(sanitizeFavourites(null)).toEqual({ keys: [], v: 2 });
    expect(sanitizeFavourites({ keys: ["bukhari:3"], v: 2 })).toEqual({ keys: ["bukhari:3"], v: 2 });
    localStorage.clear();
    hadithFavStore.reload();
    toggleFavourite("bukhari", 1);
    toggleFavourite("muslim", 5);
    hadithFavStore.reload();
    expect(hadithFavStore.get().keys).toEqual(["muslim:5", "bukhari:1"]);
    toggleFavourite("bukhari", 1);
    expect(hadithFavStore.get().keys).toEqual(["muslim:5"]);
  });

  it("sunnah.com numbers: labels, «اذهب إلى» and the same numbers the Hajj guide cites", async () => {
    serveFromRepo();
    const bukhari = hadithBook("bukhari")!;
    const muslim = hadithBook("muslim")!;
    const br = await loadRefs(bukhari);
    const mr = await loadRefs(muslim);
    expect(br).toHaveLength(bukhari.count);
    expect(mr).toHaveLength(muslim.count);
    expect(br[0]).toBe("1");
    expect(findRef(br, "1")).toBe(1);
    expect(findRef(br, "١٥٤٩")).toBe(1495); // Bukhari 1549 (talbiyah), cited by the Hajj guide
    expect(findRef(mr, "2186")).toBe(5553); // Jibril's ruqyah, kids ruqyah
    expect(findRef(mr, "1218a")).toBe(2833); // Jabir's long hadith on the Prophet's Hajj
    expect(findRef(mr, "999999")).toBeNull();
    expect(findRef(mr, "abc")).toBeNull();
    const ar = (v: string): string => v.replace(/\d/g, (d) => "٠١٢٣٤٥٦٧٨٩"[Number(d)]!);
    expect(refLabel("1218a", "ar", ar)).toBe("١٢١٨ أ");
    expect(refLabel("5709,5710", "ar", ar)).toBe("٥٧٠٩، ٥٧١٠");
    expect(refLabel("intro3", "ar", ar)).toBe("المقدمة ٣");
    expect(refLabel("~597b", "ar", ar)).toBe("بعد ٥٩٧ ب");
    expect(refLabel("1218a", "en")).toBe("1218a");
    const r = await loadRange(muslim, 2833, 2833);
    expect(r[0]!.ref).toBe("1218a");
    // every Bukhari/Muslim hadith of the Hajj guide: its "std" number is the sunnah.com number of the entry
    const src = readRepoJson<{ steps: unknown[] }>("content/pilgrimage/guide.v2.src.json");
    const cites = JSON.stringify(src).match(/"h":"(bukhari|muslim):\d+","std":\d+/g) ?? [];
    expect(cites.length).toBeGreaterThan(10);
    for (const c of cites) {
      const [, b, n, std] = /"h":"(\w+):(\d+)","std":(\d+)/.exec(c)!;
      const refs = b === "bukhari" ? br : mr;
      expect(refs[Number(n) - 1]!.replace(/[a-z]$/, "")).toBe(std);
    }
  });

  it("moves bookmarks saved before 1.2.25 from al-Alamiyya numbers to the sunnah.com copy, once", async () => {
    serveFromRepo();
    localStorage.clear();
    localStorage.setItem(
      hadithFavStore.key,
      JSON.stringify({ keys: ["bukhari:1448", "abudawud:3", "muslim:4056"] }),
    );
    hadithFavStore.reload();
    expect(hadithFavStore.get().v).toBeUndefined();
    await migrateHadithFavourites();
    expect(hadithFavStore.get()).toEqual({ keys: ["bukhari:1495", "abudawud:3", "muslim:5553"], v: 2 });
    await migrateHadithFavourites(); // second call changes nothing
    expect(hadithFavStore.get().keys).toEqual(["bukhari:1495", "abudawud:3", "muslim:5553"]);
  });
});
