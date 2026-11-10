import { normalizeArabic } from "@/lib/search";
import {
  apiLanguage,
  filterRadios,
  filterReciters,
  loadLibrary,
  MAX_AGE_MS,
  parseLibrary,
  parseSurahList,
  surahUrl,
} from "@/lib/mp3quran";
import { MP3_API } from "../mp3quran-fixture";

describe("mp3quran library", () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it("keeps only well-formed, https recordings and radios", () => {
    const lib = parseLibrary(MP3_API.reciters, MP3_API.riwayat, MP3_API.radios);
    expect(lib.reciters.map((r) => r.id)).toEqual([153, 7]);
    const akdr = lib.reciters.find((r) => r.id === 7)!;
    expect(akdr.moshafs.map((m) => m.id)).toEqual([7, 71]);
    expect(akdr.moshafs[0]!.surahs).toEqual([1, 2, 114]);
    expect(surahUrl(akdr.moshafs[0]!, 1)).toBe("https://server6.mp3quran.net/akdr/001.mp3");
    expect(lib.radios.map((r) => r.id)).toEqual([1]);
    expect(filterReciters(lib, "", 2, normalizeArabic).map((r) => r.id)).toEqual([7]);
    expect(filterReciters(lib, "ابراهيم", null, normalizeArabic).map((r) => r.id)).toEqual([7]);
    expect(filterRadios(lib, "zzz", normalizeArabic)).toEqual([]);
    expect(parseLibrary("x", null, 3)).toEqual({ reciters: [], riwayat: [], radios: [] });
    expect(parseSurahList(undefined)).toEqual([]);
    expect(apiLanguage("ar")).toBe("ar");
    expect(apiLanguage("en")).toBe("eng");
  });

  it("caches for a week and falls back to the saved copy offline", async () => {
    const calls: string[] = [];
    vi.stubGlobal("fetch", (url: string) => {
      calls.push(url);
      const key = url.split("/").pop()!.split("?")[0] as keyof typeof MP3_API;
      return Promise.resolve(new Response(JSON.stringify(MP3_API[key])));
    });
    const now = Date.UTC(2026, 10, 10);
    expect((await loadLibrary("ar", { now })).reciters).toHaveLength(2);
    expect(calls).toHaveLength(3);
    expect(calls[0]).toBe("https://www.mp3quran.net/api/v3/reciters?language=ar");
    await loadLibrary("ar", { now: now + 1000 });
    expect(calls).toHaveLength(3);
    vi.stubGlobal("fetch", () => Promise.reject(new Error("offline")));
    expect((await loadLibrary("ar", { now: now + MAX_AGE_MS + 1 })).radios).toHaveLength(1);
    await expect(loadLibrary("eng", { now })).rejects.toThrow("offline");
  });
});
