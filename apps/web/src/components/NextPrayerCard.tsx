"use client";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { nextPrayer, todayTimes } from "@/lib/next-prayer";
import { PRAYER_KEYS, type PrayerDay } from "@/lib/prayer";
import { formatCountdown, formatHHMM } from "@/lib/time";
import { gregorianDate, hijriDate } from "@/lib/dates";
import { prayerStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";
import { Icon } from "./Icon";

interface Computed {
  today: PrayerDay;
  next: ReturnType<typeof nextPrayer>;
}

/** Home hero (like the "Adhan" apps): place, dates, next prayer with a live countdown, today's times. */
export function NextPrayerCard({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const now = useNow();
  const loc = resolveLocation(prefs);
  const cityName = locale === "ar" ? loc.city?.nameAr : loc.city?.nameEn;
  const place = cityName ?? t(locale, "home.myPlace");
  const q = { ...loc, asr: prefs.asr, adjustments: prefs.adjustments };

  let computed: Computed | null = null;
  let error: string | null = null;
  if (now) {
    try {
      computed = { today: todayTimes(now, q), next: nextPrayer(now, q) };
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
    }
  }
  const next = computed?.next ?? null;

  return (
    <section className="hero" aria-labelledby="next-prayer-h" data-testid="prayer-hero">
      <div className="hero-top">
        <span className="hero-place" data-testid="home-place">
          <Icon name="location" size={18} /> {place}
        </span>
        {now ? (
          <span className="hero-dates">
            <span data-testid="home-hijri">{hijriDate(now, loc.tz, locale)}</span>
            <span data-testid="home-gregorian">{gregorianDate(now, loc.tz, locale)}</span>
          </span>
        ) : null}
      </div>
      <h2 id="next-prayer-h" className="hero-label">
        {t(locale, "home.nextPrayer")}
      </h2>
      {!now ? <p className="hero-name">{t(locale, "prayer.loading")}</p> : null}
      {error ? <p className="alert alert-error">{t(locale, "prayer.error", { msg: error })}</p> : null}
      {next && now ? (
        <>
          <p className="hero-name" data-testid="home-next-name">
            {t(locale, `prayer.${next.key}`)}{" "}
            <span className="hero-time">{localizeDigits(formatHHMM(next.at, loc.tz), locale)}</span>
          </p>
          <p className="hero-countdown">
            <span className="sr-only">{t(locale, "home.remaining")} </span>
            <span className="countdown" data-testid="home-countdown" aria-live="off">
              {localizeDigits(formatCountdown(next.at.getTime() - now.getTime()), locale)}
            </span>
          </p>
        </>
      ) : null}
      {computed ? (
        <ol className="hero-times" data-testid="home-times" aria-label={t(locale, "prayer.timesTable")}>
          {PRAYER_KEYS.map((k) => {
            const at = computed.today.times[k];
            const isNext = next?.key === k && next.at.getTime() === at.getTime();
            return (
              <li key={k} className={isNext ? "next" : undefined} data-prayer={k}>
                <span>{t(locale, `prayer.${k}`)}</span>
                <strong>{localizeDigits(formatHHMM(at, loc.tz), locale)}</strong>
                {isNext ? <span className="sr-only"> ({t(locale, "home.upNext")})</span> : null}
              </li>
            );
          })}
        </ol>
      ) : null}
      <Link className="hero-link" href={href(locale, "prayer")}>
        {t(locale, "home.openPrayer")}
      </Link>
    </section>
  );
}
