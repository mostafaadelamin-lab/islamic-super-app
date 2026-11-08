"use client";
import { useEffect, useState, useSyncExternalStore } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { SLEEP_CHOICES, sleepTimer } from "@/lib/sleep-timer";

/** "Stop the audio after N minutes" picker, with the minutes left. */
export function SleepTimer({ locale }: { locale: Locale }) {
  const st = useSyncExternalStore(sleepTimer.subscribe, sleepTimer.get, sleepTimer.getServer);
  const [, tick] = useState(0);
  useEffect(() => {
    if (st.endsAt === null) return;
    const id = setInterval(() => tick((n) => n + 1), 15_000);
    return () => clearInterval(id);
  }, [st.endsAt]);
  const left = sleepTimer.minutesLeft();
  return (
    <label className="inline-field sleep-timer">
      <span>{t(locale, "stories.sleep")}</span>
      <select
        value={st.minutes ?? 0}
        data-testid="sleep-timer"
        onChange={(e) => {
          const n = Number(e.target.value);
          sleepTimer.set(n || null);
        }}
      >
        <option value={0}>{t(locale, "stories.sleepOff")}</option>
        {SLEEP_CHOICES.map((n) => (
          <option key={n} value={n}>
            {t(locale, "stories.sleepMin", { n: localizeDigits(n, locale) })}
          </option>
        ))}
      </select>
      {left !== null ? (
        <span className="muted small" data-testid="sleep-left">
          {t(locale, "stories.sleepLeft", { time: localizeDigits(left, locale) })}
        </span>
      ) : null}
    </label>
  );
}
