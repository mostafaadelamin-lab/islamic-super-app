/**
 * «سلاسل الدروس»: complete audio lesson series by well-known scholars, grouped by topic and by scholars
 * (Al-Azhar / Egypt / Saudi). List built by tools/lessons_build.py (content/lessons/dist/lessons.v1.json →
 * /data/lessons.json); audio is streamed per lesson, or saved per lesson / whole series for offline listening.
 * Sources are recorded in docs/CONTENT_SOURCES.md, never shown on the site.
 */
import { AUDIO_CACHE, offlineSupported } from "./audio-offline";
import { withBase } from "./base-path";
import { createStore } from "./store";

export interface LessonLabel {
  id: string;
  ar: string;
  en: string;
}
export interface LessonSheikh extends LessonLabel {
  groups: string[];
}
export interface LessonEpisode {
  /** "<series>-<n>", stable while the list keeps its order. */
  id: string;
  /** 1-based position in the series. */
  index: number;
  url: string;
  title?: string;
  seconds: number;
}
export interface LessonSeries {
  id: string;
  topic: LessonLabel;
  sheikh: LessonSheikh;
  ar: string;
  en: string;
  episodes: LessonEpisode[];
}
export interface LessonCatalog {
  topics: LessonLabel[];
  groups: LessonLabel[];
  sheikhs: LessonSheikh[];
  series: LessonSeries[];
  /** Al-Sha'rawi's seerah and prophets' stories: shown in his own section, not in the lesson list. */
  sharawi: LessonSeries[];
}

type RawSeries = {
  id: string;
  topic: string;
  sheikh: string;
  ar: string;
  en: string;
  episodes: { u: string; t?: string; s?: number }[];
};

interface RawFile {
  topics: LessonLabel[];
  groups: LessonLabel[];
  sheikhs: LessonSheikh[];
  series: RawSeries[];
  sharawi?: RawSeries[];
}

export const LESSONS_URL = (): string => withBase("/data/lessons.json");

export function parseLessons(raw: unknown): LessonCatalog {
  const j = raw as RawFile;
  if (!j || !Array.isArray(j.series) || !Array.isArray(j.topics)) throw new Error("lessons.json: bad format");
  const topics = new Map(j.topics.map((x) => [x.id, x]));
  const sheikhs = new Map(j.sheikhs.map((x) => [x.id, x]));
  const one = (s: RawSeries): LessonSeries => ({
    id: s.id,
    topic: topics.get(s.topic)!,
    sheikh: sheikhs.get(s.sheikh)!,
    ar: s.ar,
    en: s.en,
    episodes: s.episodes.map((e, i) => ({
      id: `${s.id}-${i + 1}`,
      index: i + 1,
      url: e.u,
      title: e.t,
      seconds: e.s ?? 0,
    })),
  });
  return {
    topics: j.topics,
    groups: j.groups,
    sheikhs: j.sheikhs,
    series: j.series.map(one),
    sharawi: (j.sharawi ?? []).map(one),
  };
}

export async function loadLessons(fetchImpl: typeof fetch = fetch): Promise<LessonCatalog> {
  const r = await fetchImpl(LESSONS_URL());
  if (!r.ok) throw new Error(`lessons.json: HTTP ${r.status}`);
  return parseLessons(await r.json());
}

/** [group]/[topic] null = all. */
export function filterSeries(c: LessonCatalog, group: string | null, topic: string | null): LessonSeries[] {
  return c.series.filter(
    (s) => (group === null || s.sheikh.groups.includes(group)) && (topic === null || s.topic.id === topic),
  );
}

const strings = (raw: unknown): string[] =>
  Array.isArray(raw) ? raw.filter((v): v is string => typeof v === "string") : [];
const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

/** Lessons heard to the end (✓). */
export const lessonsDoneStore = createStore<string[]>("rattil.lessonsDone", [], strings);
/** Lessons saved for offline listening (audio in the "rattil-audio" Cache Storage, served by the service worker). */
export const lessonsSavedStore = createStore<string[]>("rattil.lessonsSaved", [], strings);

export interface LessonsProgress {
  /** Last lesson played in each series. */
  last: Record<string, string>;
  /** The series listened to last. */
  series: string | null;
  /** Where the listener stopped in each lesson (seconds). */
  pos: Record<string, number>;
}
export const lessonsProgressStore = createStore<LessonsProgress>(
  "rattil.lessonsProgress",
  { last: {}, series: null, pos: {} },
  (raw) => {
    const r = isObj(raw) ? raw : {};
    const rec = <T>(v: unknown, ok: (x: unknown) => x is T): Record<string, T> =>
      isObj(v)
        ? Object.fromEntries(Object.entries(v).flatMap(([k, x]) => (ok(x) ? [[k, x] as [string, T]] : [])))
        : {};
    return {
      last: rec(r.last, (x): x is string => typeof x === "string"),
      series: typeof r.series === "string" ? r.series : null,
      pos: rec(r.pos, (x): x is number => typeof x === "number" && Number.isFinite(x)),
    };
  },
);

export function setDone(id: string, done: boolean): void {
  lessonsDoneStore.set((ids) => {
    const rest = ids.filter((x) => x !== id);
    return done ? [...rest, id] : rest;
  });
}

/** Positions shorter than this are not worth resuming from. */
const MIN_RESUME_SEC = 5;

export function rememberPlay(seriesId: string, episodeId: string): void {
  lessonsProgressStore.set((p) => ({ ...p, series: seriesId, last: { ...p.last, [seriesId]: episodeId } }));
}

export function rememberPosition(episodeId: string, sec: number): void {
  lessonsProgressStore.set((p) => {
    const pos = { ...p.pos };
    if (sec > MIN_RESUME_SEC) pos[episodeId] = Math.floor(sec);
    else delete pos[episodeId];
    return { ...p, pos };
  });
}

export async function saveLessonAudio(e: LessonEpisode): Promise<void> {
  const cache = await caches.open(AUDIO_CACHE);
  if (!(await cache.match(e.url))) {
    let res: Response;
    try {
      res = await fetch(e.url, { mode: "cors" });
      if (!res.ok) throw new Error(`${e.url} ${res.status}`);
    } catch {
      res = await fetch(e.url, { mode: "no-cors" });
    }
    await cache.put(e.url, res);
  }
  lessonsSavedStore.set((ids) => (ids.includes(e.id) ? ids : [...ids, e.id]));
}

export async function deleteLessonAudio(e: LessonEpisode): Promise<void> {
  if (offlineSupported()) await (await caches.open(AUDIO_CACHE)).delete(e.url);
  lessonsSavedStore.set((ids) => ids.filter((id) => id !== e.id));
}
