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
const CARDS_KEY = "kidsCardsDone";

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

/** Today's key: cards said today are stored per day, so the stars start fresh each morning. */
export function todayKey(d = new Date()): string {
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}
export function readCardsToday(): Set<number> {
  const m = readJson<Record<string, number[]>>(CARDS_KEY, {});
  return new Set(m[todayKey()] ?? []);
}
export function writeCardsToday(s: Set<number>): void {
  writeJson(CARDS_KEY, { [todayKey()]: [...s] });
}
