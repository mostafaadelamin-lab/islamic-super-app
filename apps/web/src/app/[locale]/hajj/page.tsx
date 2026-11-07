import type { Metadata } from "next";
import hajj from "@/generated/hajj.json";
import { isLocale, t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { isRoundTool } from "@/lib/rounds";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { RoundCounter } from "@/components/RoundCounter";

interface Step {
  title: string;
  points: string[];
  dhikr: string | null;
  tool: string | null;
}

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "hajj.title") };
}

function StepCard({ locale, label, step }: { locale: Locale; label: string; step: Step }) {
  return (
    <section className="card step">
      <span className="step-label">{label}</span>
      <h3 lang="ar">{step.title}</h3>
      <ul lang="ar">
        {step.points.map((p, i) => (
          <li key={i}>{p}</li>
        ))}
      </ul>
      {step.dhikr ? (
        <p className="dua" lang="ar">
          {step.dhikr}
        </p>
      ) : null}
      {isRoundTool(step.tool) ? <RoundCounter locale={locale} tool={step.tool} /> : null}
    </section>
  );
}

/** Hajj & Umrah guide from content/pilgrimage/source-hajj.js (Arabic). Religious review is pending. */
export default async function HajjPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const n = (i: number): string => localizeDigits(i + 1, locale);
  return (
    <>
      <h1>{t(locale, "hajj.title")}</h1>
      <p className="alert alert-warn" role="note" data-testid="review-notice">
        <strong>{t(locale, "hajj.reviewTitle")}</strong> {t(locale, "hajj.reviewBody")}
      </p>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      <nav className="row toc" aria-label={t(locale, "hajj.contents")}>
        <a className="btn btn-sm" href="#umrah">
          {t(locale, "hajj.umrah")}
        </a>
        <a className="btn btn-sm" href="#hajj">
          {t(locale, "hajj.hajj")}
        </a>
        <a className="btn btn-sm" href="#ihram">
          {t(locale, "hajj.ihram")}
        </a>
      </nav>

      <h2 id="umrah">{t(locale, "hajj.umrah")}</h2>
      <p lang="ar">{hajj.umrah.intro}</p>
      {hajj.umrah.steps.map((s, i) => (
        <StepCard key={i} locale={locale} label={t(locale, "hajj.step", { n: n(i) })} step={s} />
      ))}
      <section className="card">
        <h3 lang="ar">{hajj.madinah.title}</h3>
        <ul lang="ar">
          {hajj.madinah.points.map((p, i) => (
            <li key={i}>{p}</li>
          ))}
        </ul>
      </section>

      <h2 id="hajj">{t(locale, "hajj.hajj")}</h2>
      <section className="card">
        <h3 lang="ar">{hajj.hajj.typesTitle}</h3>
        <dl lang="ar">
          {hajj.hajj.types.map((x) => (
            <div key={x.name}>
              <dt>{x.name}</dt>
              <dd>{x.body}</dd>
            </div>
          ))}
        </dl>
      </section>
      {hajj.hajj.days.map((s, i) => (
        <StepCard key={i} locale={locale} label={t(locale, "hajj.stage", { n: n(i) })} step={s} />
      ))}
      <section className="card">
        <h3 lang="ar">{hajj.hajj.pillars.title}</h3>
        <p lang="ar">{hajj.hajj.pillars.body}</p>
      </section>

      <h2 id="ihram">{t(locale, "hajj.ihram")}</h2>
      <section className="card">
        <h3 lang="ar">{hajj.ihram.miqatTitle}</h3>
        <dl lang="ar">
          {hajj.ihram.miqat.map((x) => (
            <div key={x.name}>
              <dt>{x.name}</dt>
              <dd>{x.body}</dd>
            </div>
          ))}
        </dl>
        <p className="muted" lang="ar">
          {hajj.ihram.miqatNote}
        </p>
      </section>
      <section className="card">
        <h3 lang="ar">{hajj.ihram.prohibitionsTitle}</h3>
        <ul lang="ar">
          {hajj.ihram.prohibitions.map((p, i) => (
            <li key={i}>{p}</li>
          ))}
        </ul>
        <p className="muted" lang="ar">
          {hajj.ihram.prohibitionsNote}
        </p>
      </section>
      <section className="card">
        <h3 lang="ar">{hajj.talbiya.title}</h3>
        <p className="dua" lang="ar">
          {hajj.talbiya.text}
        </p>
      </section>
      <p className="muted small">{t(locale, "hajj.source")}</p>
    </>
  );
}
