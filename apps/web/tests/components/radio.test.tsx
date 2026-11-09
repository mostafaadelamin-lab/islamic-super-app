import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { audioStore, buildQueue, radioSurahs } from "@/lib/audio";
import { player, resetPlayerForTests } from "@/lib/audio-player";
import { sleepTimer } from "@/lib/sleep-timer";
import { QuranRadio, RADIO_DURATIONS, randomSurah } from "@/components/QuranRadio";

/** jsdom has no media playback: a minimal fake Audio that records sources. */
class FakeAudio extends EventTarget {
  preload = "";
  private attrs = new Map<string, string>();
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
    this.dispatchEvent(new Event("playing"));
    return Promise.resolve();
  }
}

beforeEach(() => {
  localStorage.clear();
  audioStore.reload();
  resetPlayerForTests();
  sleepTimer.set(null);
  vi.stubGlobal("Audio", FakeAudio);
  vi.spyOn(navigator, "onLine", "get").mockReturnValue(true);
});
afterEach(() => {
  act(() => player.stop());
  sleepTimer.set(null);
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("radio queue", () => {
  it("visits every surah once, starting at the chosen one and wrapping after an-Nas", () => {
    const order = radioSurahs(113);
    expect(order).toHaveLength(114);
    expect(order.slice(0, 4)).toEqual([113, 114, 1, 2]);
    expect(new Set(order).size).toBe(114);
    expect(radioSurahs(0)[0]).toBe(1); // invalid start falls back to al-Fatihah
  });
  it("plays all 6236 ayahs plus a basmala before each surah except al-Fatihah and at-Tawbah", () => {
    const q = buildQueue({ kind: "quran", from: 1 });
    expect(q.filter((x) => x.kind === "ayah")).toHaveLength(6236);
    expect(q.filter((x) => x.kind === "basmala")).toHaveLength(112);
    expect(q[0]).toEqual({ kind: "ayah", s: 1, a: 1 });
  });
  it("random start is always a valid surah", () => {
    expect(randomSurah(() => 0)).toBe(1);
    expect(randomSurah(() => 0.999999)).toBe(114);
  });
});

describe("QuranRadio", () => {
  it("plays the whole Mushaf with the chosen reciter and stops after the chosen duration", async () => {
    vi.spyOn(Math, "random").mockReturnValue(17 / 114); // surah 18, al-Kahf
    const user = userEvent.setup();
    render(<QuranRadio locale="ar" />);
    expect(screen.getByTestId("radio-duration")).toHaveTextContent("غير محدود");
    expect(screen.getByTestId("radio-shorter")).toBeDisabled();
    await user.click(screen.getByTestId("radio-longer"));
    expect(RADIO_DURATIONS[1]).toBe(15);
    expect(screen.getByTestId("radio-duration")).toHaveTextContent("١٥ دقيقة");
    await user.selectOptions(screen.getByTestId("radio-reciter"), "Yasser_Ad-Dussary_128kbps");
    await user.click(screen.getByTestId("radio-play"));
    expect(player.get().src).toContain("/Yasser_Ad-Dussary_128kbps/001001.mp3"); // basmala before al-Kahf
    expect(player.current()).toEqual({ kind: "basmala", s: 18, a: 0 });
    expect(screen.getByTestId("radio-status")).toHaveTextContent("سورة الكهف");
    expect(screen.getByTestId("radio-play")).toHaveAttribute("aria-pressed", "true");
    expect(sleepTimer.get().minutes).toBe(15);
    // pause / resume from the same button
    await user.click(screen.getByTestId("radio-play"));
    expect(player.get().status).toBe("paused");
    expect(screen.getByTestId("radio-play")).toHaveAttribute("aria-pressed", "false");
  });
});
