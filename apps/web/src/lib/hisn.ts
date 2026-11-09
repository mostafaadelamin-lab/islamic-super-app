import hisnJson from "@/generated/hisn.json";
import sectionsJson from "@/generated/hisn-sections.json";

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

/** Browsing sections: groups of chapter ids (content/adhkar/hisn-sections.json); labels are hisn.section.<id>. */
export interface HisnSection {
  id: string;
  chapters: number[];
}
export const HISN_SECTIONS: readonly HisnSection[] = (sectionsJson as { sections: HisnSection[] }).sections;
