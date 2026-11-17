"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName, type Ref } from "@/lib/pages";
import { loadMeanings, type WordMeaning } from "@/lib/word-meanings";
import { Icon } from "./Icon";

type State =
  | { status: "loading" }
  | { status: "ready"; items: { ref: Ref; words: readonly WordMeaning[] }[] }
  | { status: "error"; offline: boolean };

export interface MeaningsSheetProps {
  locale: Locale;
  /** The ayahs to explain: the whole page, or the one selected ayah. */
  refs: readonly Ref[];
  /** Mushaf page number when showing a whole page (title "معاني كلمات الصفحة ٥"). */
  page?: number;
  onClose: () => void;
  /** Tapping an ayah heading selects that ayah on the page. */
  onSelect?: (ref: Ref) => void;
}

/**
 * «معاني الكلمات» (owner 2026-11-17): the difficult words of a Mushaf page, or of one ayah, with their meanings
 * from «السراج في بيان غريب القرآن», shown verbatim. A centred panel over a dimmed page, like the khatma panel.
 */
export function MeaningsSheet({ locale, refs, page, onClose, onSelect }: MeaningsSheetProps) {
  const [state, setState] = useState<State>({ status: "loading" });
  const [retry, setRetry] = useState(0);
  const key = refs.map(([s, a]) => `${s}:${a}`).join(",");
  useEffect(() => {
    let alive = true;
    setState({ status: "loading" });
    void (async () => {
      try {
        const items = await loadMeanings(refs);
        if (alive) setState({ status: "ready", items });
      } catch {
        if (alive) setState({ status: "error", offline: navigator.onLine === false });
      }
    })();
    return () => {
      alive = false;
    };
    // refs is described by key
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, retry]);
  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const one = refs.length === 1 ? refs[0]! : null;
  const ayahRef = ([s, a]: Ref): string =>
    t(locale, "quran.ayahRef", { surah: surahName(s, locale), ayah: localizeDigits(a, locale) });
  const title = one
    ? t(locale, "meanings.ofAyah", { ref: ayahRef(one) })
    : t(locale, "meanings.ofPage", { page: localizeDigits(page ?? 0, locale) });

  return (
    <div
      className="rd-modal"
      data-testid="meanings-backdrop"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="rd-modal-card rd-meanings"
        role="dialog"
        aria-modal="true"
        aria-labelledby="meanings-title"
        data-testid="meanings-sheet"
        lang="ar"
        dir="rtl"
      >
        <div className="rd-sheet-head">
          <h2 id="meanings-title">
            <Icon name="meanings" size={22} /> {title}
          </h2>
          <button
            type="button"
            className="btn btn-sm btn-icon"
            aria-label={t(locale, "common.close")}
            data-testid="meanings-close"
            onClick={onClose}
          >
            <Icon name="close" size={16} />
          </button>
        </div>
        <div className="mn-body" aria-live="polite" aria-busy={state.status === "loading"}>
          {state.status === "loading" ? (
            <p className="muted" data-testid="meanings-loading">
              {t(locale, "meanings.loading")}
            </p>
          ) : null}
          {state.status === "error" ? (
            <div className="alert alert-error" role="alert" data-testid="meanings-error">
              <p>{t(locale, state.offline ? "meanings.offline" : "meanings.error")}</p>
              <button type="button" className="btn btn-sm" onClick={() => setRetry((r) => r + 1)}>
                {t(locale, "tafsir.retry")}
              </button>
            </div>
          ) : null}
          {state.status === "ready" && state.items.length === 0 ? (
            <p className="muted" data-testid="meanings-none">
              {t(locale, one ? "meanings.noneAyah" : "meanings.nonePage")}
            </p>
          ) : null}
          {state.status === "ready"
            ? state.items.map(({ ref, words }) => (
                <section className="mn-ayah" key={`${ref[0]}:${ref[1]}`} data-ayah={`${ref[0]}:${ref[1]}`}>
                  {one ? null : onSelect ? (
                    <button type="button" className="mn-ref" onClick={() => onSelect(ref)}>
                      {ayahRef(ref)}
                    </button>
                  ) : (
                    <h3 className="mn-ref">{ayahRef(ref)}</h3>
                  )}
                  <dl className="mn-list" data-testid="meanings-list">
                    {words.map(([w, m], i) => (
                      <div className="mn-item" key={i}>
                        <dt className="mn-word">{w}</dt>
                        <dd className="mn-meaning">{m}</dd>
                      </div>
                    ))}
                  </dl>
                </section>
              ))
            : null}
        </div>
        <p className="mn-source muted small" data-testid="meanings-source">
          {t(locale, "meanings.source")}
        </p>
      </div>
    </div>
  );
}
