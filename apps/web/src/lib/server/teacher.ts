import "server-only";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { TeacherAudio } from "@/lib/teacher";

interface TimingsFile {
  word: string;
  reciters: Record<string, { url: string; surahs: Record<string, TeacherAudio["ayahs"]> }>;
}

let cache: TimingsFile | null = null;
function timings(): TimingsFile {
  if (!cache) {
    const file = join(process.cwd(), "../../content/kids/dist/teacher-timings.v1.json");
    cache = JSON.parse(readFileSync(file, "utf8")) as TimingsFile;
  }
  return cache;
}

/** Where every ayah and word sits in each teaching recording of surah `s` (tools/kids_teacher_timings.py). */
export function teacherAudio(s: number): { word: string; reciters: Record<string, TeacherAudio> } {
  const t = timings();
  const reciters: Record<string, TeacherAudio> = {};
  for (const [folder, r] of Object.entries(t.reciters)) {
    const ayahs = r.surahs[String(s)];
    if (!ayahs) throw new RangeError(`teacher timings ${folder} ${s}`);
    reciters[folder] = { url: fillUrl(r.url, s), ayahs };
  }
  return { word: t.word, reciters };
}

function fillUrl(tmpl: string, s: number): string {
  return tmpl.replace("{sss}", String(s).padStart(3, "0")).replace("{s}", String(s));
}
