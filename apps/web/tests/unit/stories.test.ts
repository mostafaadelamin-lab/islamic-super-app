import { readRepoJson } from "../repo";
import { buildQueue, rangeRefs, type QueueItem } from "@/lib/audio";
import {
  isAudioUrl,
  minutes,
  sanitizeSeries,
  sanitizeStories,
  SERIES,
  STORIES,
  storiesByCategory,
  storyById,
  visibleEpisodes,
  type Episode,
  type Series,
  type Story,
} from "@/lib/stories";
import { sleepTimer } from "@/lib/sleep-timer";
import { player } from "@/lib/audio-player";
import { isValidAyah } from "@/lib/pages";

const refs = (q: QueueItem[]): string[] => q.map((x) => (x.kind === "basmala" ? `b${x.s}` : `${x.s}:${x.a}`));
const bundle = readRepoJson<{ items: Story[]; series: Series[] }>("content/stories/dist/stories.v1.json");

const base: Story = {
  id: "fil",
  category: "others",
  title: { ar: "أصحاب الفيل", en: "Elephant" },
  segments: [[105, 1, 5]],
  ayahCount: 5,
  status: "pending",
  reviewer: null,
  reviewedAt: null,
};

describe("stories bundle", () => {
  it("ships every story of the built bundle, all with real verse ranges", () => {
    expect(STORIES.length).toBe(bundle.items.length);
    expect(STORIES.length).toBeGreaterThanOrEqual(20);
    for (const st of STORIES) {
      for (const [s, a, b] of st.segments)
        expect(isValidAyah(s, a) && isValidAyah(s, b) && a <= b).toBe(true);
      expect(rangeRefs(st.segments)).toHaveLength(st.ayahCount);
    }
  });
  it("nothing is approved without a named reviewer", () => {
    for (const st of STORIES) if (st.status === "approved") expect(st.reviewer?.trim()).toBeTruthy();
  });
  it("drops malformed stories and ranges that do not exist", () => {
    const bad = [
      { ...base, id: "Bad Id" },
      { ...base, id: "x1", segments: [[12, 4, 112]] }, // Yusuf has 111 ayahs
      { ...base, id: "x2", segments: [[12, 9, 3]] },
      { ...base, id: "x3", segments: [] },
      { ...base, id: "x4", status: "rejected" },
      { ...base, id: "x5", category: "fiction" },
      null,
    ];
    expect(sanitizeStories({ items: [base, ...bad] }).map((s) => s.id)).toEqual(["fil"]);
    expect(sanitizeStories("nope")).toEqual([]);
  });
  it("groups by category and finds by id", () => {
    expect(storiesByCategory().map((g) => g.category)).toEqual(["prophets", "others"]);
    expect(storyById("yusuf")?.segments).toEqual([[12, 4, 101]]);
    expect(storyById("missing")).toBeUndefined();
  });
});

const ep: Episode = {
  id: "yusuf",
  title: { ar: "قصة يوسف", en: "Joseph" },
  url: "https://archive.org/download/x/a.mp3",
  durationSec: 4459,
  story: "yusuf",
  status: "pending",
  reviewer: null,
};
const series: Series = {
  id: "awadi-prophets",
  title: { ar: "قصص الأنبياء", en: "Stories" },
  narrator: { ar: "الشيخ", en: "Sheikh" },
  source: "src",
  sourceUrl: null,
  licence: "non-commercial",
  episodes: [ep, { ...ep, id: "adam", status: "approved", reviewer: "الشيخ س" }],
};

describe("narrated series", () => {
  it("ships the owner's series: Sheikh Nabil al-Awadi, 19 episodes, none approved yet", () => {
    expect(SERIES).toHaveLength(bundle.series.length);
    expect(SERIES[0]!.narrator.ar).toContain("نبيل العوضي");
    expect(SERIES[0]!.episodes).toHaveLength(19);
    expect(SERIES[0]!.episodes.every((e) => e.status === "pending")).toBe(true);
    for (const e of SERIES[0]!.episodes) if (e.story) expect(storyById(e.story)).toBeDefined();
  });
  it("users hear approved episodes only; reviewers also get pending ones", () => {
    expect(visibleEpisodes(series, false).map((e) => e.id)).toEqual(["adam"]);
    expect(visibleEpisodes(series, true).map((e) => e.id)).toEqual(["yusuf", "adam"]);
  });
  it("accepts only https audio links", () => {
    expect(isAudioUrl("https://archive.org/download/x/%D9%82.mp3")).toBe(true);
    for (const bad of [
      "http://a.org/x.mp3",
      "javascript:alert(1)//x.mp3",
      "https://a.org/page.html",
      "data:audio/mp3,x",
      3,
    ])
      expect(isAudioUrl(bad)).toBe(false);
  });
  it("drops malformed episodes, and series left empty or without a licence", () => {
    const bad = { ...ep, id: "bad", url: "http://a.org/x.mp3" };
    const out = sanitizeSeries({
      series: [
        { ...series, episodes: [ep, bad, { ...ep, id: "r", status: "rejected" }] },
        { ...series, id: "empty", episodes: [bad] },
        { ...series, id: "nolicence", licence: " " },
      ],
    });
    expect(out.map((s) => [s.id, s.episodes.map((e) => e.id)])).toEqual([["awadi-prophets", ["yusuf"]]]);
  });
  it("rounds durations to whole minutes", () => {
    expect(minutes(4459)).toBe(74);
    expect(minutes(20)).toBe(1);
    expect(minutes(null)).toBeNull();
  });
});

describe("sleep timer", () => {
  afterEach(() => {
    vi.useRealTimers();
    sleepTimer.set(null);
  });
  it("stops the recitation and pauses every audio element when it fires", () => {
    vi.useFakeTimers();
    const stop = vi.spyOn(player, "stop");
    const el = document.createElement("audio");
    const pause = vi.spyOn(el, "pause").mockImplementation(() => undefined);
    document.body.append(el);
    sleepTimer.set(15, Date.now());
    expect(sleepTimer.minutesLeft()).toBe(15);
    vi.advanceTimersByTime(14 * 60_000);
    expect(stop).not.toHaveBeenCalled();
    expect(sleepTimer.minutesLeft()).toBe(1);
    vi.advanceTimersByTime(60_000);
    expect(stop).toHaveBeenCalled();
    expect(pause).toHaveBeenCalled();
    expect(sleepTimer.get().endsAt).toBeNull();
    el.remove();
  });
  it("can be cancelled", () => {
    vi.useFakeTimers();
    const stop = vi.spyOn(player, "stop");
    stop.mockClear();
    sleepTimer.set(30);
    sleepTimer.set(null);
    vi.advanceTimersByTime(31 * 60_000);
    expect(stop).not.toHaveBeenCalled();
    expect(sleepTimer.minutesLeft()).toBeNull();
  });
});

describe("story playback queue", () => {
  it("plays the ranges in order, with the basmala before an ayah 1 (not before mid-surah ranges)", () => {
    expect(
      refs(
        buildQueue({
          kind: "ranges",
          ranges: [
            [21, 83, 84],
            [38, 41, 42],
          ],
        }),
      ),
    ).toEqual(["21:83", "21:84", "38:41", "38:42"]);
    expect(refs(buildQueue({ kind: "ranges", ranges: [[105, 1, 2]] }))).toEqual(["b105", "105:1", "105:2"]);
  });
  it("skips invalid ranges", () => {
    expect(
      rangeRefs([
        [1, 7, 8],
        [1, 3, 2],
        [115, 1, 1],
        [1, 6, 7],
      ]),
    ).toEqual([
      [1, 6],
      [1, 7],
    ]);
  });
});
