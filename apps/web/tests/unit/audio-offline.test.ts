import { audioStore } from "@/lib/audio";
import {
  AUDIO_CACHE,
  deleteAll,
  deleteSurah,
  downloadSurah,
  downloadsStore,
  isSaved,
  sanitizeDownloads,
  savedSource,
  surahFiles,
  totalBytes,
} from "@/lib/audio-offline";
import { player, resetPlayerForTests } from "@/lib/audio-player";

const URL_OF = (folder: string, sss: string): string => `https://everyayah.com/data/${folder}/${sss}.mp3`;
const BYTES = 10;
const OK = 200;
const FATIHAH = 1;
const FATIHAH_AYAHS = 7;
const TAWBAH = 9;
const NASR = 110;
const IKHLAS = 112;
const FALAQ = 113;
const NAS = 114;
/** al-Ikhlas has 4 ayahs, plus the basmala. */
const IKHLAS_FILES = 5;
const FALAQ_NEW_FILES = 5;
const NOT_A_SURAH = 999;
const SOME_SURAH = 2;
const OTHER_SURAH = 3;
const SOME_SIZE = 5;
const A = "Alafasy_128kbps";

/** In-memory Cache Storage: enough of the API for the downloads module. */
class FakeCache {
  store = new Map<string, Response>();
  async match(url: string): Promise<Response | undefined> {
    return this.store.get(url)?.clone();
  }
  async put(url: string, res: Response): Promise<void> {
    this.store.set(url, res);
  }
  async delete(url: string): Promise<boolean> {
    return this.store.delete(url);
  }
}
const cachesByName = new Map<string, FakeCache>();
const fakeCaches = {
  open: async (name: string): Promise<FakeCache> => {
    const c = cachesByName.get(name) ?? new FakeCache();
    cachesByName.set(name, c);
    return c;
  },
  delete: async (name: string): Promise<boolean> => cachesByName.delete(name),
};

let fetched: string[] = [];

beforeEach(() => {
  localStorage.clear();
  audioStore.reload();
  downloadsStore.reload();
  cachesByName.clear();
  fetched = [];
  vi.stubGlobal("caches", fakeCaches);
  vi.stubGlobal(
    "fetch",
    vi.fn(async (url: string) => {
      fetched.push(url);
      return new Response(new Uint8Array(BYTES), { status: OK });
    }),
  );
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("offline recitations", () => {
  it("lists the basmala before every surah except al-Fatihah and at-Tawbah", () => {
    expect(surahFiles(A, IKHLAS)).toEqual(
      ["001001", "112001", "112002", "112003", "112004"].map((f) => URL_OF("Alafasy_128kbps", f)),
    );
    expect(surahFiles(A, FATIHAH)).toHaveLength(FATIHAH_AYAHS);
    expect(surahFiles(A, TAWBAH)[0]).toBe(URL_OF("Alafasy_128kbps", "009001"));
  });

  it("saves a surah with progress, records its size and skips files already saved", async () => {
    const progress: number[] = [];
    await downloadSurah(A, IKHLAS, (done) => progress.push(done));
    expect(progress).toEqual(Array.from({ length: IKHLAS_FILES }, (_, i) => i + 1));
    expect(cachesByName.get(AUDIO_CACHE)?.store.size).toBe(IKHLAS_FILES);
    expect(isSaved(downloadsStore.get(), A, IKHLAS)).toBe(true);
    expect(totalBytes(downloadsStore.get())).toBe(IKHLAS_FILES * BYTES);
    fetched = [];
    await downloadSurah(A, FALAQ);
    expect(fetched).not.toContain(URL_OF("Alafasy_128kbps", "001001"));
    expect(fetched).toHaveLength(FALAQ_NEW_FILES);
  });

  it("keeps the shared basmala until the last surah of the reciter that needs it is deleted", async () => {
    await downloadSurah(A, IKHLAS);
    await downloadSurah(A, FALAQ);
    const cache = cachesByName.get(AUDIO_CACHE)!;
    await deleteSurah(A, IKHLAS);
    expect(cache.store.has(URL_OF("Alafasy_128kbps", "001001"))).toBe(true);
    expect(cache.store.has(URL_OF("Alafasy_128kbps", "112001"))).toBe(false);
    await deleteSurah(A, FALAQ);
    expect(cache.store.size).toBe(0);
    expect(downloadsStore.get().saved).toEqual([]);
  });

  it("records nothing when a file fails", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        throw new TypeError("offline");
      }),
    );
    await expect(downloadSurah(A, IKHLAS)).rejects.toThrow();
    expect(downloadsStore.get().saved).toEqual([]);
  });

  it("delete all empties the cache and the list", async () => {
    await downloadSurah(A, NAS);
    await deleteAll();
    expect(cachesByName.has(AUDIO_CACHE)).toBe(false);
    expect(downloadsStore.get().saved).toEqual([]);
  });

  it("sanitizes the stored list", () => {
    expect(
      sanitizeDownloads({
        saved: [
          { folder: "x", surah: SOME_SURAH, bytes: SOME_SIZE },
          { folder: "x", surah: NOT_A_SURAH },
          "junk",
          { surah: OTHER_SURAH },
        ],
      }),
    ).toEqual({ saved: [{ folder: "x", surah: SOME_SURAH, bytes: SOME_SIZE }] });
    expect(sanitizeDownloads(null)).toEqual({ saved: [] });
  });

  it("gives a playable source only for saved files", async () => {
    vi.stubGlobal("URL", Object.assign(URL, { createObjectURL: () => "blob:saved" }));
    expect(await savedSource(URL_OF("Alafasy_128kbps", "112001"))).toBeNull();
    await downloadSurah(A, IKHLAS);
    expect(await savedSource(URL_OF("Alafasy_128kbps", "112001"))).toBe("blob:saved");
  });
});

describe("player with saved surahs", () => {
  class FakeAudio extends EventTarget {
    static last: FakeAudio | null = null;
    preload = "";
    playbackRate = 1;
    defaultPlaybackRate = 1;
    src = "";
    constructor() {
      super();
      FakeAudio.last = this;
    }
    getAttribute(): string | null {
      return this.src || null;
    }
    removeAttribute(): void {}
    load(): void {}
    pause(): void {}
    play(): Promise<void> {
      return Promise.resolve();
    }
  }

  it("plays a saved surah while offline, from the saved copy", async () => {
    vi.stubGlobal("Audio", FakeAudio);
    vi.stubGlobal(
      "URL",
      Object.assign(URL, { createObjectURL: () => "blob:saved", revokeObjectURL: () => {} }),
    );
    resetPlayerForTests();
    await downloadSurah(A, IKHLAS);
    vi.spyOn(navigator, "onLine", "get").mockReturnValue(false);
    player.play({ kind: "surah", surah: IKHLAS });
    await vi.waitFor(() => expect(FakeAudio.last?.src).toBe("blob:saved"));
    expect(player.get().status).not.toBe("error");
    // an unsaved surah still reports that the connection is needed
    player.play({ kind: "surah", surah: NASR });
    expect(player.get().error).toBe("offline");
    resetPlayerForTests();
  });
});
