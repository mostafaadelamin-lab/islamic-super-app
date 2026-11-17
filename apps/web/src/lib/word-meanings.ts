/**
 * Word meanings (غريب القرآن) from «السراج في بيان غريب القرآن» (Muhammad al-Khudairi), via the Quranpedia.net
 * data dump. scripts/prepare-content.mjs splits content/word-meanings/dist/siraj.v1.json into one file per surah
 * (/data/meanings/siraj/<surah>.json: one array per ayah of [word, meaning] pairs). Shown exactly as stored.
 */
import { withBase } from "./base-path";
import { isValidAyah, SURAHS, type Ref } from "./pages";

export type WordMeaning = readonly [word: string, meaning: string];
export type MeaningsFile = readonly (readonly WordMeaning[])[];

export function meaningsUrl(surah: number): string {
  if (!isValidAyah(surah, 1)) throw new RangeError(`no surah ${surah}`);
  return withBase(`/data/meanings/siraj/${surah}.json`);
}

/** The stored words of ayah `a` (empty when the book explains no word of it). */
export function meaningsEntry(file: MeaningsFile, surah: number, ayah: number): readonly WordMeaning[] {
  if (!isValidAyah(surah, ayah)) throw new RangeError(`no ayah ${surah}:${ayah}`);
  if (file.length !== SURAHS[surah - 1]!.ayahCount) {
    throw new RangeError(`meanings file for surah ${surah} does not match the Quran`);
  }
  return file[ayah - 1] ?? [];
}

const files = new Map<number, Promise<MeaningsFile>>();

/** Loads one surah's file once per session; a failed load is forgotten so that "Retry" fetches again. */
export function loadMeaningsSurah(surah: number, fetchImpl: typeof fetch = fetch): Promise<MeaningsFile> {
  const hit = files.get(surah);
  if (hit) return hit;
  const url = meaningsUrl(surah);
  const p = (async () => {
    try {
      const r = await fetchImpl(url);
      if (!r.ok) throw new Error(`${url}: ${r.status}`);
      return (await r.json()) as MeaningsFile;
    } catch (e) {
      files.delete(surah);
      throw e;
    }
  })();
  files.set(surah, p);
  return p;
}

/** The words of each ref, in order, skipping ayahs the book does not explain. */
export async function loadMeanings(
  refs: readonly Ref[],
  fetchImpl: typeof fetch = fetch,
): Promise<{ ref: Ref; words: readonly WordMeaning[] }[]> {
  const surahs = [...new Set(refs.map(([s]) => s))];
  const loaded = new Map(
    await Promise.all(surahs.map(async (s) => [s, await loadMeaningsSurah(s, fetchImpl)] as const)),
  );
  return refs
    .map(([s, a]) => ({ ref: [s, a] as Ref, words: meaningsEntry(loaded.get(s)!, s, a) }))
    .filter((x) => x.words.length > 0);
}

export function resetMeaningsForTests(): void {
  files.clear();
}
