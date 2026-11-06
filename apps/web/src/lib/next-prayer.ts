import { prayerTimes, type Adjustments, type PrayerDay, type PrayerKey } from "./prayer";
import { addDays, localDateInTz } from "./time";

export const OBLIGATORY: readonly PrayerKey[] = ["fajr", "dhuhr", "asr", "maghrib", "isha"];

export interface PrayerQuery {
  lat: number;
  lng: number;
  tz: string;
  method: string;
  asr: string;
  adjustments?: Adjustments;
}

export function todayTimes(now: Date, q: PrayerQuery): PrayerDay {
  return prayerTimes(localDateInTz(now, q.tz), q.lat, q.lng, q.method, q.asr, q.adjustments ?? {});
}

/** The next obligatory prayer strictly after `now` (rolls over to tomorrow's Fajr). */
export function nextPrayer(now: Date, q: PrayerQuery): { key: PrayerKey; at: Date } {
  const today = todayTimes(now, q);
  for (const k of OBLIGATORY) {
    if (today.times[k].getTime() > now.getTime()) return { key: k, at: today.times[k] };
  }
  const tomorrow = prayerTimes(
    addDays(localDateInTz(now, q.tz), 1),
    q.lat,
    q.lng,
    q.method,
    q.asr,
    q.adjustments ?? {},
  );
  return { key: "fajr", at: tomorrow.times.fajr };
}
