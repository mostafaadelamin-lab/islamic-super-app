/**
 * «شكل المصحف المطبوع» (owner 2026-11-20): a Mushaf page drawn with the King Fahd Complex's own font for that
 * page (QCF v2), line by line like the printed Madinah Mushaf. /data/printed/{page}.json (built from
 * content/quran/dist/mushaf-printed.v1.json by scripts/prepare-content.mjs) holds only the fonts' drawing codes
 * with the ayah of every word; the Quran text is not stored there and never changed.
 */
import { useEffect, useState } from "react";
import { withBase } from "./base-path";

/** ["S", surah] title band, ["B", surah] basmala, or the words [surah, ayah, glyph, end] of a text line. */
export type PrintedLine = ["S", number] | ["B", number] | [number, number, string, number][];
export interface PrintedPage {
  page: number;
  family: string;
  lines: PrintedLine[];
  /** Canonical text of 1:1, drawn on basmala lines in the standard Quran font. */
  basmala: string;
}

const FONT_URL = "https://static.qurancdn.com/fonts/quran/hafs/v2/woff2/p{page}.woff2";
export const printedFamily = (page: number): string => `QCF2P${page}`;

const ready = new Map<number, PrintedPage>();
const pending = new Map<number, Promise<PrintedPage | null>>();

/** The page when its layout and font are already loaded, else null. */
export function printedIfReady(page: number): PrintedPage | null {
  return ready.get(page) ?? null;
}

/**
 * Owner 2026-11-26: the Madina font can be saved once for the whole Mushaf and read without internet. Saved
 * pages (layout + font) live in Cache Storage; a page found there is never downloaded again. The cache name
 * does not start with "rattil-", so the service worker's clean-up on a new website version leaves it alone.
 * Bump the name only if the printed layout files ever change.
 */
export const PRINTED_CACHE = "mushaf-printed-v2";
export const PRINTED_PAGES = 604;
const layoutUrl = (page: number): string => withBase(`/data/printed/${page}.json`);
const fontUrl = (page: number): string => FONT_URL.replace("{page}", String(page));
export const printedOfflineSupported = (): boolean => typeof caches !== "undefined";

async function fromCache(url: string): Promise<Response | null> {
  if (!printedOfflineSupported()) return null;
  try {
    return (await (await caches.open(PRINTED_CACHE)).match(url)) ?? null;
  } catch {
    return null;
  }
}

/** How many pages (layout and font both) are saved in the browser. */
export async function printedSavedCount(): Promise<number> {
  if (!printedOfflineSupported()) return 0;
  try {
    const keys = new Set((await (await caches.open(PRINTED_CACHE)).keys()).map((r) => r.url));
    const abs = (u: string): string => new URL(u, location.href).href;
    let n = 0;
    for (let p = 1; p <= PRINTED_PAGES; p++) if (keys.has(abs(layoutUrl(p))) && keys.has(abs(fontUrl(p)))) n++;
    return n;
  } catch {
    return 0;
  }
}

/**
 * Saves the Madina font (and page layout) of every page, four at a time. Pages already saved are skipped,
 * so calling it again after a cut connection carries on where it stopped. Resolves true when all are saved.
 */
export async function downloadAllPrinted(
  onProgress: (done: number) => void,
  signal?: AbortSignal,
  fetchImpl: typeof fetch = fetch,
): Promise<boolean> {
  if (!printedOfflineSupported()) return false;
  const cache = await caches.open(PRINTED_CACHE);
  let next = 1;
  let done = 0;
  let failed = false;
  const save = async (url: string): Promise<void> => {
    if (await cache.match(url)) return;
    const r = await fetchImpl(url, { mode: "cors", signal });
    if (!r.ok) throw new Error(`${url} ${r.status}`);
    await cache.put(url, r);
  };
  const worker = async (): Promise<void> => {
    while (!failed && next <= PRINTED_PAGES) {
      const p = next++;
      try {
        await save(layoutUrl(p));
        await save(fontUrl(p));
      } catch {
        failed = true;
        return;
      }
      onProgress(++done);
    }
  };
  await Promise.all([worker(), worker(), worker(), worker()]);
  return !failed;
}

export function loadPrintedPage(page: number, fetchImpl: typeof fetch = fetch): Promise<PrintedPage | null> {
  const hit = ready.get(page);
  if (hit) return Promise.resolve(hit);
  let p = pending.get(page);
  if (!p) {
    p = (async () => {
      try {
        const r = (await fromCache(layoutUrl(page))) ?? (await fetchImpl(layoutUrl(page)));
        if (!r.ok) return null;
        const { lines, basmala } = (await r.json()) as { lines: PrintedLine[]; basmala: string };
        const family = printedFamily(page);
        if (typeof FontFace !== "undefined" && typeof document !== "undefined") {
          const saved = await fromCache(fontUrl(page));
          const face = new FontFace(family, saved ? await saved.arrayBuffer() : `url(${fontUrl(page)})`, {
            display: "block",
          });
          await face.load();
          document.fonts.add(face);
        }
        const out = { page, family, lines, basmala };
        ready.set(page, out);
        return out;
      } catch {
        return null;
      } finally {
        pending.delete(page);
      }
    })();
    pending.set(page, p);
  }
  return p;
}

/** The printed page when [enabled], loading it (and the next and previous pages) on demand. */
export function usePrintedPage(page: number, enabled: boolean): PrintedPage | null {
  const [, bump] = useState(0);
  useEffect(() => {
    if (!enabled) return;
    let alive = true;
    void loadPrintedPage(page).then((p) => {
      if (alive && p) bump((n) => n + 1);
      // warm the neighbours for page turns
      if (page < 604) void loadPrintedPage(page + 1);
      if (page > 1) void loadPrintedPage(page - 1);
    });
    return () => {
      alive = false;
    };
  }, [page, enabled]);
  return enabled ? printedIfReady(page) : null;
}
