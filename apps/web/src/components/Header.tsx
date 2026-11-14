import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { withBase } from "@/lib/base-path";
import { MainNav } from "./MainNav";
import { SiteNav } from "./SiteNav";
import { HeaderPrayer } from "./HeaderPrayer";
import { LanguageSwitch } from "./LanguageSwitch";
import { Icon } from "./Icon";

/**
 * Site header. Wide screens (website): a thin top bar (dates, next prayer, contact, language) and the main
 * bar with the logo, drop-down menus and search. Phones (app look): brand + language on top and the bottom
 * tab bar (MainNav); CSS shows one or the other.
 */
export function Header({ locale }: { locale: Locale }) {
  return (
    <header className="app-header">
      <div className="site-topbar">
        <div className="site-topbar-inner">
          <HeaderPrayer locale={locale} />
          <span className="topbar-links">
            <Link href={href(locale, "help")}>{t(locale, "help.contact")}</Link>
            <Link href={href(locale, "about")}>{t(locale, "nav.about")}</Link>
          </span>
        </div>
      </div>
      <div className="app-header-inner">
        <Link className="brand" href={href(locale)}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img className="brand-logo" src={withBase("/icon.svg")} alt="" width={40} height={40} />
          <span className="brand-text">
            <span className="brand-name">{t(locale, "appName")}</span>
            <span className="brand-tagline" aria-hidden="true">
              {t(locale, "site.tagline")}
            </span>
          </span>
        </Link>
        <SiteNav locale={locale} />
        <MainNav locale={locale} />
        <span className="header-actions">
          <Link
            className="header-icon-btn"
            href={href(locale, "search")}
            aria-label={t(locale, "nav.search")}
            title={t(locale, "nav.search")}
          >
            <Icon name="search" size={20} />
          </Link>
          <Link
            className="header-icon-btn"
            href={href(locale, "settings")}
            aria-label={t(locale, "settings.title")}
            title={t(locale, "settings.title")}
          >
            <Icon name="settings" size={20} />
          </Link>
          <LanguageSwitch locale={locale} />
        </span>
      </div>
    </header>
  );
}
