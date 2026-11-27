import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { withBase } from "@/lib/base-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "about.title") };
}

export default async function AboutPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "about.title")}</h1>
      <section className="card" aria-labelledby="free-h">
        <h2 id="free-h" style={{ marginTop: 0 }}>
          {t(locale, "about.freeTitle")}
        </h2>
        <p data-testid="free-statement">{t(locale, "about.freeBody")}</p>
        <p>{t(locale, "settings.free")}</p>
        <p>{t(locale, "about.privacy")}</p>
      </section>
      {/* Owner 2026-11-26: the sources and proof page (sources.html) is reachable from «حول التطبيق». */}
      <section className="card" aria-labelledby="proof-h">
        <h2 id="proof-h" style={{ marginTop: 0 }}>
          {t(locale, "about.proofTitle")}
        </h2>
        <p>{t(locale, "about.proofBody")}</p>
        <p>
          <a href={withBase("/sources.html#proof")} data-testid="about-proof-link">
            {t(locale, "about.proofLink")}
          </a>
        </p>
      </section>
    </>
  );
}
