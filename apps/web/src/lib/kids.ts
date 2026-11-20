/**
 * Kids section + ruqyah (owner 2026-11-20). Data: content/kids/dist/kids.v1.json (tools/kids_build.py). Quran
 * passages are references (the text comes from the KFGQPC Quran text); dua texts were copied by the build tool
 * from Hisn al-Muslim / HadeethEnc. Sources: docs/CONTENT_SOURCES.md (never shown on the site).
 */
import kidsJson from "@/generated/kids.json";

export type RuqyahItem =
  | { t: "q"; s: number; from: number; to: number }
  | { t: "d"; text: string; src: string; repeat: number; audio?: string };
export interface KidsEpisode {
  id: string;
  title: string;
  url: string;
  bytes?: number;
  seconds?: number;
}
export interface KidsSeries {
  id: string;
  group: string;
  episodes: KidsEpisode[];
}
interface KidsFile {
  ruqyah: { items: RuqyahItem[]; full?: KidsEpisode & { url: string } };
  ruqyahKids: { items: RuqyahItem[] };
  teacher: { reciters: string[]; surahs: number[] };
  series: KidsSeries[];
}

export const KIDS = kidsJson as unknown as KidsFile;

export const kidsSeries = (id: string): KidsSeries | undefined => KIDS.series.find((s) => s.id === id);
