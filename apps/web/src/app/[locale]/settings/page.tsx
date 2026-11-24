import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { surahAyahs } from "@/lib/server/content";
import { APP_LINKS } from "@/lib/app-links";
import { DisplaySettings } from "@/components/DisplaySettings";
import { AccountSync } from "@/components/AccountSync";
import { OfflineStatus } from "@/components/OfflineStatus";
import { AudioSettings } from "@/components/AudioSettings";
import { AudioDownloads } from "@/components/AudioDownloads";
import { SetupSteps, TourReplayButton } from "@/components/FirstRunTour";
import { ShareAppButton } from "@/components/ShareApp";
import { Icon } from "@/components/Icon";

/**
 * The account / bookmark-sync card needs our own sync server, which is not online yet: hidden on the live site
 * (owner 2026-11-18: «هو ايه اللى بيحصل دا», it showed a developer address). Set NEXT_PUBLIC_ACCOUNT_SYNC=1 to show it.
 */
const SHOW_ACCOUNT_SYNC = process.env.NEXT_PUBLIC_ACCOUNT_SYNC === "1";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "settings.title") };
}

/**
 * Settings in the app's order (owner 2026-11-24): display, the permissions the site asks for (location and
 * notifications only), the reading / audio choices, then the site itself: tour, share, rate, contact, an idea,
 * help, about, privacy policy and our apps.
 */
export default async function SettingsPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const { playStore, appStore } = APP_LINKS;
  const help = href(locale, "help");
  const suggest = `${help}?title=${encodeURIComponent(t(locale, "about.suggestTitle"))}#contact`;
  return (
    <>
      <h1>{t(locale, "settings.title")}</h1>
      <DisplaySettings locale={locale} preview={surahAyahs(1)[1] as string} />
      <section className="card" aria-labelledby="perm-h" data-testid="settings-permissions">
        <h2 id="perm-h" style={{ marginTop: 0 }}>
          {t(locale, "about.permissions")}
        </h2>
        <SetupSteps locale={locale} />
      </section>
      <AudioSettings locale={locale} />
      <AudioDownloads locale={locale} />
      {SHOW_ACCOUNT_SYNC ? <AccountSync locale={locale} /> : null}
      <OfflineStatus locale={locale} />
      <TourReplayButton locale={locale} />
      <section className="card" aria-labelledby="site-h" data-testid="settings-site">
        <h2 id="site-h" style={{ marginTop: 0 }}>
          {t(locale, "about.siteSection")}
        </h2>
        <ul className="settings-links">
          <li>
            <ShareAppButton locale={locale} className="btn-link" />
          </li>
          {playStore ? (
            <li>
              <a href={playStore} data-testid="rate-play">
                <Icon name="star" /> {t(locale, "help.ratePlay")}
              </a>
            </li>
          ) : null}
          {appStore ? (
            <li>
              <a href={appStore} data-testid="rate-appstore">
                <Icon name="star" /> {t(locale, "help.rateAppStore")}
              </a>
            </li>
          ) : null}
          <li>
            <Link href={`${help}#contact`} data-testid="settings-contact">
              <Icon name="mail" /> {t(locale, "help.contact")}
            </Link>
          </li>
          <li>
            <Link href={suggest} data-testid="settings-suggest">
              <Icon name="bulb" /> {t(locale, "about.suggest")}
            </Link>
          </li>
          <li>
            <Link href={help}>
              <Icon name="help" /> {t(locale, "help.faq")}
            </Link>
          </li>
          <li>
            <Link href={href(locale, "about")} data-testid="settings-about">
              <Icon name="info" /> {t(locale, "settings.about")}
            </Link>
          </li>
          <li>
            <a href="/privacy-policy.html">
              <Icon name="shield" /> {t(locale, "about.privacyLink")}
            </a>
          </li>
          <li>
            <Icon name="list" /> {t(locale, "about.ourApps")}{" "}
            <span className="muted small">{t(locale, "about.ourAppsSoon")}</span>
          </li>
        </ul>
      </section>
    </>
  );
}
