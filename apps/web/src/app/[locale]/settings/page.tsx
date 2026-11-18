import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { surahAyahs } from "@/lib/server/content";
import { DisplaySettings } from "@/components/DisplaySettings";
import { AccountSync } from "@/components/AccountSync";
import { OfflineStatus } from "@/components/OfflineStatus";
import { AudioSettings } from "@/components/AudioSettings";
import { AudioDownloads } from "@/components/AudioDownloads";
import { TourReplayButton } from "@/components/FirstRunTour";

/**
 * The account / bookmark-sync card needs our own sync server, which is not online yet: hidden on the live site
 * (owner 2026-11-18: «هو ايه اللى بيحصل دا», it showed a developer address). Set NEXT_PUBLIC_ACCOUNT_SYNC=1 to show it.
 */
const SHOW_ACCOUNT_SYNC = process.env.NEXT_PUBLIC_ACCOUNT_SYNC === "1";

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
      <AudioSettings locale={locale} />
      <AudioDownloads locale={locale} />
      {SHOW_ACCOUNT_SYNC ? <AccountSync locale={locale} /> : null}
      <OfflineStatus locale={locale} />
      <TourReplayButton locale={locale} />
      <p>
        <Link className="btn" href={href(locale, "about")}>
          {t(locale, "settings.about")}
        </Link>
      </p>
    </>
  );
}
