/**
 * «عن السورة وأسباب النزول»: the app's surah card data (apps/mobile/assets/content/surah-info.v1.json, verbatim from
 * a published source). scripts/prepare-content.mjs writes one file per surah to /data/surah-info/<n>.json so the
 * Mushaf reader can open it like the app's info sheet.
 */
import { withBase } from "./base-path";
import { isValidAyah } from "./pages";

export interface SurahInfoData {
  n: number;
  type?: string;
  order?: string;
  intro?: string;
  purposes?: string;
  asbab?: string;
  wahidi?: { ayah: number; text: string }[];
}

export function surahInfoUrl(surah: number): string {
  if (!isValidAyah(surah, 1)) throw new RangeError(`no surah ${surah}`);
  return withBase(`/data/surah-info/${surah}.json`);
}

const files = new Map<number, Promise<SurahInfoData>>();

/** Loads one surah's card once per session; a failed load is forgotten so that "Retry" fetches again. */
export function loadSurahInfo(surah: number, fetchImpl: typeof fetch = fetch): Promise<SurahInfoData> {
  const hit = files.get(surah);
  if (hit) return hit;
  const url = surahInfoUrl(surah);
  const p = (async () => {
    try {
      const r = await fetchImpl(url);
      if (!r.ok) throw new Error(`${url}: ${r.status}`);
      const d = (await r.json()) as SurahInfoData;
      if (d.n !== surah) throw new Error(`${url}: wrong surah`);
      return d;
    } catch (e) {
      files.delete(surah);
      throw e;
    }
  })();
  files.set(surah, p);
  return p;
}
