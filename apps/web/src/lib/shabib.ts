/**
 * Sheikh Mohamed Ahmed Shabib's recitations (owner 2026-11-16). No complete 114-surah recording of the
 * sheikh exists, so he has his own section in the recitation library: the murattal surahs that exist
 * (Hafs, several partial) and his mujawwad recitations. List built by tools/shabib_build.py
 * (content/shabib/dist/shabib.v1.json → /data/shabib.json); audio is streamed, or saved per track for
 * offline listening. Sources are recorded in docs/CONTENT_SOURCES.md, never shown on the site.
 */
import { AUDIO_CACHE, offlineSupported } from "./audio-offline";
import { withBase } from "./base-path";
import { createStore } from "./store";

export type ShabibKind = "murattal" | "mujawwad";
/** fajr = Quran al-Fajr, radio = radio recording, oct73 = the dawn of 6 October 1973, short = short surahs. */
export type ShabibTag = "fajr" | "radio" | "oct73" | "short";

export interface ShabibTrack {
  id: string;
  kind: ShabibKind;
  surahs: number[];
  /** Murattal only: the recording is part of the surah ("ما تيسر من"). */
  part: boolean;
  tag?: ShabibTag;
  year?: number;
  url: string;
  seconds: number;
}

export interface Shabib {
  murattal: ShabibTrack[];
  mujawwad: ShabibTrack[];
}

interface RawTrack {
  id: string;
  surahs: number[];
  part?: boolean;
  tag?: ShabibTag;
  year?: number;
  url: string;
  s: number;
}

export const SHABIB_URL = (): string => withBase("/data/shabib.json");

export function parseShabib(raw: unknown): Shabib {
  const j = raw as { murattal?: RawTrack[]; mujawwad?: RawTrack[] };
  if (!j || !Array.isArray(j.murattal) || !Array.isArray(j.mujawwad))
    throw new Error("shabib.json: bad format");
  const map =
    (kind: ShabibKind) =>
    (x: RawTrack): ShabibTrack => ({
      id: x.id,
      kind,
      surahs: x.surahs,
      part: x.part === true,
      tag: x.tag,
      year: x.year,
      url: x.url,
      seconds: x.s ?? 0,
    });
  return { murattal: j.murattal.map(map("murattal")), mujawwad: j.mujawwad.map(map("mujawwad")) };
}

export async function loadShabib(fetchImpl: typeof fetch = fetch): Promise<Shabib> {
  const r = await fetchImpl(SHABIB_URL());
  if (!r.ok) throw new Error(`shabib.json: HTTP ${r.status}`);
  return parseShabib(await r.json());
}

/** Tracks saved for offline listening: ids here, audio in the "rattil-audio" Cache Storage (served by the SW). */
export const shabibSavedStore = createStore<string[]>("rattil.shabibSaved", [], (raw) =>
  Array.isArray(raw) ? raw.filter((v): v is string => typeof v === "string" && v.length > 0) : [],
);

export async function saveShabib(x: ShabibTrack): Promise<void> {
  const cache = await caches.open(AUDIO_CACHE);
  if (!(await cache.match(x.url))) {
    let res: Response;
    try {
      res = await fetch(x.url, { mode: "cors" });
      if (!res.ok) throw new Error(`${x.url} ${res.status}`);
    } catch {
      res = await fetch(x.url, { mode: "no-cors" });
    }
    await cache.put(x.url, res);
  }
  shabibSavedStore.set((ids) => (ids.includes(x.id) ? ids : [...ids, x.id]));
}

export async function deleteShabib(x: ShabibTrack): Promise<void> {
  if (offlineSupported()) await (await caches.open(AUDIO_CACHE)).delete(x.url);
  shabibSavedStore.set((ids) => ids.filter((id) => id !== x.id));
}
