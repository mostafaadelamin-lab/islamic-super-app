"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { surahMeta } from "@/lib/pages";
import { loadSurahInfo, type SurahInfoData } from "@/lib/surah-info";
import { Icon } from "./Icon";
import { SurahInfoBody } from "./SurahInfo";

type State =
  { status: "loading" } | { status: "ready"; info: SurahInfoData } | { status: "error"; offline: boolean };

/**
 * «عن السورة وأسباب نزولها» from the Mushaf (owner 2026-11-17: as in the app's Mushaf). The surah of the selected
 * ayah, else the page's first, in a centred panel like «معاني الكلمات». Text shown verbatim from the app's asset.
 */
export function SurahInfoSheet({
  locale,
  surah,
  onClose,
}: {
  locale: Locale;
  surah: number;
  onClose: () => void;
}) {
  const [state, setState] = useState<State>({ status: "loading" });
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    let alive = true;
    setState({ status: "loading" });
    loadSurahInfo(surah).then(
      (info) => alive && setState({ status: "ready", info }),
      () => alive && setState({ status: "error", offline: navigator.onLine === false }),
    );
    return () => {
      alive = false;
    };
  }, [surah, retry]);
  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  const meta = surahMeta(surah);
  if (!meta) return null;
  const name = locale === "en" ? `${meta.translit} (${meta.nameEn})` : `سورة ${meta.nameAr}`;
  return (
    <div
      className="rd-modal"
      data-testid="surah-info-backdrop"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="rd-modal-card rd-meanings surah-info"
        role="dialog"
        aria-modal="true"
        aria-labelledby="surah-info-title"
        data-testid="surah-info-sheet"
        lang="ar"
        dir="rtl"
      >
        <div className="rd-sheet-head">
          <h2 id="surah-info-title">
            <Icon name="info" size={22} /> {t(locale, "surahInfo.title")}: {name}
          </h2>
          <button
            type="button"
            className="btn btn-sm btn-icon"
            aria-label={t(locale, "common.close")}
            data-testid="surah-info-close"
            onClick={onClose}
          >
            <Icon name="close" size={16} />
          </button>
        </div>
        <div className="mn-body" aria-live="polite" aria-busy={state.status === "loading"}>
          {state.status === "loading" ? <p className="muted">{t(locale, "surahInfo.loading")}</p> : null}
          {state.status === "error" ? (
            <div className="alert alert-error" role="alert" data-testid="surah-info-error">
              <p>{t(locale, state.offline ? "surahInfo.offline" : "surahInfo.error")}</p>
              <button type="button" className="btn btn-sm" onClick={() => setRetry((r) => r + 1)}>
                {t(locale, "tafsir.retry")}
              </button>
            </div>
          ) : null}
          {state.status === "ready" ? <SurahInfoBody locale={locale} meta={meta} info={state.info} /> : null}
        </div>
      </div>
    </div>
  );
}
