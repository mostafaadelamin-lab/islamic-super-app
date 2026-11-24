"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { withBase } from "@/lib/base-path";

/**
 * Bar at the top of every page while the site is being uploaded or changed (owner 2026-11-24):
 * new services are on the way, and anything that stops working comes back by itself.
 * The upload script (builds/ftp_deploy.py) writes /site-status.json with {"updating": true} before
 * it sends files and {"updating": false} when it is done. The file is not part of the build (a missing
 * file means no bar), so an upload never switches the bar off half-way by sending an old copy.
 * The page reads it on load, every minute and when the tab comes back, so the bar shows and goes away
 * without a reload.
 */
export type SiteStatus = { updating: boolean; message_ar?: string; message_en?: string };

export const SITE_STATUS_PATH = "/site-status.json";
const CHECK_EVERY_MS = 60_000;

export function parseSiteStatus(v: unknown): SiteStatus {
  if (!v || typeof v !== "object") return { updating: false };
  const o = v as Record<string, unknown>;
  const text = (x: unknown) => (typeof x === "string" && x.trim() ? x.trim() : undefined);
  return { updating: o.updating === true, message_ar: text(o.message_ar), message_en: text(o.message_en) };
}

export function MaintenanceBanner({ locale }: { locale: Locale }) {
  const [status, setStatus] = useState<SiteStatus | null>(null);
  const [closed, setClosed] = useState(false);

  useEffect(() => {
    let alive = true;
    const check = async () => {
      try {
        const res = await fetch(withBase(`${SITE_STATUS_PATH}?t=${Date.now()}`), { cache: "no-store" });
        // No file (or an error page) means no upload is running.
        const s = res.ok ? parseSiteStatus(await res.json()) : { updating: false };
        if (!alive) return;
        setStatus(s.updating ? s : null);
        if (!s.updating) setClosed(false); // a later upload shows the bar again
      } catch {
        // Offline or a half-uploaded file: keep what is shown now.
      }
    };
    void check();
    const timer = setInterval(() => void check(), CHECK_EVERY_MS);
    const onVisible = () => {
      if (document.visibilityState === "visible") void check();
    };
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      alive = false;
      clearInterval(timer);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, []);

  if (!status || closed) return null;
  const custom = locale === "ar" ? status.message_ar : status.message_en;
  return (
    <div className="maintenance-banner" role="status" data-testid="maintenance-banner">
      <span aria-hidden="true" className="maintenance-banner__icon">
        ⟳
      </span>
      <span className="maintenance-banner__text">{custom ?? t(locale, "maintenance.message")}</span>
      <button
        type="button"
        className="maintenance-banner__close"
        aria-label={t(locale, "maintenance.close")}
        data-testid="maintenance-close"
        onClick={() => setClosed(true)}
      >
        ×
      </button>
    </div>
  );
}
