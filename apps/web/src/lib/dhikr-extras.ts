/**
 * Per-dhikr recording URL and source hadith, for the adhkar and Hisn al-Muslim pages. Read on the server
 * and passed to the client per item, so the full maps are not shipped to the browser.
 * Data: adhkar-audio.json (tools/adhkar_audio.py) and adhkar-hadith.json (tools/adhkar_hadith.py).
 */
import audioJson from "@/generated/adhkar-audio.json";
import hadithJson from "@/generated/adhkar-hadith.json";

export interface DhikrHadith {
  hadith?: string;
  fadl?: string;
  source?: string;
}

export interface DhikrExtra {
  audio: string | null;
  hadith: DhikrHadith | null;
}

const audio = audioJson as { base: string; adhkar: Record<string, number>; hisn: Record<string, number> };
const hadith = hadithJson as { adhkar: Record<string, DhikrHadith>; hisn: Record<string, DhikrHadith> };

const url = (id: number | undefined): string | null =>
  id === undefined ? null : audio.base.replace("{id}", String(id));

/** Extras of the morning/evening adhkar, by adhkar.v1 index. */
export function adhkarExtras(count: number): DhikrExtra[] {
  return Array.from({ length: count }, (_, i) => ({
    audio: url(audio.adhkar[String(i)]),
    hadith: hadith.adhkar[String(i)] ?? null,
  }));
}

/** Extras of one Hisn chapter (chapterId is 1-based, as in the URL). */
export function hisnExtras(chapterId: number, count: number): DhikrExtra[] {
  return Array.from({ length: count }, (_, i) => ({
    audio: url(audio.hisn[`${chapterId - 1}:${i}`]),
    hadith: hadith.hisn[`${chapterId - 1}:${i}`] ?? null,
  }));
}
