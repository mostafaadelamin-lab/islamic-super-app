import geomagnetism from "geomagnetism";
import { readRepoJson } from "../repo";
import { decimalYear, magneticDeclination, trueHeading } from "@/lib/declination";

// Independent reference: npm geomagnetism@0.2.0 (its own WMM implementation, same WMM2025 coefficients).
const PLACES: [string, number, number][] = [
  ["Cairo", 30.0444, 31.2357],
  ["Makkah", 21.4225, 39.8262],
  ["Madinah", 24.4672, 39.6111],
  ["Riyadh", 24.7136, 46.6753],
  ["Alexandria", 31.2001, 29.9187],
  ["Istanbul", 41.0082, 28.9784],
  ["London", 51.5074, -0.1278],
  ["NewYork", 40.7128, -74.006],
  ["Jakarta", -6.2088, 106.8456],
  ["KualaLumpur", 3.139, 101.6869],
  ["Karachi", 24.8607, 67.0011],
  ["Reykjavik", 64.1466, -21.9426],
  ["Sydney", -33.8688, 151.2093],
  ["Anchorage", 61.2181, -149.9003],
  ["CapeTown", -33.9249, 18.4241],
  ["Equator0", 0, 0],
  ["Arctic", 80, 0],
  ["Antarctic", -80, -120],
];
const DATES = ["2025-01-01", "2026-11-09", "2028-06-15", "2029-11-01"];

describe("magnetic declination (WMM2025)", () => {
  it("matches the independent geomagnetism implementation within 0.01°", () => {
    for (const [, lat, lng] of PLACES) {
      for (const ds of DATES) {
        const d = new Date(`${ds}T00:00:00Z`);
        const ref = geomagnetism.model(d).point([lat, lng]).decl;
        expect(Math.abs(magneticDeclination(lat, lng, decimalYear(d)) - ref)).toBeLessThan(0.01);
      }
    }
  });

  it("matches the shared vectors used by the mobile port", () => {
    const v = readRepoJson<{ cases: { lat: number; lng: number; year: number; decl: number }[] }>(
      "tests/vectors/declination.json",
    );
    expect(v.cases.length).toBe(PLACES.length * DATES.length);
    for (const c of v.cases) {
      expect(Math.abs(magneticDeclination(c.lat, c.lng, c.year) - c.decl)).toBeLessThan(1e-6);
    }
  });

  it("turns a magnetic heading into a true heading", () => {
    const d = new Date("2026-11-09T00:00:00Z");
    const cairo = magneticDeclination(30.0444, 31.2357, decimalYear(d));
    expect(cairo).toBeGreaterThan(4); // Cairo is about +5° east
    expect(cairo).toBeLessThan(7);
    expect(trueHeading(0, 30.0444, 31.2357, d)).toBeCloseTo(cairo, 6);
    expect(trueHeading(358, 30.0444, 31.2357, d)).toBeCloseTo((358 + cairo) % 360, 6);
    expect(trueHeading(null, 30.0444, 31.2357, d)).toBeNull();
  });

  it("decimalYear", () => {
    expect(decimalYear(new Date("2026-01-01T00:00:00Z"))).toBe(2026);
    expect(decimalYear(new Date("2026-07-02T12:00:00Z"))).toBeCloseTo(2026.5, 2);
  });

  it("writes the vectors file when asked (WRITE_DECLINATION_VECTORS=1)", async () => {
    if (process.env.WRITE_DECLINATION_VECTORS !== "1") return;
    const { writeFileSync } = await import("node:fs");
    const { join } = await import("node:path");
    const cases = PLACES.flatMap(([city, lat, lng]) =>
      DATES.map((date) => {
        const year = decimalYear(new Date(`${date}T00:00:00Z`));
        return { city, date, lat, lng, year, decl: magneticDeclination(lat, lng, year) };
      }),
    );
    const out = {
      _note:
        "Magnetic declination (deg, east +) from WMM2025, written by apps/web tests/unit/declination.test.ts (checked there against npm geomagnetism@0.2.0 within 0.01°). Used by the Dart port.",
      generator: "apps/web/src/lib/declination.ts",
      cases,
    };
    writeFileSync(
      join(__dirname, "../../../../tests/vectors/declination.json"),
      JSON.stringify(out, null, 1) + "\n",
    );
  });
});
