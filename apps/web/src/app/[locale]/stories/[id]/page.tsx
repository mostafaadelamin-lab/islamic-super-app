import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { StoryView } from "@/components/StoryView";
import { isLocale } from "@/lib/i18n";
import { STORIES, storyById } from "@/lib/stories";
import { surahAyahs } from "@/lib/server/content";

export const dynamicParams = false;

type Params = Promise<{ locale: string; id: string }>;

export function generateStaticParams(): { id: string }[] {
  return STORIES.map((s) => ({ id: s.id }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { locale, id } = await params;
  const st = storyById(id);
  if (!st) return {};
  return { title: locale === "en" ? st.title.en : st.title.ar };
}

export default async function StoryPage({ params }: { params: Params }) {
  const { locale, id } = await params;
  const story = storyById(id);
  if (!isLocale(locale) || !story) notFound();
  const segments = story.segments.map(([surah, from, to]) => ({
    surah,
    from,
    to,
    ayahs: surahAyahs(surah).slice(from - 1, to),
  }));
  return (
    <>
      <PreloadQuranFont />
      <StoryView locale={locale} story={story} segments={segments} />
    </>
  );
}
