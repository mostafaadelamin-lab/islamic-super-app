"use client";
import { useEffect, useId, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahName, type Ref } from "@/lib/pages";
import { loadTafsir, stepRef } from "@/lib/tafsir";
import { Icon } from "./Icon";

type TafsirState =
  | { status: "loading"; key: string }
  | { status: "ready"; key: string; text: string }
  | { status: "error"; key: string; offline: boolean };

export interface TafsirPanelProps {
  locale: Locale;
  surah: number;
  ayah: number;
  /** Called by the previous/next buttons; without it the panel moves on its own. */
  onStep?: (ref: Ref) => void;
  /** Previous/next ayah buttons (hidden while following the recitation: the player has its own). */
  showNav?: boolean;
}

/** Tafsir al-Muyassar for one ayah, shown verbatim (Arabic, UI font) with previous/next ayah buttons. */
export function TafsirPanel({ locale, surah, ayah, onStep, showNav = true }: TafsirPanelProps) {
  const [own, setOwn] = useState<Ref>([surah, ayah]);
  const [retry, setRetry] = useState(0);
  const headingId = useId();
  useEffect(() => setOwn([surah, ayah]), [surah, ayah]);
  const [s, a] = onStep ? [surah, ayah] : own;
  const key = `${s}:${a}`;
  const [state, setState] = useState<TafsirState>({ status: "loading", key });

  useEffect(() => {
    let alive = true;
    setState({ status: "loading", key });
    void (async () => {
      try {
        const text = await loadTafsir(s, a);
        if (alive) setState({ status: "ready", key, text });
      } catch {
        if (alive) setState({ status: "error", key, offline: navigator.onLine === false });
      }
    })();
    return () => {
      alive = false;
    };
  }, [s, a, key, retry]);

  const move = (delta: 1 | -1): void => {
    const next = stepRef(s, a, delta);
    if (!next) return;
    if (onStep) onStep(next);
    else setOwn(next);
  };
  const ref = t(locale, "quran.ayahRef", { surah: surahName(s, locale), ayah: localizeDigits(a, locale) });
  const shown = state.key === key ? state : { status: "loading" as const, key };

  return (
    <section className="tafsir" aria-labelledby={headingId} data-testid="tafsir" data-ayah={key}>
      <div className="tafsir-head">
        <h2 id={headingId} className="tafsir-title">
          {locale === "ar" ? (
            t(locale, "tafsir.title")
          ) : (
            <>
              {t(locale, "tafsir.title")}{" "}
              <span lang="ar" dir="rtl">
                ({t("ar", "tafsir.title")})
              </span>
            </>
          )}
        </h2>
        <p className="tafsir-ref" data-testid="tafsir-ref">
          {t(locale, "tafsir.of", { ref })}
        </p>
      </div>
      {locale === "ar" ? null : (
        <p className="muted small tafsir-note" data-testid="tafsir-arabic-only">
          {t(locale, "tafsir.arabicOnly")}
        </p>
      )}
      <div className="tafsir-body" aria-live="polite" aria-busy={shown.status === "loading"}>
        {shown.status === "loading" ? (
          <p className="muted" data-testid="tafsir-loading">
            {t(locale, "tafsir.loading")}
          </p>
        ) : null}
        {shown.status === "error" ? (
          <div className="alert alert-error" role="alert" data-testid="tafsir-error">
            <p>{t(locale, shown.offline ? "tafsir.offline" : "tafsir.error")}</p>
            <button
              type="button"
              className="btn btn-sm"
              data-testid="tafsir-retry"
              onClick={() => setRetry((r) => r + 1)}
            >
              {t(locale, "tafsir.retry")}
            </button>
          </div>
        ) : null}
        {shown.status === "ready" ? (
          <p className="tafsir-text" lang="ar" dir="rtl" data-testid="tafsir-text">
            {shown.text}
          </p>
        ) : null}
      </div>
      <p className="tafsir-source muted small" data-testid="tafsir-source">
        {t(locale, "tafsir.source")}
      </p>
      {showNav ? (
        <div className="tafsir-nav">
          <button
            type="button"
            className="btn btn-sm"
            data-testid="tafsir-prev"
            disabled={!stepRef(s, a, -1)}
            onClick={() => move(-1)}
          >
            <Icon name={locale === "ar" ? "next" : "prev"} size={16} /> {t(locale, "tafsir.prev")}
          </button>
          <button
            type="button"
            className="btn btn-sm"
            data-testid="tafsir-next"
            disabled={!stepRef(s, a, 1)}
            onClick={() => move(1)}
          >
            {t(locale, "tafsir.next")} <Icon name={locale === "ar" ? "prev" : "next"} size={16} />
          </button>
        </div>
      ) : null}
    </section>
  );
}
