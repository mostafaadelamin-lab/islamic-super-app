"use client";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { HAJJ_TYPES, type HajjType } from "@/lib/hajj-flows";
import { StepsFlow } from "./StepsFlow";
import { StepNav } from "./StepPager";

export interface ExplainedStep {
  title: string;
  /** The official guide's own words for this step. */
  text: string;
}

/** The Hajj type a URL hash such as "#hajj-ifrad" (home card, menu) picks, or null. */
export function typeFromHash(hash: string): HajjType | null {
  const k = hash.replace(/^#hajj-/, "");
  return hash.startsWith("#hajj-") && (HAJJ_TYPES as readonly string[]).includes(k) ? (k as HajjType) : null;
}

/**
 * Hajj steps 1, 2, 3… for the chosen type (tamattu' by default). A tap on a step shows that step alone with
 * the official guide's words and Previous / Next (owner, 2026-11-15), instead of jumping into the whole guide.
 */
export function HajjTypeFlow({
  locale,
  flows,
  source,
}: {
  locale: Locale;
  flows: Readonly<Record<HajjType, readonly ExplainedStep[]>>;
  source: string;
}) {
  const [type, setType] = useState<HajjType>("tamattu");
  const [active, setActive] = useState(0);
  const ref = useRef<HTMLElement>(null);
  const steps = flows[type];
  const step = steps[Math.min(active, steps.length - 1)]!;

  useEffect(() => {
    const fromHash = (): void => {
      const k = typeFromHash(window.location.hash);
      if (!k) return;
      setType(k);
      setActive(0);
      requestAnimationFrame(() => ref.current?.scrollIntoView({ block: "start" }));
    };
    fromHash();
    window.addEventListener("hashchange", fromHash);
    return () => window.removeEventListener("hashchange", fromHash);
  }, []);

  return (
    <section className="card" data-testid="hajj-type-flow" id="hajj-types" ref={ref}>
      {/* Targets of the home card and menu links (#hajj-ifrad, #hajj-qiran, #hajj-tamattu). */}
      {HAJJ_TYPES.map((k) => (
        <span key={k} id={`hajj-${k}`} className="anchor-target" aria-hidden="true" />
      ))}
      <h3>{t(locale, "hajj.flow.hajj")}</h3>
      <div className="row" role="tablist" aria-label={t(locale, "hajj.flow.type")}>
        {HAJJ_TYPES.map((k) => (
          <button
            key={k}
            type="button"
            role="tab"
            aria-selected={type === k}
            className={type === k ? "btn btn-sm btn-primary" : "btn btn-sm"}
            onClick={() => {
              setType(k);
              setActive(0);
            }}
            data-testid={`hajj-type-${k}`}
          >
            {t(locale, `hajj.flow.${k}`)}
          </button>
        ))}
      </div>
      <StepsFlow
        locale={locale}
        titles={steps.map((s) => s.title)}
        idPrefix={`hajj-${type}`}
        label={`${t(locale, "hajj.flow.hajj")}: ${t(locale, `hajj.flow.${type}`)}`}
        active={active}
        onStep={setActive}
      />
      <p className="muted small step-pager-hint">{t(locale, "steps.all")}</p>
      <article className="step-pager hajj-step" data-testid="hajj-step">
        <h4 lang="ar" data-testid="hajj-step-title">
          {localizeDigits(active + 1, locale)}. {step.title}
        </h4>
        <p lang="ar" className="hajj-step-text" data-testid="hajj-step-text">
          {step.text}
        </p>
        <p className="muted small">
          {t(locale, "hajj.guide.source")}: <span lang="ar">{source}</span>
        </p>
        <StepNav
          locale={locale}
          index={active}
          count={steps.length}
          onGo={setActive}
          testId={`hajj-${type}`}
        />
      </article>
    </section>
  );
}
