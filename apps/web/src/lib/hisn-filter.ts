import { normalizeArabic } from "./search";

export interface ChapterTitle {
  id: number;
  title: string;
}

/** Chapters whose title matches the query (diacritic-insensitive Arabic); the client-side half of lib/hisn. */
export function filterHisn<T extends ChapterTitle>(query: string, list: readonly T[]): T[] {
  const q = normalizeArabic(query.trim());
  if (!q) return [...list];
  return list.filter((c) => normalizeArabic(c.title).includes(q));
}
