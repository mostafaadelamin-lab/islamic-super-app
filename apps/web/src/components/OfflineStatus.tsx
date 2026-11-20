"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  currentOfflineStatus,
  requestOfflineStatus,
  saveSiteOffline,
  stopSiteOffline,
  subscribeOfflineStatus,
  type OfflineStatus as Status,
} from "@/lib/sw-client";

export function OfflineStatus({ locale }: { locale: Locale }) {
  const [s, setS] = useState<Status>(() => currentOfflineStatus());
  const [supported, setSupported] = useState(true);
  useEffect(() => {
    setSupported(typeof navigator !== "undefined" && "serviceWorker" in navigator);
    const unsub = subscribeOfflineStatus(setS);
    requestOfflineStatus();
    return () => {
      unsub();
    };
  }, []);
  let text: string;
  if (!supported || !s.supported) text = t(locale, "settings.offlineUnsupported");
  else if (s.complete) text = t(locale, "settings.offlineComplete");
  else if (s.total > 0 && !s.saved)
    text = t(locale, "settings.offlineAsk", { mb: localizeDigits(s.mb, locale) });
  else if (s.total > 0)
    text = t(locale, "settings.offlineProgress", {
      done: localizeDigits(s.done, locale),
      total: localizeDigits(s.total, locale),
    });
  else text = t(locale, "settings.offlineWaiting");
  return (
    <section className="card" aria-labelledby="offline-h">
      <h2 id="offline-h" style={{ marginTop: 0 }}>
        {t(locale, "settings.offline")}
      </h2>
      <p role="status" data-testid="offline-status">
        {text}
      </p>
      {supported && s.supported && s.total > 0 && !s.saved && !s.complete ? (
        <button
          type="button"
          className="btn btn-primary"
          data-testid="offline-save"
          onClick={() => {
            setS((x) => ({ ...x, saved: true }));
            saveSiteOffline();
          }}
        >
          {t(locale, "settings.offlineSave")}
        </button>
      ) : null}
      {s.saved && s.total > 0 && !s.complete ? (
        <progress
          max={s.total}
          value={s.done}
          aria-label={t(locale, "settings.offline")}
          style={{ width: "100%" }}
        />
      ) : null}
      {s.saved && s.total > 0 && !s.complete ? (
        // Owner 2026-11-18: a running offline download must be easy to stop (e.g. on mobile data).
        <button
          type="button"
          className="btn"
          data-testid="offline-stop"
          onClick={() => {
            setS((x) => ({ ...x, saved: false }));
            stopSiteOffline();
          }}
        >
          {t(locale, "settings.offlineStop")}
        </button>
      ) : null}
    </section>
  );
}
