// @vitest-environment node
import { Coordinates, Qibla } from "adhan";
import { readRepoJson } from "../repo";
import {
  clampAdjustment,
  computeHours,
  fix,
  InvalidInput,
  julianDay,
  methodsConfig,
  METHOD_IDS,
  PRAYER_KEYS,
  prayerTimes,
  pyRound,
  qiblaBearing,
  type PrayerKey,
} from "@/lib/prayer";
import { addDays, formatCountdown, formatHHMM, isoDate, isValidTimeZone, localDateInTz } from "@/lib/time";
import { nextPrayer, todayTimes } from "@/lib/next-prayer";
import { CITIES, cityById, resolveLocation } from "@/lib/cities";
import { DEFAULT_PRAYER } from "@/lib/settings";

interface VectorCase {
  id: string;
  lat: number;
  lng: number;
  tz: string;
  date: string;
  method: string;
  asr: string;
  local: Record<PrayerKey, string>;
  utc: Record<PrayerKey, string>;
}
const vectors = readRepoJson<{ toleranceMinutes: number; cases: VectorCase[] }>(
  "tests/vectors/prayer-times.json",
);

const minutesOfDay = (hhmm: string): number => {
  const [h, m] = hhmm.split(":").map(Number) as [number, number];
  return h * 60 + m;
};
const circularDiff = (a: number, b: number): number => {
  const d = Math.abs(a - b) % 1440;
  return Math.min(d, 1440 - d);
};

describe("prayer times vs adhan-js vectors", () => {
  it("has 38 cases and the shared tolerance", () => {
    expect(vectors.cases).toHaveLength(38);
    expect(vectors.toleranceMinutes).toBe(2);
  });

  it.each(vectors.cases.map((c) => [c.id, c] as const))("%s", (_id, c) => {
    const [y, m, d] = c.date.split("-").map(Number) as [number, number, number];
    const day = prayerTimes({ year: y, month: m, day: d }, c.lat, c.lng, c.method, c.asr);
    for (const k of PRAYER_KEYS) {
      const expectedUtc = Date.parse(c.utc[k].replace("Z", ":00Z"));
      const diffMin = Math.abs(day.times[k].getTime() - expectedUtc) / 60000;
      expect(diffMin, `${c.id} ${k} utc`).toBeLessThanOrEqual(vectors.toleranceMinutes);
      const local = formatHHMM(day.times[k], c.tz);
      expect(
        circularDiff(minutesOfDay(local), minutesOfDay(c.local[k])),
        `${c.id} ${k} local`,
      ).toBeLessThanOrEqual(vectors.toleranceMinutes);
    }
  });
});

describe("qibla bearing (independent reference: adhan-js Qibla)", () => {
  it.each(CITIES.map((c) => [c.nameEn, c] as const))("%s within 0.5°", (_n, c) => {
    const ref = Qibla(new Coordinates(c.lat, c.lng));
    const diff = Math.abs(qiblaBearing(c.lat, c.lng) - ref);
    expect(Math.min(diff, 360 - diff)).toBeLessThanOrEqual(0.5);
  });
  it("matches published values for New York and London", () => {
    expect(qiblaBearing(40.7128, -74.006)).toBeCloseTo(58.48, 0);
    expect(qiblaBearing(51.5074, -0.1278)).toBeCloseTo(118.99, 0);
  });
  it("is within [0, 360)", () => {
    for (const [lat, lng] of [
      [0, 0],
      [-45, 170],
      [60, -150],
      [21.4225, 39.9],
    ] as const) {
      const b = qiblaBearing(lat, lng);
      expect(b).toBeGreaterThanOrEqual(0);
      expect(b).toBeLessThan(360);
    }
  });
  it("rejects invalid coordinates", () => {
    expect(() => qiblaBearing(91, 0)).toThrow(InvalidInput);
    expect(() => qiblaBearing(0, NaN)).toThrow(InvalidInput);
  });
});

describe("DST and time zones", () => {
  it("London Dhuhr moves by one hour across the March 2026 DST change", () => {
    const before = prayerTimes({ year: 2026, month: 3, day: 28 }, 51.5074, -0.1278, "mwl");
    const after = prayerTimes({ year: 2026, month: 3, day: 30 }, 51.5074, -0.1278, "mwl");
    const b = minutesOfDay(formatHHMM(before.times.dhuhr, "Europe/London"));
    const a = minutesOfDay(formatHHMM(after.times.dhuhr, "Europe/London"));
    expect(a - b).toBeGreaterThanOrEqual(58);
    expect(a - b).toBeLessThanOrEqual(60);
    // UTC instants barely move (equation of time only)
    expect(Math.abs(after.times.dhuhr.getTime() - before.times.dhuhr.getTime() - 2 * 86400000)).toBeLessThan(
      2 * 60000,
    );
  });
  it("New York local date/time across the November DST end", () => {
    const tz = "America/New_York";
    const d1 = prayerTimes({ year: 2026, month: 10, day: 31 }, 40.7128, -74.006, "isna");
    const d2 = prayerTimes({ year: 2026, month: 11, day: 2 }, 40.7128, -74.006, "isna");
    const diff = minutesOfDay(formatHHMM(d1.times.dhuhr, tz)) - minutesOfDay(formatHHMM(d2.times.dhuhr, tz));
    expect(diff).toBeGreaterThanOrEqual(59);
    expect(diff).toBeLessThanOrEqual(61);
  });
  it("localDateInTz uses the zone's calendar date", () => {
    const instant = new Date("2026-03-29T23:30:00Z");
    expect(localDateInTz(instant, "Europe/London")).toEqual({ year: 2026, month: 3, day: 30 });
    expect(localDateInTz(instant, "America/New_York")).toEqual({ year: 2026, month: 3, day: 29 });
    expect(localDateInTz(instant, "Asia/Tokyo")).toEqual({ year: 2026, month: 3, day: 30 });
  });
  it("formatHHMM uses 24h clock", () => {
    expect(formatHHMM(new Date("2026-01-01T00:05:00Z"), "UTC")).toBe("00:05");
    expect(formatHHMM(new Date("2026-01-01T23:59:00Z"), "Asia/Riyadh")).toBe("02:59");
  });
  it("validates time zones", () => {
    expect(isValidTimeZone("Africa/Cairo")).toBe(true);
    expect(isValidTimeZone("Mars/Olympus")).toBe(false);
  });
  it("date helpers", () => {
    expect(addDays({ year: 2026, month: 12, day: 31 }, 1)).toEqual({ year: 2027, month: 1, day: 1 });
    expect(addDays({ year: 2028, month: 3, day: 1 }, -1)).toEqual({ year: 2028, month: 2, day: 29 });
    expect(isoDate({ year: 2026, month: 4, day: 5 })).toBe("2026-04-05");
    expect(formatCountdown(3 * 3600000 + 62000)).toBe("3:01:02");
    expect(formatCountdown(-5)).toBe("0:00:00");
  });
});

describe("invalid input", () => {
  const d = { year: 2026, month: 6, day: 1 };
  it.each([
    ["latitude 90", () => prayerTimes(d, 90, 0)],
    ["latitude -90", () => prayerTimes(d, -90, 0)],
    ["longitude 181", () => prayerTimes(d, 0, 181)],
    ["NaN latitude", () => prayerTimes(d, NaN, 0)],
    ["unknown method", () => prayerTimes(d, 21, 39, "nope")],
    ["prototype method name", () => prayerTimes(d, 21, 39, "toString")],
    ["bad asr", () => prayerTimes(d, 21, 39, "mwl", "shafi")],
    ["bad asr factor", () => computeHours(2026, 6, 1, 21, 39, "mwl", 3)],
    ["Feb 30", () => prayerTimes({ year: 2026, month: 2, day: 30 }, 21, 39)],
    ["month 13", () => prayerTimes({ year: 2026, month: 13, day: 1 }, 21, 39)],
    ["fractional day", () => prayerTimes({ year: 2026, month: 1, day: 1.5 }, 21, 39)],
    ["polar night (Tromsø, December)", () => prayerTimes({ year: 2026, month: 12, day: 21 }, 69.65, 18.96)],
    ["polar day (Tromsø, June)", () => prayerTimes({ year: 2026, month: 6, day: 21 }, 69.65, 18.96)],
  ])("%s throws InvalidInput", (_n, fn) => {
    expect(fn).toThrow(InvalidInput);
  });
});

describe("algorithm details", () => {
  it("applies the high-latitude rule in Oslo in June and reports it", () => {
    const day = prayerTimes({ year: 2026, month: 6, day: 21 }, 59.9139, 10.7522, "mwl");
    expect(day.highLatitudeAdjusted).toEqual(["fajr", "isha"]);
  });
  it("no adjustment needed in Makkah", () => {
    expect(
      prayerTimes({ year: 2026, month: 6, day: 21 }, 21.3891, 39.8579, "makkah").highLatitudeAdjusted,
    ).toEqual([]);
  });
  it("ishaMinutes methods put Isha 90 minutes after Maghrib", () => {
    const day = prayerTimes({ year: 2026, month: 3, day: 1 }, 21.3891, 39.8579, "makkah");
    expect(day.times.isha.getTime() - day.times.maghrib.getTime()).toBeGreaterThanOrEqual(89 * 60000);
    expect(day.times.isha.getTime() - day.times.maghrib.getTime()).toBeLessThanOrEqual(91 * 60000);
  });
  it("hanafi Asr is later than standard", () => {
    const d = { year: 2026, month: 3, day: 1 };
    const s = prayerTimes(d, 41.0082, 28.9784, "mwl", "standard");
    const h = prayerTimes(d, 41.0082, 28.9784, "mwl", "hanafi");
    expect(h.times.asr.getTime()).toBeGreaterThan(s.times.asr.getTime());
  });
  it("manual adjustments shift times by whole minutes", () => {
    const d = { year: 2026, month: 3, day: 1 };
    const base = prayerTimes(d, 30.0444, 31.2357, "egypt");
    const adj = prayerTimes(d, 30.0444, 31.2357, "egypt", "standard", { fajr: 30, isha: -30, dhuhr: 2.7 });
    expect(adj.times.fajr.getTime() - base.times.fajr.getTime()).toBe(30 * 60000);
    expect(adj.times.isha.getTime() - base.times.isha.getTime()).toBe(-30 * 60000);
    expect(adj.times.dhuhr.getTime() - base.times.dhuhr.getTime()).toBe(2 * 60000);
    expect(adj.times.asr.getTime()).toBe(base.times.asr.getTime());
  });
  it("times are whole minutes", () => {
    const day = prayerTimes({ year: 2026, month: 3, day: 1 }, 30.0444, 31.2357, "egypt");
    for (const k of PRAYER_KEYS) expect(day.times[k].getTime() % 60000).toBe(0);
  });
  it("all methods from methods.json compute", () => {
    expect(METHOD_IDS).toEqual(Object.keys(methodsConfig.methods));
    for (const m of METHOD_IDS) {
      expect(() => prayerTimes({ year: 2026, month: 3, day: 1 }, 30, 31, m)).not.toThrow();
    }
  });
  it("pyRound matches Python round-half-even", () => {
    expect(pyRound(0.5)).toBe(0);
    expect(pyRound(1.5)).toBe(2);
    expect(pyRound(2.5)).toBe(2);
    expect(pyRound(-0.5) + 0).toBe(0); // Python: round(-0.5) == 0
    expect(pyRound(-1.5)).toBe(-2);
    expect(pyRound(2.4999)).toBe(2);
    expect(pyRound(2.5001)).toBe(3);
  });
  it("julianDay and fix", () => {
    expect(julianDay(2000, 1, 1)).toBe(2451544.5);
    expect(julianDay(1999, 1, 1)).toBe(2451179.5);
    expect(fix(-30, 360)).toBe(330);
    expect(fix(370, 360)).toBe(10);
  });
  it("clampAdjustment", () => {
    expect(clampAdjustment(45)).toBe(30);
    expect(clampAdjustment(-45)).toBe(-30);
    expect(clampAdjustment(NaN)).toBe(0);
    expect(clampAdjustment(4.9)).toBe(4);
  });
});

describe("next prayer", () => {
  const q = { lat: 21.3891, lng: 39.8579, tz: "Asia/Riyadh", method: "makkah", asr: "standard" };
  it("returns the next obligatory prayer of the day (skips sunrise)", () => {
    const today = todayTimes(new Date("2026-03-01T03:00:00Z"), q);
    const justAfterFajr = new Date(today.times.fajr.getTime() + 60000);
    expect(nextPrayer(justAfterFajr, q).key).toBe("dhuhr");
    const beforeFajr = new Date(today.times.fajr.getTime() - 60000);
    expect(nextPrayer(beforeFajr, q)).toEqual({ key: "fajr", at: today.times.fajr });
  });
  it("rolls over to tomorrow's Fajr after Isha", () => {
    const today = todayTimes(new Date("2026-03-01T12:00:00Z"), q);
    const after = new Date(today.times.isha.getTime() + 60000);
    const n = nextPrayer(after, q);
    expect(n.key).toBe("fajr");
    expect(n.at.getTime()).toBeGreaterThan(after.getTime());
    expect(n.at.getTime() - today.times.fajr.getTime()).toBeGreaterThan(23 * 3600000);
  });
});

describe("cities", () => {
  it("every city has a known method and valid tz", () => {
    expect(CITIES.length).toBeGreaterThan(30);
    for (const c of CITIES) {
      expect(METHOD_IDS).toContain(c.method);
      expect(isValidTimeZone(c.tz)).toBe(true);
    }
  });
  it("resolveLocation uses city defaults, overrides and custom locations", () => {
    expect(resolveLocation(DEFAULT_PRAYER).city?.id).toBe("c26");
    const cairo = resolveLocation({ ...DEFAULT_PRAYER, cityId: "c1" });
    expect(cairo.method).toBe("egypt");
    expect(resolveLocation({ ...DEFAULT_PRAYER, cityId: "c1", method: "mwl" }).method).toBe("mwl");
    expect(resolveLocation({ ...DEFAULT_PRAYER, cityId: "nope" }).city).toBe(CITIES[0]);
    const custom = resolveLocation({ ...DEFAULT_PRAYER, custom: { lat: 1, lng: 2, tz: "UTC" } });
    expect(custom).toMatchObject({ lat: 1, lng: 2, tz: "UTC", method: "mwl", city: null });
    expect(cityById("c1")?.nameEn).toBe("Cairo");
  });
});
