import 'dart:math' as math;

/// A 3-axis sensor reading in the Android device frame (x right, y up the
/// screen, z out of the screen), as delivered by sensors_plus.
class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  Vec3 scale(double k) => Vec3(x * k, y * k, z * k);
}

/// Device heading (degrees clockwise from magnetic north, 0..360) from the
/// gravity (accelerometer) and geomagnetic (magnetometer) vectors, tilt-
/// compensated — the same maths as Android's SensorManager.getRotationMatrix +
/// getOrientation. Returns null when the readings cannot give a direction
/// (free fall, or the field is parallel to gravity).
double? headingFromSensors(Vec3 gravity, Vec3 magnetic) {
  final a = gravity.length;
  if (a < 0.1 * 9.81) return null;
  var h = magnetic.cross(gravity);
  final hn = h.length;
  if (hn < 0.1) return null;
  h = h.scale(1 / hn);
  final g = gravity.scale(1 / a);
  final m = g.cross(h);
  final az = math.atan2(h.y, m.y) * 180 / math.pi;
  return normalizeDegrees(az);
}

double normalizeDegrees(double d) {
  final r = d % 360;
  return r < 0 ? r + 360 : r;
}

/// Angle (−180..180] to turn clockwise from [heading] to face [qibla].
double turnAngle(double qibla, double heading) {
  final d = normalizeDegrees(qibla - heading);
  return d > 180 ? d - 360 : d;
}

/// Exponential smoothing on the circle (avoids the 359°→0° jump).
class HeadingFilter {
  HeadingFilter({this.alpha = 0.2});
  final double alpha;
  double? _s;
  double? _c;

  double? get value => _s == null ? null : normalizeDegrees(math.atan2(_s!, _c!) * 180 / math.pi);

  double add(double deg) {
    final r = deg * math.pi / 180;
    if (_s == null) {
      _s = math.sin(r);
      _c = math.cos(r);
    } else {
      _s = _s! + alpha * (math.sin(r) - _s!);
      _c = _c! + alpha * (math.cos(r) - _c!);
    }
    return value!;
  }
}

enum CompassMode { waiting, live, staticFallback }

/// Decides between the live compass and the static diagram: live once a valid
/// heading has arrived; static when the sensor stream failed, or when nothing
/// valid arrived before the start-up timeout; otherwise still waiting.
CompassMode compassMode({required bool hasHeading, required bool sensorError, required bool timedOut}) {
  if (sensorError) return CompassMode.staticFallback;
  if (hasHeading) return CompassMode.live;
  return timedOut ? CompassMode.staticFallback : CompassMode.waiting;
}

/// Whether the phone points at the qibla (within [tolerance] degrees).
bool facesQibla(double qibla, double heading, {double tolerance = 5}) => turnAngle(qibla, heading).abs() <= tolerance;
