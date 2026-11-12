/**
 * Sheikh al-Sha'rawi's audio tafsir (khawatir): 1116 lessons by surah, each with the ayah range it explains.
 * List built by tools/sharawi_build.py (content/sharawi/dist/sharawi.v1.json → /data/sharawi.json);
 * audio is streamed per lesson, or saved per lesson for offline listening. The source is recorded in docs/CONTENT_SOURCES.md, never shown on the site.
 */
import { AUDIO_CACHE, offlineSupported } from "./audio-offline";
import { withBase } from "./base-path";
import { createStore } from "./store";

export interface SharawiLesson {
  id: number;
  surah: number;
  /** 1-based position within the surah. */
  index: number;
  url: string;
  from?: number;
  to?: number;
  seconds: number;
}
export interface SharawiSurah {
  surah: number;
  lessons: SharawiLesson[];
}

interface RawFile {
  version: number;
  base: string;
  surahs: { n: number; lessons: { id: number; p: string; s?: number; f?: number; t?: number }[] }[];
}

export const SHARAWI_URL = (): string => withBase("/data/sharawi.json");

export function parseSharawi(raw: unknown): SharawiSurah[] {
  const j = raw as RawFile;
  if (!j || typeof j.base !== "string" || !Array.isArray(j.surahs))
    throw new Error("sharawi.json: bad format");
  return j.surahs.map((s) => ({
    surah: s.n,
    lessons: s.lessons.map((l, i) => ({
      id: l.id,
      surah: s.n,
      index: i + 1,
      url: j.base + l.p.split("/").map(encodeURIComponent).join("/"),
      from: l.f,
      to: l.t,
      seconds: l.s ?? 0,
    })),
  }));
}

export async function loadSharawi(fetchImpl: typeof fetch = fetch): Promise<SharawiSurah[]> {
  const r = await fetchImpl(SHARAWI_URL());
  if (!r.ok) throw new Error(`sharawi.json: HTTP ${r.status}`);
  return parseSharawi(await r.json());
}

/** Lessons saved for offline listening: ids in a small store, audio in the "rattil-audio" Cache Storage,
 * which the service worker serves to the <audio> element (same as saved recitations). */
export const sharawiSavedStore = createStore<number[]>("rattil.sharawiSaved", [], (raw) =>
  Array.isArray(raw) ? raw.filter((v): v is number => Number.isInteger(v) && v > 0) : [],
);

export async function saveLesson(l: SharawiLesson): Promise<void> {
  const cache = await caches.open(AUDIO_CACHE);
  if (!(await cache.match(l.url))) {
    let res: Response;
    try {
      res = await fetch(l.url, { mode: "cors" });
      if (!res.ok) throw new Error(`${l.url} ${res.status}`);
    } catch {
      res = await fetch(l.url, { mode: "no-cors" });
    }
    await cache.put(l.url, res);
  }
  sharawiSavedStore.set((ids) => (ids.includes(l.id) ? ids : [...ids, l.id]));
}

export async function deleteLesson(l: SharawiLesson): Promise<void> {
  if (offlineSupported()) await (await caches.open(AUDIO_CACHE)).delete(l.url);
  sharawiSavedStore.set((ids) => ids.filter((id) => id !== l.id));
}
