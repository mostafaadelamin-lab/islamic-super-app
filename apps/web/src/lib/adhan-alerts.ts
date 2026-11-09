/**
 * Adhan alerts on the website. Browsers cannot wake a closed web page at a
 * given time, so these fire only while a page of the site is open (any tab);
 * the mobile app schedules real system notifications instead.
 */
import { createStore } from "./store";
import { prayerTimes, type PrayerKey } from "./prayer";
import { OBLIGATORY, type PrayerQuery } from "./next-prayer";
import { addDays, localDateInTz } from "./time";

export interface AdhanPrefs {
  enabled: boolean;
  /** Per-prayer switches (all on by default). */
  prayers: Record<string, boolean>;
  /** Play the adhan recording (otherwise only the notification is shown). */
  sound: boolean;
}

export const DEFAULT_ADHAN: AdhanPrefs = { enabled: false, prayers: {}, sound: true };

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

export function sanitizeAdhan(raw: unknown): AdhanPrefs {
  const r = isObj(raw) ? raw : {};
  const prayers: Record<string, boolean> = {};
  if (isObj(r.prayers)) {
    for (const k of OBLIGATORY) if (r.prayers[k] === false) prayers[k] = false;
  }
  return { enabled: r.enabled === true, prayers, sound: r.sound !== false };
}

export const adhanStore = createStore<AdhanPrefs>("rattil.adhan", DEFAULT_ADHAN, sanitizeAdhan);

export function adhanFor(p: AdhanPrefs, k: PrayerKey): boolean {
  return p.prayers[k] !== false;
}

export const ADHAN_AUDIO_PATH = "/audio/adhan.mp3";

/**
 * The next enabled obligatory prayer strictly after `now` (today or the next
 * two days), or null when alerts are off or no prayer is enabled.
 */
export function nextAdhanAlert(
  now: Date,
  q: PrayerQuery,
  prefs: AdhanPrefs,
): { key: PrayerKey; at: Date } | null {
  if (!prefs.enabled) return null;
  const enabled = OBLIGATORY.filter((k) => adhanFor(prefs, k));
  if (enabled.length === 0) return null;
  const today = localDateInTz(now, q.tz);
  for (let i = 0; i < 3; i++) {
    let day;
    try {
      day = prayerTimes(addDays(today, i), q.lat, q.lng, q.method, q.asr, q.adjustments ?? {});
    } catch {
      continue; // polar day/night: no times that day
    }
    for (const k of enabled) {
      const at = day.times[k];
      if (at.getTime() > now.getTime()) return { key: k, at };
    }
  }
  return null;
}
