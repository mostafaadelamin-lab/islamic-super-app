// Magnetic declination (degrees, east positive) from the World Magnetic Model
// 2025 (assets/schemas/wmm2025.json = packages/shared-schemas/geo/wmm2025.json,
// NOAA/BGS, public domain). Port of apps/web/src/lib/declination.ts, checked
// against the same vectors (tests/vectors/declination.json).
//
// Phone compasses point to magnetic north; the qibla bearing is measured from
// true north, so the compass adds the local declination.
import 'dart:math' as math;

class WorldMagneticModel {
  WorldMagneticModel._(this.epoch, this.nMax, this._g, this._h, this._dg, this._dh);

  factory WorldMagneticModel.fromJson(Map<String, dynamic> j) {
    List<List<double>> rows(String k) => [
      for (final r in j[k] as List<dynamic>) [for (final v in r as List<dynamic>) (v as num).toDouble()],
    ];
    return WorldMagneticModel._(
      (j['epoch'] as num).toDouble(),
      (j['nMax'] as num).toInt(),
      rows('g'),
      rows('h'),
      rows('dg'),
      rows('dh'),
    );
  }

  final double epoch;
  final int nMax;
  final List<List<double>> _g, _h, _dg, _dh;

  /// Declination in degrees (east of true north positive) at a geodetic point
  /// and decimal year (e.g. 2026.85).
  double declination(double lat, double lng, double year, {double altKm = 0}) {
    final n0 = nMax;
    const a = 6378.137, b = 6356.7523142, re = 6371.2;
    const a2 = a * a, b2 = b * b, c2 = a2 - b2, a4 = a2 * a2, b4 = b2 * b2, c4 = a4 - b4;
    final dt = year - epoch;
    List<List<double>> square() => List.generate(n0 + 1, (_) => List<double>.filled(n0 + 1, 0));

    final g = square(), h = square(), k = square(), snorm = square();
    snorm[0][0] = 1;
    for (var n = 1; n <= n0; n++) {
      snorm[n][0] = snorm[n - 1][0] * (2 * n - 1) / n;
      var j = 2;
      for (var m = 0; m <= n; m++) {
        k[n][m] = ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3));
        if (m > 0) {
          snorm[n][m] = snorm[n][m - 1] * math.sqrt((n - m + 1) * j / (n + m));
          j = 1;
        }
        g[n][m] = snorm[n][m] * (_g[n][m] + dt * _dg[n][m]);
        h[n][m] = snorm[n][m] * (_h[n][m] + dt * _dh[n][m]);
      }
    }

    const rad = math.pi / 180;
    final srlat = math.sin(lat * rad), crlat = math.cos(lat * rad);
    final srlat2 = srlat * srlat, crlat2 = crlat * crlat;
    final sp = List<double>.filled(n0 + 1, 0), cp = List<double>.filled(n0 + 1, 0);
    sp[1] = math.sin(lng * rad);
    cp[0] = 1;
    cp[1] = math.cos(lng * rad);
    for (var m = 2; m <= n0; m++) {
      sp[m] = sp[1] * cp[m - 1] + cp[1] * sp[m - 1];
      cp[m] = cp[1] * cp[m - 1] - sp[1] * sp[m - 1];
    }
    final q = math.sqrt(a2 - c2 * srlat2);
    final q1 = altKm * q;
    final q2 = math.pow((q1 + a2) / (q1 + b2), 2).toDouble();
    final ct = srlat / math.sqrt(q2 * crlat2 + srlat2);
    final st = math.sqrt(1 - ct * ct);
    final r = math.sqrt(altKm * altKm + 2 * q1 + (a4 - c4 * srlat2) / (q * q));
    final d = math.sqrt(a2 * crlat2 + b2 * srlat2);
    final ca = (altKm + d) / r;
    final sa = c2 * crlat * srlat / (r * d);

    final aor = re / r;
    var ar = aor * aor;
    final p = square(), dp = square();
    p[0][0] = 1;
    final pp = List<double>.filled(n0 + 1, 0);
    pp[0] = 1;
    var br = 0.0, bt = 0.0, bp = 0.0, bpp = 0.0;
    for (var n = 1; n <= n0; n++) {
      ar *= aor;
      for (var m = 0; m <= n; m++) {
        if (n == m) {
          p[n][m] = st * p[n - 1][m - 1];
          dp[n][m] = st * dp[n - 1][m - 1] + ct * p[n - 1][m - 1];
        } else if (n == 1 && m == 0) {
          p[n][m] = ct * p[n - 1][m];
          dp[n][m] = ct * dp[n - 1][m] - st * p[n - 1][m];
        } else {
          final p2 = m > n - 2 ? 0.0 : p[n - 2][m];
          final dp2 = m > n - 2 ? 0.0 : dp[n - 2][m];
          p[n][m] = ct * p[n - 1][m] - k[n][m] * p2;
          dp[n][m] = ct * dp[n - 1][m] - st * p[n - 1][m] - k[n][m] * dp2;
        }
        final par = ar * p[n][m];
        final t1 = g[n][m] * cp[m] + h[n][m] * sp[m];
        final t2 = g[n][m] * sp[m] - h[n][m] * cp[m];
        bt -= ar * t1 * dp[n][m];
        bp += m * t2 * par;
        br += (n + 1) * t1 * par;
        if (st == 0 && m == 1) {
          pp[n] = n == 1 ? pp[n - 1] : ct * pp[n - 1] - k[n][m] * pp[n - 2];
          bpp += m * t2 * ar * pp[n];
        }
      }
    }
    bp = st == 0 ? bpp : bp / st;
    final bx = -bt * ca - br * sa;
    return math.atan2(bp, bx) / rad;
  }
}

/// Decimal year of an instant (e.g. 2026.85), as the WMM uses.
double decimalYear(DateTime t) {
  final u = t.toUtc();
  final start = DateTime.utc(u.year).millisecondsSinceEpoch;
  final end = DateTime.utc(u.year + 1).millisecondsSinceEpoch;
  return u.year + (u.millisecondsSinceEpoch - start) / (end - start);
}
