import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { isLocale, t } from "@/lib/i18n";
import { PAGES, isValidPage } from "@/lib/pages";
import { mushafPage } from "@/lib/server/content";
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

/** Madinah Mushaf page (15 lines), rendered at build time from the canonical text and the line layout. */
export default async function MushafRoute({ params }: { params: Params }) {
  const { locale, p } = await params;
  const page = Number(p);
  if (!isLocale(locale) || !isValidPage(page) || String(page) !== p) notFound();
  return (
    <>
      <PreloadQuranFont />
      <PageReader key={page} locale={locale} initial={mushafPage(page)} />
    </>
  );
}
