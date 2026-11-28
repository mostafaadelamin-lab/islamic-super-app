import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { audioStore, buildQueue, radioSurahs } from "@/lib/audio";
import { player, resetPlayerForTests } from "@/lib/audio-player";
import { sleepTimer } from "@/lib/sleep-timer";
import {
  DEFAULT_STATION,
  QuranRadio,
  RADIO_DURATIONS,
  radioStationStore,
  randomSurah,
} from "@/components/QuranRadio";
import { LIVE_RADIOS } from "@/lib/live-radios";
import { SITE_GROUPS, itemHref, locate } from "@/lib/site-map";

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
  radioStationStore.reload();
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
    expect(screen.queryByTestId("radio-reciter")).toBeNull(); // live station: no reciter
    await user.selectOptions(screen.getByTestId("radio-station"), "mushaf");
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

describe("home radio station (owner, 2026-11-14)", () => {
  it("defaults to the Holy Quran Radio from Cairo, listed first", () => {
    render(<QuranRadio locale="ar" />);
    const select = screen.getByTestId("radio-station") as HTMLSelectElement;
    expect(DEFAULT_STATION).toBe("eg");
    expect(select.value).toBe("eg");
    expect(select.options[0]!.textContent).toBe("إذاعة القرآن الكريم من القاهرة  ·  🎧 صوتي");
    expect(LIVE_RADIOS.find((r) => r.id === "eg")!.url).toMatch(/^https:/);
    expect(screen.getByTestId("radio-status")).toHaveTextContent("بث مباشر");
  });
  it("plays the live stream and stops the recitation player", async () => {
    const user = userEvent.setup();
    const play = vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    const stop = vi.spyOn(player, "stop");
    render(<QuranRadio locale="ar" />);
    await user.click(screen.getByTestId("radio-play"));
    expect(play).toHaveBeenCalled();
    expect(stop).toHaveBeenCalled();
    expect((screen.getByTestId("radio-live-audio") as HTMLAudioElement).getAttribute("src")).toBe(
      LIVE_RADIOS.find((r) => r.id === "eg")!.url,
    );
    expect(screen.getByTestId("radio-play")).toHaveAttribute("aria-pressed", "true");
  });
});

describe("Haramain live video in the home radio (owner, 2026-11-28)", () => {
  it("marks every station in the list as audio («صوتي»), the stations and their order unchanged", () => {
    render(<QuranRadio locale="ar" />);
    const select = screen.getByTestId("radio-station") as HTMLSelectElement;
    const texts = [...select.options].map((o) => o.textContent ?? "");
    expect(texts).toHaveLength(LIVE_RADIOS.length + 1);
    for (const t of texts) expect(t.endsWith("🎧 صوتي")).toBe(true);
    expect([...select.options].map((o) => o.value)).toEqual(["eg", "makkah", "madinah", "sa", "mushaf"]);
  });
  it("shows two «مباشر الآن فيديو» buttons; a tap opens the live video and stops the audio", async () => {
    const user = userEvent.setup();
    const stop = vi.spyOn(player, "stop");
    render(<QuranRadio locale="ar" />);
    const makkah = screen.getByTestId("radio-live-makkah");
    expect(makkah).toHaveTextContent("المسجد الحرام");
    expect(makkah).toHaveTextContent("مباشر الآن فيديو");
    expect(screen.getByTestId("radio-live-madinah")).toHaveTextContent("المسجد النبوي");
    expect(screen.queryByTestId("radio-video")).toBeNull();
    await user.click(makkah);
    expect(stop).toHaveBeenCalled();
    expect(makkah).toHaveAttribute("aria-pressed", "true");
    const src = screen.getByTestId("radio-video-player").getAttribute("src")!;
    expect(src).toContain("/embed/IsJTAdC3-Jw?");
    expect(src).toContain("mute=0");
    // switch to Madinah, then close
    await user.click(screen.getByTestId("radio-live-madinah"));
    expect(screen.getByTestId("radio-video-player").getAttribute("src")).toContain("/embed/10aUPlTW8wQ?");
    await user.click(screen.getByTestId("radio-video-close"));
    expect(screen.queryByTestId("radio-video")).toBeNull();
  });
  it("closes the video when the audio radio starts", async () => {
    const user = userEvent.setup();
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    render(<QuranRadio locale="ar" />);
    await user.click(screen.getByTestId("radio-live-makkah"));
    expect(screen.getByTestId("radio-video")).toBeTruthy();
    await user.click(screen.getByTestId("radio-play"));
    expect(screen.queryByTestId("radio-video")).toBeNull();
  });
});

describe("website menus", () => {
  it("the prayer menu has adhan alerts, linking to the alerts on the prayer page", () => {
    const prayer = SITE_GROUPS.find((g) => g.path === "prayer")!;
    expect(prayer.items).toContain("adhan");
    expect(itemHref("ar", "adhan")).toBe("/ar/prayer/#adhan");
    expect(locate("/prayer/")!.group.path).toBe("prayer");
    expect(locate("/surah/2/")!.group.path).toBe("quran");
    expect(locate("/")).toBeNull();
  });
});
