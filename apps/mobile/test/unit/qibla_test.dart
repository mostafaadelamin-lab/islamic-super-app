import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/qibla.dart';

void main() {
  // Phone flat, screen up: gravity reads +9.81 on z. The horizontal field
  // component points to magnetic north; in the northern hemisphere it also dips down (−z).
  const g = Vec3(0, 0, 9.81);
  Vec3 fieldTowards(double headingDeg) {
    // North expressed in device axes when the phone's top points at headingDeg.
    final r = headingDeg * math.pi / 180;
    return Vec3(-20 * math.sin(r), 20 * math.cos(r), -40);
  }

  test('heading from accelerometer + magnetometer (flat phone)', () {
    for (final h in [0.0, 45.0, 90.0, 135.0, 180.0, 270.0, 300.0]) {
      expect(headingFromSensors(g, fieldTowards(h)), closeTo(h, 1e-6), reason: '$h°');
    }
  });

  test('tilt-compensated: same heading when the phone is tilted towards the user', () {
    // Pitch the phone 30° (top up): rotate gravity and field about the x axis.
    const c = 0.8660254037844386, s = 0.5;
    Vec3 pitch(Vec3 v) => Vec3(v.x, c * v.y + s * v.z, -s * v.y + c * v.z);
    expect(headingFromSensors(pitch(g), pitch(fieldTowards(60))), closeTo(60, 1e-6));
  });

  test('no heading in free fall or when the field is parallel to gravity', () {
    expect(headingFromSensors(const Vec3(0, 0, 0.2), fieldTowards(10)), isNull);
    expect(headingFromSensors(g, const Vec3(0, 0, -40)), isNull);
  });

  test('turn angle is the shortest way round', () {
    expect(turnAngle(136, 100), closeTo(36, 1e-9));
    expect(turnAngle(10, 350), closeTo(20, 1e-9));
    expect(turnAngle(350, 10), closeTo(-20, 1e-9));
    expect(turnAngle(100, 280), closeTo(180, 1e-9));
    expect(facesQibla(136, 133), isTrue);
    expect(facesQibla(136, 120), isFalse);
  });

  test('heading filter smooths across 359° → 1° without swinging through 180°', () {
    final f = HeadingFilter(alpha: 0.5);
    f.add(359);
    final v = f.add(1);
    expect(turnAngle(v, 0).abs(), lessThan(1.01));
  });

  test('fallback: static on sensor error or timeout; live once a heading arrives', () {
    expect(compassMode(hasHeading: false, sensorError: false, timedOut: false), CompassMode.waiting);
    expect(compassMode(hasHeading: false, sensorError: false, timedOut: true), CompassMode.staticFallback);
    expect(compassMode(hasHeading: false, sensorError: true, timedOut: false), CompassMode.staticFallback);
    expect(compassMode(hasHeading: true, sensorError: false, timedOut: true), CompassMode.live);
    expect(compassMode(hasHeading: true, sensorError: true, timedOut: false), CompassMode.staticFallback);
  });
}
