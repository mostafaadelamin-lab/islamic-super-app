import { readRepoJson } from "../repo";
import {
  afterEnded,
  audioStore,
  audioUrl,
  buildQueue,
  DEFAULT_RECITER,
  itemPage,
  itemUrl,
  needsBasmala,
  RECITERS,
  sanitizeAudio,
  stepAyah,
  withBasmala,
  type QueueItem,
} from "@/lib/audio";

const reciters = readRepoJson<{ urlTemplate: string; default: string; reciters: { folder: string }[] }>(
  "packages/shared-schemas/audio/reciters.json",
);
const refs = (q: QueueItem[]): string[] => q.map((x) => (x.kind === "basmala" ? `b${x.s}` : `${x.s}:${x.a}`));

describe("reciters and URLs", () => {
  it("uses the shared reciters list and default", () => {
    expect(RECITERS.map((r) => r.folder)).toEqual(reciters.reciters.map((r) => r.folder));
    expect(RECITERS).toHaveLength(8);
    expect(DEFAULT_RECITER).toBe("Alafasy_128kbps");
  });
  it("builds everyayah per-ayah URLs with 3-digit padding", () => {
    expect(audioUrl("Alafasy_128kbps", 2, 255)).toBe("https://everyayah.com/data/Alafasy_128kbps/002255.mp3");
    expect(audioUrl("Husary_128kbps", 1, 1)).toBe("https://everyayah.com/data/Husary_128kbps/001001.mp3");
    expect(audioUrl("Maher_AlMuaiqly_64kbps", 114, 6)).toBe(
      "https://everyayah.com/data/Maher_AlMuaiqly_64kbps/114006.mp3",
    );
  });
  it("rejects unknown reciters and ayahs", () => {
    expect(() => audioUrl("evil/../x", 1, 1)).toThrow(RangeError);
    expect(() => audioUrl("Alafasy_128kbps", 1, 8)).toThrow(RangeError);
    expect(() => audioUrl("Alafasy_128kbps", 115, 1)).toThrow(RangeError);
  });
});

describe("queue and the basmala rule", () => {
  it("basmala before ayah 1 of every surah except al-Fatihah (1) and at-Tawbah (9)", () => {
    expect(needsBasmala(2, 1)).toBe(true);
    expect(needsBasmala(114, 1)).toBe(true);
    expect(needsBasmala(1, 1)).toBe(false);
    expect(needsBasmala(9, 1)).toBe(false);
    expect(needsBasmala(2, 2)).toBe(false);
    const all = Array.from({ length: 114 }, (_, i) => [i + 1, 1] as const);
    expect(withBasmala(all).filter((x) => x.kind === "basmala")).toHaveLength(112);
  });
  it("surah scope", () => {
    expect(refs(buildQueue({ kind: "surah", surah: 1 }))).toEqual([
      "1:1",
      "1:2",
      "1:3",
      "1:4",
      "1:5",
      "1:6",
      "1:7",
    ]);
    const baqarah = buildQueue({ kind: "surah", surah: 2 });
    expect(baqarah).toHaveLength(287);
    expect(refs(baqarah).slice(0, 3)).toEqual(["b2", "2:1", "2:2"]);
    expect(refs(buildQueue({ kind: "surah", surah: 9 }))[0]).toBe("9:1");
    expect(refs(buildQueue({ kind: "surah", surah: 112 }))).toEqual([
      "b112",
      "112:1",
      "112:2",
      "112:3",
      "112:4",
    ]);
  });
  it("page scope (with the basmala of surahs that start on the page)", () => {
    expect(refs(buildQueue({ kind: "page", page: 1 }))).toEqual([
      "1:1",
      "1:2",
      "1:3",
      "1:4",
      "1:5",
      "1:6",
      "1:7",
    ]);
    expect(refs(buildQueue({ kind: "page", page: 2 }))).toEqual(["b2", "2:1", "2:2", "2:3", "2:4", "2:5"]);
    expect(refs(buildQueue({ kind: "page", page: 3 }))[0]).toBe("2:6");
    const last = refs(buildQueue({ kind: "page", page: 604 }));
    expect(last.filter((x) => x.startsWith("b"))).toEqual(["b112", "b113", "b114"]);
    expect(last).toHaveLength(18);
  });
  it("from-ayah scope continues to the end of the surah", () => {
    expect(refs(buildQueue({ kind: "from", surah: 2, ayah: 284 }))).toEqual(["2:284", "2:285", "2:286"]);
    expect(refs(buildQueue({ kind: "from", surah: 3, ayah: 1 })).slice(0, 2)).toEqual(["b3", "3:1"]);
    expect(buildQueue({ kind: "from", surah: 1, ayah: 9 })).toEqual([]);
  });
  it("item URLs: the basmala plays 001001 with the chosen reciter; pages follow the item", () => {
    const [b, first] = buildQueue({ kind: "surah", surah: 18 });
    expect(itemUrl(b!, "Husary_128kbps")).toBe("https://everyayah.com/data/Husary_128kbps/001001.mp3");
    expect(itemUrl(first!, "Husary_128kbps")).toBe("https://everyayah.com/data/Husary_128kbps/018001.mp3");
    expect(itemPage(b!)).toBe(293);
    expect(itemPage({ kind: "ayah", s: 2, a: 6 })).toBe(3);
  });
});

describe("playback cursor", () => {
  const q = buildQueue({ kind: "page", page: 2 }); // b2, 2:1..2:5
  it("advances, never repeats the basmala, repeats ayahs `repeat` times, ends at the last item", () => {
    expect(afterEnded(q, { index: 0, plays: 0 }, 3)).toEqual({ index: 1, plays: 0 });
    expect(afterEnded(q, { index: 1, plays: 0 }, 1)).toEqual({ index: 2, plays: 0 });
    expect(afterEnded(q, { index: 1, plays: 0 }, 3)).toEqual({ index: 1, plays: 1 });
    expect(afterEnded(q, { index: 1, plays: 1 }, 3)).toEqual({ index: 1, plays: 2 });
    expect(afterEnded(q, { index: 1, plays: 2 }, 3)).toEqual({ index: 2, plays: 0 });
    expect(afterEnded(q, { index: 5, plays: 0 }, 1)).toBeNull();
    expect(afterEnded(q, { index: 9, plays: 0 }, 1)).toBeNull();
    expect(afterEnded(q, { index: 2, plays: 0 }, 0)).toEqual({ index: 3, plays: 0 });
  });
  it("next/previous ayah skip the basmala", () => {
    expect(stepAyah(q, 1, -1)).toBeNull();
    expect(stepAyah(q, 0, 1)).toBe(1);
    expect(stepAyah(q, 1, 1)).toBe(2);
    expect(stepAyah(q, 5, 1)).toBeNull();
    const two = buildQueue({ kind: "page", page: 604 });
    const i113 = two.findIndex((x) => x.kind === "ayah" && x.s === 113 && x.a === 1);
    expect(two[stepAyah(two, i113, -1)!]).toEqual({ kind: "ayah", s: 112, a: 4 });
  });
});

describe("audio settings", () => {
  beforeEach(() => {
    localStorage.clear();
    audioStore.reload();
  });
  it("sanitizes stored values", () => {
    expect(sanitizeAudio(null)).toEqual({
      reciter: "Alafasy_128kbps",
      repeat: 1,
      follow: true,
      tafsir: false,
    });
    expect(sanitizeAudio({ reciter: "Husary_128kbps", repeat: 3, follow: false, tafsir: true })).toEqual({
      reciter: "Husary_128kbps",
      repeat: 3,
      follow: false,
      tafsir: true,
    });
    // "tafsir with recitation" is off unless explicitly true
    expect(sanitizeAudio({ tafsir: "yes" }).tafsir).toBe(false);
    expect(sanitizeAudio({ tafsir: 1 }).tafsir).toBe(false);
    expect(sanitizeAudio({ reciter: "nope", repeat: 4 })).toMatchObject({
      reciter: DEFAULT_RECITER,
      repeat: 1,
    });
  });
  it("persists the chosen reciter", () => {
    audioStore.set((p) => ({ ...p, reciter: "Minshawy_Murattal_128kbps" }));
    expect(JSON.parse(localStorage.getItem("rattil.audio")!)).toMatchObject({
      reciter: "Minshawy_Murattal_128kbps",
    });
    audioStore.reload();
    expect(audioStore.get().reciter).toBe("Minshawy_Murattal_128kbps");
  });
  it("persists 'tafsir with recitation' (default off)", () => {
    expect(audioStore.get().tafsir).toBe(false);
    audioStore.set((p) => ({ ...p, tafsir: true }));
    expect(JSON.parse(localStorage.getItem("rattil.audio")!)).toMatchObject({ tafsir: true });
    audioStore.reload();
    expect(audioStore.get().tafsir).toBe(true);
  });
});
