import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
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
      {/* No "content sources" section (owner, 2026-11-15): kept in docs/CONTENT_SOURCES.md. The font
          licences still ship next to the fonts in /fonts/. */}
    </>
  );
}
