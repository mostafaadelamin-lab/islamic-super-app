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

export function loadPrintedPage(page: number, fetchImpl: typeof fetch = fetch): Promise<PrintedPage | null> {
  const hit = ready.get(page);
  if (hit) return Promise.resolve(hit);
  let p = pending.get(page);
  if (!p) {
    p = (async () => {
      try {
        const r = await fetchImpl(withBase(`/data/printed/${page}.json`));
        if (!r.ok) return null;
        const { lines, basmala } = (await r.json()) as { lines: PrintedLine[]; basmala: string };
        const family = printedFamily(page);
        if (typeof FontFace !== "undefined" && typeof document !== "undefined") {
          const face = new FontFace(family, `url(${FONT_URL.replace("{page}", String(page))})`, {
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
