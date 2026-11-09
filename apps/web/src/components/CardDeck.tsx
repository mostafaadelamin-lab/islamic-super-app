"use client";
import { useEffect, useState, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { adhkarViewStore, type AdhkarMode } from "@/lib/dhikr-share";
import { useStore } from "@/hooks/useStore";

const MODES: readonly AdhkarMode[] = ["list", "cards"];

/** List / cards switch for adhkar pages (remembered on this device). */
export function ModeSwitch({ locale }: { locale: Locale }) {
  const { mode } = useStore(adhkarViewStore);
  return (
    <div className="segmented" role="group" aria-label={t(locale, "dhikr.view")}>
      {MODES.map((m) => (
        <button
          key={m}
          type="button"
          aria-pressed={mode === m}
          onClick={() => adhkarViewStore.set(() => ({ mode: m }))}
          data-testid={`view-${m}`}
        >
          {t(locale, `dhikr.view.${m}`)}
        </button>
      ))}
    </div>
  );
}

/**
 * One item at a time with previous / next. `advance` moves on by itself (e.g. when a dhikr's count is
 * complete); `resetKey` returns to the first card (e.g. when the session changes).
 */
export function CardDeck({
  locale,
  count,
  render,
  advanceWhen,
  resetKey,
}: {
  locale: Locale;
  count: number;
  render: (i: number) => ReactNode;
  advanceWhen?: (i: number) => boolean;
  resetKey?: string;
}) {
  const [i, setI] = useState(0);
  useEffect(() => setI(0), [resetKey]);
  const last = Math.max(0, count - 1);
  const at = Math.min(i, last);
  const done = advanceWhen?.(at) ?? false;
  useEffect(() => {
    if (done && at < last) setI(at + 1);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- advance once, when this card becomes done
  }, [done]);
  if (count === 0) return null;
  return (
    <div className="card-deck" data-testid="card-deck">
      {render(at)}
      <nav className="pager" aria-label={t(locale, "dhikr.cardNav")}>
        <button
          type="button"
          className="btn"
          disabled={at === 0}
          onClick={() => setI(at - 1)}
          data-testid="card-prev"
        >
          {t(locale, "dhikr.prevCard")}
        </button>
        <span className="muted small" data-testid="card-pos">
          {localizeDigits(at + 1, locale)} / {localizeDigits(count, locale)}
        </span>
        <button
          type="button"
          className="btn btn-primary"
          disabled={at === last}
          onClick={() => setI(at + 1)}
          data-testid="card-next"
        >
          {t(locale, "dhikr.nextCard")}
        </button>
      </nav>
    </div>
  );
}
