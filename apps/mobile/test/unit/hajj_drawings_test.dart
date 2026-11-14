import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/steps_flow.dart';
import 'package:rattil/ui/tawaf_plan.dart';

typedef _L = StepsFlowLayout;

typedef _G = TawafPlanGeometry;

/// Owner, 2026-11-14: tawaf starts at the Black Stone and goes anti-clockwise (screen y down).
void main() {
  test('every arrow turns anti-clockwise seen from above', () {
    for (final a in _G.arrows) {
      final p = Offset(math.cos(a) * _G.rx, math.sin(a) * _G.ry);
      final h = _G.heading(a);
      expect(p.dx * math.sin(h) - p.dy * math.cos(h), lessThan(0), reason: 'arrow at $a');
    }
  });

  test('corners in tawaf order: Black Stone, Iraqi, Shami, Yemeni going anti-clockwise', () {
    double ang(Offset p) => math.atan2(-(p.dy - _G.cy), p.dx - _G.cx);
    final order = [_G.blackStone, _G.iraqi, _G.shami, _G.yemeni].map(ang).toList();
    final rel = [for (final a in order) (a - order.first + 4 * math.pi) % (2 * math.pi)];
    expect(rel, [...rel]..sort());
  });

  test('starts on the path, outside the Kaaba, next to the Black Stone', () {
    final s = _G.startPoint();
    expect(math.pow((s.dx - _G.cx) / _G.rx, 2) + math.pow((s.dy - _G.cy) / _G.ry, 2), closeTo(1, 0.05));
    expect(s.dx, lessThan(_G.kaabaLeft));
    expect(s.dy, greaterThan(_G.kaabaTop + _G.kaabaSize));
  });

  test('steps snake right to left, then back; titles shortened and wrapped', () {
    expect(_L.position(0).dx, greaterThan(_L.position(1).dx));
    expect(_L.position(3).dx, lessThan(_L.position(4).dx));
    expect(_L.position(3).dx, _L.position(2).dx);
    expect(_L.shortTitle('٨ ذو الحجة · يوم التروية'), 'يوم التروية');
    expect(_L.twoLines('السعي بين الصفا والمروة'), hasLength(2));
    expect(_L.twoLines('الطواف'), ['الطواف']);
  });
}
