/**
 * Magnetic declination (degrees, east positive) from the World Magnetic Model 2025
 * (packages/shared-schemas/geo/wmm2025.json, NOAA/BGS, public domain).
 *
 * Phone compasses point to magnetic north, but the Qibla bearing is measured from true north, so the compass
 * adds the local declination: trueHeading = magneticHeading + declination. In Cairo this is about +5°, in parts
 * of the world more than 10°. Standard WMM spherical-harmonic synthesis (degree 12, WGS-84 ellipsoid); the
 * Dart port in apps/mobile/lib/domain/declination.dart is checked against the same vectors.
 */
import wmmJson from "@/generated/wmm2025.json";

interface Wmm {
  epoch: number;
  nMax: number;
  g: number[][];
  h: number[][];
  dg: number[][];
  dh: number[][];
}
const W = wmmJson as Wmm;

/** Decimal year of a date (e.g. 2026.85), as used by the WMM. */
export function decimalYear(d: Date): number {
  const y = d.getUTCFullYear();
  const start = Date.UTC(y, 0, 1);
  const end = Date.UTC(y + 1, 0, 1);
  return y + (d.getTime() - start) / (end - start);
}

const square = (n: number): number[][] =>
  Array.from({ length: n + 1 }, () => new Array<number>(n + 1).fill(0));

/** Declination in degrees (east of true north positive) at a geodetic point and decimal year. */
export function magneticDeclination(lat: number, lng: number, year: number, altKm = 0): number {
  const N = W.nMax;
  const a = 6378.137;
  const b = 6356.7523142;
  const re = 6371.2;
  const a2 = a * a;
  const b2 = b * b;
  const c2 = a2 - b2;
  const a4 = a2 * a2;
  const b4 = b2 * b2;
  const c4 = a4 - b4;
  const dt = year - W.epoch;

  // Schmidt semi-normalised coefficients at `year`, and the recursion constants k[n][m].
  const g = square(N);
  const h = square(N);
  const k = square(N);
  const snorm = square(N);
  snorm[0]![0] = 1;
  for (let n = 1; n <= N; n++) {
    snorm[n]![0] = (snorm[n - 1]![0]! * (2 * n - 1)) / n;
    let j = 2;
    for (let m = 0; m <= n; m++) {
      k[n]![m] = ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3));
      if (m > 0) {
        snorm[n]![m] = snorm[n]![m - 1]! * Math.sqrt(((n - m + 1) * j) / (n + m));
        j = 1;
      }
      g[n]![m] = snorm[n]![m]! * (W.g[n]![m]! + dt * W.dg[n]![m]!);
      h[n]![m] = snorm[n]![m]! * (W.h[n]![m]! + dt * W.dh[n]![m]!);
    }
  }

  const rad = Math.PI / 180;
  const srlat = Math.sin(lat * rad);
  const crlat = Math.cos(lat * rad);
  const srlat2 = srlat * srlat;
  const crlat2 = crlat * crlat;
  const sp = [0, Math.sin(lng * rad)];
  const cp = [1, Math.cos(lng * rad)];
  for (let m = 2; m <= N; m++) {
    sp[m] = sp[1]! * cp[m - 1]! + cp[1]! * sp[m - 1]!;
    cp[m] = cp[1]! * cp[m - 1]! - sp[1]! * sp[m - 1]!;
  }
  // Geodetic -> geocentric spherical coordinates.
  const q = Math.sqrt(a2 - c2 * srlat2);
  const q1 = altKm * q;
  const q2 = ((q1 + a2) / (q1 + b2)) ** 2;
  const ct = srlat / Math.sqrt(q2 * crlat2 + srlat2);
  const st = Math.sqrt(1 - ct * ct);
  const r = Math.sqrt(altKm * altKm + 2 * q1 + (a4 - c4 * srlat2) / (q * q));
  const d = Math.sqrt(a2 * crlat2 + b2 * srlat2);
  const ca = (altKm + d) / r;
  const sa = (c2 * crlat * srlat) / (r * d);

  const aor = re / r;
  let ar = aor * aor;
  const p = square(N);
  const dp = square(N);
  p[0]![0] = 1;
  const pp = [1];
  let br = 0;
  let bt = 0;
  let bp = 0;
  let bpp = 0;
  for (let n = 1; n <= N; n++) {
    ar *= aor;
    for (let m = 0; m <= n; m++) {
      if (n === m) {
        p[n]![m] = st * p[n - 1]![m - 1]!;
        dp[n]![m] = st * dp[n - 1]![m - 1]! + ct * p[n - 1]![m - 1]!;
      } else if (n === 1 && m === 0) {
        p[n]![m] = ct * p[n - 1]![m]!;
        dp[n]![m] = ct * dp[n - 1]![m]! - st * p[n - 1]![m]!;
      } else {
        const p2 = m > n - 2 ? 0 : p[n - 2]![m]!;
        const dp2 = m > n - 2 ? 0 : dp[n - 2]![m]!;
        p[n]![m] = ct * p[n - 1]![m]! - k[n]![m]! * p2;
        dp[n]![m] = ct * dp[n - 1]![m]! - st * p[n - 1]![m]! - k[n]![m]! * dp2;
      }
      const par = ar * p[n]![m]!;
      const t1 = g[n]![m]! * cp[m]! + h[n]![m]! * sp[m]!;
      const t2 = g[n]![m]! * sp[m]! - h[n]![m]! * cp[m]!;
      bt -= ar * t1 * dp[n]![m]!;
      bp += m * t2 * par;
      br += (n + 1) * t1 * par;
      if (st === 0 && m === 1) {
        pp[n] = n === 1 ? pp[n - 1]! : ct * pp[n - 1]! - k[n]![m]! * pp[n - 2]!;
        bpp += m * t2 * ar * pp[n]!;
      }
    }
  }
  bp = st === 0 ? bpp : bp / st;
  const bx = -bt * ca - br * sa; // north component
  const by = bp; // east component
  return Math.atan2(by, bx) / rad;
}

/** True-north heading from a magnetic-north heading at a place (null stays null). */
export function trueHeading(
  magnetic: number | null,
  lat: number,
  lng: number,
  when: Date = new Date(),
): number | null {
  if (magnetic === null) return null;
  const t = magnetic + magneticDeclination(lat, lng, decimalYear(when));
  return ((t % 360) + 360) % 360;
}
