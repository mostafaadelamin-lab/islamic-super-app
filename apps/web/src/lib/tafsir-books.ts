/**
 * The tafsir books and the ayah studies (owner 2026-11-20). In the Mushaf al-Muyassar stays the default; the
 * reader can switch to al-Sa'di, Ibn Kathir, al-Tabari, al-Baghawi or al-Qurtubi, and open the i'rab, sarf,
 * balagha and fawa'id of the ayah from «الجدول في إعراب القرآن وصرفه وبيانه». Every text is shown exactly as
 * stored (built by tools/tafsir_books.py and tools/irab_build.py from published books); nothing here edits it.
 *
 * Files (scripts/prepare-content.mjs):
 *  - /data/tafsir/muyassar/<n>.json: string[] (one entry per ayah)
 *  - /data/tafsir/<book>/<n>.json:   [from, to, text, notes?][] (a section explains ayahs from..to together)
 *  - /data/tafsir/<book>/book.v1.dat: the whole book, gzipped JSON {surahs: sections[][]} (search)
 *  - /data/irab/jadwal/<n>.json:      [from, to, irab, sarf, balagha, fawaid][]
 */
import sizes from "@/generated/tafsir-books.json";
import { withBase } from "./base-path";
import { isValidAyah, SURAHS } from "./pages";
import { loadTafsirSurah } from "./tafsir";

export type TafsirBookId = "muyassar" | "saadi" | "ibn-kathir" | "tabari" | "baghawi" | "qurtubi";

export interface TafsirBook {
  readonly id: TafsirBookId;
  readonly nameAr: string;
  /** On the book chips. */
  readonly shortAr: string;
  readonly nameEn: string;
  readonly authorAr: string;
  readonly length: "short" | "medium" | "long";
}

export const TAFSIR_BOOKS: readonly TafsirBook[] = [
  { id: "muyassar", nameAr: "التفسير الميسر", shortAr: "الميسر", nameEn: "Al-Muyassar", authorAr: "نخبة من العلماء", length: "short" },
  { id: "saadi", nameAr: "تفسير السعدي", shortAr: "السعدي", nameEn: "Al-Sa'di", authorAr: "عبد الرحمن بن ناصر السعدي", length: "medium" },
  { id: "ibn-kathir", nameAr: "تفسير ابن كثير", shortAr: "ابن كثير", nameEn: "Ibn Kathir", authorAr: "ابن كثير", length: "long" },
  { id: "tabari", nameAr: "تفسير الطبري", shortAr: "الطبري", nameEn: "Al-Tabari", authorAr: "محمد بن جرير الطبري", length: "long" },
  { id: "baghawi", nameAr: "تفسير البغوي", shortAr: "البغوي", nameEn: "Al-Baghawi", authorAr: "الحسين بن مسعود البغوي", length: "long" },
  { id: "qurtubi", nameAr: "تفسير القرطبي", shortAr: "القرطبي", nameEn: "Al-Qurtubi", authorAr: "محمد بن أحمد القرطبي", length: "long" },
];

export const DEFAULT_TAFSIR: TafsirBookId = "muyassar";

export const IRAB_BOOK = { nameAr: "الجدول في إعراب القرآن وصرفه وبيانه", authorAr: "محمود صافي" } as const;

/** The parts of «الجدول», in the book's order (index into an i'rab section after from/to). */
export const IRAB_PARTS = ["irab", "sarf", "balagha", "fawaid"] as const;
export type IrabPart = (typeof IRAB_PARTS)[number];

const BYTES_PER_MB = 1_048_576;
/** The two bytes every gzip file starts with. */
const GZIP_ID1 = 31;
const GZIP_ID2 = 139;
/** Columns before the four parts in an i'rab section: from, to. */
const IRAB_FIRST_PART = 2;
const SEARCH_LIMIT = 200;
export const MIN_QUERY_LETTERS = 2;
const SNIPPET_BEFORE = 60;
const SNIPPET_AFTER = 80;

export function tafsirBook(id: string): TafsirBook | undefined {
  return TAFSIR_BOOKS.find((b) => b.id === id);
}

/** Size of the whole book file in MB (rounded up, at least 1). */
export function bookSizeMb(id: TafsirBookId): number {
  const b = (sizes as Record<string, { bytes: number }>)[id];
  return b ? Math.max(1, Math.ceil(b.bytes / BYTES_PER_MB)) : 0;
}

/** [from, to, text, notes?] */
export type Section = readonly [number, number, string, string?];
/** [from, to, irab, sarf, balagha, fawaid] */
export type IrabSection = readonly [number, number, string, string, string, string];

export interface SectionView {
  readonly from: number;
  readonly to: number;
  readonly text: string;
  readonly notes?: string;
}

/** Fetches a JSON file once per session; a failed load is forgotten so that "Retry" fetches again. */
function cachedJson<T>(cache: Map<string, Promise<T>>, url: string, check: (v: T) => void, fetchImpl: typeof fetch): Promise<T> {
  const hit = cache.get(url);
  if (hit) return hit;
  const p = (async (): Promise<T> => {
    try {
      const r = await fetchImpl(url);
      if (!r.ok) throw new Error(`${url}: ${r.status}`);
      const v = (await r.json()) as T;
      check(v);
      return v;
    } catch (e) {
      cache.delete(url);
      throw e;
    }
  })();
  cache.set(url, p);
  return p;
}

/** Every ayah of the surah belongs to exactly one section, in order. */
export function checkSections(secs: readonly (readonly [number, number, ...unknown[]])[], surah: number): void {
  const end = secs.reduce((next, s) => {
    if (s[0] !== next || s[1] < s[0]) throw new RangeError(`bad tafsir file ${surah}`);
    return s[1] + 1;
  }, 1);
  if (end !== SURAHS[surah - 1]!.ayahCount + 1) throw new RangeError(`tafsir file ${surah} does not match the Quran`);
}

const files = new Map<string, Promise<Section[]>>();

/** One surah of a book; al-Muyassar comes from its own files as one section per ayah. */
export async function loadBookSurah(id: TafsirBookId, surah: number, fetchImpl: typeof fetch = fetch): Promise<Section[]> {
  if (!isValidAyah(surah, 1)) throw new RangeError(`no surah ${surah}`);
  if (id === "muyassar") {
    const entries = await loadTafsirSurah(surah, fetchImpl);
    return entries.map((t, i): Section => [i + 1, i + 1, t]);
  }
  const url = withBase(`/data/tafsir/${id}/${surah}.json`);
  return cachedJson(files, url, (v: Section[]) => checkSections(v, surah), fetchImpl);
}

/** The section that explains ayah `a`. */
export function sectionFor<T extends readonly [number, number, ...unknown[]]>(secs: readonly T[], ayah: number): T {
  const s = secs.find((x) => x[0] <= ayah && ayah <= x[1]);
  if (!s) throw new RangeError(`no section for ayah ${ayah}`);
  return s;
}

export async function loadBookSection(
  id: TafsirBookId,
  surah: number,
  ayah: number,
  fetchImpl: typeof fetch = fetch,
): Promise<SectionView> {
  if (!isValidAyah(surah, ayah)) throw new RangeError(`no ayah ${surah}:${ayah}`);
  const [from, to, text, notes] = sectionFor(await loadBookSurah(id, surah, fetchImpl), ayah);
  return notes ? { from, to, text, notes } : { from, to, text };
}

const irabFiles = new Map<string, Promise<IrabSection[]>>();

export async function loadIrabSurah(surah: number, fetchImpl: typeof fetch = fetch): Promise<IrabSection[]> {
  if (!isValidAyah(surah, 1)) throw new RangeError(`no surah ${surah}`);
  const url = withBase(`/data/irab/jadwal/${surah}.json`);
  return cachedJson(irabFiles, url, (v: IrabSection[]) => checkSections(v, surah), fetchImpl);
}

export interface IrabView {
  readonly from: number;
  readonly to: number;
  readonly part: string;
}

export async function loadIrab(surah: number, ayah: number, part: IrabPart, fetchImpl: typeof fetch = fetch): Promise<IrabView> {
  if (!isValidAyah(surah, ayah)) throw new RangeError(`no ayah ${surah}:${ayah}`);
  const s = sectionFor(await loadIrabSurah(surah, fetchImpl), ayah);
  return { from: s[0], to: s[1], part: s[IRAB_FIRST_PART + IRAB_PARTS.indexOf(part)] as string };
}

// A Quran quote inside a book: «﴿» up to the next «﴾». Matches "﴿الْحَمْدُ لِلَّهِ﴾"; leaves "(الحمد لله)" alone.
// https://regex101.com/?regex=%EF%B4%BF%5B%5E%EF%B4%BE%5D*%EF%B4%BE&testString=%EF%B4%BF%D8%A7%D9%84%D8%AD%D9%85%D8%AF%EF%B4%BE
const QUOTE = /﴿[^﴾]*﴾/g;

/** Splits a text into plain runs and Quran quotes (﴿…﴾) so the quotes can be shown in the Quran colour. */
export function quoteRuns(text: string): { quote: boolean; text: string }[] {
  const out: { quote: boolean; text: string }[] = [];
  const last = [...text.matchAll(QUOTE)].reduce((at, m) => {
    if (m.index > at) out.push({ quote: false, text: text.slice(at, m.index) });
    out.push({ quote: true, text: m[0] });
    return m.index + m[0].length;
  }, 0);
  if (last < text.length) out.push({ quote: false, text: text.slice(last) });
  return out;
}

// ---- Search -------------------------------------------------------------------------------------------

// Tashkeel, Quranic marks and tatweel: removed before matching. Matches the fatha in "حَ"; leaves "ح".
// https://regex101.com/?regex=%5B%5Cu0610-%5Cu061a%5Cu064b-%5Cu065f%5Cu0670%5Cu06d6-%5Cu06ed%5Cu0640%5D&testString=%D8%AD%D9%8E
const MARKS = /[ؐ-ًؚ-ٰٟۖ-ۭـ]/g;
// Alef forms read as a plain alef: matches "أ" "إ" "آ" "ٱ"; leaves "ا".
// https://regex101.com/?regex=%5B%D8%A3%D8%A5%D8%A2%D9%B1%5D&testString=%D8%A3%D8%A7
const ALEFS = /[أإآٱ]/g;
// Whitespace of any kind (spaces, new lines): matches " " and "\n"; leaves "ا".
// https://regex101.com/?regex=%5Cs&testString=a%20b
const SPACE = /\s/;
// A run of whitespace, folded to one space in a query: matches "  " and " \n"; leaves "اب".
// https://regex101.com/?regex=%5Cs%2B&testString=a%20%20b
const SPACES = /\s+/g;
const LETTER_FORMS: Readonly<Record<string, string>> = { ى: "ي", ة: "ه", ؤ: "و", ئ: "ي" };

/** Letters only, for matching: no tashkeel or tatweel, alef/ya/ta-marbuta forms unified. */
export function normalizeArabic(s: string): string {
  return [...s.replace(MARKS, "").replace(ALEFS, "ا")].map((c) => LETTER_FORMS[c] ?? c).join("");
}

const books = new Map<TafsirBookId, Promise<Section[][]>>();

async function readMaybeGzip(r: Response): Promise<string> {
  const bytes = new Uint8Array(await r.arrayBuffer());
  // A server that already unpacked the file (Content-Encoding) hands over plain JSON.
  const zipped = bytes[0] === GZIP_ID1 && bytes[1] === GZIP_ID2;
  if (!zipped) return new TextDecoder().decode(bytes);
  return new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"))).text();
}

/** The whole book (for search), downloaded once per session and kept by the service worker. */
export function loadWholeBook(id: TafsirBookId, fetchImpl: typeof fetch = fetch): Promise<Section[][]> {
  const hit = books.get(id);
  if (hit) return hit;
  const url = withBase(`/data/tafsir/${id}/book.v1.dat`);
  const p = (async (): Promise<Section[][]> => {
    try {
      const r = await fetchImpl(url);
      if (!r.ok) throw new Error(`${url}: ${r.status}`);
      const book = JSON.parse(await readMaybeGzip(r)) as { surahs: Section[][] };
      if (book.surahs.length !== SURAHS.length) throw new Error(`${url}: not a whole book`);
      return book.surahs;
    } catch (e) {
      books.delete(id);
      throw e;
    }
  })();
  books.set(id, p);
  return p;
}

export interface SearchHit {
  readonly surah: number;
  readonly from: number;
  readonly to: number;
  /** text around the first match, verbatim */
  readonly before: string;
  readonly match: string;
  readonly after: string;
}

/** The text reduced to matching letters, with the index in the original text of every kept letter. */
function foldForSearch(text: string): { norm: string; map: number[] } {
  const kept = [...text]
    .map((ch, i) => ({ c: SPACE.test(ch) ? " " : normalizeArabic(ch), i }))
    .filter((x) => x.c !== "")
    .filter((x, k, all) => !(x.c === " " && k > 0 && all[k - 1]!.c === " "));
  return { norm: kept.map((x) => x.c).join(""), map: kept.map((x) => x.i) };
}

function hitIn(sec: Section, surah: number, q: string): SearchHit | null {
  const text = sec[2];
  const { norm, map } = foldForSearch(text);
  const at = norm.indexOf(q);
  if (at < 0) return null;
  const start = map[at]!;
  const end = map[at + q.length - 1]! + 1;
  const from = Math.max(0, text.lastIndexOf(" ", Math.max(0, start - SNIPPET_BEFORE)));
  const stop = text.indexOf(" ", Math.min(text.length, end + SNIPPET_AFTER));
  return {
    surah,
    from: sec[0],
    to: sec[1],
    before: (from > 0 ? "… " : "") + text.slice(from, start).trimStart(),
    match: text.slice(start, end),
    after: stop < 0 ? text.slice(end) : `${text.slice(end, stop)} …`,
  };
}

/** Finds `query` in every section of a book, ignoring tashkeel: at most `limit` hits, in Mushaf order. */
export function searchBook(surahs: readonly (readonly Section[])[], query: string, limit = SEARCH_LIMIT): SearchHit[] {
  const q = normalizeArabic(query.trim()).replace(SPACES, " ");
  if (q.length < MIN_QUERY_LETTERS) return [];
  const hits: SearchHit[] = [];
  surahs.some((secs, i) =>
    secs.some((sec) => {
      const h = hitIn(sec, i + 1, q);
      if (h) hits.push(h);
      return hits.length >= limit;
    }),
  );
  return hits;
}

export function resetTafsirBooksForTests(): void {
  files.clear();
  irabFiles.clear();
  books.clear();
}
