/**
 * 15-line Madinah Mushaf layout (content/quran/dist/mushaf-lines.v1.json).
 *
 * A text line is a list of word ranges [surah, ayah, w0, w1, end] into the canonical ayah text of
 * quran.v1.json (words = the ayah split on single spaces). Rendering only joins canonical words with
 * single spaces and then applies the display glyph map (renderQuranText) to the resulting string; no other
 * transformation is ever made to Quran text.
 */
import { renderQuranText } from "./quran-render";
import { PAGE_COUNT } from "./pages";

export type WordRange = [s: number, a: number, w0: number, w1: number, end: 0 | 1];
export type RawLine = { k: "sura"; s: number } | { k: "basmala"; s: number } | { k: "text"; g: WordRange[] };
export interface RawPage {
  page: number;
  lines: RawLine[];
}
export interface MushafLinesFile {
  schema: string;
  pages: RawPage[];
}

/** One ayah fragment on a line: the display string and whether the ayah ends here. */
export interface Segment {
  s: number;
  a: number;
  text: string;
  end: boolean;
}
export type Line =
  | { kind: "sura"; s: number }
  | { kind: "basmala"; s: number; text: string }
  | { kind: "text"; segments: Segment[] };
export interface ResolvedPage {
  page: number;
  lines: Line[];
}

/** Returns the canonical text of ayah s:a. */
export type TextLookup = (s: number, a: number) => string;

export function lookupFrom(surahs: readonly (readonly string[])[]): TextLookup {
  return (s, a) => {
    const t = surahs[s - 1]?.[a - 1];
    if (t === undefined) throw new RangeError(`ayah ${s}:${a}`);
    return t;
  };
}

/** The canonical words w0..w1-1 of an ayah, joined by single spaces (before the display map). */
export function canonicalWords(text: string, w0: number, w1: number): string {
  const words = text.split(" ");
  if (!(Number.isInteger(w0) && Number.isInteger(w1) && w0 >= 0 && w1 > w0 && w1 <= words.length)) {
    throw new RangeError(`word range ${w0}..${w1} outside ${words.length} words`);
  }
  return words.slice(w0, w1).join(" ");
}

export function resolveLine(line: RawLine, lookup: TextLookup): Line {
  if (line.k === "sura") return { kind: "sura", s: line.s };
  // The basmala line shows the canonical text of 1:1 (al-Fatihah's first ayah is the basmala).
  if (line.k === "basmala") return { kind: "basmala", s: line.s, text: renderQuranText(lookup(1, 1)) };
  return {
    kind: "text",
    segments: line.g.map(([s, a, w0, w1, end]) => ({
      s,
      a,
      text: renderQuranText(canonicalWords(lookup(s, a), w0, w1)),
      end: end === 1,
    })),
  };
}

export function resolvePage(raw: RawPage, lookup: TextLookup): ResolvedPage {
  return { page: raw.page, lines: raw.lines.map((l) => resolveLine(l, lookup)) };
}

/** Pages 1 and 2 (al-Fatihah, start of al-Baqarah) have 8 centred lines; all others 15 justified lines. */
export const CENTRED_PAGES = 2;
export function isCentredPage(page: number): boolean {
  return page <= CENTRED_PAGES;
}

/** Distinct ayahs on a resolved page, in reading order. */
export function pageAyahRefs(p: ResolvedPage): [number, number][] {
  const refs = p.lines.flatMap((l) => (l.kind === "text" ? l.segments.map((g) => `${g.s}:${g.a}`) : []));
  return [...new Set(refs)].map((k) => k.split(":").map(Number) as [number, number]);
}

/** Surahs that have text on the page (for the header). */
export function pageSurahs(p: ResolvedPage): number[] {
  return [...new Set(pageAyahRefs(p).map(([s]) => s))];
}

/**
 * Page reached by a horizontal swipe of `dx` pixels on a page `width` wide.
 * In a right-to-left book (Arabic UI), dragging the page to the right turns forward, like a printed Mushaf.
 * Returns null when the drag is too short (and not fast enough) or would leave 1..604.
 */
/** Swipe tuning: fraction of the page width, minimum distance (px), fling speed (px/ms) and its distance. */
export const SWIPE = { fraction: 0.18, minPx: 40, flingSpeed: 0.5, flingPx: 24 } as const;

export function swipeTarget(
  dx: number,
  width: number,
  page: number,
  dir: "rtl" | "ltr",
  velocity = 0,
): number | null {
  const far = Math.abs(dx) >= Math.max(SWIPE.minPx, width * SWIPE.fraction);
  const fast = Math.abs(velocity) > SWIPE.flingSpeed && Math.abs(dx) > SWIPE.flingPx;
  if (!far && !fast) return null;
  const forward = dir === "rtl" ? dx > 0 : dx < 0;
  const target = page + (forward ? 1 : -1);
  return target >= 1 && target <= PAGE_COUNT ? target : null;
}

/** Clamps a slider value to a page number. */
export function clampPage(v: number): number {
  if (!Number.isFinite(v)) return 1;
  return Math.min(PAGE_COUNT, Math.max(1, Math.round(v)));
}

/**
 * Font size (px) that makes the widest line of a page exactly fill `available` pixels, given each line's
 * natural width measured at `probe` px. Bounded so a page with few short lines does not blow up.
 */
export const FIT_FONT = { min: 8, max: 64 } as const;

export function fitFontSize(
  naturalWidths: number[],
  probe: number,
  available: number,
  max: number = FIT_FONT.max,
): number {
  const widest = Math.max(0, ...naturalWidths);
  if (widest <= 0 || available <= 0) return probe;
  return Math.max(FIT_FONT.min, Math.min(max, (probe * available) / widest));
}
