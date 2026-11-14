import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/hajj_art.dart';

/// Owner, 2026-11-14: the tawaf drawing must show the walk anti-clockwise (Kaaba on the left).
/// The oval is the floor seen from the front (screen y grows downwards): the near half (lower
/// on screen) must run left to right, the far half right to left, the right end upwards and
/// the left end downwards.
void main() {
  const rx = 120.0, ry = 34.0;
  Offset dir(double a) {
    final d = tawafArrowDirection(a, rx, ry);
    return Offset(math.cos(d), math.sin(d));
  }

  test('tawaf arrows go anti-clockwise seen from above', () {
    expect(dir(math.pi / 2).dx, greaterThan(0.99)); // near side: left -> right
    expect(dir(math.pi * 1.5).dx, lessThan(-0.99)); // far side: right -> left
    expect(dir(0).dy, lessThan(-0.99)); // right end: away from the viewer
    expect(dir(math.pi).dy, greaterThan(0.99)); // left end: towards the viewer
    for (final a in tawafArrowAngles) {
      final p = Offset(math.cos(a) * rx, math.sin(a) * ry);
      final d = dir(a);
      // Cross product of position and heading: negative on screen (y down) = anti-clockwise.
      expect(p.dx * d.dy - p.dy * d.dx, lessThan(0), reason: 'arrow at $a');
    }
  });
}
