/**
 * The nine hadith books from Open-Hadith-Data (ODbL 1.0; content/hadith/dist, built by
 * tools/build_hadith.py). Text is shown exactly as in the source; parts of each book are fetched on demand
 * from /data/hadith/<book>/<k>.json and kept by the service worker once read.
 */
import booksJson from "@/generated/hadith-books.json";
import { withBase } from "./base-path";
import { normalizeArabic } from "./search";
import { createStore } from "./store";

export interface HadithBook {
  id: string;
  nameAr: string;
  nameEn: string;
  count: number;
  chunks: number;
  textSha256: string;
}
interface HadithMeta {
  reviewStatus: string;
  numbering: string;
  chunkSize: number;
  source: { name: string; url: string; commit: string; licence: string; origin: string };
  books: HadithBook[];
}
interface HadithChunk {
  book: string;
  from: number;
  ahadith: string[];
}

export const HADITH = booksJson as unknown as HadithMeta;
export const HADITH_BOOKS: readonly HadithBook[] = HADITH.books;
export const hadithBook = (id: string): HadithBook | undefined => HADITH_BOOKS.find((b) => b.id === id);
export const bookName = (b: HadithBook, locale: string): string => (locale === "ar" ? b.nameAr : b.nameEn);

/** Which part file holds hadith `n` (1-based). */
export const chunkOf = (n: number): number => Math.floor((n - 1) / HADITH.chunkSize);
export const chunkUrl = (book: string, k: number): string => withBase(`/data/hadith/${book}/${k}.json`);

const loaded = new Map<string, Promise<string[]>>();

/** The texts of one part of a book (cached in memory for the page's lifetime). */
export function loadChunk(book: string, k: number): Promise<string[]> {
  const key = `${book}/${k}`;
  const hit = loaded.get(key);
  if (hit) return hit;
  const p = fetch(chunkUrl(book, k))
    .then((r) => {
      if (!r.ok) throw new Error(`${key}: ${r.status}`);
      return r.json() as Promise<HadithChunk>;
    })
    .then((c) => c.ahadith);
  loaded.set(key, p);
  p.catch(() => loaded.delete(key));
  return p;
}

export interface HadithItem {
  n: number;
  text: string;
}

/** Hadiths `from`..`to` (inclusive, clamped to the book). */
export async function loadRange(book: HadithBook, from: number, to: number): Promise<HadithItem[]> {
  const a = Math.max(1, from);
  const b = Math.min(book.count, to);
  if (b < a) return [];
  const parts = Array.from({ length: chunkOf(b) - chunkOf(a) + 1 }, (_, i) => chunkOf(a) + i);
  const texts = await Promise.all(parts.map((k) => loadChunk(book.id, k)));
  const firstN = parts[0]! * HADITH.chunkSize + 1;
  return texts
    .flat()
    .map((text, i) => ({ n: firstN + i, text }))
    .filter((h) => h.n >= a && h.n <= b);
}

/** The hadiths numbered `ns` (any order; read from their parts). */
export async function loadItems(book: HadithBook, ns: readonly number[]): Promise<HadithItem[]> {
  const ok = ns.filter((n) => n >= 1 && n <= book.count);
  const texts = await Promise.all(ok.map((n) => loadChunk(book.id, chunkOf(n))));
  return ok.map((n, i) => ({ n, text: texts[i]![(n - 1) % HADITH.chunkSize] ?? "" }));
}

/** Text for display: the source's own words, without the spaces around them. */
export const displayText = (text: string): string => text.trim();

export const SEARCH_LIMIT = 200;

/**
 * Hadiths of `book` whose text contains every word of `query`, ignoring diacritics (shared search
 * normalisation). Loads the whole book part by part; `onProgress(done, total)` after each part.
 */
export async function searchBook(
  book: HadithBook,
  query: string,
  onProgress?: (done: number, total: number) => void,
): Promise<HadithItem[]> {
  const words = normalizeArabic(query).split(" ").filter(Boolean);
  if (words.length === 0) return [];
  const hits: HadithItem[] = [];
  for (let k = 0; k < book.chunks && hits.length < SEARCH_LIMIT; k++) {
    const texts = await loadChunk(book.id, k);
    texts.forEach((text, i) => {
      const norm = normalizeArabic(text);
      if (hits.length < SEARCH_LIMIT && words.every((w) => norm.includes(w))) {
        hits.push({ n: k * HADITH.chunkSize + i + 1, text });
      }
    });
    onProgress?.(k + 1, book.chunks);
  }
  return hits;
}

export interface HadithFavourites {
  /** "book:n" keys, newest first. */
  keys: string[];
}
const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;
/** "bukhari:1" → a known book and a number inside it. https://regex101.com/?regex=%5E(%5Ba-z%5D%2B)%3A(%5Cd%2B)%24&testString=bukhari%3A1 */
const KEY_RE = /^([a-z]+):(\d+)$/;

export function parseKey(key: string): { book: HadithBook; n: number } | null {
  const m = KEY_RE.exec(key);
  if (!m) return null;
  const book = hadithBook(m[1]!);
  const n = Number(m[2]);
  return book && n >= 1 && n <= book.count ? { book, n } : null;
}

export function sanitizeFavourites(raw: unknown): HadithFavourites {
  const list = isObj(raw) && Array.isArray(raw.keys) ? raw.keys : [];
  const keys = [...new Set(list.filter((k): k is string => typeof k === "string" && parseKey(k) !== null))];
  return { keys };
}

export const hadithFavStore = createStore<HadithFavourites>(
  "rattil.hadithFavourites",
  { keys: [] },
  sanitizeFavourites,
);

export function toggleFavourite(book: string, n: number): void {
  const key = `${book}:${n}`;
  hadithFavStore.set((s) => ({
    keys: s.keys.includes(key) ? s.keys.filter((k) => k !== key) : [key, ...s.keys],
  }));
}

/** A simplified explanation quoted from a published hadith encyclopedia (same data as the app). */
export interface HadithExplanation {
  title: string;
  explanation: string;
  grade?: string | null;
  attribution?: string | null;
  hints?: string[];
}
interface ExplainedBook {
  map: Record<string, string>;
  entries: Record<string, HadithExplanation>;
}
const explainedCache = new Map<string, Promise<ExplainedBook | null>>();

/** Loads one book's explanations once (null when the file cannot be fetched). */
export function loadExplained(book: string): Promise<ExplainedBook | null> {
  let p = explainedCache.get(book);
  if (!p) {
    p = fetch(withBase(`/data/hadith/explained/${book}.json`))
      .then((r) => (r.ok ? (r.json() as Promise<ExplainedBook>) : null))
      .catch(() => null);
    explainedCache.set(book, p);
    void p.then((v) => {
      if (v === null) explainedCache.delete(book); // try again next time (e.g. back online)
    });
  }
  return p;
}

export function explanationOf(data: ExplainedBook | null, n: number): HadithExplanation | null {
  const id = data?.map[String(n)];
  return (id && data?.entries[id]) || null;
}

/** Numbers of the hadiths in a book that have an explanation, in order. */
export function explainedNumbers(data: ExplainedBook | null): number[] {
  return Object.keys(data?.map ?? {})
    .map(Number)
    .filter((n) => Number.isInteger(n) && n > 0)
    .sort((a, b) => a - b);
}

/** Tests only. */
export function resetExplainedCache(): void {
  explainedCache.clear();
}
