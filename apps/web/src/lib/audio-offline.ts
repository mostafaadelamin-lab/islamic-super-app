/**
 * Recitations saved for offline listening, one whole surah at a time, in the browser's Cache Storage
 * ("rattil-audio"). The list of saved surahs lives in a small store so the player can tell synchronously
 * whether it should look in the cache before streaming.
 *
 * If everyayah.com answers with CORS headers the saved file is played from a blob: URL; otherwise the
 * (opaque) copy is served to the <audio> element by the service worker, which looks in the same cache.
 */
import { createStore, type Store } from "./store";
import { audioUrl, BASMALA_REF, needsBasmala } from "./audio";
import { surahMeta } from "./pages";

export const AUDIO_CACHE = "rattil-audio";
const CONCURRENCY = 4;

export interface SavedSurah {
  folder: string;
  surah: number;
  /** Bytes stored (0 when the browser hides the size of opaque responses). */
  bytes: number;
}
export interface DownloadsState {
  saved: SavedSurah[];
}
export const DEFAULT_DOWNLOADS: DownloadsState = { saved: [] };

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

export function sanitizeDownloads(raw: unknown): DownloadsState {
  const list = isObj(raw) && Array.isArray(raw.saved) ? raw.saved : [];
  const saved = list.flatMap((r: unknown): SavedSurah[] =>
    isObj(r) &&
    typeof r.folder === "string" &&
    typeof r.surah === "number" &&
    surahMeta(r.surah) !== undefined
      ? [
          {
            folder: r.folder,
            surah: r.surah,
            bytes: typeof r.bytes === "number" && r.bytes > 0 ? r.bytes : 0,
          },
        ]
      : [],
  );
  return { saved };
}

export const downloadsStore = createStore<DownloadsState>(
  "rattil.audioDownloads",
  DEFAULT_DOWNLOADS,
  sanitizeDownloads,
);

export const isSaved = (s: DownloadsState, folder: string, surah: number): boolean =>
  s.saved.some((d) => d.folder === folder && d.surah === surah);

export const totalBytes = (s: DownloadsState): number => s.saved.reduce((a, d) => a + d.bytes, 0);

/** Every file a surah needs: its ayahs, plus the basmala (1:1) before every surah except 1 and 9. */
export function surahFiles(folder: string, surah: number): string[] {
  const count = surahMeta(surah)?.ayahCount ?? 0;
  const ayahs = Array.from({ length: count }, (_, i) => audioUrl(folder, surah, i + 1));
  return needsBasmala(surah, 1) ? [audioUrl(folder, BASMALA_REF[0], BASMALA_REF[1]), ...ayahs] : ayahs;
}

export const offlineSupported = (): boolean => typeof caches !== "undefined";

/** Fetches one file, readable (CORS) when the server allows it, opaque otherwise. */
async function fetchFile(url: string, signal?: AbortSignal): Promise<Response> {
  try {
    const res = await fetch(url, { mode: "cors", signal });
    if (!res.ok) throw new Error(`${url} ${res.status}`);
    return res;
  } catch (e) {
    if (signal?.aborted) throw e;
    return fetch(url, { mode: "no-cors", signal });
  }
}

async function sizeOf(res: Response): Promise<number> {
  if (res.type === "opaque") return 0;
  return (await res.clone().blob()).size;
}

/**
 * Saves a whole surah. `onProgress(done, total)` is called after each file. Files already in the cache are
 * not fetched again. Rejects (and records nothing) when a file fails or the download is aborted.
 */
export async function downloadSurah(
  folder: string,
  surah: number,
  onProgress?: (done: number, total: number) => void,
  signal?: AbortSignal,
): Promise<void> {
  const cache = await caches.open(AUDIO_CACHE);
  const files = surahFiles(folder, surah);
  const queue = [...files];
  const sizes: number[] = [];
  const worker = async (): Promise<void> => {
    const url = queue.shift();
    if (url === undefined) return;
    const have = await cache.match(url);
    const res = have ?? (await fetchFile(url, signal));
    const size = await sizeOf(res);
    if (!have) await cache.put(url, res);
    sizes.push(size);
    onProgress?.(sizes.length, files.length);
    await worker();
  };
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  const bytes = sizes.reduce((a, b) => a + b, 0);
  downloadsStore.set((s) => ({
    saved: [...s.saved.filter((d) => !(d.folder === folder && d.surah === surah)), { folder, surah, bytes }],
  }));
}

/** Deletes a saved surah. The shared basmala file stays while another saved surah of the reciter needs it. */
export async function deleteSurah(folder: string, surah: number): Promise<void> {
  const rest = downloadsStore.get().saved.filter((d) => !(d.folder === folder && d.surah === surah));
  const keep = new Set(rest.filter((d) => d.folder === folder).flatMap((d) => surahFiles(d.folder, d.surah)));
  if (offlineSupported()) {
    const cache = await caches.open(AUDIO_CACHE);
    await Promise.all(
      surahFiles(folder, surah)
        .filter((u) => !keep.has(u))
        .map((u) => cache.delete(u)),
    );
  }
  downloadsStore.set(() => ({ saved: rest }));
}

export async function deleteAll(): Promise<void> {
  if (offlineSupported()) await caches.delete(AUDIO_CACHE);
  downloadsStore.set(() => DEFAULT_DOWNLOADS);
}

/**
 * Where to play `url` from when it is saved: a blob: URL for a readable copy, or the URL itself for an
 * opaque copy (the service worker serves it). Null when it is not saved.
 */
export async function savedSource(url: string): Promise<string | null> {
  if (!offlineSupported()) return null;
  const hit = await (await caches.open(AUDIO_CACHE)).match(url);
  if (!hit) return null;
  if (hit.type === "opaque") return url;
  return URL.createObjectURL(await hit.blob());
}

/**
 * Single recordings (a story episode, a reciter's surah from the library) saved for offline listening: the file
 * goes into the same "rattil-audio" cache, which the service worker answers .mp3 requests from, so the normal
 * player plays the saved copy with no change. Each list keeps the saved URLs in its own small store.
 */
export const createSavedUrls = (key: string): Store<string[]> =>
  createStore<string[]>(key, [], (raw) =>
    Array.isArray(raw) ? raw.filter((v): v is string => typeof v === "string" && /^https?:\/\//.test(v)) : [],
  );

/** Episodes of the audio stories (the app saves them too). */
export const storySavedStore = createSavedUrls("rattil.storySaved");
/** Surahs of any reciter in the recitation library (the app saves them too). */
export const librarySavedStore = createSavedUrls("rattil.librarySaved");

export async function saveAudioFile(store: Store<string[]>, url: string): Promise<void> {
  const cache = await caches.open(AUDIO_CACHE);
  if (!(await cache.match(url))) await cache.put(url, await fetchFile(url));
  store.set((urls) => (urls.includes(url) ? urls : [...urls, url]));
}

export async function deleteAudioFile(store: Store<string[]>, url: string): Promise<void> {
  if (offlineSupported()) await (await caches.open(AUDIO_CACHE)).delete(url);
  store.set((urls) => urls.filter((u) => u !== url));
}
