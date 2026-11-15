import type { Metadata } from "next";
import Link from "next/link";
import hajj from "@/generated/hajj.json";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { Icon } from "@/components/Icon";
import { OfficialHajjGuide } from "@/components/OfficialHajjGuide";
import { HajjServices } from "@/components/HajjServices";
import { GUIDE, GuideSources, GuideStepCard, KIND_TITLE, PILGRIMAGE_KINDS } from "@/components/HajjGuide";
import { localizeDigits } from "@/lib/digits";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "hajj.title") };
}

/**
 * The Hajj & Umrah hub (owner 2026-11-16): pick Umrah or a kind of Hajj; under it the days of Hajj in full,
 * the miqat and ihram, and the visit to Madinah, every text from its source (content/pilgrimage/dist).
 */
export default async function HajjPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const tawaf = GUIDE.flows.umrah.findIndex((s) => s.step === "tawaf-first");
  return (
    <>
      <h1>{t(locale, "hajj.title")}</h1>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      <nav className="hajj-kinds" aria-label={t(locale, "hajj.contents")} data-testid="hajj-kinds">
        {PILGRIMAGE_KINDS.map((k) => (
          <Link
            key={k}
            className="card hajj-kind"
            href={href(locale, `hajj/${k}`)}
            data-testid={`hajj-kind-${k}`}
          >
            <span className="hajj-kind-icon">
              <Icon name="kaaba" size={28} />
            </span>
            <span>
              <strong>{t(locale, KIND_TITLE[k])}</strong>
              <span className="muted small">
                {t(locale, k === "umrah" ? "nav.hajjUmrahSub" : "nav.hajjTypeSub")}
              </span>
            </span>
            <span className="home-more-chevron">
              <Icon name="chevron" size={20} />
            </span>
          </Link>
        ))}
      </nav>
      <HajjServices
        locale={locale}
        tawafHref={tawaf < 0 ? null : `${href(locale, "hajj/umrah")}#umrah-step-${tawaf + 1}`}
      />
      <h2 id="ihram">{t(locale, "hajj.ihram")}</h2>
      {GUIDE.hub.ihram.map((s) => (
        <GuideStepCard key={s} locale={locale} id={`hajj-${s}`} label={t(locale, "hajj.ihram")} stepId={s} />
      ))}
      {/* The stages of Hajj by day, in full. */}
      <h2 id="hajj">{t(locale, "hajj.hajj")}</h2>
      {GUIDE.hub.days.map((s, i) => (
        <GuideStepCard
          key={s}
          id={`hajj-stage-${i + 1}`}
          locale={locale}
          label={t(locale, "hajj.stage", { n: localizeDigits(i + 1, locale) })}
          stepId={s}
        />
      ))}
      <section className="card">
        <h3 lang="ar">{hajj.hajj.pillars.title}</h3>
        <p lang="ar">{hajj.hajj.pillars.body}</p>
      </section>
      <h2 id="madinah">{GUIDE.steps[GUIDE.hub.madinah]?.title}</h2>
      <GuideStepCard
        locale={locale}
        id="hajj-madinah"
        label={t(locale, "hajj.madinah")}
        stepId={GUIDE.hub.madinah}
      />
      <OfficialHajjGuide locale={locale} />
      <GuideSources locale={locale} />
    </>
  );
}
