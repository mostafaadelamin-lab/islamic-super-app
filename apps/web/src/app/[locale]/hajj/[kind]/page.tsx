import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import hajj from "@/generated/hajj.json";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { StepPager } from "@/components/StepPager";
import {
  EXPLAINED,
  KIND_TITLE,
  PILGRIMAGE_KINDS,
  StepCard,
  TypeStepCard,
  isPilgrimageKind,
} from "@/components/HajjGuide";

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
 * One kind of pilgrimage on its own page (owner 2026-11-15): the numbered steps pinned at the top, and
 * only the chosen step under them, so a pilgrim always knows where they are.
 */
export default async function PilgrimagePage({ params }: { params: Params }) {
  const { locale, kind } = await params;
  if (!isLocale(locale) || !isPilgrimageKind(kind)) notFound();
  const n = (i: number): string => localizeDigits(i + 1, locale);
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
        <>
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
        </>
      ) : (
        <StepPager
          locale={locale}
          titles={EXPLAINED[kind].map((s) => s.title)}
          idPrefix={`hajj-${kind}`}
          label={`${t(locale, "hajj.flow.hajj")}: ${t(locale, `hajj.flow.${kind}`)}`}
        >
          {EXPLAINED[kind].map((s, i) => (
            <TypeStepCard key={i} locale={locale} index={i} step={s} kind={kind} />
          ))}
        </StepPager>
      )}
    </>
  );
}
