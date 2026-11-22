/**
 * Adhan alerts on the website. Browsers cannot wake a closed web page at a
 * given time, so these fire only while a page of the site is open (any tab);
 * the mobile app schedules real system notifications instead.
 */
import { createStore } from "./store";
import { prayerTimes, type PrayerDay, type PrayerKey } from "./prayer";
import { OBLIGATORY, type PrayerQuery } from "./next-prayer";
import { addDays, localDateInTz, zonedInstant } from "./time";
import { DEFAULT_ADHAN_VOICE, DEFAULT_FAJR_VOICE, isAdhanVoiceId } from "./adhan-voices";

export interface AdhanPrefs {
  enabled: boolean;
  /** Per-prayer switches (all on by default). */
  prayers: Record<string, boolean>;
  /** Play the adhan recording (otherwise only the notification is shown). */
  sound: boolean;
  /** Muezzin for Dhuhr to Isha (a bundled voice id or "iw" + collection id). */
  voice: string;
  /** Muezzin for Fajr: a Fajr adhan, with "as-salatu khayrun min an-nawm". */
  fajrVoice: string;
  /** Reminder this many minutes before each enabled adhan (0 = off). */
  preMinutes: number;
  /** Iqama reminder after each enabled adhan. */
  iqamaEnabled: boolean;
  /** Minutes from the adhan to the iqama, per prayer. */
  iqama: Record<string, number>;
  /** A prayer's own sound; prayers not listed follow `sound`. */
  soundFor: Record<string, AlertSound>;
  /** Alert at sunrise (end of the Fajr time). */
  sunrise: boolean;
  /** Alert at the start of the last third of the night. */
  lastThird: boolean;
  /** Friday reminder (Surat al-Kahf) at "HH:MM", or null when off. */
  friday: string | null;
  /** Morning / evening adhkar reminders at "HH:MM", or null when off. */
  adhkarMorning: string | null;
  adhkarEvening: string | null;
}

export type AlertSound = "adhan" | "tone" | "silent";
export const ALERT_SOUNDS: readonly AlertSound[] = ["adhan", "tone", "silent"];
/** A time "HH:MM": matches "10:00", rejects "9:5". */
const HHMM_RE = /^([01]\d|2[0-3]):[0-5]\d$/;
export const DEFAULT_FRIDAY_TIME = "10:00";
export const DEFAULT_MORNING_ADHKAR = "06:30";
export const DEFAULT_EVENING_ADHKAR = "17:00";
const FRIDAY = 5;

/** Choices offered for the reminder before the adhan (minutes; 0 = off). */
export const PRE_CHOICES = [0, 5, 10, 15, 20, 30] as const;
export const IQAMA_MIN = 1;
export const IQAMA_MAX = 60;
/** Usual waits between adhan and iqama in mosques (minutes); the user changes them to match their mosque. */
export const DEFAULT_IQAMA: Readonly<Record<string, number>> = {
  fajr: 20,
  dhuhr: 15,
  asr: 15,
  maghrib: 10,
  isha: 15,
};

/** Reminder before the adhan and iqama alert are on until the user turns them off (owner 2026-11-22). */
export const DEFAULT_PRE_MINUTES = 10;
/** No other reminder from this many minutes before each enabled adhan until its iqama (owner 2026-11-22). */
export const QUIET_MINUTES = 10;

export const DEFAULT_ADHAN: AdhanPrefs = {
  enabled: false,
  prayers: {},
  sound: true,
  voice: DEFAULT_ADHAN_VOICE,
  fajrVoice: DEFAULT_FAJR_VOICE,
  preMinutes: DEFAULT_PRE_MINUTES,
  iqamaEnabled: true,
  iqama: { ...DEFAULT_IQAMA },
  soundFor: {},
  sunrise: false,
  lastThird: false,
  friday: null,
  adhkarMorning: null,
  adhkarEvening: null,
};

export function clampIqama(v: unknown): number {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return IQAMA_MIN;
  return Math.min(IQAMA_MAX, Math.max(IQAMA_MIN, Math.round(n)));
}

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

export function sanitizeAdhan(raw: unknown): AdhanPrefs {
  const r = isObj(raw) ? raw : {};
  const prayers: Record<string, boolean> = {};
  if (isObj(r.prayers)) {
    for (const k of OBLIGATORY) if (r.prayers[k] === false) prayers[k] = false;
  }
  const pre =
    typeof r.preMinutes === "number" && (PRE_CHOICES as readonly number[]).includes(r.preMinutes)
      ? r.preMinutes
      : DEFAULT_PRE_MINUTES;
  const iq = isObj(r.iqama) ? r.iqama : {};
  const iqama = Object.fromEntries(
    OBLIGATORY.map((k) => [k, iq[k] === undefined ? (DEFAULT_IQAMA[k] ?? 15) : clampIqama(iq[k])]),
  ) as Record<string, number>;
  return {
    enabled: r.enabled === true,
    prayers,
    sound: r.sound !== false,
    voice: isAdhanVoiceId(r.voice) ? r.voice : DEFAULT_ADHAN_VOICE,
    fajrVoice: isAdhanVoiceId(r.fajrVoice) ? r.fajrVoice : DEFAULT_FAJR_VOICE,
    preMinutes: pre,
    iqamaEnabled: r.iqamaEnabled !== false,
    iqama,
    soundFor: Object.fromEntries(
      OBLIGATORY.flatMap((k) => {
        const v = isObj(r.soundFor) ? r.soundFor[k] : undefined;
        return (ALERT_SOUNDS as readonly unknown[]).includes(v) ? [[k, v as AlertSound]] : [];
      }),
    ),
    sunrise: r.sunrise === true,
    lastThird: r.lastThird === true,
    friday: typeof r.friday === "string" && HHMM_RE.test(r.friday) ? r.friday : null,
    adhkarMorning:
      typeof r.adhkarMorning === "string" && HHMM_RE.test(r.adhkarMorning) ? r.adhkarMorning : null,
    adhkarEvening:
      typeof r.adhkarEvening === "string" && HHMM_RE.test(r.adhkarEvening) ? r.adhkarEvening : null,
  };
}

export const adhanStore = createStore<AdhanPrefs>("rattil.adhan", DEFAULT_ADHAN, sanitizeAdhan);

export function adhanFor(p: AdhanPrefs, k: PrayerKey): boolean {
  return p.prayers[k] !== false;
}

export const ADHAN_AUDIO_PATH = "/audio/adhan.mp3";

export type AlertKind =
  "adhan" | "pre" | "iqama" | "sunrise" | "lastThird" | "friday" | "adhkarMorning" | "adhkarEvening";

/** Sound of `k`'s adhan alert: its own choice, else the general switch. */
export function soundFor(p: AdhanPrefs, k: PrayerKey): AlertSound {
  return p.soundFor[k] ?? (p.sound ? "adhan" : "silent");
}

/** Start of the last third of the night between `maghrib` and the next `fajr`. */
export function lastThirdStart(maghrib: Date, fajr: Date): Date {
  const TWO_THIRDS = 2 / 3;
  return new Date(maghrib.getTime() + (fajr.getTime() - maghrib.getTime()) * TWO_THIRDS);
}
export interface PlannedAlert {
  kind: AlertKind;
  key: PrayerKey;
  /** When the alert rings. */
  at: Date;
  /** The prayer (adhan) time it belongs to. */
  prayerAt: Date;
}
const MINUTE_MS = 60_000;
const LOOKAHEAD_DAYS = 3;

/**
 * The next alert of any kind (reminder before the adhan, adhan, iqama) strictly after `now`, for the enabled
 * prayers of today and the next two days; null when alerts are off or no prayer is enabled.
 */
export function nextAlert(now: Date, q: PrayerQuery, prefs: AdhanPrefs): PlannedAlert | null {
  if (!prefs.enabled) return null;
  const enabled = OBLIGATORY.filter((k) => adhanFor(prefs, k));
  if (enabled.length === 0) return null;
  const today = localDateInTz(now, q.tz);
  const dayAt = (i: number): PrayerDay | null => {
    try {
      return prayerTimes(addDays(today, i), q.lat, q.lng, q.method, q.asr, q.adjustments ?? {});
    } catch {
      return null; // polar day/night: no times that day
    }
  };
  const all = Array.from({ length: LOOKAHEAD_DAYS }, (_, i) => i).flatMap((i): PlannedAlert[] => {
    const day = dayAt(i);
    if (!day) return [];
    const date = addDays(today, i);
    const extras: PlannedAlert[] = [];
    if (prefs.sunrise)
      extras.push({ kind: "sunrise", key: "sunrise", at: day.times.sunrise, prayerAt: day.times.sunrise });
    const tomorrow = prefs.lastThird ? dayAt(i + 1) : null;
    if (tomorrow) {
      const at = lastThirdStart(day.times.maghrib, tomorrow.times.fajr);
      extras.push({ kind: "lastThird", key: "isha", at, prayerAt: at });
    }
    const isFriday = new Date(Date.UTC(date.year, date.month - 1, date.day)).getUTCDay() === FRIDAY;
    if (prefs.friday && isFriday) {
      const [hh, mm] = prefs.friday.split(":").map(Number) as [number, number];
      const at = zonedInstant(date, hh, mm, q.tz);
      extras.push({ kind: "friday", key: "dhuhr", at, prayerAt: at });
    }
    const daily: [AlertKind, string | null, PrayerKey][] = [
      ["adhkarMorning", prefs.adhkarMorning, "fajr"],
      ["adhkarEvening", prefs.adhkarEvening, "asr"],
    ];
    daily.forEach(([kind, time, key]) => {
      if (!time) return;
      const [hh, mm] = time.split(":").map(Number) as [number, number];
      const at = zonedInstant(date, hh, mm, q.tz);
      extras.push({ kind, key, at, prayerAt: at });
    });
    return [
      ...extras,
      ...enabled.flatMap((k): PlannedAlert[] => {
        const prayerAt = day.times[k];
        const out: PlannedAlert[] = [{ kind: "adhan", key: k, at: prayerAt, prayerAt }];
        if (prefs.preMinutes > 0)
          out.push({
            kind: "pre",
            key: k,
            at: new Date(prayerAt.getTime() - prefs.preMinutes * MINUTE_MS),
            prayerAt,
          });
        if (prefs.iqamaEnabled)
          out.push({
            kind: "iqama",
            key: k,
            at: new Date(prayerAt.getTime() + (prefs.iqama[k] ?? DEFAULT_IQAMA[k] ?? 15) * MINUTE_MS),
            prayerAt,
          });
        return out;
      }),
    ];
  });
  const quiet = quietWindows(now, q, prefs);
  const future = all
    .map((a) => (REMINDER_KINDS.includes(a.kind) ? { ...a, at: afterQuiet(a.at, quiet) } : a))
    .filter((a) => a.at.getTime() > now.getTime())
    .sort((a, b) => a.at.getTime() - b.at.getTime());
  return future[0] ?? null;
}

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

/** The muezzin chosen for a prayer: Fajr has its own adhan. */
export function voiceForPrayer(prefs: AdhanPrefs, key: PrayerKey): string {
  return key === "fajr" ? prefs.fajrVoice : prefs.voice;
}

/** Reminders the quiet time around the adhan moves to its end (the prayer alerts themselves never move). */
const REMINDER_KINDS: readonly AlertKind[] = ["friday", "adhkarMorning", "adhkarEvening"];

/** The iqama instant of `k` on the day whose adhan is `prayerAt`, or null when the iqama alert is off. */
function iqamaAt(prefs: AdhanPrefs, k: PrayerKey, prayerAt: Date): Date | null {
  if (!prefs.iqamaEnabled) return null;
  return new Date(prayerAt.getTime() + (prefs.iqama[k] ?? DEFAULT_IQAMA[k] ?? 15) * MINUTE_MS);
}

/**
 * Around each enabled adhan (yesterday to two days ahead): from QUIET_MINUTES before it until its iqama
 * (or QUIET_MINUTES after it when the iqama alert is off). No other reminder rings then (owner 2026-11-22).
 */
export function quietWindows(now: Date, q: PrayerQuery, prefs: AdhanPrefs): { from: Date; to: Date }[] {
  if (!prefs.enabled) return [];
  const enabled = OBLIGATORY.filter((k) => adhanFor(prefs, k));
  const today = localDateInTz(now, q.tz);
  const out: { from: Date; to: Date }[] = [];
  for (let i = -1; i < LOOKAHEAD_DAYS; i++) {
    let day: PrayerDay;
    try {
      day = prayerTimes(addDays(today, i), q.lat, q.lng, q.method, q.asr, q.adjustments ?? {});
    } catch {
      continue;
    }
    for (const k of enabled) {
      const at = day.times[k];
      out.push({
        from: new Date(at.getTime() - QUIET_MINUTES * MINUTE_MS),
        to: iqamaAt(prefs, k, at) ?? new Date(at.getTime() + QUIET_MINUTES * MINUTE_MS),
      });
    }
  }
  return out;
}

/** True when `at` falls in one of `quiet`. */
export function inQuiet(at: Date, quiet: readonly { from: Date; to: Date }[]): boolean {
  return quiet.some((w) => at.getTime() >= w.from.getTime() && at.getTime() < w.to.getTime());
}

/** `at`, or the end of the quiet time it falls in (moving on while quiet times touch). */
export function afterQuiet(at: Date, quiet: readonly { from: Date; to: Date }[]): Date {
  let t = at;
  for (let guard = 0; guard < quiet.length; guard++) {
    const w = quiet.find((x) => t.getTime() >= x.from.getTime() && t.getTime() < x.to.getTime());
    if (!w) break;
    t = w.to;
  }
  return t;
}

/**
 * Between a prayer's adhan and its iqama: that prayer and the iqama instant (owner 2026-11-22:
 * a countdown to the iqama); null otherwise or when the iqama alert is off.
 */
export function iqamaWait(now: Date, q: PrayerQuery, prefs: AdhanPrefs): { key: PrayerKey; at: Date } | null {
  if (!prefs.iqamaEnabled) return null;
  const today = localDateInTz(now, q.tz);
  for (const i of [0, -1]) {
    let day: PrayerDay;
    try {
      day = prayerTimes(addDays(today, i), q.lat, q.lng, q.method, q.asr, q.adjustments ?? {});
    } catch {
      continue;
    }
    for (const k of [...OBLIGATORY].reverse()) {
      const adhan = day.times[k];
      if (adhan.getTime() > now.getTime()) continue;
      const at = iqamaAt(prefs, k, adhan);
      if (at && at.getTime() > now.getTime()) return { key: k, at };
    }
  }
  return null;
}
