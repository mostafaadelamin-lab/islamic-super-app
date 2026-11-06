"use client";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { nextPrayer } from "@/lib/next-prayer";
import { formatCountdown, formatHHMM } from "@/lib/time";
import { prayerStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";

export function NextPrayerCard({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const now = useNow();
  const loc = resolveLocation(prefs);
  let body: React.ReactNode = <p className="muted">{t(locale, "prayer.loading")}</p>;
  if (now) {
    try {
      const np = nextPrayer(now, { ...loc, asr: prefs.asr, adjustments: prefs.adjustments });
      const name = t(locale, `prayer.${np.key}`);
      body = (
        <>
          <p style={{ margin: 0 }}>
            {t(locale, "prayer.next", { name })} — {localizeDigits(formatHHMM(np.at, loc.tz), locale)}
          </p>
          <p className="countdown" data-testid="home-countdown" aria-live="off">
            {localizeDigits(formatCountdown(np.at.getTime() - now.getTime()), locale)}
          </p>
          <p className="muted">{loc.city ? (locale === "ar" ? loc.city.nameAr : loc.city.nameEn) : loc.tz}</p>
        </>
      );
    } catch (e) {
      body = (
        <p className="alert alert-error">
          {t(locale, "prayer.error", { msg: e instanceof Error ? e.message : String(e) })}
        </p>
      );
    }
  }
  return (
    <section className="card" aria-labelledby="next-prayer-h">
      <h2 id="next-prayer-h" style={{ marginTop: 0 }}>
        {t(locale, "home.nextPrayer")}
      </h2>
      {body}
      <Link className="btn" href={href(locale, "prayer")}>
        {t(locale, "home.openPrayer")}
      </Link>
    </section>
  );
}
