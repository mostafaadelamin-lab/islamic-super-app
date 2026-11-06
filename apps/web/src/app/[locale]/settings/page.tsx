import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { surahAyahs } from "@/lib/server/content";
import { DisplaySettings } from "@/components/DisplaySettings";
import { AccountSync } from "@/components/AccountSync";
import { OfflineStatus } from "@/components/OfflineStatus";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "settings.title") };
}

export default async function SettingsPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "settings.title")}</h1>
      <DisplaySettings locale={locale} preview={surahAyahs(1)[1] as string} />
      <AccountSync locale={locale} />
      <OfflineStatus locale={locale} />
      <p>
        <Link className="btn" href={href(locale, "about")}>
          {t(locale, "settings.about")}
        </Link>
      </p>
    </>
  );
}
