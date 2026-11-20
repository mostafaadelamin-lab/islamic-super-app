/**
 * The interactive «المصحف المعلّم» (owner 2026-11-20): the kids' Mushaf lights up the word the sheikh is reading,
 * plays one ayah (again and again) and says any word the child taps. Timings: content/kids/dist/teacher-timings.v1.json.
 */

/** One teaching recording of a surah: per ayah [start ms, end ms, [token index, start ms, end ms][]]. */
export interface TeacherAudio {
  url: string;
  ayahs: [number, number, [number, number, number][]][];
}

/** The ayah text split into its words (KFGQPC tokens) and the spaces between them, so joining gives the text back. */
export function ayahTokens(text: string): { words: string[]; gaps: string[] } {
  const parts = text.split(/(\s+)/);
  const words: string[] = [];
  const gaps: string[] = [];
  for (let i = 0; i < parts.length; i++) {
    if (i % 2 === 0) words.push(parts[i] ?? "");
    else gaps.push(parts[i] ?? "");
  }
  return { words, gaps };
}

/** Quran.com word-by-word audio of word `w` (1-based, Quran.com numbering) of ayah s:a. */
export function wordAudioUrl(tmpl: string, s: number, a: number, w: number): string {
  const p = (n: number) => String(n).padStart(3, "0");
  return tmpl.replace("{sss}", p(s)).replace("{aaa}", p(a)).replace("{www}", p(w));
}

/** Quran.com word number of KFGQPC token `k`: the rub el-hizb sign «۞» is its own token here, glued to the next word there. */
export function quranComWord(words: string[], k: number): number | null {
  if (words[k] === "۞") return null;
  let n = 0;
  for (let i = 0; i <= k; i++) if (words[i] !== "۞") n++;
  return n;
}

/** Which ayah (0-based) and which word token are being read at `ms` (word null between words). */
export function positionAt(audio: TeacherAudio, ms: number): { ayah: number; word: number | null } | null {
  const ay = audio.ayahs;
  for (let i = 0; i < ay.length; i++) {
    const [lo, hi, segs] = ay[i]!;
    if (ms >= lo && ms < hi) {
      const seg = segs.find(([, st, en]) => ms >= st && ms < en);
      return { ayah: i, word: seg ? seg[0] : null };
    }
  }
  return null;
}

const STARS_KEY = "kidsTeacherStars";

/** Stars a child earned per surah (one per full listen), kept on this device only. */
export function readStars(): Record<string, number> {
  try {
    const v = JSON.parse(localStorage.getItem(STARS_KEY) ?? "{}") as unknown;
    return v && typeof v === "object" ? (v as Record<string, number>) : {};
  } catch {
    return {};
  }
}

export function addStar(s: number): number {
  const all = readStars();
  const n = (all[String(s)] ?? 0) + 1;
  all[String(s)] = n;
  try {
    localStorage.setItem(STARS_KEY, JSON.stringify(all));
  } catch {
    /* private mode: the star still shows until the page closes */
  }
  return n;
}
