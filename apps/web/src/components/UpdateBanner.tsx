"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { subscribeUpdate } from "@/lib/sw-client";

/** «تحديث جديد متاح»: shown when a new version of the site was uploaded while the page is open. */
export function UpdateBanner({ locale }: { locale: Locale }) {
  const [ready, setReady] = useState(false);
  useEffect(() => subscribeUpdate(() => setReady(true)), []);
  if (!ready) return null;
  return (
    <div className="update-banner" role="status" data-testid="update-banner">
      <span>{t(locale, "update.available")}</span>
      <button
        type="button"
        className="btn btn-primary"
        data-testid="update-reload"
        onClick={() => window.location.reload()}
      >
        {t(locale, "update.reload")}
      </button>
      <button
        type="button"
        className="btn"
        aria-label={t(locale, "update.later")}
        onClick={() => setReady(false)}
      >
        {t(locale, "update.later")}
      </button>
    </div>
  );
}
