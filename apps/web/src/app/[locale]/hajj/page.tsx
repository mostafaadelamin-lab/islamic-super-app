import type { Metadata } from "next";
import hajj from "@/generated/hajj.json";
import { isLocale, t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { isRoundTool } from "@/lib/rounds";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { RoundCounter } from "@/components/RoundCounter";
import { TawafPlan, type TawafPlanLabels } from "@/components/TawafPlan";
import { StepPager } from "@/components/StepPager";
import { HajjTypeFlow, type ExplainedStep } from "@/components/HajjTypeFlow";
import dalil from "@/generated/dalil-hajj.json";
import { HAJJ_FLOWS, type HajjType } from "@/lib/hajj-flows";
import { OfficialHajjGuide } from "@/components/OfficialHajjGuide";
import { HajjServices } from "@/components/HajjServices";

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

function planLabels(locale: Locale): TawafPlanLabels {
  const k = [
    "title",
    "kaaba",
    "blackStone",
    "yemeni",
    "shami",
    "iraqi",
    "door",
    "hijr",
    "maqam",
    "start",
    "direction",
  ] as const;
  return Object.fromEntries(k.map((x) => [x, t(locale, `hajj.plan.${x}`)])) as unknown as TawafPlanLabels;
}

function StepCard({ locale, label, step, id }: { locale: Locale; label: string; step: Step; id: string }) {
  return (
    <section className="card step" id={id}>
      <span className="step-label">{label}</span>
      {step.tool === "tawaf" ? <TawafPlan l={planLabels(locale)} /> : null}
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

/** The official guide's words for a step of the Hajj graphic (its anchor in lib/hajj-flows.ts). */
function explain(anchor: string): string {
  const u = /^#dalil-u(\d+)$/.exec(anchor);
  if (u) return dalil.umrah[Number(u[1]) - 1] ?? "";
  const h = /^#dalil-h(\d+)$/.exec(anchor);
  if (h) return dalil.hajj[Number(h[1]) - 1] ?? "";
  if (anchor === "#dalil-types") return dalil.types.map((x) => `${x.name}: ${x.text}`).join("\n\n");
  const st = /^#hajj-stage-(\d+)$/.exec(anchor);
  if (st) return (hajj.hajj.days[Number(st[1]) - 1]?.points ?? []).join("\n");
  return "";
}

const explained = (k: HajjType): readonly ExplainedStep[] =>
  HAJJ_FLOWS[k].map((s) => ({ title: s.title, text: explain(s.href) }));
const EXPLAINED: Record<HajjType, readonly ExplainedStep[]> = {
  tamattu: explained("tamattu"),
  qiran: explained("qiran"),
  ifrad: explained("ifrad"),
};

/** Hajj & Umrah guide from content/pilgrimage/source-hajj.js (Arabic). Religious review is pending. */
export default async function HajjPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const n = (i: number): string => localizeDigits(i + 1, locale);
  const tawaf = hajj.umrah.steps.findIndex((s) => s.tool === "tawaf");
  return (
    <>
      <h1>{t(locale, "hajj.title")}</h1>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      <HajjServices locale={locale} tawafHref={tawaf < 0 ? null : `#umrah-step-${tawaf + 1}`} />
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
      <StepPager
        locale={locale}
        titles={hajj.umrah.steps.map((s) => s.title)}
        idPrefix="umrah-step"
        label={t(locale, "hajj.flow.umrah")}
      >
        {hajj.umrah.steps.map((s, i) => (
          <StepCard
            key={i}
            id={`umrah-step-${i + 1}-card`}
            locale={locale}
            label={t(locale, "hajj.step", { n: n(i) })}
            step={s}
          />
        ))}
      </StepPager>
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
      <HajjTypeFlow locale={locale} flows={EXPLAINED} source={dalil.source.title} />
      {hajj.hajj.days.map((s, i) => (
        <StepCard
          key={i}
          id={`hajj-stage-${i + 1}`}
          locale={locale}
          label={t(locale, "hajj.stage", { n: n(i) })}
          step={s}
        />
      ))}
      <section className="card">
        <h3 lang="ar">{hajj.hajj.pillars.title}</h3>
        <p lang="ar">{hajj.hajj.pillars.body}</p>
      </section>
      <OfficialHajjGuide locale={locale} />

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
