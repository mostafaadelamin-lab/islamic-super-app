import { audioStore } from "@/lib/audio";
import { player, resetPlayerForTests } from "@/lib/audio-player";

/** jsdom has no media playback: Audio is replaced by a minimal fake that records sources. */
class FakeAudio extends EventTarget {
  static last: FakeAudio | null = null;
  static playImpl: () => Promise<void> = () => Promise.resolve();
  preload = "";
  currentTime = 0;
  paused = true;
  seeking = false;
  playbackRate = 1;
  defaultPlaybackRate = 1;
  private attrs = new Map<string, string>();
  played: string[] = [];
  constructor() {
    super();
    FakeAudio.last = this;
  }
  set src(v: string) {
    this.attrs.set("src", v);
  }
  get src(): string {
    return this.attrs.get("src") ?? "";
  }
  getAttribute(k: string): string | null {
    return this.attrs.get(k) ?? null;
  }
  removeAttribute(k: string): void {
    this.attrs.delete(k);
  }
  load(): void {}
  pause(): void {
    this.paused = true;
  }
  play(): Promise<void> {
    this.paused = false;
    this.played.push(this.src);
    return FakeAudio.playImpl();
  }
}

const URL_OF = (sss: string): string => `https://everyayah.com/data/Alafasy_128kbps/${sss}.mp3`;
const flush = (): Promise<void> => new Promise((r) => setTimeout(r, 0));

beforeEach(() => {
  localStorage.clear();
  audioStore.reload();
  resetPlayerForTests();
  FakeAudio.playImpl = () => Promise.resolve();
  vi.stubGlobal("Audio", FakeAudio);
  vi.spyOn(navigator, "onLine", "get").mockReturnValue(true);
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("recitation player", () => {
  it("plays the basmala then the ayahs, advancing on 'ended', and stops at the end", async () => {
    player.play({ kind: "page", page: 2 });
    const a = FakeAudio.last!;
    expect(player.get().src).toBe(URL_OF("001001"));
    a.dispatchEvent(new Event("playing"));
    expect(player.get().status).toBe("playing");
    a.dispatchEvent(new Event("ended"));
    expect(player.get().src).toBe(URL_OF("002001"));
    for (let i = 0; i < 4; i++) a.dispatchEvent(new Event("ended"));
    expect(player.get().src).toBe(URL_OF("002005"));
    a.dispatchEvent(new Event("ended"));
    expect(player.get().status).toBe("idle");
    expect(a.played).toEqual(["001001", "002001", "002002", "002003", "002004", "002005"].map(URL_OF));
  });

  it("repeats each ayah and uses the saved reciter", () => {
    audioStore.set((p) => ({ ...p, repeat: 2, reciter: "Husary_128kbps" }));
    player.play({ kind: "from", surah: 114, ayah: 5 });
    const a = FakeAudio.last!;
    a.dispatchEvent(new Event("ended"));
    a.dispatchEvent(new Event("ended"));
    a.dispatchEvent(new Event("ended"));
    expect(a.played).toEqual([
      "https://everyayah.com/data/Husary_128kbps/114005.mp3",
      "https://everyayah.com/data/Husary_128kbps/114005.mp3",
      "https://everyayah.com/data/Husary_128kbps/114006.mp3",
      "https://everyayah.com/data/Husary_128kbps/114006.mp3",
    ]);
  });

  it("next/previous ayah, pause/resume and stop", () => {
    player.play({ kind: "surah", surah: 112 });
    player.step(1);
    expect(player.current()).toEqual({ kind: "ayah", s: 112, a: 1 });
    player.step(1);
    player.step(-1);
    expect(player.current()).toEqual({ kind: "ayah", s: 112, a: 1 });
    player.step(-1); // no previous ayah (only the basmala): stays
    expect(player.current()).toEqual({ kind: "ayah", s: 112, a: 1 });
    FakeAudio.last!.dispatchEvent(new Event("playing"));
    player.toggle();
    expect(player.get().status).toBe("paused");
    player.toggle();
    expect(player.get().status).toBe("loading");
    player.stop();
    expect(player.get()).toMatchObject({ status: "idle", queue: [] });
  });

  it("ignores 'ended' that is not the end of the current item (paused, stopped, stale source)", () => {
    player.play({ kind: "page", page: 2 });
    const a = FakeAudio.last!;
    a.dispatchEvent(new Event("playing"));
    player.toggle(); // pause
    a.dispatchEvent(new Event("ended"));
    expect(player.get()).toMatchObject({ status: "paused", src: URL_OF("001001"), cursor: { index: 0 } });
    player.toggle(); // resume
    a.src = URL_OF("002004"); // a late event from some other source
    a.dispatchEvent(new Event("ended"));
    expect(player.get().cursor.index).toBe(0);
    a.src = URL_OF("001001");
    a.dispatchEvent(new Event("ended"));
    expect(player.get().src).toBe(URL_OF("002001"));
    player.stop();
    a.dispatchEvent(new Event("ended"));
    expect(player.get()).toMatchObject({ status: "idle", queue: [] });
    expect(a.played).toEqual(["001001", "001001", "002001"].map(URL_OF));
  });

  it("reports network errors and offline state clearly", async () => {
    player.play({ kind: "surah", surah: 1 });
    FakeAudio.last!.dispatchEvent(new Event("error"));
    expect(player.get()).toMatchObject({ status: "error", error: "network" });
    vi.spyOn(navigator, "onLine", "get").mockReturnValue(false);
    player.toggle(); // retry while offline
    expect(player.get()).toMatchObject({ status: "error", error: "offline" });
    vi.spyOn(navigator, "onLine", "get").mockReturnValue(true);
    FakeAudio.playImpl = () => Promise.reject(new DOMException("blocked", "NotAllowedError"));
    player.toggle();
    await flush();
    expect(player.get()).toMatchObject({ status: "error", error: "blocked" });
    FakeAudio.playImpl = () => Promise.reject(new DOMException("superseded", "AbortError"));
    player.play({ kind: "surah", surah: 1 });
    await flush();
    expect(player.get().status).toBe("loading");
  });

  it("plays at the chosen speed and follows speed changes while playing", () => {
    audioStore.set((p) => ({ ...p, speed: 1.5 }));
    player.play({ kind: "surah", surah: 112 });
    const a = FakeAudio.last!;
    expect(a.playbackRate).toBe(1.5);
    expect(a.defaultPlaybackRate).toBe(1.5);
    audioStore.set((p) => ({ ...p, speed: 0.75 }));
    expect(a.playbackRate).toBe(0.75);
  });

  it("publishes lock-screen metadata and answers the media keys", () => {
    const handlers = new Map<string, () => void>();
    const ms = {
      metadata: null as { title: string; artist: string } | null,
      playbackState: "none",
      setActionHandler: (k: string, fn: () => void) => handlers.set(k, fn),
    };
    Object.defineProperty(navigator, "mediaSession", { value: ms, configurable: true });
    vi.stubGlobal(
      "MediaMetadata",
      class {
        title: string;
        artist: string;
        constructor(m: { title: string; artist: string }) {
          this.title = m.title;
          this.artist = m.artist;
        }
      },
    );
    try {
      player.play({ kind: "from", surah: 114, ayah: 2 });
      const a = FakeAudio.last!;
      a.dispatchEvent(new Event("playing"));
      expect(ms.metadata?.title).toBe("An-Nas 114:2");
      expect(ms.metadata?.artist).toMatch(/Alafasy/);
      expect(ms.playbackState).toBe("playing");
      handlers.get("nexttrack")!();
      expect(player.get().src).toBe(URL_OF("114003"));
      handlers.get("pause")!();
      expect(player.get().status).toBe("paused");
      expect(ms.playbackState).toBe("paused");
      handlers.get("stop")!();
      expect(player.get().status).toBe("idle");
      expect(ms.metadata).toBeNull();
    } finally {
      Reflect.deleteProperty(navigator, "mediaSession");
    }
  });
});

describe("one sound at a time (owner 2026-11-14)", () => {
  it("another sound pauses the recitation, which keeps its ayah and resumes from it", async () => {
    const { registerAudio, pauseOthers, resetAudioFocusForTests } = await import("@/lib/audio-focus");
    const { lastReadStore } = await import("@/lib/settings");
    resetAudioFocusForTests();
    player.play({ kind: "from", surah: 2, ayah: 255 });
    const a = FakeAudio.last!;
    Object.defineProperty(a, "paused", { value: false, configurable: true });
    a.dispatchEvent(new Event("playing"));
    expect(player.get().status).toBe("playing");

    // An adhkar recording starts.
    const dhikr = new EventTarget() as unknown as HTMLAudioElement;
    Object.defineProperty(dhikr, "paused", { value: false });
    const dhikrPause = vi.fn();
    registerAudio(dhikr, dhikrPause);
    pauseOthers(dhikr);
    expect(player.get().status).toBe("paused");
    expect(player.wasInterrupted()).toBe(true);
    expect(player.current()).toMatchObject({ kind: "ayah", s: 2, a: 255 });
    expect(lastReadStore.get()).toMatchObject({ surah: 2, ayah: 255, page: 42 });
    expect(dhikrPause).not.toHaveBeenCalled();

    // Back to the recitation: it continues (same ayah, no reload) and the adhkar pause.
    const played = a.played.length;
    player.toggle();
    expect(player.wasInterrupted()).toBe(false);
    expect(a.played).toHaveLength(played + 1);
    expect(a.played.at(-1)).toBe(URL_OF("002255"));
    a.dispatchEvent(new Event("play"));
    expect(dhikrPause).toHaveBeenCalled();
    resetAudioFocusForTests();
  });

  it("applies the volume from the reader's slider", () => {
    audioStore.set((p) => ({ ...p, volume: 0.35 }));
    player.play({ kind: "ayah", surah: 1, ayah: 1 });
    expect((FakeAudio.last as unknown as { volume: number }).volume).toBe(0.35);
    audioStore.set((p) => ({ ...p, volume: 0.8 }));
    expect((FakeAudio.last as unknown as { volume: number }).volume).toBe(0.8);
  });

  describe("reciters recorded one file per surah", () => {
    const FILE = (sss: string): string => `https://cdn.mp3quran.net/audio/ahmad-masarawi/r1/${sss}.mp3`;
    const stubTimings = (
      row112: number[],
      row113: number[] = [500, 3000, 6000, 9000, 12000, 15000],
    ): void => {
      const rows = Array.from({ length: 114 }, (_, i) =>
        i === 111 ? row112 : i === 112 ? row113 : [0, 1000],
      );
      vi.stubGlobal(
        "fetch",
        vi.fn(() =>
          Promise.resolve(
            new Response(JSON.stringify({ reciters: { mp3q_ahmad_masarawi: rows } }), { status: 200 }),
          ),
        ),
      );
    };
    const at = async (a: FakeAudio, seconds: number): Promise<void> => {
      a.currentTime = seconds;
      a.dispatchEvent(new Event("timeupdate"));
      await flush();
    };

    it("plays the surah file once and follows the ayahs by their timings", async () => {
      stubTimings([4000, 6000, 8000, 10000, 12000]);
      audioStore.set((p) => ({ ...p, reciter: "mp3q_ahmad_masarawi" }));
      player.play({ kind: "surah", surah: 112 });
      await flush();
      await flush();
      const a = FakeAudio.last!;
      expect(player.get().src).toBe(FILE("112"));
      expect(player.current()).toMatchObject({ kind: "basmala", s: 112 });
      a.dispatchEvent(new Event("playing"));
      await at(a, 4.0);
      expect(player.current()).toMatchObject({ kind: "ayah", s: 112, a: 1 });
      await at(a, 6.5);
      expect(player.current()).toMatchObject({ kind: "ayah", s: 112, a: 2 });
      await at(a, 8.0);
      await at(a, 10.0);
      expect(player.current()).toMatchObject({ kind: "ayah", s: 112, a: 4 });
      expect(a.played).toEqual([FILE("112")]);
      await at(a, 12.0);
      expect(player.get().status).toBe("idle");
    });

    it("skips a basmala the recording does not have and starts at ayah 1's time", async () => {
      stubTimings([800, 6000, 8000, 10000, 12000]);
      audioStore.set((p) => ({ ...p, reciter: "mp3q_ahmad_masarawi" }));
      player.play({ kind: "surah", surah: 112 });
      await flush();
      await flush();
      expect(player.current()).toMatchObject({ kind: "ayah", s: 112, a: 1 });
      const a = FakeAudio.last!;
      a.dispatchEvent(new Event("loadedmetadata"));
      expect(a.currentTime).toBeCloseTo(0.8);
    });

    it("seeks back to repeat an ayah and jumps with next", async () => {
      stubTimings([4000, 6000, 8000, 10000, 12000]);
      audioStore.set((p) => ({ ...p, reciter: "mp3q_ahmad_masarawi", repeat: 2 }));
      player.play({ kind: "ayah", surah: 112, ayah: 2 });
      await flush();
      await flush();
      const a = FakeAudio.last!;
      a.dispatchEvent(new Event("loadedmetadata"));
      expect(a.currentTime).toBeCloseTo(6);
      a.dispatchEvent(new Event("playing"));
      await at(a, 8.0);
      expect(a.currentTime).toBeCloseTo(6); // second time
      await at(a, 8.0);
      expect(player.get().status).toBe("idle");
    });
  });
});
