import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { SectionTiles } from "@/components/SectionTiles";
import { InstallApp } from "@/components/InstallApp";
import { Icon } from "@/components/Icon";
import { SITE_GROUPS } from "@/lib/site-map";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "nav.more") };
}

export default async function MorePage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "more.title")}</h1>
      <div className="mobile-only">
        <SectionTiles locale={locale} />
      </div>
      {/* Wide screens: the same sections, grouped like the site menus (a site map). */}
      <div className="desktop-only more-groups">
        {SITE_GROUPS.map((g) => (
          <section key={g.title} aria-labelledby={`more-${g.path}`}>
            <h2 id={`more-${g.path}`} className="site-section-title">
              <Icon name={g.icon} size={24} />
              {t(locale, g.title)}
            </h2>
            <SectionTiles locale={locale} paths={g.items} testId={`more-group-${g.path}`} />
          </section>
        ))}
      </div>
      <InstallApp locale={locale} />
    </>
  );
}
