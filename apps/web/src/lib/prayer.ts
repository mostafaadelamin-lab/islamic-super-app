/**
 * Prayer-time calculation — faithful TypeScript port of services/api/app/domain/prayer.py
 * (Meeus / USNO low-precision solar coordinates, twilight-angle high-latitude rule,
 * Dhuhr offset from methods.json, rounding to the nearest minute like Python's round()).
 */
import methodsJson from "@/generated/methods.json";

export const PRAYER_KEYS = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"] as const;
export type PrayerKey = (typeof PRAYER_KEYS)[number];
export type AsrSchool = "standard" | "hanafi";

export interface MethodDef {
  nameAr: string;
  nameEn: string;
  fajr: number;
  isha?: number;
  ishaMinutes?: number;
}
export interface MethodsConfig {
  dhuhrOffsetMinutes: number;
  sunAltitudeForSunriseSunset: number;
  methods: Record<string, MethodDef>;
  asr: Record<string, number>;
  kaaba: { lat: number; lng: number };
}

export const methodsConfig: MethodsConfig = methodsJson as MethodsConfig;
export const METHOD_IDS = Object.keys(methodsConfig.methods);

export class InvalidInput extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidInput";
  }
}

const d2r = (d: number): number => (d * Math.PI) / 180;
const r2d = (r: number): number => (r * 180) / Math.PI;

export function fix(a: number, b: number): number {
  const v = a - b * Math.floor(a / b);
  return v < 0 ? v + b : v;
}

/** Python's round(): nearest integer, ties to even. */
export function pyRound(x: number): number {
  const f = Math.floor(x);
  const diff = x - f;
  if (diff > 0.5) return f + 1;
  if (diff < 0.5) return f;
  return f % 2 === 0 ? f : f + 1;
}

export function julianDay(year: number, month: number, day: number): number {
  let y = year;
  let m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  const a = Math.floor(y / 100);
  const b = 2 - a + Math.floor(a / 4);
  return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day + b - 1524.5;
}

/** Returns [declination in degrees, equation of time in hours]. */
export function sunPosition(jd: number): [number, number] {
  const dd = jd - 2451545.0;
  const g = fix(357.529 + 0.98560028 * dd, 360);
  const q = fix(280.459 + 0.98564736 * dd, 360);
  const lam = fix(q + 1.915 * Math.sin(d2r(g)) + 0.02 * Math.sin(d2r(2 * g)), 360);
  const e = 23.439 - 0.00000036 * dd;
  const ra = fix(r2d(Math.atan2(Math.cos(d2r(e)) * Math.sin(d2r(lam)), Math.cos(d2r(lam)))) / 15, 24);
  const decl = r2d(Math.asin(Math.sin(d2r(e)) * Math.sin(d2r(lam))));
  return [decl, q / 15 - ra];
}

export type PrayerHours = Record<PrayerKey, number>;

/** UTC fractional hours (may be < 0 or >= 24) for the local calendar date y-m-d. */
export function computeHours(
  y: number,
  m: number,
  d: number,
  lat: number,
  lng: number,
  method: string,
  asrFactor: number,
  cfg: MethodsConfig = methodsConfig,
): { hours: PrayerHours; adjusted: PrayerKey[] } {
  if (
    !Number.isFinite(lat) ||
    !Number.isFinite(lng) ||
    !(lat > -90 && lat < 90) ||
    !(lng >= -180 && lng <= 180)
  ) {
    throw new InvalidInput("latitude must be in (-90, 90) and longitude in [-180, 180]");
  }
  if (!Object.prototype.hasOwnProperty.call(cfg.methods, method)) {
    throw new InvalidInput(`unknown method '${method}'`);
  }
  if (asrFactor !== 1 && asrFactor !== 2) {
    throw new InvalidInput("asr factor must be 1 (standard) or 2 (hanafi)");
  }
  const mt = cfg.methods[method] as MethodDef;
  const hasIshaMinutes = mt.ishaMinutes !== undefined;
  const jd = julianDay(y, m, d) - lng / (15 * 24);

  const noon = (t: number): number => fix(12 - sunPosition(jd + t)[1], 24);
  const angleTime = (angle: number, t: number, beforeNoon: boolean): number => {
    const decl = sunPosition(jd + t)[0];
    const cosH =
      (-Math.sin(d2r(angle)) - Math.sin(d2r(decl)) * Math.sin(d2r(lat))) /
      (Math.cos(d2r(decl)) * Math.cos(d2r(lat)));
    if (cosH < -1 || cosH > 1) return NaN;
    const h = r2d(Math.acos(cosH)) / 15;
    const n = noon(t);
    return beforeNoon ? n - h : n + h;
  };
  const asrTime = (factor: number, t: number): number => {
    const decl = sunPosition(jd + t)[0];
    const angle = -r2d(Math.atan(1 / (factor + Math.tan(d2r(Math.abs(lat - decl))))));
    return angleTime(angle, t, false);
  };

  const sr = -cfg.sunAltitudeForSunriseSunset;
  let t: PrayerHours = { fajr: 5, sunrise: 6, dhuhr: 12, asr: 13, maghrib: 18, isha: 18 };
  for (let i = 0; i < 2; i++) {
    const p = {} as PrayerHours;
    for (const k of PRAYER_KEYS) p[k] = (Number.isNaN(t[k]) ? 12 : t[k]) / 24;
    t = {
      fajr: angleTime(mt.fajr, p.fajr, true),
      sunrise: angleTime(sr, p.sunrise, true),
      dhuhr: noon(p.dhuhr),
      asr: asrTime(asrFactor, p.asr),
      maghrib: angleTime(sr, p.maghrib, false),
      isha: hasIshaMinutes ? NaN : angleTime(mt.isha as number, p.isha, false),
    };
  }
  if (Number.isNaN(t.sunrise) || Number.isNaN(t.maghrib)) {
    throw new InvalidInput("the sun does not rise or set at this location on this date (polar day/night)");
  }
  const adjusted: PrayerKey[] = [];
  if (hasIshaMinutes) t.isha = t.maghrib + (mt.ishaMinutes as number) / 60;
  const night = fix(t.sunrise - t.maghrib, 24);
  let portion = (mt.fajr / 60) * night;
  if (Number.isNaN(t.fajr) || fix(t.sunrise - t.fajr, 24) > portion) {
    t.fajr = t.sunrise - portion;
    adjusted.push("fajr");
  }
  if (!hasIshaMinutes) {
    portion = ((mt.isha as number) / 60) * night;
    if (Number.isNaN(t.isha) || fix(t.isha - t.maghrib, 24) > portion) {
      t.isha = t.maghrib + portion;
      adjusted.push("isha");
    }
  }
  t.dhuhr += cfg.dhuhrOffsetMinutes / 60;
  const hours = {} as PrayerHours;
  for (const k of PRAYER_KEYS) hours[k] = t[k] - lng / 15;
  return { hours, adjusted };
}

export interface PrayerDay {
  times: Record<PrayerKey, Date>;
  highLatitudeAdjusted: PrayerKey[];
}
export type Adjustments = Partial<Record<PrayerKey, number>>;

export interface LocalDate {
  year: number;
  month: number;
  day: number;
}

/** Prayer times (UTC instants) for a local calendar day, rounded to the nearest minute. */
export function prayerTimes(
  date: LocalDate,
  lat: number,
  lng: number,
  method = "mwl",
  asr: AsrSchool | string = "standard",
  adjustments: Adjustments = {},
  cfg: MethodsConfig = methodsConfig,
): PrayerDay {
  const factor = Object.prototype.hasOwnProperty.call(cfg.asr, asr) ? cfg.asr[asr] : undefined;
  if (factor === undefined) throw new InvalidInput("asr must be 'standard' or 'hanafi'");
  const { year, month, day } = date;
  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
    throw new InvalidInput("invalid date");
  }
  const probe = new Date(Date.UTC(year, month - 1, day));
  if (probe.getUTCFullYear() !== year || probe.getUTCMonth() !== month - 1 || probe.getUTCDate() !== day) {
    throw new InvalidInput("invalid date");
  }
  const { hours, adjusted } = computeHours(year, month, day, lat, lng, method, factor, cfg);
  const base = Date.UTC(year, month - 1, day);
  const times = {} as Record<PrayerKey, Date>;
  for (const k of PRAYER_KEYS) {
    const adj = Math.trunc(adjustments[k] ?? 0);
    const minutes = pyRound(hours[k] * 60) + adj;
    times[k] = new Date(base + minutes * 60_000);
  }
  return { times, highLatitudeAdjusted: adjusted };
}

export function qiblaBearing(lat: number, lng: number, cfg: MethodsConfig = methodsConfig): number {
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new InvalidInput("latitude must be in [-90, 90] and longitude in [-180, 180]");
  }
  const k = cfg.kaaba;
  const dl = d2r(k.lng - lng);
  const x = Math.sin(dl);
  const y = Math.cos(d2r(lat)) * Math.tan(d2r(k.lat)) - Math.sin(d2r(lat)) * Math.cos(dl);
  return fix(r2d(Math.atan2(x, y)), 360);
}

export const ADJUST_MIN = -30;
export const ADJUST_MAX = 30;
export function clampAdjustment(v: number): number {
  if (!Number.isFinite(v)) return 0;
  return Math.max(ADJUST_MIN, Math.min(ADJUST_MAX, Math.trunc(v)));
}
