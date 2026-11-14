"use client";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { resolveLocation } from "@/lib/cities";
import { nextPrayer } from "@/lib/next-prayer";
import { formatClock, formatCountdown } from "@/lib/time";
import { gregorianDay, hijriDate, weekdayName } from "@/lib/dates";
import { prayerStore, prefsStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { useNow } from "@/hooks/useNow";
import { Icon } from "./Icon";

/** Website top bar: today's dates and the next prayer with a live countdown (wide screens only). */
export function HeaderPrayer({ locale }: { locale: Locale }) {
  const prefs = useStore(prayerStore);
  const display = useStore(prefsStore);
  const now = useNow();
  if (!now) return <span className="topbar-info" />;
  const loc = resolveLocation(prefs);
  let next: ReturnType<typeof nextPrayer> | null = null;
  try {
    next = nextPrayer(now, { ...loc, asr: prefs.asr, adjustments: prefs.adjustments });
  } catch {
    next = null;
  }
  const hijri = hijriDate(now, loc.tz, locale);
  return (
    <span className="topbar-info">
      <span className="topbar-date">
        <Icon name="calendar" size={16} />
        {weekdayName(now, loc.tz, locale)} · {gregorianDay(now, loc.tz, locale)}
        {hijri ? <span className="topbar-hijri"> · {hijri}</span> : null}
      </span>
      {next ? (
        <Link className="topbar-prayer" href={href(locale, "prayer")} data-testid="topbar-prayer">
          <Icon name="clock" size={16} />
          {t(locale, "home.prayerOf", { name: t(locale, `prayer.${next.key}`) })}{" "}
          <strong>{localizeDigits(formatClock(next.at, loc.tz, display.clock, locale), locale)}</strong>
          <span className="topbar-left">
            ({t(locale, "home.left")} {localizeDigits(formatCountdown(next.at.getTime() - now.getTime()), locale)})
          </span>
        </Link>
      ) : null}
    </span>
  );
}
