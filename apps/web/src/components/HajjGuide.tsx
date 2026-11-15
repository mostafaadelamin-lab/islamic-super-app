import hajj from "@/generated/hajj.json";
import dalil from "@/generated/dalil-hajj.json";
import { t, type Locale } from "@/lib/i18n";
import { isRoundTool } from "@/lib/rounds";
import { localizeDigits } from "@/lib/digits";
import { HAJJ_FLOWS, type HajjType } from "@/lib/hajj-flows";
import { RoundCounter } from "./RoundCounter";
import { HajjPicture, StepSay, pictureFor } from "./HajjStepExtras";
import { DuaText } from "./DuaText";

/** One page per kind of pilgrimage (owner 2026-11-15): Umrah and the three kinds of Hajj. */
export const PILGRIMAGE_KINDS = ["umrah", "tamattu", "qiran", "ifrad"] as const;
export type PilgrimageKind = (typeof PILGRIMAGE_KINDS)[number];
export const isPilgrimageKind = (x: string): x is PilgrimageKind =>
  (PILGRIMAGE_KINDS as readonly string[]).includes(x);

export interface ExplainedStep {
  readonly title: string;
  readonly text: string;
}

export interface Step {
  title: string;
  points: string[];
  dhikr: string | null;
  tool: string | null;
}

export function StepCard({
  locale,
  label,
  step,
  id,
}: {
  locale: Locale;
  label: string;
  step: Step;
  id: string;
}) {
  return (
    <section className="card step" id={id}>
      <span className="step-label">{label}</span>
      <h3 lang="ar">{step.title}</h3>
      <StepPicture title={step.title} umrah locale={locale} />
      <ul lang="ar">
        {step.points.map((p, i) => (
          <li key={i}>
            <DuaText text={p} />
          </li>
        ))}
      </ul>
      {/* The step's own dhikr always stays; what is said at its places follows below in full. */}
      {step.dhikr ? (
        <p className="dua" lang="ar">
          {step.dhikr}
        </p>
      ) : null}
      <StepSay title={step.title} locale={locale} />
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
export const EXPLAINED: Record<HajjType, readonly ExplainedStep[]> = {
  tamattu: explained("tamattu"),
  qiran: explained("qiran"),
  ifrad: explained("ifrad"),
};

/** Menu title and short line of each kind's page. */
export const KIND_TITLE: Record<PilgrimageKind, string> = {
  umrah: "nav.hajjUmrah",
  tamattu: "nav.hajjTamattu",
  qiran: "nav.hajjQiran",
  ifrad: "nav.hajjIfrad",
};

/** The counter a step of a Hajj kind gets: seven rounds of tawaf, sa'i or stones. */
function toolOf(title: string): "tawaf" | "sai" | "jamarat" | null {
  if (title.startsWith("طواف")) return "tawaf";
  if (title.startsWith("سعي") || title.startsWith("السعي")) return "sai";
  if (title.startsWith("رمي")) return "jamarat";
  return null;
}

/** A step of one kind of Hajj, in the official guide's words, duas shaded. */
export function TypeStepCard({
  locale,
  index,
  step,
  kind,
}: {
  locale: Locale;
  index: number;
  step: ExplainedStep;
  kind: HajjType;
}) {
  return (
    <section className="card step hajj-step" id={`hajj-${kind}-${index + 1}-card`}>
      <span className="step-label">{t(locale, "hajj.step", { n: localizeDigits(index + 1, locale) })}</span>
      <h3 lang="ar" data-testid="hajj-step-title">
        {step.title}
      </h3>
      <StepPicture title={step.title} umrah={false} locale={locale} />
      <p lang="ar" className="hajj-step-text" data-testid="hajj-step-text">
        <DuaText text={step.text} />
      </p>
      <StepSay title={step.title} locale={locale} />
      <p className="muted small">
        {t(locale, "hajj.guide.source")}: <span lang="ar">{dalil.source.title}</span>
      </p>
      {toolOf(step.title) ? <RoundCounter locale={locale} tool={toolOf(step.title)!} /> : null}
    </section>
  );
}

/** The picture of where a step happens (owner 2026-11-15: every step has one again). */
function StepPicture({ title, umrah, locale }: { title: string; umrah: boolean; locale: Locale }) {
  const pic = pictureFor(title, umrah);
  return pic ? <HajjPicture pic={pic} locale={locale} /> : null;
}
