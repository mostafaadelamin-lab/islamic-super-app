import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LessonsView } from "@/components/LessonsView";
import { SECTIONS } from "@/components/SectionTiles";
import {
  filterSeries,
  lessonsDoneStore,
  lessonsProgressStore,
  lessonsSavedStore,
  parseLessons,
} from "@/lib/lessons";
import { readRepoJson } from "../repo";

const data = parseLessons(readRepoJson("content/lessons/dist/lessons.v1.json"));
const load = (): Promise<typeof data> => Promise.resolve(data);
const MIN_SERIES = 45;
const MIN_PER_GROUP = 5;
const MIN_KAFY = 15;
const DAR_AKHIRA_LESSONS = 32;
const HTTP_OK = 200;
/** An https mp3 link from archive.org or the Grand Imam's official podcast, no raw spaces:
 *  matches "https://archive.org/download/x/1.mp3" and "https://api.spreaker.com/download/episode/1/a.mp3", rejects "http://x/a b.mp3". */
const AUDIO_MP3 = /^https:\/\/(?:archive\.org|api\.spreaker\.com)\/download\/[^ ]+\.mp3$/i;
const MIN_TAYEB = 4;

beforeEach(() => {
  window.location.hash = "";
  lessonsDoneStore.set([]);
  lessonsSavedStore.set([]);
  lessonsProgressStore.set({ last: {}, series: null, pos: {} });
});

describe("lesson series: data", () => {
  it("has every topic and scholar group, all of Omar Abdelkafy's series, https mp3 audio, the Grand Imam's talks and no Sha'rawi series", () => {
    expect(data.series.length).toBeGreaterThanOrEqual(MIN_SERIES);
    expect(data.topics.filter((x) => filterSeries(data, null, x.id).length === 0)).toEqual([]);
    expect(
      ["azhar", "egypt", "saudi"].filter((g) => filterSeries(data, g, null).length < MIN_PER_GROUP),
    ).toEqual([]);
    expect(data.series.filter((s) => s.sheikh.id === "kafy").length).toBeGreaterThanOrEqual(MIN_KAFY);
    expect(data.series.filter((s) => s.episodes.length === 0)).toEqual([]);
    const bad = data.series.flatMap((s) => s.episodes).filter((e) => !AUDIO_MP3.test(e.url));
    expect(bad).toEqual([]);
    // Owner 2026-11-23: Sha'rawi has his own section; add the Grand Imam Ahmed al-Tayeb.
    expect(data.series.filter((s) => s.sheikh.id === "shaarawi")).toEqual([]);
    expect(data.series.filter((s) => s.sheikh.id === "tayeb").length).toBeGreaterThanOrEqual(MIN_TAYEB);
  });

  it("is listed under More", () => {
    expect(SECTIONS.some((s) => s.path === "lessons")).toBe(true);
  });
});

describe("lesson series: page", () => {
  it("filters by scholars and topic, searches, and opens a series", async () => {
    const user = userEvent.setup();
    render(<LessonsView locale="ar" loader={load} />);
    expect(await screen.findByTestId("lessons-note")).toBeInTheDocument();
    expect(screen.getByTestId("lessons-series-seerah-hassan")).toBeInTheDocument();
    await user.click(screen.getByTestId("lessons-group-saudi"));
    expect(screen.queryByTestId("lessons-series-seerah-hassan")).toBeNull();
    expect(screen.getByTestId("lessons-series-riyadh-uthaymeen")).toBeInTheDocument();
    await user.click(screen.getByTestId("lessons-group-azhar"));
    expect(screen.getByTestId("lessons-series-asma-tayeb")).toBeInTheDocument();
    await user.click(screen.getByTestId("lessons-group-all"));
    await user.click(screen.getByTestId("lessons-topic-akhira"));
    expect(screen.getByTestId("lessons-series-nihaya-hassan")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-series-seerah-hassan")).toBeNull();
    await user.click(screen.getByTestId("lessons-topic-all"));
    await user.type(screen.getByTestId("lessons-search"), "عبد الكافي");
    expect(screen.getByTestId("lessons-series-safwa-kafy")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-series-seerah-hassan")).toBeNull();
    await user.click(screen.getByTestId("lessons-series-dar-akhira-kafy"));
    expect(await screen.findByTestId("lessons-hero")).toHaveTextContent("الدار الآخرة");
    expect(screen.getByTestId("lessons-episodes").querySelectorAll("li")).toHaveLength(DAR_AKHIRA_LESSONS);
    await user.click(screen.getByTestId("lessons-back"));
    expect(await screen.findByTestId("lessons-grid")).toBeInTheDocument();
  });

  it("plays a lesson with the player under it, ✓ at its end, then continue from the series list", async () => {
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    const user = userEvent.setup();
    window.location.hash = "nihaya-hassan";
    render(<LessonsView locale="ar" loader={load} />);
    const s = data.series.find((x) => x.id === "nihaya-hassan")!;
    await user.click(await screen.findByTestId("lesson-nihaya-hassan-3"));
    const audio = screen.getByTestId("library-audio") as HTMLAudioElement;
    expect(audio.getAttribute("src")).toBe(s.episodes[2]!.url);
    const row = screen.getByTestId("lesson-nihaya-hassan-3").closest("li")!;
    expect(row.contains(screen.getByTestId("library-now"))).toBe(true);
    expect(row.textContent).toContain("الموت");
    act(() => {
      audio.dispatchEvent(new Event("ended"));
    });
    expect(lessonsDoneStore.get()).toContain("nihaya-hassan-3");
    expect(audio.getAttribute("src")).toBe(s.episodes[3]!.url);
    expect(lessonsProgressStore.get().series).toBe("nihaya-hassan");
    expect(screen.getByTestId("lessons-continue-btn")).toHaveTextContent("٤");
    // ✓ by hand, and off again.
    await user.click(screen.getByTestId("lesson-done-nihaya-hassan-1"));
    expect(lessonsDoneStore.get()).toContain("nihaya-hassan-1");
    await user.click(screen.getByTestId("lesson-done-nihaya-hassan-1"));
    expect(lessonsDoneStore.get()).not.toContain("nihaya-hassan-1");
    await user.click(screen.getByTestId("lessons-back"));
    expect(await screen.findByTestId("lessons-continue")).toHaveTextContent("أحداث النهاية");
    vi.restoreAllMocks();
  });

  it("downloads the whole series for offline listening", async () => {
    const store = new Map<string, Response>();
    const cache = {
      match: (u: string) => Promise.resolve(store.get(u)),
      put: (u: string, r: Response) => (store.set(u, r), Promise.resolve()),
      delete: (u: string) => Promise.resolve(store.delete(u)),
    };
    vi.stubGlobal("caches", { open: () => Promise.resolve(cache) });
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.resolve(new Response("mp3", { status: HTTP_OK }))),
    );
    const user = userEvent.setup();
    window.location.hash = "huquq-kafy";
    render(<LessonsView locale="ar" loader={load} />);
    await user.click(await screen.findByTestId("lessons-download-all"));
    expect(await screen.findByText("السلسلة كلها محمّلة")).toBeInTheDocument();
    const s = data.series.find((x) => x.id === "huquq-kafy")!;
    expect(store.size).toBe(s.episodes.length);
    expect(lessonsSavedStore.get()).toHaveLength(s.episodes.length);
    vi.unstubAllGlobals();
  });
});
