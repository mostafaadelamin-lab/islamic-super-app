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
/** An https mp3 link from archive.org or an official podcast (Spreaker, Simplecast), no raw spaces:
 *  matches "https://archive.org/download/x/1.mp3", "https://api.spreaker.com/download/episode/1/a.mp3" and
 *  "https://cdn.simplecast.com/audio/x/default_tc.mp3", rejects "http://x/a b.mp3". */
const AUDIO_MP3 =
  /^https:\/\/(?:(?:archive\.org|api\.spreaker\.com)\/download|cdn\.simplecast\.com\/audio)\/[^ ]+\.mp3$/i;
/** «بودكاست» (owner 2026-11-27): the shows' own hosts (Simplecast, Anchor's CloudFront, SoundCloud streams). */
const PODCAST_AUDIO =
  /^https:\/\/(?:injector\.simplecastaudio\.com\/[^ ]+\.mp3|d3ctxlq1ktw2nl\.cloudfront\.net\/[^ ]+\.(?:mp3|m4a)|feeds\.soundcloud\.com\/stream\/[^ ]+)$/i;
const PODCAST_IDS = [
  "sahaba-waie",
  "tahrar-amgad",
  "muhlikat-amgad",
  "qudwa-amgad",
  "ibadat-araby",
  "khulud-araby",
  "rabbi-sharkawy",
  "khabaith-ayoubi",
  "sahaba-alaa",
];
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
    const bad = data.series
      .flatMap((s) => s.episodes.map((e) => ({ e, pod: s.topic.id === "podcast" })))
      .filter(({ e, pod }) => !(pod ? PODCAST_AUDIO : AUDIO_MP3).test(e.url));
    expect(bad).toEqual([]);
    // Owner 2026-11-23: Sha'rawi has his own section; add the Grand Imam Ahmed al-Tayeb.
    expect(data.series.filter((s) => s.sheikh.id === "shaarawi")).toEqual([]);
    expect(data.series.filter((s) => s.sheikh.id === "tayeb").length).toBeGreaterThanOrEqual(MIN_TAYEB);
    // Owner 2026-11-26: sheikhs with legal/security problems in Egypt or Saudi Arabia removed, Al-Azhar scholars instead.
    const gone = ["munajjid", "arifi", "yaqoub", "awadi"];
    expect(data.series.filter((s) => gone.includes(s.sheikh.id))).toEqual([]);
    expect(data.series.some((s) => s.id === "nur-yaqin-gabr")).toBe(true);
    // Owner 2026-11-26: Eng. Ayman Abdelrahim removed; Saudi scholars with no arrest or ban record added.
    expect(data.series.filter((s) => s.sheikh.id === "ayman")).toEqual([]);
    for (const sh of ["fawzan", "ibnbaz", "humaid", "mutlaq", "ruhaily"])
      expect(data.series.some((s) => s.sheikh.id === sh)).toBe(true);
  });

  it("is listed under More", () => {
    expect(SECTIONS.some((s) => s.path === "lessons")).toBe(true);
  });

  it("«بودكاست»: only the checked religious shows, its own section right after al-Sha'rawi", () => {
    expect(filterSeries(data, null, "podcast").map((s) => s.id)).toEqual(PODCAST_IDS);
    const titles = filterSeries(data, null, "podcast").flatMap((s) => s.episodes.map((e) => e.title ?? ""));
    expect(titles.filter((x) => /غزة|فاهم|\|/.test(x))).toEqual([]);
    const paths = SECTIONS.map((s) => s.path);
    expect(paths.indexOf("podcast")).toBe(paths.indexOf("sharawi") + 1);
  });
});

describe("lesson series: page", () => {
  it("«بودكاست» page lists only the podcasts, no topic chips; «افهم دينك» has a «بودكاست» topic", async () => {
    const user = userEvent.setup();
    const { unmount } = render(<LessonsView locale="ar" loader={load} fixedTopic="podcast" />);
    expect(await screen.findByTestId("lessons-note")).toHaveTextContent("برنامج");
    expect(screen.getByTestId("lessons-series-tahrar-amgad")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-series-nur-yaqin-gabr")).toBeNull();
    expect(screen.queryByTestId("lessons-topic-all")).toBeNull();
    await user.click(screen.getByTestId("lessons-series-tahrar-amgad"));
    expect(await screen.findByTestId("lessons-back")).toHaveTextContent("بودكاست");
    // Episodes, not lessons.
    expect(screen.getByTestId("lessons-meta")).toHaveTextContent("٦ حلقة");
    expect(screen.getByTestId("lessons-episodes")).toHaveTextContent("الحلقة ١");
    unmount();
    window.location.hash = "";
    render(<LessonsView locale="ar" loader={load} />);
    await user.click(await screen.findByTestId("lessons-topic-podcast"));
    expect(screen.getByTestId("lessons-series-sahaba-waie")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-series-nur-yaqin-gabr")).toBeNull();
  });

  it("shows every topic (no scholars' groups), filters, searches, and opens a series", async () => {
    const user = userEvent.setup();
    render(<LessonsView locale="ar" loader={load} />);
    expect(await screen.findByTestId("lessons-note")).toBeInTheDocument();
    expect(screen.getByTestId("lessons-series-nur-yaqin-gabr")).toBeInTheDocument();
    // Owner (2026-11-24): no groups row (no nationality or institution shown), every topic at once.
    expect(screen.queryByTestId("lessons-group-saudi")).toBeNull();
    expect(screen.getByTestId("lessons-topic-stories")).toBeInTheDocument();
    await user.click(screen.getByTestId("lessons-topic-stories"));
    expect(screen.getByTestId("lessons-series-ahsan-qasas-kafy")).toBeInTheDocument();
    await user.click(screen.getByTestId("lessons-topic-akhira"));
    expect(screen.getByTestId("lessons-series-dar-akhira-kafy")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-series-nur-yaqin-gabr")).toBeNull();
    await user.click(screen.getByTestId("lessons-topic-all"));
    await user.type(screen.getByTestId("lessons-search"), "عبد الكافي");
    expect(screen.getByTestId("lessons-series-safwa-kafy")).toBeInTheDocument();
    expect(screen.queryByTestId("lessons-series-nur-yaqin-gabr")).toBeNull();
    await user.click(screen.getByTestId("lessons-series-dar-akhira-kafy"));
    expect(await screen.findByTestId("lessons-hero")).toHaveTextContent("الدار الآخرة");
    expect(screen.getByTestId("lessons-episodes").querySelectorAll("li")).toHaveLength(DAR_AKHIRA_LESSONS);
    await user.click(screen.getByTestId("lessons-back"));
    expect(await screen.findByTestId("lessons-grid")).toBeInTheDocument();
  });

  it("plays a lesson with the player under it, ✓ at its end, then continue from the series list", async () => {
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    const user = userEvent.setup();
    window.location.hash = "manazil-gabr";
    render(<LessonsView locale="ar" loader={load} />);
    const s = data.series.find((x) => x.id === "manazil-gabr")!;
    await user.click(await screen.findByTestId("lesson-manazil-gabr-3"));
    const audio = screen.getByTestId("library-audio") as HTMLAudioElement;
    expect(audio.getAttribute("src")).toBe(s.episodes[2]!.url);
    const row = screen.getByTestId("lesson-manazil-gabr-3").closest("li")!;
    expect(row.contains(screen.getByTestId("library-now"))).toBe(true);
    expect(row.textContent).toContain("اليقظة");
    act(() => {
      audio.dispatchEvent(new Event("ended"));
    });
    expect(lessonsDoneStore.get()).toContain("manazil-gabr-3");
    expect(audio.getAttribute("src")).toBe(s.episodes[3]!.url);
    expect(lessonsProgressStore.get().series).toBe("manazil-gabr");
    expect(screen.getByTestId("lessons-continue-btn")).toHaveTextContent("٤");
    // ✓ by hand, and off again.
    await user.click(screen.getByTestId("lesson-done-manazil-gabr-1"));
    expect(lessonsDoneStore.get()).toContain("manazil-gabr-1");
    await user.click(screen.getByTestId("lesson-done-manazil-gabr-1"));
    expect(lessonsDoneStore.get()).not.toContain("manazil-gabr-1");
    await user.click(screen.getByTestId("lessons-back"));
    expect(await screen.findByTestId("lessons-continue")).toHaveTextContent("منازل السائرين");
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

describe("lesson music is jumped over (owner 2026-11-23)", () => {
  it("skipEnd gives the end of the music stretch the time is in", async () => {
    const { skipEnd } = await import("@/components/RecitationLibrary");
    const tr = {
      key: "k",
      title: "t",
      url: "u",
      live: false,
      skips: [
        [0, 45],
        [380, 397],
      ] as const,
    };
    expect(skipEnd(tr, 0)).toBe(45);
    expect(skipEnd(tr, 44.9)).toBe(45);
    expect(skipEnd(tr, 45)).toBeNull();
    expect(skipEnd(tr, 390)).toBe(397);
    expect(skipEnd({ ...tr, skips: undefined }, 10)).toBeNull();
  });
  it("the Grand Imam's lessons carry their music stretches", () => {
    const c = parseLessons(readRepoJson("content/lessons/dist/lessons.v1.json"));
    const asma = c.series.find((s) => s.id === "asma-tayeb")!;
    expect(asma.episodes.filter((e) => e.skips.length > 0).length).toBeGreaterThan(asma.episodes.length / 2);
  });
});
