"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { explanationOf, loadExplained, type HadithExplanation } from "@/lib/hadith";
import { Icon } from "./Icon";

/** "Simplified explanation" for one hadith, as in the app; nothing is shown when there is none. */
export function HadithExplain({ locale, book, n }: { locale: Locale; book: string; n: number }) {
  const [e, setE] = useState<HadithExplanation | null>(null);
  useEffect(() => {
    let live = true;
    void loadExplained(book).then((d) => {
      if (live) setE(explanationOf(d, n));
    });
    return () => {
      live = false;
    };
  }, [book, n]);
  if (!e) return null;
  const meta = [e.attribution, e.grade ? t(locale, "hadith.grade", { grade: e.grade }) : null].filter(
    Boolean,
  );
  return (
    <details className="hadith-explain" data-testid={`hadith-explain-${n}`}>
      <summary>
        <Icon name="book" size={18} /> {t(locale, "hadith.explain")}
      </summary>
      <div lang="ar" dir="rtl">
        <h3>{e.title}</h3>
        {meta.length > 0 ? <p className="muted small">{meta.join(" · ")}</p> : null}
        <p className="hadith-explain-text">{e.explanation}</p>
        {e.hints && e.hints.length > 0 ? (
          <>
            <h4>{t(locale, "hadith.benefits")}</h4>
            <ul>
              {e.hints.map((h, i) => (
                <li key={i}>{h}</li>
              ))}
            </ul>
          </>
        ) : null}
      </div>
      <p className="muted small">{t(locale, "hadith.explainSource")}</p>
    </details>
  );
}
