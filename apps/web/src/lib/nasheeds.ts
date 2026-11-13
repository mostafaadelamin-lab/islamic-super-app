/**
 * Nasheeds (voice-only, same list as the mobile app: apps/mobile/assets/content/nasheeds.v2.json → /data/nasheeds.json).
 * Audio is streamed per nasheed, or saved for offline listening (Cache Storage, served by the service worker).
 * Sources are recorded in docs/CONTENT_SOURCES.md and never shown on the site.
 */
import { AUDIO_CACHE, offlineSupported } from "./audio-offline";
import { withBase } from "./base-path";
import { createStore } from "./store";

export interface Nasheed {
  id: number;
  title: string;
  url: string;
  bytes: number | null;
}
export interface Munshid {
  id: number;
  name: string;
  items: Nasheed[];
}

export const NASHEEDS_URL = (): string => withBase("/data/nasheeds.json");

export function parseNasheeds(raw: unknown): Munshid[] {
  const j = raw as { singers?: unknown } | null;
  if (!j || !Array.isArray(j.singers)) throw new Error("nasheeds.json: bad format");
  return (j.singers as Record<string, unknown>[])
    .filter((s) => typeof s.id === "number" && typeof s.name === "string" && Array.isArray(s.items))
    .map((s) => ({
      id: s.id as number,
      name: s.name as string,
      items: (s.items as Record<string, unknown>[])
        .filter((i) => typeof i.id === "number" && typeof i.title === "string" && typeof i.url === "string")
        .filter((i) => (i.url as string).startsWith("https://"))
        .map((i) => ({
          id: i.id as number,
          title: i.title as string,
          url: i.url as string,
          bytes: typeof i.bytes === "number" ? i.bytes : null,
        })),
    }))
    .filter((s) => s.items.length > 0);
}

export async function loadNasheeds(fetchImpl: typeof fetch = fetch): Promise<Munshid[]> {
  const r = await fetchImpl(NASHEEDS_URL());
  if (!r.ok) throw new Error(`nasheeds.json: HTTP ${r.status}`);
  return parseNasheeds(await r.json());
}

export const normalizeArabic = (s: string): string =>
  s
    .toLowerCase()
    .replace(/[ً-ْـ]/g, "")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه");

export const nasheedsSavedStore = createStore<number[]>("rattil.nasheedsSaved", [], (raw) =>
  Array.isArray(raw) ? raw.filter((v): v is number => Number.isInteger(v) && v > 0) : [],
);

export async function saveNasheed(n: Nasheed): Promise<void> {
  const cache = await caches.open(AUDIO_CACHE);
  if (!(await cache.match(n.url))) {
    let res: Response;
    try {
      res = await fetch(n.url, { mode: "cors" });
      if (!res.ok) throw new Error(`${n.url} ${res.status}`);
    } catch {
      res = await fetch(n.url, { mode: "no-cors" });
    }
    await cache.put(n.url, res);
  }
  nasheedsSavedStore.set((ids) => (ids.includes(n.id) ? ids : [...ids, n.id]));
}

export async function deleteNasheed(n: Nasheed): Promise<void> {
  if (offlineSupported()) await (await caches.open(AUDIO_CACHE)).delete(n.url);
  nasheedsSavedStore.set((ids) => ids.filter((id) => id !== n.id));
}
