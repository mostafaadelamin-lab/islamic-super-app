import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { TafsirLibrary } from "@/components/TafsirLibrary";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "tafsirLib.title") };
}

export default async function TafsirLibraryPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "tafsirLib.title")}</h1>
      <TafsirLibrary locale={locale} />
    </>
  );
}
