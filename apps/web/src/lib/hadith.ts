/**
 * The nine hadith books (content/hadith/dist): eight are the sunnah.com copy (tools/build_hadith_sunnah.py;
 * Bukhari/Muslim owner 2026-11-26, the six Sunan/Muwatta/Darimi books 2026-11-27) with sunnah.com's numbers
 * in <book>/refs.json; Musnad Ahmad is Open-Hadith-Data (ODbL 1.0; tools/build_hadith.py). Text is shown exactly as in the source; parts of each book are fetched on demand
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
  /** true: entries carry sunnah.com numbers (refs.json); the entry index n is only the app's own position. */
  refs?: boolean;
  numbering?: string;
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
  /** Position of the entry in the book (1-based): the app's key for links, bookmarks and "#n". */
  n: number;
  text: string;
  /** sunnah.com number(s) of the entry, raw (e.g. "2186", "1218a", "5709,5710", "intro3", "~597b"). */
  ref?: string;
}

const refsCache = new Map<string, Promise<string[]>>();
export const refsUrl = (book: string): string => withBase(`/data/hadith/${book}/refs.json`);

/** sunnah.com numbers of every entry of a book with `refs` (empty list for the other books). */
export function loadRefs(book: HadithBook): Promise<string[]> {
  if (!book.refs) return Promise.resolve([]);
  let p = refsCache.get(book.id);
  if (!p) {
    p = fetch(refsUrl(book.id))
      .then((r) => {
        if (!r.ok) throw new Error(`${book.id} refs: ${r.status}`);
        return r.json() as Promise<{ refs: string[] }>;
      })
      .then((j) => j.refs);
    refsCache.set(book.id, p);
    p.catch(() => refsCache.delete(book.id));
  }
  return p;
}

async function withRefs(book: HadithBook, items: HadithItem[]): Promise<HadithItem[]> {
  if (!book.refs) return items;
  const refs = await loadRefs(book);
  return items.map((h) => ({ ...h, ref: refs[h.n - 1] ?? "" }));
}

/** sunnah.com letters after a number (a, b, c…) shown as Arabic abjad letters in Arabic. */
const ABJAD = "أبجدهوزحطيكلمنسعفصقرشتثخذضظغ";
function oneRef(r: string, locale: string, digits: (v: string) => string): string {
  const intro = /^intro(\d+)$/.exec(r);
  if (intro) return locale === "ar" ? `المقدمة ${digits(intro[1]!)}` : `Introduction ${intro[1]}`;
  const m = /^(\d+)([a-z]?)$/.exec(r);
  if (!m) return r;
  const letter = m[2] ? (locale === "ar" ? ` ${ABJAD[m[2].charCodeAt(0) - 97] ?? m[2]}` : m[2]) : "";
  return `${digits(m[1]!)}${letter}`;
}

/** A raw sunnah.com number for display: "1218a" → "١٢١٨ أ", "5709,5710" → "٥٧٠٩، ٥٧١٠", "~597b" → "بعد ٥٩٧ ب". */
export function refLabel(raw: string, locale: string, digits: (v: string) => string = (v) => v): string {
  if (!raw) return "";
  if (raw.startsWith("~")) {
    const inner = oneRef(raw.slice(1), locale, digits);
    return locale === "ar" ? `بعد ${inner}` : `after ${inner}`;
  }
  return raw
    .split(",")
    .map((r) => oneRef(r, locale, digits))
    .join(locale === "ar" ? "، " : ", ");
}

/**
 * The entry (1-based) that holds sunnah.com number `query` ("2186", "2186a", "١٢١٨"); null when none.
 * A number without a letter opens its first part (a).
 */
export function findRef(refs: readonly string[], query: string): number | null {
  const q = query
    .trim()
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x660))
    .toLowerCase()
    .replace(/\s+/g, "");
  const m = /^(\d+)([a-z]?)$/.exec(q);
  if (!m) return null;
  const wanted = (r: string): boolean => {
    const x = /^(\d+)([a-z]?)$/.exec(r);
    return !!x && x[1] === String(Number(m[1])) && (m[2] === "" || x[2] === m[2]);
  };
  const i = refs.findIndex((all) => !all.startsWith("~") && all.split(",").some(wanted));
  return i < 0 ? null : i + 1;
}

/** Hadiths `from`..`to` (inclusive, clamped to the book). */
export async function loadRange(book: HadithBook, from: number, to: number): Promise<HadithItem[]> {
  const a = Math.max(1, from);
  const b = Math.min(book.count, to);
  if (b < a) return [];
  const parts = Array.from({ length: chunkOf(b) - chunkOf(a) + 1 }, (_, i) => chunkOf(a) + i);
  const texts = await Promise.all(parts.map((k) => loadChunk(book.id, k)));
  const firstN = parts[0]! * HADITH.chunkSize + 1;
  return withRefs(
    book,
    texts
      .flat()
      .map((text, i) => ({ n: firstN + i, text }))
      .filter((h) => h.n >= a && h.n <= b),
  );
}

/** The hadiths numbered `ns` (any order; read from their parts). */
export async function loadItems(book: HadithBook, ns: readonly number[]): Promise<HadithItem[]> {
  const ok = ns.filter((n) => n >= 1 && n <= book.count);
  const texts = await Promise.all(ok.map((n) => loadChunk(book.id, chunkOf(n))));
  return withRefs(
    book,
    ok.map((n, i) => ({ n, text: texts[i]![(n - 1) % HADITH.chunkSize] ?? "" })),
  );
}

/**
 * Text for display: the source's own words, without the spaces around them. The sunnah.com copy keeps the
 * line breaks of the site's page source, which the site itself shows as spaces: shown the same way here.
 */
export const displayText = (text: string): string => text.replace(/[ \t]*\n\s*/g, " ").trim();

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
  return withRefs(book, hits);
}

export interface HadithFavourites {
  /** "book:n" keys, newest first. */
  keys: string[];
  /**
   * 2 = Bukhari/Muslim keys are positions in the sunnah.com copy (since 1.2.25). Older lists hold
   * al-Alamiyya numbers for those two books and are moved once by migrateHadithFavourites().
   */
  v?: 2;
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
  // An empty list has nothing to move: mark it as new so later keys are never moved by mistake.
  return isObj(raw) && raw.v === 2 ? { keys, v: 2 } : keys.length === 0 ? { keys, v: 2 } : { keys };
}

export const hadithFavStore = createStore<HadithFavourites>(
  "rattil.hadithFavourites",
  { keys: [], v: 2 },
  sanitizeFavourites,
);

/** Books whose numbers changed in 1.2.25 (al-Alamiyya → sunnah.com copy). */
const MOVED_BOOKS = ["bukhari", "muslim", "abudawud", "tirmidhi", "nasai", "ibnmajah", "malik", "darimi"] as const;

/**
 * Moves saved hadiths of the eight sunnah.com books from their old al-Alamiyya numbers to the same hadith in the
 * sunnah.com copy (table built by tools/build_hadith_sunnah.py). Runs once; safe to call again.
 */
export async function migrateHadithFavourites(): Promise<void> {
  const cur = hadithFavStore.get();
  if (cur.v === 2) return;
  const tables: Record<string, number[]> = {};
  for (const b of MOVED_BOOKS) {
    if (!cur.keys.some((k) => k.startsWith(`${b}:`))) continue;
    const r = await fetch(withBase(`/data/hadith/${b}/from-alamiyya.json`));
    if (!r.ok) return; // try again next time
    tables[b] = ((await r.json()) as { to: number[] }).to;
  }
  hadithFavStore.set((s) => ({
    v: 2,
    keys: s.keys.flatMap((k) => {
      const [b, n] = k.split(":");
      const table = tables[b!];
      if (!table) return [k];
      const to = table[Number(n) - 1];
      return to ? [`${b}:${to}`] : [];
    }),
  }));
}

export function toggleFavourite(book: string, n: number): void {
  const key = `${book}:${n}`;
  hadithFavStore.set((s) => ({
    ...s,
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
