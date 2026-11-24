"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { adhkarViewStore } from "@/lib/dhikr-share";
import { useStore } from "@/hooks/useStore";
import { useAutoExit } from "@/hooks/useAutoExit";
import { countStatedIn } from "@/lib/hisn-count";
import { href } from "@/lib/locale-path";
import { withBase } from "@/lib/base-path";
import { goBack } from "@/lib/back-nav";
import { Icon } from "./Icon";
import { CardDeck, ModeSwitch } from "./CardDeck";
import { DhikrTools } from "./DhikrTools";
import type { DhikrExtra } from "@/lib/dhikr-extras";

/** The items of one Hisn al-Muslim chapter (text unchanged), as a list or one card at a time. */
export function HisnItems({
  locale,
  chapterId,
  title,
  items,
  extras = [],
}: {
  locale: Locale;
  chapterId: number;
  title: string;
  items: readonly string[];
  extras?: readonly DhikrExtra[];
}) {
  const { mode } = useStore(adhkarViewStore);
  // Tap counters in the one-card view, as in the app (target = the count the text states, else 1).
  const [taps, setTaps] = useState<number[]>(() => items.map(() => 0));
  const target = (i: number): number => countStatedIn(items[i]!);
  const isDone = (i: number): boolean => (taps[i] ?? 0) >= target(i);
  const tap = (i: number): void =>
    setTaps((cur) => cur.map((n, k) => (k === i ? (n >= target(i) ? 0 : n + 1) : n)));
  // Finishing the last counter goes back to the chapter list it came from.
  useAutoExit(
    mode === "cards" && items.length > 0 && items.every((_, i) => isDone(i)),
    String(chapterId),
    // Back to the page before (it keeps the section the reader had picked); else the chapter list.
    () => goBack(() => window.location.assign(withBase(href(locale, "hisn")))),
  );
  const counter = (i: number): React.JSX.Element => {
    const n = taps[i] ?? 0;
    const done = isDone(i);
    return (
      <div className="dhikr-foot">
        <button
          type="button"
          className={done ? "counter done" : "counter"}
          data-testid={`hisn-count-${i + 1}`}
          onClick={() => tap(i)}
        >
          {done ? <Icon name="check" size={18} /> : null}
          <span className="sr-only">
            {t(locale, "adhkar.countLabel", {
              i: localizeDigits(i + 1, locale),
              n: localizeDigits(n, locale),
              total: localizeDigits(target(i), locale),
            })}
          </span>
          <span aria-hidden="true">
            {localizeDigits(Math.min(n, target(i)), locale)} / {localizeDigits(target(i), locale)}
          </span>
        </button>
      </div>
    );
  };
  const source = t(locale, "hisn.shareSource", { title, n: localizeDigits(chapterId, locale) });
  const item = (i: number): React.JSX.Element => (
    <li key={i} className="dhikr">
      <p className="dhikr-text" lang="ar" dir="rtl">
        {items[i]}
      </p>
      {mode === "cards" ? counter(i) : null}
      <DhikrTools
        locale={locale}
        text={items[i]!}
        source={source}
        where={`${source} · ${localizeDigits(i + 1, locale)}`}
        testId={`hisn-${i + 1}`}
        extra={extras[i]}
      />
    </li>
  );
  return (
    <>
      <ModeSwitch locale={locale} />
      {mode === "cards" ? (
        <CardDeck
          locale={locale}
          count={items.length}
          resetKey={String(chapterId)}
          render={(i) => <ol className="dhikr-list">{item(i)}</ol>}
        />
      ) : (
        <ol className="dhikr-list" data-testid="hisn-items">
          {items.map((_, i) => item(i))}
        </ol>
      )}
    </>
  );
}
