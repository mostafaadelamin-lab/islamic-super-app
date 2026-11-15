"use client";
import { Children, useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { StepsFlow } from "./StepsFlow";

/** The step (from 0) a URL hash such as "#umrah-step-2" points at, or null. */
export function stepFromHash(hash: string, idPrefix: string, count: number): number | null {
  const m = new RegExp(`^#${idPrefix}-(\\d+)$`).exec(hash);
  if (!m) return null;
  const n = Number(m[1]);
  return n >= 1 && n <= count ? n - 1 : null;
}

/**
 * One step at a time (owner, 2026-11-15: a tap on step 1 showed every step). The numbered graphic picks
 * the step; under it only that step's card, with Previous / Next. Links such as #umrah-step-2 still work.
 */
export function StepPager({
  locale,
  titles,
  idPrefix,
  label,
  children,
}: {
  locale: Locale;
  titles: readonly string[];
  idPrefix: string;
  label: string;
  /** One card per step, in order. */
  children: ReactNode;
}) {
  const cards = Children.toArray(children);
  const count = cards.length;
  const [active, setActive] = useState(0);
  const boxRef = useRef<HTMLDivElement>(null);

  const show = useCallback(
    (i: number, scroll = true): void => {
      setActive(Math.max(0, Math.min(count - 1, i)));
      // Bring the step into view only when its top is off screen (e.g. Next at the bottom of a long step).
      if (scroll)
        requestAnimationFrame(() => {
          const box = boxRef.current;
          if (!box) return;
          const top = box.getBoundingClientRect().top;
          if (top < 0 || top > window.innerHeight * 0.7) box.scrollIntoView({ block: "start" });
        });
    },
    [count],
  );

  useEffect(() => {
    const fromHash = (): void => {
      const i = stepFromHash(window.location.hash, idPrefix, count);
      if (i !== null) show(i);
    };
    fromHash();
    window.addEventListener("hashchange", fromHash);
    return () => window.removeEventListener("hashchange", fromHash);
  }, [idPrefix, count, show]);

  return (
    <div className="step-pager-wrap" data-testid={`step-pager-${idPrefix}`}>
      <StepsFlow
        locale={locale}
        titles={titles}
        idPrefix={idPrefix}
        label={label}
        active={active}
        onStep={(i) => show(i)}
      />
      <p className="muted small step-pager-hint">{t(locale, "steps.all")}</p>
      <div className="step-pager" ref={boxRef} id={`${idPrefix}-view`}>
        {cards.map((card, i) => (
          <div key={i} hidden={i !== active} data-testid={`step-card-${idPrefix}-${i + 1}`}>
            {card}
          </div>
        ))}
        <StepNav locale={locale} index={active} count={count} onGo={(i) => show(i)} testId={idPrefix} />
      </div>
    </div>
  );
}

/** "Step n of N" with Previous / Next under the step on show. */
export function StepNav({
  locale,
  index,
  count,
  onGo,
  testId,
}: {
  locale: Locale;
  index: number;
  count: number;
  onGo: (i: number) => void;
  testId: string;
}) {
  return (
    <nav className="step-nav" aria-label={label(locale, index, count)} data-testid={`step-nav-${testId}`}>
      <button
        type="button"
        className="btn"
        disabled={index <= 0}
        onClick={() => onGo(index - 1)}
        data-testid={`step-prev-${testId}`}
      >
        {t(locale, "steps.prev")}
      </button>
      <span className="step-nav-count" data-testid={`step-count-${testId}`}>
        {label(locale, index, count)}
      </span>
      <button
        type="button"
        className="btn btn-primary"
        disabled={index >= count - 1}
        onClick={() => onGo(index + 1)}
        data-testid={`step-next-${testId}`}
      >
        {t(locale, "steps.next")}
      </button>
    </nav>
  );
}

function label(locale: Locale, index: number, count: number): string {
  return t(locale, "steps.of", {
    n: localizeDigits(index + 1, locale),
    total: localizeDigits(count, locale),
  });
}
