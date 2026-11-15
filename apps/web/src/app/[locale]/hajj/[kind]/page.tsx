import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { StepPager } from "@/components/StepPager";
import { GUIDE, GuideStepCard, KIND_TITLE, PILGRIMAGE_KINDS, isPilgrimageKind } from "@/components/HajjGuide";

export const dynamicParams = false;

type Params = Promise<{ locale: string; kind: string }>;

export function generateStaticParams(): { kind: string }[] {
  return PILGRIMAGE_KINDS.map((kind) => ({ kind }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { locale, kind } = await params;
  if (!isPilgrimageKind(kind)) return {};
  return { title: t(isLocale(locale) ? locale : "ar", KIND_TITLE[kind]) };
}

/**
 * One kind of pilgrimage on its own page (owner 2026-11-15): the numbered steps pinned at the top, and only
 * the chosen step under them. Each step (owner 2026-11-16): its picture, the official guide's words, then
 * every sunnah, dhikr and ayah of it in full, each with its reference (content/pilgrimage/dist/hajj-guide.v2.json).
 */
export default async function PilgrimagePage({ params }: { params: Params }) {
  const { locale, kind } = await params;
  if (!isLocale(locale) || !isPilgrimageKind(kind)) notFound();
  const flow = GUIDE.flows[kind];
  const prefix = kind === "umrah" ? "umrah-step" : `hajj-${kind}`;
  const label =
    kind === "umrah"
      ? t(locale, "hajj.flow.umrah")
      : `${t(locale, "hajj.flow.hajj")}: ${t(locale, `hajj.flow.${kind}`)}`;
  return (
    <>
      <p>
        <Link className="btn btn-sm" href={href(locale, "hajj")} data-testid="hajj-back">
          {t(locale, "hajj.title")}
        </Link>
      </p>
      <h1 data-testid="hajj-kind-title">{t(locale, KIND_TITLE[kind])}</h1>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      {kind === "umrah" ? (
        <GuideStepCard
          locale={locale}
          id="umrah-intro"
          label={t(locale, "hajj.umrah")}
          stepId={GUIDE.hub.umrahIntro}
        />
      ) : null}
      <StepPager locale={locale} titles={flow.map((s) => s.title)} idPrefix={prefix} label={label}>
        {flow.map((s, i) => (
          <GuideStepCard
            key={i}
            locale={locale}
            id={`${prefix}-${i + 1}-card`}
            label={t(locale, "hajj.step", { n: localizeDigits(i + 1, locale) })}
            stepId={s.step}
            title={s.title}
            dalil={s.dalil}
            kind={kind}
          />
        ))}
      </StepPager>
    </>
  );
}
