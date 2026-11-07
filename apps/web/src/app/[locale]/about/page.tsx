import type { Metadata } from "next";
import info from "@/generated/quran-info.json";
import pages from "@/generated/pages.json";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { withBase } from "@/lib/base-path";

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
      <section className="card" aria-labelledby="sources-h">
        <h2 id="sources-h" style={{ marginTop: 0 }}>
          {t(locale, "settings.sources")}
        </h2>
        <dl>
          <dt>
            <strong>{t(locale, "about.quranText")}</strong>
          </dt>
          <dd dir="ltr" lang="en">
            {info.source.text}
          </dd>
          <dt>
            <strong>{t(locale, "about.translation")}</strong>
          </dt>
          <dd dir="ltr" lang="en">
            {info.source.translationEn}
          </dd>
          <dt>
            <strong>{t(locale, "about.layout")}</strong>
          </dt>
          <dd dir="ltr" lang="en">
            {pages.layout}
          </dd>
          <dt>
            <strong>{t(locale, "about.fonts")}</strong>
          </dt>
          <dd>
            {t(locale, "about.fontsBody")} <a href={withBase("/fonts/OFL.txt")}>Amiri Quran — OFL</a> ·{" "}
            <a href={withBase("/fonts/OFL-IBMPlexSansArabic.txt")}>IBM Plex Sans Arabic — OFL</a>
          </dd>
          <dt>
            <strong>{t(locale, "about.prayerAlgo")}</strong>
          </dt>
          <dd>{t(locale, "about.prayerAlgoBody")}</dd>
        </dl>
        <p className="muted">{t(locale, "about.sourcesNote")}</p>
        <p className="muted">
          {t(locale, "about.version", { v: info.version, riwayah: info.riwayah, numbering: info.numbering })}
        </p>
      </section>
    </>
  );
}
