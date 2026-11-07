// Prayer-time calculation — a faithful Dart port of the reference
// implementation in services/api/app/domain/prayer.py (Jean Meeus,
// "Astronomical Algorithms", low-precision USNO solar coordinates).
//
// Same formulas, same two-pass iteration, same twilight-angle high-latitude
// rule, same Dhuhr offset and the same rounding to the nearest minute
// (Python's round(): half to even). Configuration comes from
// packages/shared-schemas/prayer/methods.json (bundled as an asset).
import 'dart:math' as math;

const prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

class InvalidPrayerInput implements Exception {
  InvalidPrayerInput(this.message);
  final String message;
  @override
  String toString() => 'InvalidPrayerInput: $message';
}

class PrayerMethod {
  const PrayerMethod({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.fajr,
    this.isha,
    this.ishaMinutes,
    this.ishaMinutesRamadan,
  });

  factory PrayerMethod.fromJson(String id, Map<String, dynamic> j) => PrayerMethod(
    id: id,
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    fajr: (j['fajr'] as num).toDouble(),
    isha: (j['isha'] as num?)?.toDouble(),
    ishaMinutes: (j['ishaMinutes'] as num?)?.toDouble(),
    ishaMinutesRamadan: (j['ishaMinutesRamadan'] as num?)?.toDouble(),
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final double fajr;
  final double? isha;
  final double? ishaMinutes;

  /// Umm al-Qura: Isha interval during Ramadan (120 instead of 90).
  final double? ishaMinutesRamadan;
}

class PrayerConfig {
  const PrayerConfig({
    required this.dhuhrOffsetMinutes,
    required this.sunAltitude,
    required this.methods,
    required this.asrFactors,
    required this.kaabaLat,
    required this.kaabaLng,
    this.ramadan = const [],
  });

  factory PrayerConfig.fromJson(Map<String, dynamic> j) {
    final m = j['methods'] as Map<String, dynamic>;
    final k = j['kaaba'] as Map<String, dynamic>;
    if (j['highLatitudeRule'] != 'twilightAngle') {
      throw InvalidPrayerInput('unsupported highLatitudeRule ${j['highLatitudeRule']}');
    }
    return PrayerConfig(
      dhuhrOffsetMinutes: (j['dhuhrOffsetMinutes'] as num).toDouble(),
      sunAltitude: (j['sunAltitudeForSunriseSunset'] as num).toDouble(),
      methods: {for (final e in m.entries) e.key: PrayerMethod.fromJson(e.key, e.value as Map<String, dynamic>)},
      asrFactors: {for (final e in (j['asr'] as Map<String, dynamic>).entries) e.key: (e.value as num).toInt()},
      kaabaLat: (k['lat'] as num).toDouble(),
      kaabaLng: (k['lng'] as num).toDouble(),
      ramadan: [
        for (final v in ((j['ramadanUmmAlQura'] as Map<String, dynamic>?) ?? const {}).values)
          ((v as List)[0] as String, v[1] as String),
      ],
    );
  }

  final double dhuhrOffsetMinutes;
  final double sunAltitude;
  final Map<String, PrayerMethod> methods;
  final Map<String, int> asrFactors;
  final double kaabaLat;
  final double kaabaLng;

  /// [first, last] Gregorian day of each Ramadan (ISO, inclusive) by the Umm al-Qura calendar.
  final List<(String, String)> ramadan;

  /// True if the Gregorian date falls in Ramadan by the Umm al-Qura calendar.
  bool inRamadan(int y, int m, int d) {
    final iso = '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    return ramadan.any((r) => r.$1.compareTo(iso) <= 0 && iso.compareTo(r.$2) <= 0);
  }
}

/// Prayer times (UTC instants) for one local calendar date.
class PrayerDay {
  const PrayerDay(this.utc, this.highLatitudeAdjusted);
  final Map<String, DateTime> utc;
  final List<String> highLatitudeAdjusted;
}

double _d2r(double d) => d * math.pi / 180;
double _r2d(double r) => r * 180 / math.pi;

double _fix(double a, double b) {
  final x = a - b * (a / b).floorToDouble();
  return x < 0 ? x + b : x;
}

/// Python's round(): nearest integer, ties to even.
int roundHalfEven(double x) {
  final f = x.floorToDouble();
  final diff = x - f;
  if (diff > 0.5) return f.toInt() + 1;
  if (diff < 0.5) return f.toInt();
  return f.toInt().isEven ? f.toInt() : f.toInt() + 1;
}

double julianDay(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5;
}

/// Returns (declination in degrees, equation of time in hours).
(double, double) sunPosition(double jd) {
  final dd = jd - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * dd, 360);
  final q = _fix(280.459 + 0.98564736 * dd, 360);
  final lam = _fix(q + 1.915 * math.sin(_d2r(g)) + 0.020 * math.sin(_d2r(2 * g)), 360);
  final e = 23.439 - 0.00000036 * dd;
  final ra = _fix(_r2d(math.atan2(math.cos(_d2r(e)) * math.sin(_d2r(lam)), math.cos(_d2r(lam)))) / 15, 24);
  final decl = _r2d(math.asin(math.sin(_d2r(e)) * math.sin(_d2r(lam))));
  return (decl, q / 15 - ra);
}

class PrayerCalculator {
  const PrayerCalculator(this.config);
  final PrayerConfig config;

  /// UTC fractional hours (may be < 0 or >= 24) for the local date y-m-d.
  (Map<String, double>, List<String>) computeHours(
    int y,
    int m,
    int d,
    double lat,
    double lng,
    String method,
    int asrFactor,
  ) {
    if (lat.isNaN || lng.isNaN || !(lat > -90 && lat < 90) || lng < -180 || lng > 180) {
      throw InvalidPrayerInput('latitude must be in (-90, 90) and longitude in [-180, 180]');
    }
    final mt = config.methods[method];
    if (mt == null) throw InvalidPrayerInput('unknown method "$method"');
    if (asrFactor != 1 && asrFactor != 2) {
      throw InvalidPrayerInput('asr factor must be 1 (standard) or 2 (hanafi)');
    }
    final jd = julianDay(y, m, d) - lng / (15 * 24);

    double noon(double t) => _fix(12 - sunPosition(jd + t).$2, 24);

    double angleTime(double angle, double t, bool beforeNoon) {
      final decl = sunPosition(jd + t).$1;
      final cosH =
          (-math.sin(_d2r(angle)) - math.sin(_d2r(decl)) * math.sin(_d2r(lat))) /
          (math.cos(_d2r(decl)) * math.cos(_d2r(lat)));
      if (cosH < -1 || cosH > 1) return double.nan;
      final h = _r2d(math.acos(cosH)) / 15;
      final n = noon(t);
      return beforeNoon ? n - h : n + h;
    }

    double asrTime(int factor, double t) {
      final decl = sunPosition(jd + t).$1;
      final angle = -_r2d(math.atan(1 / (factor + math.tan(_d2r((lat - decl).abs())))));
      return angleTime(angle, t, false);
    }

    final sr = -config.sunAltitude;
    var t = <String, double>{'fajr': 5.0, 'sunrise': 6.0, 'dhuhr': 12.0, 'asr': 13.0, 'maghrib': 18.0, 'isha': 18.0};
    for (var i = 0; i < 2; i++) {
      final p = {for (final e in t.entries) e.key: (e.value.isNaN ? 12.0 : e.value) / 24};
      t = {
        'fajr': angleTime(mt.fajr, p['fajr']!, true),
        'sunrise': angleTime(sr, p['sunrise']!, true),
        'dhuhr': noon(p['dhuhr']!),
        'asr': asrTime(asrFactor, p['asr']!),
        'maghrib': angleTime(sr, p['maghrib']!, false),
        'isha': mt.ishaMinutes != null ? double.nan : angleTime(mt.isha!, p['isha']!, false),
      };
    }
    if (t['sunrise']!.isNaN || t['maghrib']!.isNaN) {
      throw InvalidPrayerInput('the sun does not rise or set at this location on this date (polar day/night)');
    }
    final adjusted = <String>[];
    if (mt.ishaMinutes != null) {
      final minutes = mt.ishaMinutesRamadan != null && config.inRamadan(y, m, d)
          ? mt.ishaMinutesRamadan!
          : mt.ishaMinutes!;
      t['isha'] = t['maghrib']! + minutes / 60;
    }
    final night = _fix(t['sunrise']! - t['maghrib']!, 24);
    var portion = mt.fajr / 60 * night;
    if (t['fajr']!.isNaN || _fix(t['sunrise']! - t['fajr']!, 24) > portion) {
      t['fajr'] = t['sunrise']! - portion;
      adjusted.add('fajr');
    }
    if (mt.ishaMinutes == null) {
      portion = mt.isha! / 60 * night;
      if (t['isha']!.isNaN || _fix(t['isha']! - t['maghrib']!, 24) > portion) {
        t['isha'] = t['maghrib']! + portion;
        adjusted.add('isha');
      }
    }
    t['dhuhr'] = t['dhuhr']! + config.dhuhrOffsetMinutes / 60;
    return ({for (final e in t.entries) e.key: e.value - lng / 15}, adjusted);
  }

  /// Prayer times for a local calendar day, rounded to the nearest minute.
  PrayerDay times({
    required int year,
    required int month,
    required int day,
    required double lat,
    required double lng,
    String method = 'mwl',
    String asr = 'standard',
    Map<String, int> adjustments = const {},
  }) {
    final factor = config.asrFactors[asr];
    if (factor == null) {
      throw InvalidPrayerInput("asr must be 'standard' or 'hanafi'");
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      throw InvalidPrayerInput('invalid date $year-$month-$day');
    }
    final base = DateTime.utc(year, month, day);
    if (base.month != month || base.day != day) {
      throw InvalidPrayerInput('invalid date $year-$month-$day');
    }
    final (hours, adjusted) = computeHours(year, month, day, lat, lng, method, factor);
    final out = <String, DateTime>{};
    for (final k in prayerKeys) {
      final minutes = roundHalfEven(hours[k]! * 60) + (adjustments[k] ?? 0);
      out[k] = base.add(Duration(minutes: minutes));
    }
    return PrayerDay(out, List.unmodifiable(adjusted));
  }

  /// Qibla bearing in degrees clockwise from true north.
  double qiblaBearing(double lat, double lng) {
    final dl = _d2r(config.kaabaLng - lng);
    final x = math.sin(dl);
    final y = math.cos(_d2r(lat)) * math.tan(_d2r(config.kaabaLat)) - math.sin(_d2r(lat)) * math.cos(dl);
    return _fix(_r2d(math.atan2(x, y)), 360);
  }
}
