/** Gregorian and Hijri (Umm al-Qura, via Intl) dates for the home screen. */
import type { Locale } from "./i18n";

export function gregorianDate(d: Date, tz: string, locale: Locale): string {
  return new Intl.DateTimeFormat(locale === "ar" ? "ar-EG-u-nu-arab" : "en-GB", {
    timeZone: tz,
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(d);
}

/**
 * Hijri date by the Umm al-Qura calendar, or null if the engine lacks it. It can differ by a day from the
 * locally announced date (moon sighting).
 */
export function hijriDate(d: Date, tz: string, locale: Locale): string | null {
  try {
    const f = new Intl.DateTimeFormat(
      locale === "ar" ? "ar-SA-u-ca-islamic-umalqura-nu-arab" : "en-u-ca-islamic-umalqura",
      { timeZone: tz, day: "numeric", month: "long", year: "numeric" },
    );
    if (!f.resolvedOptions().calendar.startsWith("islamic")) return null;
    return f.format(d);
  } catch {
    return null;
  }
}
