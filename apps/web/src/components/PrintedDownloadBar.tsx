"use client";

import { useEffect, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { pageForAyah, surahMeta } from "@/lib/pages";
import { prefsStore } from "@/lib/settings";
import {
  ALL_PAGES,
  dismissPrintedJob,
  printedJob,
  printedOfflineSupported,
  printedSavedIn,
  startPrintedDownload,
  subscribePrintedJob,
} from "@/lib/mushaf-printed";

const useJob = () => useSyncExternalStore(subscribePrintedJob, printedJob, printedJob);

/** The pages of surah [s] in the Madinah Mushaf. */
export function surahPages(s: number): number[] {
  const n = surahMeta(s)?.ayahCount ?? 1;
  const a = pageForAyah(s, 1);
  const b = pageForAyah(s, n);
  return Array.from({ length: b - a + 1 }, (_, i) => a + i);
}

/**
 * Owner 2026-11-27: «تغيير الخط» opens three choices: switch the font, download this surah's Madina font, or
 * download the whole Mushaf's Madina font once. Pages already saved are never downloaded again; no file size shown.
 */
export function MushafFontMenu({
  locale,
  surah,
  printed,
  onClose,
}: {
  locale: Locale;
  surah: number;
  printed: boolean;
  onClose: () => void;
}) {
  const j = useJob();
  const [saved, setSaved] = useState<{ surah: boolean; all: boolean } | null>(null);
  const pages = surahPages(surah);
  useEffect(() => {
    let alive = true;
    void Promise.all([printedSavedIn(pages), printedSavedIn(ALL_PAGES)]).then(
      ([s, a]) => alive && setSaved({ surah: s, all: a }),
    );
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [surah]);
  const canSave = printedOfflineSupported();
  const download = (list: readonly number[]) => {
    onClose();
    if (!printed) prefsStore.set((p) => ({ ...p, mushafPrinted: true, mushafPrintedV: 3 }));
    void startPrintedDownload(list);
  };
  const madina = t(locale, "reader.fontMadina");
  const uthmani = t(locale, "reader.fontUthmani");
  return (
    <div className="rd-font-menu" role="dialog" aria-label={t(locale, "reader.fontMenuTitle")} data-testid="font-menu">
      <div className="rd-font-menu-head">
        <strong>{t(locale, "reader.fontMenuTitle")}</strong>
        <button type="button" className="rd-printed-x" aria-label={t(locale, "common.close")} onClick={onClose}>
          ✕
        </button>
      </div>
      <button
        type="button"
        className="rd-font-opt"
        data-testid="font-opt-switch"
        onClick={() => {
          prefsStore.set((p) => ({ ...p, mushafPrinted: !printed, mushafPrintedV: 3 }));
          onClose();
        }}
      >
        <span>{t(locale, "reader.fontOptSwitch", { font: printed ? uthmani : madina })}</span>
        <small>{t(locale, "reader.fontNow", { font: printed ? madina : uthmani })}</small>
      </button>
      {canSave ? (
        <>
          <button
            type="button"
            className="rd-font-opt"
            data-testid="font-opt-surah"
            disabled={j.running || saved?.surah === true}
            onClick={() => download(pages)}
          >
            <span>
              {saved?.surah ? "✓ " : "⬇ "}
              {t(locale, "reader.fontOptSurah", { name: surahMeta(surah)?.nameAr ?? String(surah) })}
            </span>
            {saved?.surah ? <small>{t(locale, "reader.fontSaved")}</small> : null}
          </button>
          <button
            type="button"
            className="rd-font-opt"
            data-testid="font-opt-all"
            disabled={j.running || saved?.all === true}
            onClick={() => download(ALL_PAGES)}
          >
            <span>
              {saved?.all ? "✓ " : "⬇ "}
              {t(locale, "reader.fontOptAll")}
            </span>
            <small>{saved?.all ? t(locale, "reader.fontSaved") : t(locale, "reader.fontOptHint")}</small>
          </button>
        </>
      ) : null}
    </div>
  );
}

/** The running Madina-font download: progress, then «محفوظ» or «تعذّر» with ✕. */
export function PrintedDownloadBar({ locale }: { locale: Locale }) {
  const j = useJob();
  if (!j.running && !j.finished) return null;
  if (j.running) {
    return (
      <div className="rd-printed-bar" data-testid="printed-download-bar" role="status">
        <progress max={j.total} value={j.done} aria-hidden="true" />
        <span>
          {t(locale, "reader.printedProgress", {
            done: localizeDigits(j.done, locale),
            total: localizeDigits(j.total, locale),
          })}
        </span>
      </div>
    );
  }
  return (
    <div className="rd-printed-bar" data-testid="printed-download-bar" role="status">
      <span>{j.failed ? t(locale, "reader.printedFailed") : `✓ ${t(locale, "reader.fontSaved")}`}</span>
      <button type="button" className="rd-printed-x" aria-label={t(locale, "common.close")} onClick={dismissPrintedJob}>
        ✕
      </button>
    </div>
  );
}
