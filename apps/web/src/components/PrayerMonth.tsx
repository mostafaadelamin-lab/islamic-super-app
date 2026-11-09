"use client";
import { useMemo, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { PRAYER_KEYS, prayerTimes, type PrayerDay, type PrayerKey } from "@/lib/prayer";
import { formatClock, localDateInTz } from "@/lib/time";
import { prayerStore, prefsStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";

const MONTHS_PER_YEAR = 12;
/** A mid-month day, used only to format the month's name. */
const MID_MONTH_DAY = 15;

/** Number of days in a Gregorian month (month 1-12). */
export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** Moves a {year, month} by `delta` months. */
export function shiftMonth(
  ym: { year: number; month: number },
  delta: number,
): { year: number; month: number } {
  const i = ym.year * MONTHS_PER_YEAR + (ym.month - 1) + delta;
  return { year: Math.floor(i / MONTHS_PER_YEAR), month: (i % MONTHS_PER_YEAR) + 1 };
}

/** Hijri day number ("16") and month name for an instant, by Umm al-Qura; null if the engine lacks it. */
function hijriParts(d: Date, tz: string, locale: Locale): { day: string; month: string } | null {
  try {
    const f = new Intl.DateTimeFormat(
      locale === "ar" ? "ar-SA-u-ca-islamic-umalqura-nu-latn" : "en-u-ca-islamic-umalqura",
      {
        timeZone: tz,
        day: "numeric",
        month: "short",
      },
    );
    if (!f.resolvedOptions().calendar.startsWith("islamic")) return null;
    const out = Object.fromEntries(f.formatToParts(d).map((p) => [p.type, p.value])) as Record<
      string,
      string
    >;
    return { day: out.day ?? "", month: out.month ?? "" };
  } catch {
    return null;
  }
}

/** Monthly prayer timetable for the chosen location, with month arrows; today's row is highlighted. */
export function PrayerMonth({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const display = useStore(prefsStore);
  const now = useNow();
  const loc = resolveLocation(prefs);
  const today = now ? localDateInTz(now, loc.tz) : null;
  const [delta, setDelta] = useState(0);
  const ym = today ? shiftMonth({ year: today.year, month: today.month }, delta) : null;

  const rows = useMemo((): { day: number; pd: PrayerDay | null }[] => {
    if (!ym) return [];
    const days = Array.from({ length: daysInMonth(ym.year, ym.month) }, (_, i) => i + 1);
    return days.map((day) => {
      try {
        return {
          day,
          pd: prayerTimes({ ...ym, day }, loc.lat, loc.lng, loc.method, prefs.asr, prefs.adjustments),
        };
      } catch {
        return { day, pd: null };
      }
    });
  }, [ym?.year, ym?.month, loc.lat, loc.lng, loc.method, prefs.asr, prefs.adjustments]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!ym) return null;
  const monthTitle = new Intl.DateTimeFormat(locale === "ar" ? "ar-EG-u-nu-arab" : "en-GB", {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(ym.year, ym.month - 1, MID_MONTH_DAY)));
  const name = (k: PrayerKey): string => t(locale, `prayer.${k}`);
  const isToday = (day: number): boolean =>
    !!today && today.year === ym.year && today.month === ym.month && today.day === day;

  return (
    <section className="card" id="month" aria-labelledby="month-h" data-testid="prayer-month">
      <h2 id="month-h" style={{ marginTop: 0 }}>
        {t(locale, "prayer.monthTitle")}
      </h2>
      <div className="day-nav">
        <button
          type="button"
          className="btn day-nav-btn"
          aria-label={t(locale, "prayer.prevMonth")}
          onClick={() => setDelta((d) => d - 1)}
          data-testid="month-prev"
        >
          {locale === "ar" ? "›" : "‹"}
        </button>
        <div className="day-nav-label">
          <strong data-testid="month-label">{monthTitle}</strong>
        </div>
        <button
          type="button"
          className="btn day-nav-btn"
          aria-label={t(locale, "prayer.nextMonth")}
          onClick={() => setDelta((d) => d + 1)}
          data-testid="month-next"
        >
          {locale === "ar" ? "‹" : "›"}
        </button>
      </div>
      <div className="month-scroll">
        <table className="times month-table" data-testid="month-table">
          <thead>
            <tr>
              <th scope="col">{t(locale, "prayer.day")}</th>
              <th scope="col">{t(locale, "prayer.hijriCol")}</th>
              {PRAYER_KEYS.map((k) => (
                <th scope="col" key={k}>
                  {name(k)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map(({ day, pd }) => {
              const h = pd ? hijriParts(pd.times.dhuhr, loc.tz, locale) : null;
              return (
                <tr key={day} className={isToday(day) ? "next" : undefined} data-day={day}>
                  <th scope="row">{localizeDigits(day, locale)}</th>
                  <td className="muted">{h ? localizeDigits(`${h.day} ${h.month}`, locale) : ""}</td>
                  {PRAYER_KEYS.map((k) => (
                    <td className="time" key={k}>
                      {pd
                        ? localizeDigits(formatClock(pd.times[k], loc.tz, display.clock, locale), locale)
                        : "—"}
                    </td>
                  ))}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </section>
  );
}
