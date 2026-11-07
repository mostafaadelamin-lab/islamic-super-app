/**
 * Client-side Mushaf data: the line layout (/data/mushaf-lines.json, ~370 KB) and the canonical Arabic text
 * (/data/quran-text.json, shared with search) are fetched once per session; the service worker keeps both
 * for offline use. Any page can then be rendered instantly while turning pages.
 */
import { withBase } from "./base-path";
import { lookupFrom, resolvePage, type MushafLinesFile, type ResolvedPage } from "./mushaf";

export interface MushafData {
  page(n: number): ResolvedPage | null;
  /** Canonical (unmodified) text of an ayah, e.g. for copying. */
  text(s: number, a: number): string;
}

let promise: Promise<MushafData> | null = null;

async function getJson<T>(url: string, fetchImpl: typeof fetch): Promise<T> {
  const r = await fetchImpl(url);
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return (await r.json()) as T;
}

async function fetchData(fetchImpl: typeof fetch): Promise<MushafData> {
  const [lines, text] = await Promise.all([
    getJson<MushafLinesFile>(withBase("/data/mushaf-lines.json"), fetchImpl),
    getJson<string[][]>(withBase("/data/quran-text.json"), fetchImpl),
  ]);
  const lookup = lookupFrom(text);
  const cache = new Map<number, ResolvedPage>();
  return {
    text: lookup,
    page(n) {
      const hit = cache.get(n);
      if (hit) return hit;
      const raw = lines.pages[n - 1];
      if (!raw) return null;
      const resolved = resolvePage(raw, lookup);
      cache.set(n, resolved);
      return resolved;
    },
  };
}

/** Loads once; a failed load is forgotten so the next call retries. */
export function loadMushafData(fetchImpl: typeof fetch = fetch): Promise<MushafData> {
  promise ??= (async () => {
    try {
      return await fetchData(fetchImpl);
    } catch (e) {
      promise = null;
      throw e;
    }
  })();
  return promise;
}

export function resetMushafDataForTests(): void {
  promise = null;
}
