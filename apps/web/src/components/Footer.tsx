import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { BrandLogo } from "./BrandLogo";
import { SITE_GROUPS, itemHref, sectionOf } from "@/lib/site-map";

/** Website footer: about column + a site map column per menu group, then a bottom bar. */
export function Footer({ locale }: { locale: Locale }) {
  return (
    <footer className="app-footer">
      <div className="site-footer-inner">
        <div className="site-footer-about">
          <Link className="site-footer-brand" href={href(locale)}>
            <BrandLogo size={44} />
            <strong>{t(locale, "appName")}</strong>
          </Link>
          <p>{t(locale, "settings.free")}</p>
          <p className="site-footer-links">
            <Link href={href(locale, "about")}>{t(locale, "nav.about")}</Link>
            <Link href={href(locale, "page/1")}>{t(locale, "quran.pages")}</Link>
            <Link href={href(locale, "help")}>{t(locale, "help.contact")}</Link>
            <a href="/privacy-policy.html">{t(locale, "help.privacy")}</a>
          </p>
        </div>
        {SITE_GROUPS.slice(0, 4).map((g) => (
          <nav className="site-footer-col" key={g.title} aria-label={t(locale, g.title)}>
            <h2>{t(locale, g.title)}</h2>
            <ul>
              {g.items.map((p) => (
                <li key={p}>
                  <Link href={itemHref(locale, p)}>{t(locale, sectionOf(p).title)}</Link>
                </li>
              ))}
            </ul>
          </nav>
        ))}
      </div>
      <div className="site-footer-bottom">
        <span>
          © {new Date().getFullYear()} {t(locale, "appName")} · rattilwasalli.com
        </span>
        <span>{t(locale, "site.noAds")}</span>
      </div>
    </footer>
  );
}
