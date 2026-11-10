/**
 * Display-only glyph mapping (packages/shared-schemas/quran-render.json).
 * Apply ONLY to strings handed to the text renderer — never to stored, searched, synced or hashed text.
 */
import renderJson from "@/generated/quran-render.json";
import { toArabicIndic } from "./digits";

export const RENDER_MAP: Readonly<Record<string, string>> = (renderJson as { map: Record<string, string> })
  .map;

export function renderQuranText(text: string, map: Readonly<Record<string, string>> = RENDER_MAP): string {
  let out = "";
  for (const ch of text) out += map[ch] ?? ch;
  return out;
}

/**
 * End-of-ayah mark for text drawn in the KFGQPC HAFS font: the font itself draws the Complex's ayah
 * ornament around Arabic-Indic digits (as in hafsData_v18), so no U+06DD is added.
 */
export function ayahEndMark(n: number): string {
  return toArabicIndic(n);
}
