import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { isLocale, t } from "@/lib/i18n";
import { ayahsOnPage, juzForPage, PAGES, isValidPage } from "@/lib/pages";
import { ayahText, surahAyahs } from "@/lib/server/content";
import { PageReader } from "@/components/PageReader";

export const dynamicParams = false;

type Params = Promise<{ locale: string; p: string }>;

export function generateStaticParams(): { p: string }[] {
  return PAGES.map((x) => ({ p: String(x.page) }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { locale, p } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "quran.page", { page: p }) };
}

export default async function MushafPage({ params }: { params: Params }) {
  const { locale, p } = await params;
  const page = Number(p);
  if (!isLocale(locale) || !isValidPage(page) || String(page) !== p) notFound();
  const ayahs = ayahsOnPage(page).map(([s, a]) => ({ s, a, text: ayahText(s, a) }));
  return (
    <>
      <PreloadQuranFont />
      <PageReader
        locale={locale}
        page={page}
        juz={juzForPage(page)}
        ayahs={ayahs}
        basmala={surahAyahs(1)[0] as string}
      />
    </>
  );
}
