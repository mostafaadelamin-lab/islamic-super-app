import { surahAyahs } from "./content";
import type { RuqyahItem } from "@/lib/kids";
import type { RuqyahPassage } from "@/components/RuqyahView";

/** The ayah texts of the ruqyah's Quran passages (a whole surah other than al-Fatihah gets its basmala line). */
export function ruqyahPassages(items: RuqyahItem[]): RuqyahPassage[] {
  return items.flatMap((i) => {
    if (i.t !== "q") return [];
    const all = surahAyahs(i.s);
    const whole = i.from === 1 && i.to === all.length && i.s !== 1 && i.s !== 9;
    return [
      {
        s: i.s,
        from: i.from,
        to: i.to,
        ayahs: all.slice(i.from - 1, i.to),
        ...(whole ? { basmala: surahAyahs(1)[0] } : {}),
      },
    ];
  });
}
