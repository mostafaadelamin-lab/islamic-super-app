"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { explanationOf, loadExplained, type HadithExplanation } from "@/lib/hadith";
import { Icon } from "./Icon";

/**
 * «الشرح المبسّط» shown under a hadith (owner 2026-11-15: visible, not hidden
 * behind a button): the start of the explanation, then the rest, the grade and
 * the benefits on «اقرأ الشرح كاملًا». Nothing is shown when there is none.
 * The text is quoted word for word from a published hadith encyclopedia.
 */
export function HadithExplain({ locale, book, n }: { locale: Locale; book: string; n: number }) {
  const [e, setE] = useState<HadithExplanation | null>(null);
  const [open, setOpen] = useState(false);
  useEffect(() => {
    let live = true;
    setOpen(false);
    const load = async (): Promise<void> => {
      const d = await loadExplained(book);
      if (live) setE(explanationOf(d, n));
    };
    void load();
    return () => {
      live = false;
    };
  }, [book, n]);
  if (!e) return null;
  const meta = [e.attribution, e.grade ? t(locale, "hadith.grade", { grade: e.grade }) : null].filter(
    Boolean,
  );
  const bodyId = `hadith-explain-body-${book}-${n}`;
  return (
    <section
      className={`hadith-explain${open ? " is-open" : ""}`}
      data-testid={`hadith-explain-${n}`}
      aria-label={t(locale, "hadith.explain")}
    >
      <h3 className="hadith-explain-label">
        <Icon name="book" size={18} /> {t(locale, "hadith.explain")}
      </h3>
      <div lang="ar" dir="rtl" id={bodyId}>
        <p className="hadith-explain-text">{e.explanation}</p>
        {open ? (
          <>
            {meta.length > 0 ? <p className="muted small">{meta.join(" · ")}</p> : null}
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
            <p className="muted small">{t(locale, "hadith.explainSource")}</p>
          </>
        ) : null}
      </div>
      <button
        type="button"
        className="btn-link hadith-explain-more"
        aria-expanded={open}
        aria-controls={bodyId}
        onClick={() => setOpen((v) => !v)}
        data-testid={`hadith-explain-more-${n}`}
      >
        {t(locale, open ? "hadith.explainLess" : "hadith.explainMore")}
      </button>
    </section>
  );
}
