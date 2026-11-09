/** Time-zone helpers built on Intl (IANA zones). */
import type { LocalDate } from "./prayer";

export function isValidTimeZone(tz: string): boolean {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

function parts(instant: Date, tz: string): Record<string, string> {
  const fmt = new Intl.DateTimeFormat("en-US", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  });
  const out: Record<string, string> = {};
  for (const p of fmt.formatToParts(instant)) out[p.type] = p.value;
  return out;
}

/** The calendar date at `instant` in time zone `tz`. */
export function localDateInTz(instant: Date, tz: string): LocalDate {
  const p = parts(instant, tz);
  return { year: Number(p.year), month: Number(p.month), day: Number(p.day) };
}

/** "HH:MM" (24 h) of `instant` in `tz`. */
export function formatHHMM(instant: Date, tz: string): string {
  const p = parts(instant, tz);
  return `${p.hour}:${p.minute}`;
}

/** Clock style chosen in the settings: 24 h ("13:05") or 12 h ("1:05 PM" / "1:05 م"). */
export type ClockStyle = "24" | "12";

/**
 * Time of `instant` in `tz` in the chosen clock style. Arabic uses ص / م for AM / PM. Digits stay Latin here;
 * callers localise them.
 */
export function formatClock(
  instant: Date,
  tz: string,
  clock: ClockStyle,
  locale: "ar" | "en" = "en",
): string {
  const p = parts(instant, tz);
  if (clock === "24") return `${p.hour}:${p.minute}`;
  const h = Number(p.hour);
  const h12 = h % 12 === 0 ? 12 : h % 12;
  const pm = h >= 12;
  const suffix = locale === "ar" ? (pm ? "م" : "ص") : pm ? "PM" : "AM";
  return `${h12}:${p.minute} ${suffix}`;
}

export function addDays(d: LocalDate, n: number): LocalDate {
  const t = new Date(Date.UTC(d.year, d.month - 1, d.day + n));
  return { year: t.getUTCFullYear(), month: t.getUTCMonth() + 1, day: t.getUTCDate() };
}

export function isoDate(d: LocalDate): string {
  return `${d.year}-${String(d.month).padStart(2, "0")}-${String(d.day).padStart(2, "0")}`;
}

/** Formats a positive duration in ms as H:MM:SS. */
export function formatCountdown(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}
