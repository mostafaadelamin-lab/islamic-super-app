/**
 * Quran khatma (completing the whole Mushaf on a plan): pure planning logic.
 * The Mushaf pages [startPage..endPage] are split into `wirds` daily portions
 * of whole pages; one wird per day from `startDate`. The same rules live in
 * apps/mobile/lib/domain/khatma.dart.
 */
import { createStore } from "./store";

export const MUSHAF_PAGES = 604;
export const MIN_DAYS = 1;
export const MAX_DAYS = 365;
export const MIN_PAGES_PER_DAY = 1;
export const MAX_PAGES_PER_DAY = 60;
const DAY_MS = 86_400_000;
const MAX_NAME_LENGTH = 40;
/** Length of "YYYY-MM-DD". */
const ISO_DAY_LENGTH = 10;
/** A date "YYYY-MM-DD": matches "2026-11-09", rejects "2026-1-9". */
const ISO_DAY_RE = /^\d{4}-\d\d-\d\d$/;
/** A time "HH:MM": matches "05:30", rejects "5:30". */
const HHMM_RE = /^\d\d:\d\d$/;

/** A calendar date as "YYYY-MM-DD" (local to the user). */
export type IsoDay = string;

export interface Khatma {
  name: string;
  /** Day of the first wird. */
  startDate: IsoDay;
  startPage: number;
  endPage: number;
  /** Number of daily portions. */
  wirds: number;
  /** Portions read so far. */
  done: number;
  /** Daily reminder time "HH:MM", or null for none. */
  reminder: string | null;
}

export interface FinishedKhatma {
  name: string;
  startDate: IsoDay;
  finishedDate: IsoDay;
  days: number;
}

export interface KhatmaState {
  current: Khatma | null;
  history: FinishedKhatma[];
}

export const DEFAULT_KHATMA_STATE: KhatmaState = { current: null, history: [] };

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;
const isDay = (v: unknown): v is IsoDay => typeof v === "string" && ISO_DAY_RE.test(v);
const isInt = (v: unknown, lo: number, hi: number): v is number =>
  typeof v === "number" && Number.isInteger(v) && v >= lo && v <= hi;

export function sanitizeKhatma(raw: unknown): KhatmaState {
  const r = isObj(raw) ? raw : {};
  let current: Khatma | null = null;
  const c = r.current;
  if (
    isObj(c) &&
    isDay(c.startDate) &&
    isInt(c.startPage, 1, MUSHAF_PAGES) &&
    isInt(c.endPage, 1, MUSHAF_PAGES) &&
    c.endPage >= c.startPage &&
    isInt(c.wirds, 1, MUSHAF_PAGES) &&
    c.wirds <= c.endPage - c.startPage + 1 &&
    isInt(c.done, 0, c.wirds)
  ) {
    current = {
      name: typeof c.name === "string" && c.name.trim() ? c.name.trim().slice(0, MAX_NAME_LENGTH) : "",
      startDate: c.startDate,
      startPage: c.startPage,
      endPage: c.endPage,
      wirds: c.wirds,
      done: c.done,
      reminder: typeof c.reminder === "string" && HHMM_RE.test(c.reminder) ? c.reminder : null,
    };
  }
  const history = Array.isArray(r.history)
    ? r.history
        .filter(
          (h): h is FinishedKhatma =>
            isObj(h) && isDay(h.startDate) && isDay(h.finishedDate) && typeof h.days === "number",
        )
        .map((h) => ({
          name: String(h.name ?? ""),
          startDate: h.startDate,
          finishedDate: h.finishedDate,
          days: h.days,
        }))
    : [];
  return { current, history };
}

export const khatmaStore = createStore<KhatmaState>("rattil.khatma", DEFAULT_KHATMA_STATE, sanitizeKhatma);

export function dayNumber(d: IsoDay): number {
  const [y, m, day] = d.split("-").map(Number) as [number, number, number];
  return Math.round(Date.UTC(y, m - 1, day) / DAY_MS);
}

export function isoFromDayNumber(n: number): IsoDay {
  return new Date(n * DAY_MS).toISOString().slice(0, ISO_DAY_LENGTH);
}

/** Days from `a` to `b` (b − a). */
export function daysBetween(a: IsoDay, b: IsoDay): number {
  return dayNumber(b) - dayNumber(a);
}

export function addDaysIso(d: IsoDay, n: number): IsoDay {
  return isoFromDayNumber(dayNumber(d) + n);
}

/** New plan finishing in `days` days (pages spread as evenly as possible). */
export function planByDays(name: string, startDate: IsoDay, days: number): Khatma {
  const n = Math.min(MAX_DAYS, Math.max(MIN_DAYS, Math.round(days)));
  return { name, startDate, startPage: 1, endPage: MUSHAF_PAGES, wirds: n, done: 0, reminder: null };
}

/** New plan of `pagesPerDay` pages a day (the last wird may be shorter). */
export function planByPages(name: string, startDate: IsoDay, pagesPerDay: number): Khatma {
  const p = Math.min(MAX_PAGES_PER_DAY, Math.max(MIN_PAGES_PER_DAY, Math.round(pagesPerDay)));
  return { ...planByDays(name, startDate, 1), wirds: Math.ceil(MUSHAF_PAGES / p) };
}

/** Pages (inclusive) of wird `i` (0-based). */
export function wirdPages(k: Khatma, i: number): { from: number; to: number } {
  const total = k.endPage - k.startPage + 1;
  const from = k.startPage + Math.floor((i * total) / k.wirds);
  const to = k.startPage + Math.floor(((i + 1) * total) / k.wirds) - 1;
  return { from, to };
}

export interface KhatmaProgress {
  /** Share of the whole Mushaf read, 0..1. */
  fraction: number;
  /** Wirds still to read. */
  remainingWirds: number;
  /** Planned last day. */
  endDate: IsoDay;
  /** Days left until the planned last day, counting today (0 once past it). */
  remainingDays: number;
  /** Wirds behind the plan as of `today` (0 when on time or ahead). */
  behind: number;
  /** Wirds ahead of the plan (0 when on time or behind). */
  ahead: number;
  finished: boolean;
}

export function progress(k: Khatma, today: IsoDay): KhatmaProgress {
  const pagesDone = k.done === 0 ? k.startPage - 1 : wirdPages(k, k.done - 1).to;
  const endDate = addDaysIso(k.startDate, k.wirds - 1);
  // Wirds that should be done by the end of today.
  const due = Math.min(k.wirds, Math.max(0, daysBetween(k.startDate, today) + 1));
  // Today's wird is not late yet: "behind" counts only past days.
  const duePast = Math.max(0, due - 1);
  return {
    fraction: pagesDone / MUSHAF_PAGES,
    remainingWirds: k.wirds - k.done,
    endDate,
    remainingDays: Math.max(0, daysBetween(today, endDate) + 1),
    behind: Math.max(0, duePast - k.done),
    ahead: Math.max(0, k.done - due),
    finished: k.done >= k.wirds,
  };
}

/** Spreads the unread pages over the days left (at least one day), starting today. */
export function reschedule(k: Khatma, today: IsoDay): Khatma {
  if (k.done >= k.wirds) return k;
  const from = wirdPages(k, k.done).from;
  const left = Math.max(1, daysBetween(today, addDaysIso(k.startDate, k.wirds - 1)) + 1);
  const pages = k.endPage - from + 1;
  return { ...k, startDate: today, startPage: from, wirds: Math.min(left, pages), done: 0 };
}

/** Marks today's wird read; on the last one the khatma moves to the history. */
export function completeWird(s: KhatmaState, today: IsoDay): KhatmaState {
  const k = s.current;
  if (!k) return s;
  const done = Math.min(k.wirds, k.done + 1);
  if (done < k.wirds) return { ...s, current: { ...k, done } };
  return {
    current: null,
    history: [
      {
        name: k.name,
        startDate: k.startDate,
        finishedDate: today,
        days: daysBetween(k.startDate, today) + 1,
      },
      ...s.history,
    ],
  };
}
