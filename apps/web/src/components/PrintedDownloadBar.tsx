"use client";

import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  downloadAllPrinted,
  PRINTED_PAGES,
  printedOfflineSupported,
  printedSavedCount,
} from "@/lib/mushaf-printed";

/**
 * Owner 2026-11-26: with the Madina font on, offer to save it once for the whole Mushaf and read without
 * internet. Pages already saved are never fetched again, so the offer goes away for good once all are saved.
 */
export function PrintedDownloadBar({ locale, enabled }: { locale: Locale; enabled: boolean }) {
  const [saved, setSaved] = useState<number | null>(null);
  const [done, setDone] = useState<number | null>(null);
  const [failed, setFailed] = useState(false);
  const [later, setLater] = useState(false);
  const [ran, setRan] = useState(false);
  const abort = useRef<AbortController | null>(null);

  useEffect(() => {
    if (!enabled || !printedOfflineSupported()) return;
    let alive = true;
    void printedSavedCount().then((n) => alive && setSaved(n));
    return () => {
      alive = false;
    };
  }, [enabled]);
  useEffect(() => () => abort.current?.abort(), []);

  if (!enabled || saved === null) return null;
  const all = saved >= PRINTED_PAGES;
  if ((all && !ran) || (later && done === null)) return null;

  const start = async () => {
    setRan(true);
    setFailed(false);
    setDone(0);
    abort.current = new AbortController();
    const ok = await downloadAllPrinted((n) => setDone(n), abort.current.signal);
    setFailed(!ok);
    setSaved(await printedSavedCount());
    setDone(null);
  };

  if (done !== null) {
    return (
      <div className="rd-printed-bar" data-testid="printed-download-bar" role="status">
        <progress max={PRINTED_PAGES} value={done} aria-hidden="true" />
        <span>
          {t(locale, "reader.printedProgress", {
            done: localizeDigits(done, locale),
            total: localizeDigits(PRINTED_PAGES, locale),
          })}
        </span>
      </div>
    );
  }
  if (all) {
    return (
      <div className="rd-printed-bar" data-testid="printed-download-bar" role="status">
        <span aria-hidden="true">✓</span>
        <span>{t(locale, "reader.printedSavedAll")}</span>
        <button type="button" className="rd-printed-x" aria-label={t(locale, "reader.printedLater")} onClick={() => setRan(false)}>
          ✕
        </button>
      </div>
    );
  }
  return (
    <div className="rd-printed-bar" data-testid="printed-download-bar">
      <span>{failed ? t(locale, "reader.printedFailed") : t(locale, "reader.printedOffer")}</span>
      <button type="button" className="rd-printed-later" data-testid="printed-download-later" onClick={() => setLater(true)}>
        {t(locale, "reader.printedLater")}
      </button>
      <button type="button" className="rd-printed-go" data-testid="printed-download-all" onClick={() => void start()}>
        {failed ? t(locale, "reader.printedResume") : t(locale, "reader.printedDownload")}
      </button>
    </div>
  );
}
