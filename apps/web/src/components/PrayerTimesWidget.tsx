"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { nextPrayer, todayTimes } from "@/lib/next-prayer";
import type { PrayerKey } from "@/lib/prayer";
import { formatClock, formatCountdown } from "@/lib/time";
import { gregorianDay, hijriDate, weekdayName } from "@/lib/dates";
import { prayerStore, prefsStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";

/** The six times in the order of the day (sunrise is shown, never counted down to). */
export const WIDGET_TIMES: readonly PrayerKey[] = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"];

/**
 * The phone's wide prayer widget as a card on the website home (owner 2026-11-22: browsers have no
 * widgets, so the site gets the same layout). One side lists the six times with the next prayer in gold;
 * the other is a panel with the day, the Hijri and Gregorian dates, the next prayer and a live countdown.
 * Colours follow the user's colour style (the brand hero colours).
 */
export function PrayerTimesWidget({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const display = useStore(prefsStore);
  const now = useNow();
  if (!now) return null;
  const loc = resolveLocation(prefs);
  const q = { ...loc, asr: prefs.asr, adjustments: prefs.adjustments };
  let next: { key: PrayerKey; at: Date };
  let listedDay: Date;
  try {
    next = nextPrayer(now, q);
    // After Isha the next prayer is tomorrow's Fajr: then the card shows tomorrow.
    listedDay = next.at.getTime() === todayTimes(now, q).times[next.key].getTime() ? now : next.at;
  } catch {
    return null;
  }
  const listed = todayTimes(listedDay, q);
  const hhmm = (d: Date): string => localizeDigits(formatClock(d, loc.tz, display.clock, locale), locale);
  const hijri = hijriDate(listedDay, loc.tz, locale);
  return (
    <section className="prayer-widget" aria-label={t(locale, "home.widget")} data-testid="prayer-widget">
      <ol className="prayer-widget-list">
        {WIDGET_TIMES.map((k) => {
          const at = listed.times[k];
          const on = next.key === k && next.at.getTime() === at.getTime();
          return (
            <li key={k} className={on ? "on" : undefined} data-prayer={k}>
              <span>{t(locale, k === "sunrise" ? "home.sunrise" : `prayer.${k}`)}</span>
              <span className="prayer-widget-time">{hhmm(at)}</span>
              {on ? <span className="sr-only"> ({t(locale, "home.upNext")})</span> : null}
            </li>
          );
        })}
      </ol>
      <div className="prayer-widget-panel">
        <strong className="prayer-widget-day">{weekdayName(listedDay, loc.tz, locale)}</strong>
        {hijri ? <span>{hijri}</span> : null}
        <span>{gregorianDay(listedDay, loc.tz, locale)}</span>
        <strong className="prayer-widget-next" data-testid="prayer-widget-next">
          {t(locale, `prayer.${next.key}`)}
        </strong>
        <span className="prayer-widget-countdown" aria-live="off" data-testid="prayer-widget-countdown">
          {localizeDigits(formatCountdown(next.at.getTime() - now.getTime()), locale)}
        </span>
      </div>
    </section>
  );
}
