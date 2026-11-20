import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { DhikrRemindersView } from "@/components/DhikrReminders";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "dhikrRem.title") };
}

/** «تنبيهات الأذكار» (owner 2026-11-20). */
export default async function DhikrRemindersPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "dhikrRem.title")}</h1>
      <DhikrRemindersView locale={locale} />
    </>
  );
}
