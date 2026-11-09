/**
 * Worship tracker: for each day, which of the five prayers were prayed, whether the user fasted, and a short
 * note. Kept on this device only.
 */
import { createStore } from "./store";
import { OBLIGATORY } from "./next-prayer";
import { addDays, isoDate } from "./time";
import type { LocalDate } from "./prayer";

export const MAX_NOTE = 200;
const WEEK_DAYS = 7;
/** Longest streak counted back (about three years); stops runaway loops on bad data. */
const MAX_STREAK = 1100;
/** A calendar day: matches "2026-11-09", rejects "2026-11-9". https://regex101.com/?regex=%5E%5Cd%7B4%7D-%5Cd%5Cd-%5Cd%5Cd%24&testString=2026-11-09 */
const ISO_DATE_RE = /^\d{4}-\d\d-\d\d$/;

export interface WorshipDay {
  /** Obligatory prayers prayed that day. */
  prayers: Record<string, boolean>;
  fasting: boolean;
  note: string;
}
export interface WorshipState {
  days: Record<string, WorshipDay>;
}
export const EMPTY_DAY: WorshipDay = { prayers: {}, fasting: false, note: "" };
export const DEFAULT_WORSHIP: WorshipState = { days: {} };

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

function sanitizeDay(raw: unknown): WorshipDay {
  const r = isObj(raw) ? raw : {};
  const p = isObj(r.prayers) ? r.prayers : {};
  return {
    prayers: Object.fromEntries(OBLIGATORY.filter((k) => p[k] === true).map((k) => [k, true])),
    fasting: r.fasting === true,
    note: typeof r.note === "string" ? r.note.slice(0, MAX_NOTE) : "",
  };
}

const isEmpty = (d: WorshipDay): boolean =>
  Object.keys(d.prayers).length === 0 && !d.fasting && d.note.trim() === "";

export function sanitizeWorship(raw: unknown): WorshipState {
  const days = isObj(raw) && isObj(raw.days) ? raw.days : {};
  return {
    days: Object.fromEntries(
      Object.entries(days)
        .filter(([k]) => ISO_DATE_RE.test(k))
        .map(([k, v]) => [k, sanitizeDay(v)] as const)
        .filter(([, d]) => !isEmpty(d)),
    ),
  };
}

export function dayOf(s: WorshipState, day: string): WorshipDay {
  return s.days[day] ?? EMPTY_DAY;
}

function withDay(s: WorshipState, day: string, d: WorshipDay): WorshipState {
  const days = Object.fromEntries(Object.entries(s.days).filter(([k]) => k !== day));
  return { days: isEmpty(d) ? days : { ...days, [day]: d } };
}

export function togglePrayer(s: WorshipState, day: string, key: string): WorshipState {
  const d = dayOf(s, day);
  const prayers = Object.fromEntries(Object.entries(d.prayers).filter(([k]) => k !== key));
  return withDay(s, day, { ...d, prayers: d.prayers[key] ? prayers : { ...prayers, [key]: true } });
}

export function setFasting(s: WorshipState, day: string, fasting: boolean): WorshipState {
  return withDay(s, day, { ...dayOf(s, day), fasting });
}

export function setNote(s: WorshipState, day: string, note: string): WorshipState {
  return withDay(s, day, { ...dayOf(s, day), note: note.slice(0, MAX_NOTE) });
}

export const prayedCount = (d: WorshipDay): number => OBLIGATORY.filter((k) => d.prayers[k]).length;
const fullDay = (d: WorshipDay): boolean => prayedCount(d) === OBLIGATORY.length;

export interface WorshipStats {
  days: number;
  prayed: number;
  /** Prayers possible over the period (five a day). */
  possible: number;
  fullDays: number;
  fasted: number;
}

/** Totals over the `n` days ending on `last` (inclusive). */
export function statsFor(s: WorshipState, last: LocalDate, n: number): WorshipStats {
  const list = Array.from({ length: n }, (_, i) => dayOf(s, isoDate(addDays(last, -i))));
  return {
    days: n,
    prayed: list.reduce((a, d) => a + prayedCount(d), 0),
    possible: n * OBLIGATORY.length,
    fullDays: list.filter(fullDay).length,
    fasted: list.filter((d) => d.fasting).length,
  };
}

export const weekStats = (s: WorshipState, today: LocalDate): WorshipStats => statsFor(s, today, WEEK_DAYS);

/** Totals for a whole Gregorian month (up to `today` when it is the current month). */
export function monthStats(s: WorshipState, year: number, month: number, today: LocalDate): WorshipStats {
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const current = today.year === year && today.month === month;
  const end = current ? today.day : lastDay;
  return statsFor(s, { year, month, day: end }, end);
}

/**
 * Days in a row with all five prayers, ending today — or yesterday while today is not complete yet, so the
 * streak does not drop to zero in the morning.
 */
export function streak(s: WorshipState, today: LocalDate): number {
  const start = fullDay(dayOf(s, isoDate(today))) ? 0 : 1;
  const run = Array.from({ length: MAX_STREAK }, (_, i) => isoDate(addDays(today, -(start + i))));
  const firstGap = run.findIndex((d) => !fullDay(dayOf(s, d)));
  return firstGap === -1 ? run.length : firstGap;
}

export const worshipStore = createStore<WorshipState>("rattil.worship", DEFAULT_WORSHIP, sanitizeWorship);
