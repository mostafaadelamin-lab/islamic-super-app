"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { OBLIGATORY } from "@/lib/next-prayer";
import { addDays, isoDate } from "@/lib/time";
import type { LocalDate } from "@/lib/prayer";
import {
  dayOf,
  MAX_NOTE,
  monthStats,
  prayedCount,
  setFasting,
  setNote,
  streak,
  togglePrayer,
  weekStats,
  worshipStore,
  type WorshipStats,
} from "@/lib/worship";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";
import { shiftMonth, daysInMonth } from "./PrayerMonth";

const PERCENT = 100;
const SATURDAY = 6;
const WEEK = 7;
const MID_MONTH_DAY = 15;
/** 3 January 2026 was a Saturday: the first column of the calendar. */
const A_SATURDAY = Date.UTC(2026, 0, 3);
const DAY_MS = 86_400_000;

const localToday = (now: Date): LocalDate => ({
  year: now.getFullYear(),
  month: now.getMonth() + 1,
  day: now.getDate(),
});

function StatsCard({
  title,
  s,
  locale,
  testId,
}: {
  title: string;
  s: WorshipStats;
  locale: Locale;
  testId: string;
}) {
  const pct = s.possible ? Math.round((s.prayed / s.possible) * PERCENT) : 0;
  const n = (v: number): string => localizeDigits(v, locale);
  return (
    <div className="worship-stat" data-testid={testId}>
      <h3>{title}</h3>
      <p>
        {t(locale, "worship.prayedOf", { n: n(s.prayed), total: n(s.possible) })} ({n(pct)}%)
      </p>
      <progress max={s.possible} value={s.prayed} aria-label={title} />
      <p className="muted">
        {t(locale, "worship.fullDays", { n: n(s.fullDays) })} ·{" "}
        {t(locale, "worship.fasted", { n: n(s.fasted) })}
      </p>
    </div>
  );
}

/** Worship tracker: monthly calendar, the day's five prayers, fasting and a note, weekly / monthly totals and the streak. */
export function WorshipView({ locale }: { locale: Locale }) {
  const s = useStore(worshipStore);
  const now = useNow();
  const [delta, setDelta] = useState(0);
  const [picked, setPicked] = useState<string | null>(null);
  if (!now) return <p>{t(locale, "prayer.loading")}</p>;
  const today = localToday(now);
  const todayIso = isoDate(today);
  const selected = picked ?? todayIso;
  const day = dayOf(s, selected);
  const ym = shiftMonth({ year: today.year, month: today.month }, delta);
  const first = { ...ym, day: 1 };
  const lead = (new Date(Date.UTC(ym.year, ym.month - 1, 1)).getUTCDay() - SATURDAY + WEEK) % WEEK;
  const cells = Array.from({ length: daysInMonth(ym.year, ym.month) }, (_, i) => addDays(first, i));
  const weekdays = Array.from({ length: WEEK }, (_, i) =>
    new Intl.DateTimeFormat(locale === "ar" ? "ar-EG" : "en-GB", {
      weekday: "short",
      timeZone: "UTC",
    }).format(new Date(A_SATURDAY + i * DAY_MS)),
  );
  const monthTitle = new Intl.DateTimeFormat(locale === "ar" ? "ar-EG-u-nu-arab" : "en-GB", {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(ym.year, ym.month - 1, MID_MONTH_DAY)));
  const longDate = (iso: string): string =>
    new Intl.DateTimeFormat(locale === "ar" ? "ar-EG-u-nu-arab" : "en-GB", {
      weekday: "long",
      day: "numeric",
      month: "long",
      timeZone: "UTC",
    }).format(new Date(`${iso}T12:00:00Z`));
  const st = streak(s, today);

  return (
    <div className="worship">
      <p className="worship-streak" data-testid="worship-streak">
        {t(locale, "worship.streak", { n: localizeDigits(st, locale) })}
      </p>

      <section className="card" aria-labelledby="worship-month-h">
        <div className="day-nav">
          <button
            type="button"
            className="btn day-nav-btn"
            aria-label={t(locale, "prayer.prevMonth")}
            onClick={() => setDelta((d) => d - 1)}
            data-testid="worship-prev"
          >
            {locale === "ar" ? "›" : "‹"}
          </button>
          <div className="day-nav-label">
            <strong id="worship-month-h" data-testid="worship-month">
              {monthTitle}
            </strong>
          </div>
          <button
            type="button"
            className="btn day-nav-btn"
            aria-label={t(locale, "prayer.nextMonth")}
            onClick={() => setDelta((d) => d + 1)}
            disabled={delta >= 0}
            data-testid="worship-next"
          >
            {locale === "ar" ? "‹" : "›"}
          </button>
        </div>
        <div className="worship-grid" data-testid="worship-grid">
          {weekdays.map((w) => (
            <span key={w} className="worship-wd muted" aria-hidden="true">
              {w}
            </span>
          ))}
          {Array.from({ length: lead }, (_, i) => (
            <span key={`pad-${i}`} aria-hidden="true" />
          ))}
          {cells.map((c) => {
            const iso = isoDate(c);
            const d = dayOf(s, iso);
            const n = prayedCount(d);
            const future = iso > todayIso;
            const cls = [
              "worship-cell",
              iso === selected ? "selected" : "",
              iso === todayIso ? "today" : "",
              n === OBLIGATORY.length ? "full" : "",
            ]
              .filter(Boolean)
              .join(" ");
            return (
              <button
                key={iso}
                type="button"
                className={cls}
                disabled={future}
                aria-pressed={iso === selected}
                aria-label={`${longDate(iso)}: ${t(locale, "worship.prayedOf", {
                  n: localizeDigits(n, locale),
                  total: localizeDigits(OBLIGATORY.length, locale),
                })}${d.fasting ? ` · ${t(locale, "worship.fasting")}` : ""}`}
                onClick={() => setPicked(iso)}
                data-day={iso}
              >
                <span className="worship-num">{localizeDigits(c.day, locale)}</span>
                <span className="worship-dots" aria-hidden="true">
                  {n > 0 ? localizeDigits(`${n}/${OBLIGATORY.length}`, locale) : ""}
                  {d.fasting ? " ◐" : ""}
                </span>
              </button>
            );
          })}
        </div>
      </section>

      <section className="card" aria-labelledby="worship-day-h" data-testid="worship-day">
        <h2 id="worship-day-h" style={{ marginTop: 0 }}>
          {selected === todayIso ? t(locale, "worship.today") : longDate(selected)}
        </h2>
        <fieldset className="adhan-prayers">
          <legend className="muted">{t(locale, "worship.prayers")}</legend>
          {OBLIGATORY.map((k) => (
            <label className="check" key={k}>
              <input
                type="checkbox"
                checked={!!day.prayers[k]}
                onChange={() => worshipStore.set((p) => togglePrayer(p, selected, k))}
                data-testid={`worship-${k}`}
              />{" "}
              {t(locale, `prayer.${k}`)}
            </label>
          ))}
        </fieldset>
        <label className="check">
          <input
            type="checkbox"
            checked={day.fasting}
            onChange={(e) => worshipStore.set((p) => setFasting(p, selected, e.target.checked))}
            data-testid="worship-fasting"
          />{" "}
          {t(locale, "worship.fasting")}
        </label>
        <div className="field">
          <label htmlFor="worship-note">{t(locale, "worship.note")}</label>
          <textarea
            id="worship-note"
            rows={2}
            maxLength={MAX_NOTE}
            value={day.note}
            onChange={(e) => worshipStore.set((p) => setNote(p, selected, e.target.value))}
          />
        </div>
      </section>

      <section className="card worship-stats" aria-label={t(locale, "worship.stats")}>
        <StatsCard
          title={t(locale, "worship.week")}
          s={weekStats(s, today)}
          locale={locale}
          testId="worship-week"
        />
        <StatsCard
          title={t(locale, "worship.month")}
          s={monthStats(s, ym.year, ym.month, today)}
          locale={locale}
          testId="worship-month-stats"
        />
      </section>
      <p className="muted">{t(locale, "worship.private")}</p>
    </div>
  );
}
