import type { Metadata } from "next";
import { t, isLocale } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { PrayerView } from "@/components/PrayerView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "prayer.title") };
}

export default async function PrayerPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "prayer.title")}</h1>
      <PrayerView locale={locale} />
    </>
  );
}
