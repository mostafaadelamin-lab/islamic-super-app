/**
 * Kids' learning corner, client side: types, small helpers and the child's progress in this browser
 * (same storage keys as the app). No content import here, so pages only ship what they show.
 */
import { readJson, writeJson } from "@/lib/storage";

export interface KidsBook {
  id: number;
  shelf: string;
  title: string;
  author: string;
  pages: number;
}
export interface HadithLevel {
  level: number;
  from: number;
  to: number;
  color: string;
}

export const bookPageUrl = (base: string, b: KidsBook, page: number): string => `${base}${b.id}/${page}.webp`;
export const levelCount = (l: HadithLevel): number => l.to - l.from + 1;

const MEMORIZED_KEY = "kidsHadithMemorized";

/** Hadith numbers the child marked «حفظته». */
export function readMemorized(): Set<number> {
  return new Set(readJson<number[]>(MEMORIZED_KEY, []));
}
export function writeMemorized(s: Set<number>): void {
  writeJson(
    MEMORIZED_KEY,
    [...s].sort((a, b) => a - b),
  );
}

/** One dhikr of the adhkar cards as text: m / e = repeat counts in the morning / evening (0 = not said then). */
export interface CardDhikr {
  n: number;
  card: number;
  text: string;
  note: string;
  m: number;
  e: number;
  surahs?: string[];
}

/** Today's key: counts are kept per day, so each morning and evening start fresh. */
export function todayKey(d = new Date()): string {
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}
const CARD_COUNTS_KEY = "kidsCardsCount";
export function readCardCounts(): Record<string, number> {
  const m = readJson<Record<string, Record<string, number>>>(CARD_COUNTS_KEY, {});
  return m[todayKey()] ?? {};
}
export function writeCardCounts(c: Record<string, number>): void {
  writeJson(CARD_COUNTS_KEY, { [todayKey()]: c });
}
