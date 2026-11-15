"use client";
import { usePlaceName } from "@/hooks/usePlaceName";
import { useMemo, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { PRAYER_KEYS, prayerTimes, type LocalDate, type PrayerDay, type PrayerKey } from "@/lib/prayer";
import { addDays, formatClock, localDateInTz } from "@/lib/time";
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

const DAY_MS = 86_400_000;
/** Mean length of a lunar month, to step between Hijri months. */
const LUNAR_MONTH_DAYS = 29.53;
/** Days searched on each side of a Hijri month's middle for its days (a month has at most 30). */
const HIJRI_SEARCH_DAYS = 20;
const HIJRI_MID_DAY = 15;
const NOON_UTC = 12;

export type CalendarKind = "gregorian" | "hijri";

const noon = (d: LocalDate, offsetDays = 0): Date =>
  new Date(Date.UTC(d.year, d.month - 1, d.day, NOON_UTC) + offsetDays * DAY_MS);

/** Umm al-Qura date (numbers) of a civil date, shifted by the user's offset; null if the engine lacks it. */
export function hijriOf(d: LocalDate, offsetDays: number): LocalDate | null {
  try {
    const f = new Intl.DateTimeFormat("en-u-ca-islamic-umalqura-nu-latn", {
      timeZone: "UTC",
      day: "numeric",
      month: "numeric",
      year: "numeric",
    });
    if (!f.resolvedOptions().calendar.startsWith("islamic")) return null;
    const out = Object.fromEntries(f.formatToParts(noon(d, offsetDays)).map((p) => [p.type, p.value]));
    const n = (v: string | undefined): number => parseInt(v ?? "", 10);
    const r = { year: n(out.year), month: n(out.month), day: n(out.day) };
    return Number.isFinite(r.year + r.month + r.day) ? r : null;
  } catch {
    return null;
  }
}

/** The civil days of the Hijri month `delta` months away from the one holding `today`. */
export function hijriMonthDays(today: LocalDate, delta: number, offsetDays: number): LocalDate[] {
  const h = hijriOf(today, offsetDays);
  if (!h) return [];
  const mid = addDays(today, HIJRI_MID_DAY - h.day + Math.round(delta * LUNAR_MONTH_DAYS));
  const target = hijriOf(mid, offsetDays);
  if (!target) return [];
  return Array.from({ length: 2 * HIJRI_SEARCH_DAYS + 1 }, (_, i) =>
    addDays(mid, i - HIJRI_SEARCH_DAYS),
  ).filter((d) => {
    const x = hijriOf(d, offsetDays);
    return !!x && x.year === target.year && x.month === target.month;
  });
}

/** "16 Jumada I" style label (day + short month) in the chosen calendar. */
function dayLabel(d: LocalDate, kind: CalendarKind, offsetDays: number, locale: Locale): string {
  const cal = kind === "hijri" ? "gregory" : "islamic-umalqura";
  try {
    const f = new Intl.DateTimeFormat(locale === "ar" ? `ar-SA-u-ca-${cal}-nu-latn` : `en-GB-u-ca-${cal}`, {
      timeZone: "UTC",
      day: "numeric",
      month: "short",
    });
    if (kind === "gregorian" && !f.resolvedOptions().calendar.startsWith("islamic")) return "";
    return f.format(noon(d, kind === "gregorian" ? offsetDays : 0));
  } catch {
    return "";
  }
}

const sameDay = (a: LocalDate | null, b: LocalDate): boolean =>
  !!a && a.year === b.year && a.month === b.month && a.day === b.day;

/** Prints only the monthly table (the browser's print dialog also saves it as PDF). */
function printMonth(): void {
  const root = document.documentElement;
  root.classList.add("print-month");
  const done = (): void => {
    root.classList.remove("print-month");
    window.removeEventListener("afterprint", done);
  };
  window.addEventListener("afterprint", done);
  try {
    window.print();
  } finally {
    // Some browsers return from print() only after the dialog closes; others never fire afterprint.
    setTimeout(done, 0);
  }
}

/** Monthly prayer timetable (Gregorian or Hijri month) for the chosen location; today's row is highlighted. */
export function PrayerMonth({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const gpsPlace = usePlaceName(locale);
  const display = useStore(prefsStore);
  const now = useNow();
  const loc = resolveLocation(prefs);
  const today = now ? localDateInTz(now, loc.tz) : null;
  const [delta, setDelta] = useState(0);
  const [kind, setKind] = useState<CalendarKind>("gregorian");
  const [shared, setShared] = useState(false);
  const offset = display.hijriOffset;
  const ym = today ? shiftMonth({ year: today.year, month: today.month }, delta) : null;

  const days = useMemo((): LocalDate[] => {
    if (!today || !ym) return [];
    if (kind === "hijri") return hijriMonthDays(today, delta, offset);
    return Array.from({ length: daysInMonth(ym.year, ym.month) }, (_, i) => ({ ...ym, day: i + 1 }));
  }, [kind, delta, offset, today?.year, today?.month, today?.day]); // eslint-disable-line react-hooks/exhaustive-deps

  const rows = useMemo(
    (): { date: LocalDate; pd: PrayerDay | null }[] =>
      days.map((date) => {
        try {
          return {
            date,
            pd: prayerTimes(date, loc.lat, loc.lng, loc.method, prefs.asr, prefs.adjustments),
          };
        } catch {
          return { date, pd: null };
        }
      }),
    [days, loc.lat, loc.lng, loc.method, prefs.asr, prefs.adjustments],
  );

  if (!ym) return null;
  const first = days[0];
  const hijriTitle = (): string => {
    if (!first) return "";
    try {
      return new Intl.DateTimeFormat(
        locale === "ar" ? "ar-SA-u-ca-islamic-umalqura-nu-arab" : "en-u-ca-islamic-umalqura",
        { timeZone: "UTC", month: "long", year: "numeric" },
      ).format(noon(first, offset));
    } catch {
      return "";
    }
  };
  const monthTitle =
    kind === "hijri"
      ? hijriTitle()
      : new Intl.DateTimeFormat(locale === "ar" ? "ar-EG-u-nu-arab" : "en-GB", {
          month: "long",
          year: "numeric",
          timeZone: "UTC",
        }).format(new Date(Date.UTC(ym.year, ym.month - 1, MID_MONTH_DAY)));
  const name = (k: PrayerKey): string => t(locale, `prayer.${k}`);
  const dayNumber = (d: LocalDate): number => (kind === "hijri" ? (hijriOf(d, offset)?.day ?? d.day) : d.day);
  /** The app shares the month (there as a picture); the site shares it as text, or copies it. */
  const shareMonth = async (): Promise<void> => {
    const place =
      gpsPlace ??
      (loc.city ? (locale === "ar" ? loc.city.nameAr : loc.city.nameEn) : t(locale, "home.myPlace"));
    const title = `${t(locale, "prayer.monthTitle")} · ${monthTitle} · ${place}`;
    const lines = rows.map(({ date, pd }) =>
      [
        localizeDigits(dayNumber(date), locale),
        ...PRAYER_KEYS.map((k) =>
          pd
            ? `${name(k)} ${localizeDigits(formatClock(pd.times[k], loc.tz, display.clock, locale), locale)}`
            : "—",
        ),
      ].join(" | "),
    );
    const text = [title, ...lines].join("\n");
    try {
      if (typeof navigator !== "undefined" && navigator.share) await navigator.share({ title, text });
      else {
        await navigator.clipboard.writeText(text);
        setShared(true);
      }
    } catch {
      /* the viewer closed the share sheet */
    }
  };
  const switchKind = (k: CalendarKind): void => {
    setKind(k);
    setDelta(0);
  };

  return (
    <section className="card month-card" id="month" aria-labelledby="month-h" data-testid="prayer-month">
      <h2 id="month-h" style={{ marginTop: 0 }}>
        {t(locale, "prayer.monthTitle")}
      </h2>
      <div className="month-tools no-print">
        <div className="segmented" role="group" aria-label={t(locale, "prayer.calendarKind")}>
          {(["gregorian", "hijri"] as const).map((k) => (
            <button
              key={k}
              type="button"
              aria-pressed={kind === k}
              onClick={() => switchKind(k)}
              data-testid={`month-kind-${k}`}
            >
              {t(locale, `prayer.kind.${k}`)}
            </button>
          ))}
        </div>
        <button type="button" className="btn" onClick={printMonth} data-testid="month-print">
          {t(locale, "prayer.printMonth")}
        </button>
        <button type="button" className="btn" onClick={() => void shareMonth()} data-testid="month-share">
          {t(locale, "prayer.shareCalendar")}
        </button>
        {shared ? (
          <span className="muted small" role="status">
            {t(locale, "prayer.calendarCopied")}
          </span>
        ) : null}
      </div>
      <div className="day-nav">
        <button
          type="button"
          className="btn day-nav-btn no-print"
          aria-label={t(locale, "prayer.prevMonth")}
          onClick={() => setDelta((d) => d - 1)}
          data-testid="month-prev"
        >
          {locale === "ar" ? "›" : "‹"}
        </button>
        <div className="day-nav-label">
          <strong data-testid="month-label">{monthTitle}</strong>
          {loc.city ? (
            <span className="muted print-only">{locale === "ar" ? loc.city.nameAr : loc.city.nameEn}</span>
          ) : null}
        </div>
        <button
          type="button"
          className="btn day-nav-btn no-print"
          aria-label={t(locale, "prayer.nextMonth")}
          onClick={() => setDelta((d) => d + 1)}
          data-testid="month-next"
        >
          {locale === "ar" ? "‹" : "›"}
        </button>
      </div>
      <div className="month-scroll">
        <table className="times month-table" data-testid="month-table" data-kind={kind}>
          <thead>
            <tr>
              <th scope="col">{t(locale, "prayer.day")}</th>
              <th scope="col">{t(locale, kind === "hijri" ? "prayer.gregorianCol" : "prayer.hijriCol")}</th>
              {PRAYER_KEYS.map((k) => (
                <th scope="col" key={k}>
                  {name(k)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map(({ date, pd }) => (
              <tr
                key={`${date.year}-${date.month}-${date.day}`}
                className={sameDay(today, date) ? "next" : undefined}
                data-day={date.day}
              >
                <th scope="row">{localizeDigits(dayNumber(date), locale)}</th>
                <td className="muted">{localizeDigits(dayLabel(date, kind, offset, locale), locale)}</td>
                {PRAYER_KEYS.map((k) => (
                  <td className="time" key={k}>
                    {pd
                      ? localizeDigits(formatClock(pd.times[k], loc.tz, display.clock, locale), locale)
                      : "—"}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
