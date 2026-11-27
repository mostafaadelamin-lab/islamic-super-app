import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { LessonsView } from "@/components/LessonsView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "podcast.title") };
}

/** «بودكاست» (owner 2026-11-27): the checked religious podcasts, its own section; also a topic in «افهم دينك». */
export default async function PodcastPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "podcast.title")}</h1>
      <LessonsView locale={locale} fixedTopic="podcast" />
    </>
  );
}
