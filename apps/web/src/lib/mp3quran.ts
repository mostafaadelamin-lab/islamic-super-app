/**
 * Recitations (every riwaya) and Quran radios from mp3quran.net's public API (v3), fetched in the browser and kept
 * in localStorage for a week. The owner chose this source on 2026-11-10; the site's notice allows any visitor or
 * developer to use its material and links. Only https addresses are kept.
 */
import { readJson, writeJson } from "./storage";

export const MP3QURAN_API = "https://www.mp3quran.net/api/v3";
const CACHE_PREFIX = "rattil.mp3quran.";
const DAY_MS = 86_400_000;
const CACHE_DAYS = 7;
/** How long a saved answer is used before asking the API again. */
export const MAX_AGE_MS = CACHE_DAYS * DAY_MS;
const LAST_SURAH = 114;
const FILE_DIGITS = 3;

export interface Moshaf {
  id: number;
  name: string;
  rewayaId: number;
  /** Folder of the MP3 files, ending in "/". */
  server: string;
  surahs: number[];
}
export interface Reciter {
  id: number;
  name: string;
  moshafs: Moshaf[];
}
export interface Rewaya {
  id: number;
  name: string;
}
export interface Radio {
  id: number;
  name: string;
  url: string;
}
export interface Library {
  reciters: Reciter[];
  riwayat: Rewaya[];
  radios: Radio[];
}

type Obj = Record<string, unknown>;
const isObj = (v: unknown): v is Obj => typeof v === "object" && v !== null && !Array.isArray(v);
const list = (j: unknown, key: string): unknown[] => {
  const v = isObj(j) ? j[key] : undefined;
  return Array.isArray(v) ? v : [];
};
const isInt = (v: unknown): v is number => Number.isInteger(v);
const isStr = (v: unknown): v is string => typeof v === "string";
const byName = (a: { name: string }, b: { name: string }): number =>
  a.name < b.name ? -1 : Number(a.name > b.name);

export function isHttps(url: string): boolean {
  try {
    const u = new URL(url);
    return u.protocol === "https:" && u.hostname !== "";
  } catch {
    return false;
  }
}

/** "1,2,114" → [1, 2, 114] (only 1..114, no repeats, in order). */
export function parseSurahList(raw: unknown): number[] {
  if (!isStr(raw)) return [];
  const nums = raw
    .split(",")
    .map((p) => Number(p.trim()))
    .filter((n) => Number.isInteger(n) && n >= 1 && n <= LAST_SURAH);
  return [...new Set(nums)].sort((a, b) => a - b);
}

/** Address of one surah's recording ("001.mp3" … "114.mp3"). */
export const surahUrl = (m: Moshaf, surah: number): string =>
  `${m.server}${String(surah).padStart(FILE_DIGITS, "0")}.mp3`;

function parseMoshaf(m: unknown): Moshaf | null {
  if (!isObj(m) || !isInt(m.id) || !isStr(m.name) || !isStr(m.server) || !isHttps(m.server)) return null;
  const surahs = parseSurahList(m.surah_list);
  if (surahs.length === 0) return null;
  return {
    id: m.id,
    name: m.name.trim(),
    rewayaId: isInt(m.rewaya_id) ? m.rewaya_id : 0,
    server: m.server.endsWith("/") ? m.server : `${m.server}/`,
    surahs,
  };
}

/** Builds the library from the three API answers, dropping anything malformed or not https. */
export function parseLibrary(reciters: unknown, riwayat: unknown, radios: unknown): Library {
  const rs: Reciter[] = list(reciters, "reciters").flatMap((r) => {
    if (!isObj(r) || !isInt(r.id) || !isStr(r.name)) return [];
    const moshafs = (Array.isArray(r.moshaf) ? r.moshaf : [])
      .map(parseMoshaf)
      .filter((m): m is Moshaf => !!m);
    return moshafs.length > 0 ? [{ id: r.id, name: r.name.trim(), moshafs }] : [];
  });
  const rw: Rewaya[] = list(riwayat, "riwayat").flatMap((w) =>
    isObj(w) && isInt(w.id) && isStr(w.name) ? [{ id: w.id, name: w.name.trim() }] : [],
  );
  const rd: Radio[] = list(radios, "radios").flatMap((r) =>
    isObj(r) && isInt(r.id) && isStr(r.name) && isStr(r.url) && isHttps(r.url)
      ? [{ id: r.id, name: r.name.trim(), url: r.url }]
      : [],
  );
  return { reciters: rs.sort(byName), riwayat: rw, radios: rd.sort(byName) };
}

export function filterReciters(
  lib: Library,
  query: string,
  rewaya: number | null,
  normalize: (s: string) => string,
): Reciter[] {
  const q = normalize(query);
  return lib.reciters.filter(
    (r) =>
      (rewaya === null || r.moshafs.some((m) => m.rewayaId === rewaya)) &&
      (!q || normalize(r.name).includes(q)),
  );
}

export function filterRadios(lib: Library, query: string, normalize: (s: string) => string): Radio[] {
  const q = normalize(query);
  return lib.radios.filter((r) => !q || normalize(r.name).includes(q));
}

/** API language for the site's locale. */
export const apiLanguage = (locale: string): string => (locale === "ar" ? "ar" : "eng");

interface Cached {
  at: number;
  reciters: unknown;
  riwayat: unknown;
  radios: unknown;
}

async function get(path: string, lang: string): Promise<unknown> {
  const res = await fetch(`${MP3QURAN_API}/${path}?language=${lang}`);
  if (!res.ok) throw new Error(`${path}: ${res.status}`);
  return res.json();
}

/**
 * The library: the saved copy if it is fresh, else the API (saved for next time). When the network fails, a saved
 * copy of any age is used; with none it throws.
 */
export async function loadLibrary(
  lang: string,
  opts: { refresh?: boolean; now?: number } = {},
): Promise<Library> {
  const now = opts.now ?? Date.now();
  const cached = readJson<Cached | null>(CACHE_PREFIX + lang, null);
  const ok = isObj(cached) && typeof cached.at === "number";
  if (ok && !opts.refresh && now - cached.at < MAX_AGE_MS) {
    return parseLibrary(cached.reciters, cached.riwayat, cached.radios);
  }
  try {
    const [reciters, riwayat, radios] = await Promise.all([
      get("reciters", lang),
      get("riwayat", lang),
      get("radios", lang),
    ]);
    const lib = parseLibrary(reciters, riwayat, radios);
    if (lib.reciters.length === 0 && lib.radios.length === 0) throw new Error("empty answer");
    writeJson(CACHE_PREFIX + lang, { at: now, reciters, riwayat, radios } satisfies Cached);
    return lib;
  } catch (e) {
    if (ok) return parseLibrary(cached.reciters, cached.riwayat, cached.radios);
    throw e;
  }
}
