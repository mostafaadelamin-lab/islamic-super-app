import type { Metadata } from "next";
import { t, isLocale } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { KhatmaView } from "@/components/KhatmaView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "khatma.title") };
}

export default async function KhatmaPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "khatma.title")}</h1>
      <KhatmaView locale={locale} />
    </>
  );
}
