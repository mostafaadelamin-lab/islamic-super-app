import { audioStore } from "@/lib/audio";
import { player, resetPlayerForTests } from "@/lib/audio-player";

/** jsdom has no media playback: Audio is replaced by a minimal fake that records sources. */
class FakeAudio extends EventTarget {
  static last: FakeAudio | null = null;
  static playImpl: () => Promise<void> = () => Promise.resolve();
  preload = "";
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
  pause(): void {}
  play(): Promise<void> {
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
});
