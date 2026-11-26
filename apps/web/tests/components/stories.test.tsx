import { act, render, screen } from "@testing-library/react";
import { registerAudio } from "@/lib/audio-focus";
import userEvent from "@testing-library/user-event";
import { StoriesIndex } from "@/components/StoriesIndex";
import { StoryView, type StorySegmentText } from "@/components/StoryView";
import { player, resetPlayerForTests } from "@/lib/audio-player";
import { audioStore } from "@/lib/audio";
import { reelsPrefsStore } from "@/lib/reels";
import { SERIES, storyById, type Series, type Story } from "@/lib/stories";
import { readRepoJson } from "../repo";
import { resetStores } from "./reset";

const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");
const segs = (st: Story): StorySegmentText[] =>
  st.segments.map(([surah, from, to]) => ({
    surah,
    from,
    to,
    ayahs: quran.surahs[surah - 1]!.ayahs.slice(from - 1, to),
  }));

class FakeAudio extends EventTarget {
  static last: FakeAudio | null = null;
  preload = "";
  src = "";
  constructor() {
    super();
    FakeAudio.last = this;
  }
  getAttribute(k: string): string | null {
    return k === "src" && this.src ? this.src : null;
  }
  removeAttribute(): void {
    this.src = "";
  }
  load(): void {}
  pause(): void {}
  play(): Promise<void> {
    queueMicrotask(() => this.dispatchEvent(new Event("playing")));
    return Promise.resolve();
  }
}

beforeEach(() => {
  resetStores();
  reelsPrefsStore.reload();
  audioStore.reload();
  resetPlayerForTests();
  vi.stubGlobal("Audio", FakeAudio);
  vi.spyOn(navigator, "onLine", "get").mockReturnValue(true);
});
afterEach(() => {
  act(() => player.stop());
  vi.unstubAllGlobals();
});

describe("StoriesIndex", () => {
  it("lists the verse stories by category with links", () => {
    render(<StoriesIndex locale="ar" />);
    const link = screen.getByText("يوسف عليه السلام").closest("a")!;
    expect(link.getAttribute("href")).toBe("/ar/stories/yusuf/");
    expect(screen.getByTestId("stories-prophets")).toBeInTheDocument();
    expect(screen.getByTestId("stories-others")).toBeInTheDocument();
  });
});

describe("Sheikh al-Sha'rawi's prophets' stories (replaced Sheikh Nabil al-Awadi's series, owner 2026-11-26)", () => {
  const approved: Series = {
    ...SERIES[0]!,
    episodes: SERIES[0]!.episodes.map((e, i) =>
      i === 0 ? { ...e, status: "approved", reviewer: "الشيخ س" } : e,
    ),
  };

  it("lists every episode with no review labels or reviewer switch (as in the app); playing one pauses the other sound", async () => {
    render(<StoriesIndex locale="ar" />);
    expect(screen.queryByTestId("stories-reviewer")).toBeNull();
    expect(screen.queryByTestId("series-hidden")).toBeNull();
    expect(document.querySelectorAll("[data-episode]")).toHaveLength(44);
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    await userEvent.click(screen.getByTestId("episode-yusuf-1"));
    const audio = screen.getByTestId("series-audio") as HTMLAudioElement;
    expect(audio.getAttribute("src")).toMatch(
      /^https:\/\/archive\.org\/download\/Islamic_Tape-250_uP_bY_mUSLEm\/.+\.mp3$/,
    );
    expect(screen.queryByRole("note")).toBeNull();
    expect(screen.getByText("اقرأ آيات القصة").closest("a")?.getAttribute("href")).toBe("/ar/stories/yusuf/");
    // One sound at a time: another playing sound (e.g. the recitation) pauses.
    const other = new Audio();
    Object.defineProperty(other, "paused", { value: false });
    const pauseOther = vi.fn();
    const unregister = registerAudio(other, pauseOther);
    act(() => void audio.dispatchEvent(new Event("play")));
    expect(pauseOther).toHaveBeenCalled();
    unregister();
  });

  it("has no episode videos (Awadi's were removed) and 30-second rewind/forward", async () => {
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    vi.spyOn(HTMLMediaElement.prototype, "pause").mockImplementation(() => undefined);
    render(<StoriesIndex locale="ar" />);
    expect(screen.queryByTestId("episode-video-yusuf-1")).toBeNull();
    await userEvent.click(screen.getByTestId("episode-yusuf-1"));
    const audio = screen.getByTestId("series-audio") as HTMLAudioElement;
    // The player sits under the episode playing, with the time and a seek bar (owner 2026-11-22).
    expect(screen.getByTestId("series-now").closest("li")?.getAttribute("data-episode")).toBe("yusuf-1");
    expect(screen.getByTestId("series-seek")).toBeInTheDocument();
    audio.currentTime = 100;
    act(() => void audio.dispatchEvent(new Event("timeupdate")));
    expect(screen.getByTestId("series-elapsed").textContent).toBe("١:٤٠");
    await userEvent.click(screen.getByTestId("series-back"));
    expect(audio.currentTime).toBe(70);
    act(() => void audio.dispatchEvent(new Event("timeupdate")));
    await userEvent.click(screen.getByTestId("series-fwd"));
    expect(audio.currentTime).toBe(100);
  });

  it("does not show a reviewer's name on episodes", () => {
    render(<StoriesIndex locale="ar" series={[approved]} />);
    expect(screen.getByTestId("episode-intro").textContent).not.toContain("الشيخ س");
  });

  it("shows an error when the episode cannot load", async () => {
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    render(<StoriesIndex locale="en" series={[approved]} />);
    await userEvent.click(screen.getByTestId("episode-adam-1"));
    act(() => void screen.getByTestId("series-audio").dispatchEvent(new Event("error")));
    expect(screen.getByTestId("series-error")).toBeInTheDocument();
  });
});

describe("StoryView", () => {
  const ayyub = storyById("ayyub")!;

  it("shows only the verses of every range, with their source (no text of ours)", () => {
    render(<StoryView locale="ar" story={ayyub} segments={segs(ayyub)} />);
    expect(document.querySelectorAll("article.ayah")).toHaveLength(6);
    expect(screen.getByTestId("story-source").textContent).toContain("التفسير الميسّر");
    expect(screen.getByTestId("sleep-timer")).toBeInTheDocument();
  });

  it("listen plays the story's ranges in order and highlights the recited ayah", async () => {
    render(<StoryView locale="en" story={ayyub} segments={segs(ayyub)} />);
    await userEvent.click(screen.getByTestId("story-play"));
    expect(player.current()).toEqual({ kind: "ayah", s: 21, a: 83 });
    expect(FakeAudio.last!.src).toBe("https://everyayah.com/data/Alafasy_128kbps/021083.mp3");
    expect(document.querySelector('[data-ref="21:83"]')?.getAttribute("data-playing")).toBe("true");
    await act(async () => void FakeAudio.last!.dispatchEvent(new Event("playing")));
    act(() => void FakeAudio.last!.dispatchEvent(new Event("ended")));
    act(() => void FakeAudio.last!.dispatchEvent(new Event("ended")));
    expect(player.current()).toEqual({ kind: "ayah", s: 38, a: 41 });
    expect(document.querySelector('[data-ref="38:41"]')?.getAttribute("data-playing")).toBe("true");
    expect(document.querySelector('[data-ref="21:83"]')?.getAttribute("data-playing")).toBeNull();
  });
});
