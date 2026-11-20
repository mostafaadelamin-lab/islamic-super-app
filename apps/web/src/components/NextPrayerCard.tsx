"use client";
import { usePlaceName } from "@/hooks/usePlaceName";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { nextPrayer, OBLIGATORY, todayTimes } from "@/lib/next-prayer";
import type { PrayerDay, PrayerKey } from "@/lib/prayer";
import { formatClock, formatCountdown } from "@/lib/time";
import { gregorianDay, hijriDate, weekdayName } from "@/lib/dates";
import { prayerStore, prefsStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";
import { Icon, type IconName } from "./Icon";
import { MosqueArt } from "./MosqueArt";

const MINUTE_MS = 60_000;
/** How long after a prayer's adhan the home card says how much time has passed since it. */
export const ELAPSED_WINDOW_MIN = 30;

/** The obligatory prayer whose adhan was less than ELAPSED_WINDOW_MIN ago, with the minutes since it. */
export function recentPrayer(now: Date, today: PrayerDay): { key: PrayerKey; minutes: number } | null {
  const past = OBLIGATORY.map((key) => ({ key, ms: now.getTime() - today.times[key].getTime() })).filter(
    (p) => p.ms >= 0 && p.ms < ELAPSED_WINDOW_MIN * MINUTE_MS,
  );
  const last = past[past.length - 1];
  return last ? { key: last.key, minutes: Math.floor(last.ms / MINUTE_MS) } : null;
}

interface Computed {
  today: PrayerDay;
  next: ReturnType<typeof nextPrayer>;
}

const PRAYER_ICON: Record<PrayerKey, IconName> = {
  fajr: "moon",
  sunrise: "sunrise",
  dhuhr: "sunHigh",
  asr: "sunLow",
  maghrib: "sunset",
  isha: "moon",
};

/**
 * Home top (owner's mockup, 2026-11-09): place, mosque art, next prayer with its time and a live
 * countdown; then the day card (weekday, Gregorian + Hijri dates, prayer calendar link), the five prayers and
 * sunrise / sunset.
 */
export function NextPrayerCard({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const display = useStore(prefsStore);
  const now = useNow();
  const loc = resolveLocation(prefs);
  const city = loc.city;
  const cityLabel = locale === "ar" && city ? `${city.countryAr} - ${city.nameAr}` : city?.nameEn;
  const gpsPlace = usePlaceName(locale);
  const place = gpsPlace ?? cityLabel ?? t(locale, "home.myPlace");
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
  // After Isha the next prayer is tomorrow's Fajr: the list then shows tomorrow's times, with Fajr marked.
  const tomorrow = !!computed && !!next && next.at.getTime() !== computed.today.times[next.key].getTime();
  const listed = computed && next && tomorrow ? todayTimes(next.at, q) : (computed?.today ?? null);
  // Sunset is the astronomical Maghrib time, without the user's Maghrib adjustment.
  const sunset = listed
    ? new Date(listed.times.maghrib.getTime() - Math.trunc(prefs.adjustments?.maghrib ?? 0) * MINUTE_MS)
    : null;
  const hhmm = (d: Date): string => localizeDigits(formatClock(d, loc.tz, display.clock, locale), locale);
  const hijri = now ? hijriDate(now, loc.tz, locale) : null;
  const recent = now && computed ? recentPrayer(now, computed.today) : null;

  return (
    <>
      <section className="home-hero" aria-labelledby="next-prayer-h" data-testid="prayer-hero">
        <div className="home-hero-top">
          <div className="home-place">
            <Icon name="location" size={22} />
            <span>
              <span className="home-place-label">{t(locale, "home.timingFor")}</span>
              <strong data-testid="home-place">{place}</strong>
            </span>
          </div>
          {/* No settings button here (owner, 2026-11-15): the prayer settings are on the prayer page. */}
        </div>
        <div className="home-hero-body">
          <MosqueArt />
          <div className="home-next">
            <h2 id="next-prayer-h" className="sr-only">
              {t(locale, "home.nextPrayer")}
            </h2>
            {!now ? <p className="home-next-name">{t(locale, "prayer.loading")}</p> : null}
            {error ? <p className="alert alert-error">{t(locale, "prayer.error", { msg: error })}</p> : null}
            {next && now ? (
              <>
                <p className="home-next-name" data-testid="home-next-name">
                  {t(locale, "home.prayerOf", { name: t(locale, `prayer.${next.key}`) })}
                </p>
                <p className="home-next-time" data-testid="home-next-time">
                  {/* 12 h (the default): the AM/PM mark small beside the big time, on the same line. */}
                  {hhmm(next.at)
                    .split(" ")
                    .map((part, i) => (i === 0 ? part : <small key={i}> {part}</small>))}
                </p>
                <p className="home-left">
                  <span>{t(locale, "home.left")} </span>
                  <span className="countdown" data-testid="home-countdown" aria-live="off">
                    {localizeDigits(formatCountdown(next.at.getTime() - now.getTime()), locale)}
                  </span>
                </p>
                {recent ? (
                  <p className="home-elapsed" data-testid="home-elapsed">
                    {t(locale, "home.elapsed", {
                      name: t(locale, `prayer.${recent.key}`),
                      n: localizeDigits(recent.minutes, locale),
                    })}
                  </p>
                ) : null}
              </>
            ) : null}
          </div>
        </div>
      </section>

      <section className="card home-day" aria-label={t(locale, "prayer.timesTable")}>
        <div className="home-day-top">
          <div className="home-dates">
            {now ? (
              <>
                <strong className="home-weekday" data-testid="home-weekday">
                  {weekdayName(tomorrow && next ? next.at : now, loc.tz, locale)}
                </strong>
                <span className="home-date-lines">
                  <span data-testid="home-gregorian">
                    {gregorianDay(tomorrow && next ? next.at : now, loc.tz, locale)}
                  </span>
                  {hijri ? (
                    <span className="home-hijri" data-testid="home-hijri">
                      {hijri}
                    </span>
                  ) : null}
                </span>
              </>
            ) : null}
          </div>
          <Link className="home-calendar" href={`${href(locale, "prayer")}#month`}>
            <Icon name="calendar" size={20} />
            {t(locale, "home.calendar")}
          </Link>
        </div>
        {tomorrow ? (
          <p className="home-times-day" data-testid="home-times-day">
            {t(locale, "home.tomorrowTimes")}
          </p>
        ) : null}
        {listed ? (
          <>
            <ol
              className="home-times"
              data-testid="home-times"
              data-day={tomorrow ? "tomorrow" : "today"}
              aria-label={tomorrow ? t(locale, "home.tomorrowTimes") : t(locale, "prayer.timesTable")}
            >
              {OBLIGATORY.map((k) => {
                const at = listed.times[k];
                const isNext = next?.key === k && next.at.getTime() === at.getTime();
                return (
                  <li key={k} className={isNext ? "next" : undefined} data-prayer={k}>
                    <Icon name={PRAYER_ICON[k]} size={22} />
                    <span>{t(locale, `prayer.${k}`)}</span>
                    <strong>{hhmm(at)}</strong>
                    {isNext ? <span className="sr-only"> ({t(locale, "home.upNext")})</span> : null}
                  </li>
                );
              })}
            </ol>
            <p className="home-sun" data-testid="home-sun">
              <span>
                <Icon name="sunrise" size={18} /> {t(locale, "home.sunrise")}{" "}
                <strong data-testid="home-sunrise">{hhmm(listed.times.sunrise)}</strong>
              </span>
              <span>
                <Icon name="sunset" size={18} /> {t(locale, "home.sunset")}{" "}
                <strong data-testid="home-sunset">{sunset ? hhmm(sunset) : ""}</strong>
              </span>
            </p>
          </>
        ) : null}
      </section>
    </>
  );
}
