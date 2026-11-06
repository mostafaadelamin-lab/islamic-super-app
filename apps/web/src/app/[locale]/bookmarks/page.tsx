import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { BookmarksView } from "@/components/BookmarksView";
import { ContinueReading } from "@/components/ContinueReading";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "bookmarks.title") };
}

export default async function BookmarksPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "bookmarks.title")}</h1>
      <ContinueReading locale={locale} />
      <BookmarksView locale={locale} />
    </>
  );
}
