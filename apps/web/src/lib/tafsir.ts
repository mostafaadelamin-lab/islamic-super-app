/**
 * Tafsir al-Muyassar (King Fahd Glorious Quran Printing Complex), Arabic only.
 * scripts/prepare-content.mjs splits content/tafsir/dist/muyassar.v1.json into one file per surah
 * (/data/tafsir/muyassar/<surah>.json, an array with one entry per ayah). Files are fetched on demand and
 * kept by the service worker once used. The text is shown exactly as stored: nothing here edits it.
 */
import { withBase } from "./base-path";
import { isValidAyah, SURAHS, surahMeta, type Ref } from "./pages";

export const TAFSIR_ID = "muyassar";

export function tafsirUrl(surah: number): string {
  if (!isValidAyah(surah, 1)) throw new RangeError(`no surah ${surah}`);
  return withBase(`/data/tafsir/${TAFSIR_ID}/${surah}.json`);
}

/** The stored entry for ayah `a` of a surah file, verbatim. */
export function tafsirEntry(file: readonly string[], surah: number, ayah: number): string {
  if (!isValidAyah(surah, ayah)) throw new RangeError(`no ayah ${surah}:${ayah}`);
  const text = file[ayah - 1];
  if (typeof text !== "string" || file.length !== SURAHS[surah - 1]!.ayahCount) {
    throw new RangeError(`tafsir file for surah ${surah} does not match the Quran`);
  }
  return text;
}

/** The ayah before/after `s:a` in Mushaf order, across surah boundaries; null at 1:1 and 114:6. */
export function stepRef(s: number, a: number, delta: 1 | -1): Ref | null {
  if (!isValidAyah(s, a)) return null;
  if (isValidAyah(s, a + delta)) return [s, a + delta];
  if (delta === 1) return isValidAyah(s + 1, 1) ? [s + 1, 1] : null;
  const prev = surahMeta(s - 1);
  return prev ? [s - 1, prev.ayahCount] : null;
}

const files = new Map<number, Promise<string[]>>();

/** Loads one surah's file once per session; a failed load is forgotten so that "Retry" fetches again. */
export function loadTafsirSurah(surah: number, fetchImpl: typeof fetch = fetch): Promise<string[]> {
  const hit = files.get(surah);
  if (hit) return hit;
  const url = tafsirUrl(surah); // throws RangeError for an unknown surah, before anything is cached
  const p = (async () => {
    try {
      const r = await fetchImpl(url);
      if (!r.ok) throw new Error(`${url}: ${r.status}`);
      return (await r.json()) as string[];
    } catch (e) {
      files.delete(surah);
      throw e;
    }
  })();
  files.set(surah, p);
  return p;
}

export async function loadTafsir(
  surah: number,
  ayah: number,
  fetchImpl: typeof fetch = fetch,
): Promise<string> {
  return tafsirEntry(await loadTafsirSurah(surah, fetchImpl), surah, ayah);
}

export function resetTafsirForTests(): void {
  files.clear();
}
