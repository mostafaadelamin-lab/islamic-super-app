/**
 * Recitation queue logic (pure; no DOM). Audio is streamed per ayah from everyayah.com using the URL
 * template in packages/shared-schemas/audio/reciters.json. Nothing is bundled or cached offline.
 */
import recitersJson from "@/generated/reciters.json";
import { createStore } from "./store";
import { ayahsOnPage, isValidAyah, pageForAyah, surahMeta } from "./pages";

export interface Reciter {
  folder: string;
  ar: string;
  en: string;
}
interface RecitersFile {
  urlTemplate: string;
  default: string;
  reciters: Reciter[];
}
const RECITERS_FILE = recitersJson as RecitersFile;
export const RECITERS: readonly Reciter[] = RECITERS_FILE.reciters;
export const DEFAULT_RECITER: string = RECITERS_FILE.default;
export const URL_TEMPLATE: string = RECITERS_FILE.urlTemplate;

/** The surahs that are not preceded by a recited basmala: al-Fatihah (its 1st ayah is the basmala), at-Tawbah. */
export const NO_BASMALA_BEFORE: readonly number[] = [1, 9];
/** The basmala recording: al-Fatihah 1:1. */
export const BASMALA_REF: readonly [number, number] = [1, 1];
export const REPEAT_CHOICES: readonly number[] = [1, 2, 3, 5, 10];

const PAD = 3;
const pad3 = (n: number): string => String(n).padStart(PAD, "0");

export function isReciter(folder: unknown): folder is string {
  return typeof folder === "string" && RECITERS.some((r) => r.folder === folder);
}

export function audioUrl(folder: string, s: number, a: number, template: string = URL_TEMPLATE): string {
  if (!isReciter(folder)) throw new RangeError(`unknown reciter ${folder}`);
  if (!isValidAyah(s, a)) throw new RangeError(`ayah ${s}:${a}`);
  return template.replace("{folder}", folder).replace("{sss}", pad3(s)).replace("{aaa}", pad3(a));
}

/** An entry of the play queue. A basmala entry belongs to surah `s` but plays the 1:1 recording. */
export interface QueueItem {
  kind: "ayah" | "basmala";
  s: number;
  a: number;
}

export function needsBasmala(s: number, a: number): boolean {
  return a === 1 && !NO_BASMALA_BEFORE.includes(s);
}

/** Expands ayah references into a queue, inserting the basmala before ayah 1 of every surah except 1 and 9. */
export function withBasmala(refs: readonly (readonly [number, number])[]): QueueItem[] {
  return refs.flatMap(([s, a]): QueueItem[] =>
    needsBasmala(s, a)
      ? [
          { kind: "basmala", s, a: 0 },
          { kind: "ayah", s, a },
        ]
      : [{ kind: "ayah", s, a }],
  );
}

function surahRefs(s: number, from: number): [number, number][] {
  const count = surahMeta(s)?.ayahCount ?? 0;
  return Array.from({ length: Math.max(0, count - from + 1) }, (_, i) => [s, from + i]);
}

export type PlayScope =
  | { kind: "page"; page: number }
  | { kind: "surah"; surah: number }
  | { kind: "from"; surah: number; ayah: number };

/**
 * Builds the queue for a scope: the ayahs of one Mushaf page; a whole surah; or from an ayah to the end of
 * its surah. Surah playback crosses page boundaries (the reader turns the page as it goes).
 */
export function buildQueue(scope: PlayScope): QueueItem[] {
  if (scope.kind === "page") return withBasmala(ayahsOnPage(scope.page));
  if (scope.kind === "surah") return withBasmala(surahRefs(scope.surah, 1));
  if (!isValidAyah(scope.surah, scope.ayah)) return [];
  return withBasmala(surahRefs(scope.surah, scope.ayah));
}

export function itemUrl(item: QueueItem, folder: string): string {
  return item.kind === "basmala"
    ? audioUrl(folder, BASMALA_REF[0], BASMALA_REF[1])
    : audioUrl(folder, item.s, item.a);
}

/** Mushaf page on which an item is shown (a basmala is shown on the page where its surah starts). */
export function itemPage(item: QueueItem): number {
  return pageForAyah(item.s, item.kind === "basmala" ? 1 : item.a);
}

export interface Cursor {
  index: number;
  /** How many times the current item has finished playing. */
  plays: number;
}

/**
 * What to play after the current item ends. Ayahs are repeated `repeat` times; the basmala is never
 * repeated. Returns null at the end of the queue.
 */
export function afterEnded(queue: readonly QueueItem[], cur: Cursor, repeat: number): Cursor | null {
  const item = queue[cur.index];
  if (!item) return null;
  const plays = cur.plays + 1;
  if (item.kind === "ayah" && plays < Math.max(1, repeat)) return { index: cur.index, plays };
  return cur.index + 1 < queue.length ? { index: cur.index + 1, plays: 0 } : null;
}

/** Index of the next (+1) or previous (-1) ayah, skipping basmala entries; null at either end. */
export function stepAyah(queue: readonly QueueItem[], index: number, delta: 1 | -1): number | null {
  const candidates = queue
    .map((q, i) => ({ q, i }))
    .filter(({ q, i }) => q.kind === "ayah" && (delta > 0 ? i > index : i < index));
  const pick = delta > 0 ? candidates[0] : candidates[candidates.length - 1];
  return pick ? pick.i : null;
}

export interface AudioPrefs {
  reciter: string;
  repeat: number;
  /** Turn the Mushaf page to follow the recitation. */
  follow: boolean;
}
export const DEFAULT_AUDIO: AudioPrefs = { reciter: DEFAULT_RECITER, repeat: 1, follow: true };

export function sanitizeAudio(raw: unknown): AudioPrefs {
  const r = typeof raw === "object" && raw !== null ? (raw as Record<string, unknown>) : {};
  return {
    reciter: isReciter(r.reciter) ? r.reciter : DEFAULT_RECITER,
    repeat: typeof r.repeat === "number" && REPEAT_CHOICES.includes(r.repeat) ? r.repeat : 1,
    follow: r.follow !== false,
  };
}

export const audioStore = createStore<AudioPrefs>("rattil.audio", DEFAULT_AUDIO, sanitizeAudio);
