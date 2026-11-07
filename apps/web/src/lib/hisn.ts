import hisnJson from "@/generated/hisn.json";

/** Hisn al-Muslim (content/adhkar/hisn.json): [chapter title, items[]] in book order; ids are 1-based. */
export interface HisnChapter {
  id: number;
  title: string;
  items: string[];
}

export const HISN: readonly HisnChapter[] = (hisnJson as [string, string[]][]).map(([title, items], i) => ({
  id: i + 1,
  title,
  items,
}));

export function hisnChapter(id: number): HisnChapter | undefined {
  return HISN[id - 1];
}
