"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { adhkarViewStore } from "@/lib/dhikr-share";
import { useStore } from "@/hooks/useStore";
import { CardDeck, ModeSwitch } from "./CardDeck";
import { DhikrTools } from "./DhikrTools";
import { DhikrPlayerBar } from "./DhikrAudio";
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
  const source = t(locale, "hisn.shareSource", { title, n: localizeDigits(chapterId, locale) });
  const item = (i: number): React.JSX.Element => (
    <li key={i} className="dhikr">
      <p className="dhikr-text" lang="ar" dir="rtl">
        {items[i]}
      </p>
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
      <DhikrPlayerBar locale={locale} />
    </>
  );
}
