import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { surahName } from "@/lib/pages";
import { KIDS } from "@/lib/kids";
import { surahAyahs } from "@/lib/server/content";
import { teacherAudio } from "@/lib/server/teacher";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { KidsMushaf } from "@/components/KidsMushaf";

export const dynamicParams = false;

type Params = Promise<{ locale: string; surah: string }>;

export function generateStaticParams(): { surah: string }[] {
  return KIDS.teacher.surahs.map((s) => ({ surah: String(s) }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { locale, surah } = await params;
  const loc = isLocale(locale) ? locale : "ar";
  return { title: `${t(loc, "kids.teacher")} · ${surahName(Number(surah), loc)}` };
}

/** «المصحف المعلّم» for one surah: the interactive kids' Mushaf (owner 2026-11-20). */
export default async function KidsTeacherSurahPage({ params }: { params: Params }) {
  const { locale, surah } = await params;
  const s = Number(surah);
  if (!isLocale(locale) || !KIDS.teacher.surahs.includes(s)) notFound();
  const { word, reciters } = teacherAudio(s);
  return (
    <>
      <PreloadQuranFont />
      <nav className="crumbs">
        <Link href={`${href(locale, "kids")}#teacher`}>{t(locale, "kids.teacher")}</Link>
      </nav>
      <KidsMushaf
        locale={locale}
        surah={s}
        ayahs={surahAyahs(s)}
        {...(s !== 1 && s !== 9 ? { basmala: surahAyahs(1)[0] } : {})}
        word={word}
        audio={reciters}
      />
    </>
  );
}
