"use client";
import type { CSSProperties } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { khatmaProgress, khatmaStore, startKhatma } from "@/lib/page-khatma";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

export interface KhatmaSheetProps {
  locale: Locale;
  onGo: (page: number) => void;
  onClose: () => void;
}

/**
 * "الختمة": progress of the current khatma (pages read in the reader) and where to continue. A centred panel
 * over a dimmed page, alone on screen (owner 2026-11-15: no more stacking over the ayah menu and player).
 */
export function KhatmaSheet({ locale, onGo, onClose }: KhatmaSheetProps) {
  const k = useStore(khatmaStore);
  const p = k ? khatmaProgress(k) : null;
  const n = (v: number): string => localizeDigits(v, locale);
  return (
    <div
      className="rd-modal"
      data-testid="khatma-backdrop"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="rd-modal-card rd-khatma"
        role="dialog"
        aria-modal="true"
        aria-labelledby="khatma-title"
        data-testid="khatma-sheet"
      >
        <div className="rd-sheet-head">
          <h2 id="khatma-title">
            <Icon name="openBook" size={22} /> {t(locale, "reader.khatmaTitle")}
          </h2>
          <button
            type="button"
            className="btn btn-sm btn-icon"
            aria-label={t(locale, "common.close")}
            data-testid="khatma-close"
            onClick={onClose}
          >
            <Icon name="close" size={16} />
          </button>
        </div>
        {k && p ? (
          <>
            <div className="kh-summary">
              <div
                className="kh-ring"
                role="progressbar"
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={p.pct}
                aria-label={t(locale, "reader.khatmaTitle")}
                style={{ "--kh-pct": `${p.pct}%` } as CSSProperties}
              >
                <span>{n(p.pct)}٪</span>
              </div>
              <div className="kh-facts">
                <p className="kh-main" data-testid="khatma-progress">
                  {t(locale, "reader.khatmaProgress", { done: n(p.done), pct: n(p.pct) })}
                </p>
                <p className="muted small">
                  {p.next === null
                    ? t(locale, "reader.khatmaDone")
                    : t(locale, "reader.khatmaLeft", { left: n(p.left) })}
                </p>
                <p className="muted small">
                  {t(locale, "reader.khatmaSince", {
                    date: new Date(k.startedAt).toLocaleDateString(locale === "ar" ? "ar-EG" : "en-GB"),
                  })}
                </p>
              </div>
            </div>
            {p.next !== null ? (
              <button
                type="button"
                className="btn btn-primary kh-go"
                data-testid="khatma-continue"
                onClick={() => onGo(p.next!)}
              >
                {t(locale, "reader.khatmaContinue", { page: n(p.next) })}
              </button>
            ) : null}
            <button
              type="button"
              className="kh-reset"
              data-testid="khatma-reset"
              onClick={() => khatmaStore.set(null)}
            >
              {t(locale, "reader.khatmaReset")}
            </button>
          </>
        ) : (
          <>
            <p>{t(locale, "reader.khatmaNone")}</p>
            <button
              type="button"
              className="btn btn-primary kh-go"
              data-testid="khatma-start"
              onClick={() => {
                khatmaStore.set(startKhatma(Date.now()));
                onGo(1);
              }}
            >
              {t(locale, "reader.khatmaStart")}
            </button>
          </>
        )}
      </div>
    </div>
  );
}
