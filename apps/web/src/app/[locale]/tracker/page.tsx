import type { Metadata } from "next";
import { t, isLocale } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { WorshipView } from "@/components/WorshipView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "worship.title") };
}

export default async function TrackerPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "worship.title")}</h1>
      <WorshipView locale={locale} />
    </>
  );
}
