import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { isLocale } from "@/lib/i18n";
import { SURAHS, surahMeta } from "@/lib/pages";
import { surahAyahs } from "@/lib/server/content";
import { SurahReader } from "@/components/SurahReader";

export const dynamicParams = false;

type Params = Promise<{ locale: string; n: string }>;

export function generateStaticParams(): { n: string }[] {
  return SURAHS.map((s) => ({ n: String(s.n) }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { locale, n } = await params;
  const m = surahMeta(Number(n));
  if (!m) return {};
  return { title: locale === "en" ? `${m.translit} (${m.nameEn})` : `سورة ${m.nameAr}` };
}

export default async function SurahPage({ params }: { params: Params }) {
  const { locale, n } = await params;
  const num = Number(n);
  const meta = surahMeta(num);
  if (!isLocale(locale) || !meta || String(num) !== n) notFound();
  const basmala = num !== 1 && num !== 9 ? (surahAyahs(1)[0] as string) : null;
  return (
    <>
      <PreloadQuranFont />
      <SurahReader locale={locale} meta={meta} ayahs={surahAyahs(num)} basmala={basmala} />
    </>
  );
}
