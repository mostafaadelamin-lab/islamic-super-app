import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

typedef _G = TawafPlanGeometry;

/// Tawaf seen from above (owner, 2026-11-14): our own drawing, a map turned so the Kaaba's door
/// wall faces the reader. Rotation only, never mirrored, so the walk stays anti-clockwise:
/// Black Stone = east corner (near left), Iraqi = north (near right), Shami = west (far right),
/// Yemeni = south (far left), Hijr Ismail beside the north-west wall (right), Maqam Ibrahim in
/// front of the door. Same numbers as apps/web/src/lib/tawaf-plan.ts.
class TawafPlanGeometry {
  TawafPlanGeometry._();
  static const width = 360.0;
  static const height = 300.0;
  static const kaabaLeft = 130.0, kaabaTop = 100.0, kaabaSize = 90.0;
  static const cx = 185.0, cy = 145.0, rx = 140.0, ry = 108.0;
  static const blackStone = Offset(130, 190);
  static const iraqi = Offset(220, 190);
  static const shami = Offset(220, 100);
  static const yemeni = Offset(130, 100);
  static const arrows = [
    math.pi * 0.3,
    math.pi * 0.55,
    math.pi,
    math.pi * 1.25,
    math.pi * 1.5,
    math.pi * 1.7,
    math.pi * 1.9,
  ];

  /// Anti-clockwise heading (screen y down) at angle [a] on the path.
  static double heading(double a) => math.atan2(-math.cos(a) * ry, math.sin(a) * rx);

  /// Where the start line from the Black Stone (outwards) meets the path.
  static Offset startPoint() {
    const d = math.sqrt1_2;
    var t = 0.0;
    for (; t < 400; t += 0.5) {
      final x = blackStone.dx - d * t, y = blackStone.dy + d * t;
      if (math.pow((x - cx) / rx, 2) + math.pow((y - cy) / ry, 2) >= 1) break;
    }
    return Offset(blackStone.dx - d * t, blackStone.dy + d * t);
  }
}

class TawafPlanLabels {
  const TawafPlanLabels({
    required this.kaaba,
    required this.blackStone,
    required this.yemeni,
    required this.shami,
    required this.iraqi,
    required this.door,
    required this.hijr,
    required this.maqam,
    required this.start,
    required this.direction,
    required this.title,
  });
  final String kaaba, blackStone, yemeni, shami, iraqi, door, hijr, maqam, start, direction, title;

  static const ar = TawafPlanLabels(
    kaaba: 'الكعبة',
    blackStone: 'الحجر الأسود',
    yemeni: 'الركن اليماني',
    shami: 'الركن الشامي',
    iraqi: 'الركن العراقي',
    door: 'الباب',
    hijr: 'حِجر إسماعيل',
    maqam: 'مقام إبراهيم',
    start: 'بداية الطواف',
    direction: 'اتجاه الطواف: عكس عقارب الساعة',
    title: 'خريطة الطواف من أعلى: يبدأ من الحجر الأسود عكس اتجاه عقارب الساعة والكعبة عن يسارك',
  );
  static const en = TawafPlanLabels(
    kaaba: 'Kaaba',
    blackStone: 'Black Stone',
    yemeni: 'Yemeni corner',
    shami: 'Shami corner',
    iraqi: 'Iraqi corner',
    door: 'Door',
    hijr: 'Hijr Ismail',
    maqam: 'Maqam Ibrahim',
    start: 'Start of tawaf',
    direction: 'Direction: anti-clockwise',
    title: 'Tawaf from above: start at the Black Stone, anti-clockwise, Kaaba on your left',
  );
}

/// Cream and brown colours of the Hajj drawings (same as the website).
class HajjDrawingColors {
  HajjDrawingColors._();
  static const bg = Color(0xFFF6EEDC);
  static const path = Color(0xFF8A6A45);
  static const accent = Color(0xFFB5652B);
  static const ink = Color(0xFF4A3726);
  static const strong = Color(0xFF8A3F12);
  static const gold = Color(0xFFC9A24A);
  static const hijr = Color(0xFFC9B48C);
  static const circle = Color(0xFFE9DCC0);
  static const number = Color(0xFF6B4A2B);
}

class TawafPlan extends StatelessWidget {
  const TawafPlan({super.key, required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final l = arabic ? TawafPlanLabels.ar : TawafPlanLabels.en;
    return Semantics(
      label: l.title,
      image: true,
      child: AspectRatio(
        aspectRatio: TawafPlanGeometry.width / TawafPlanGeometry.height,
        child: CustomPaint(key: const Key('tawafPlan'), painter: _PlanPainter(l)),
      ),
    );
  }
}

enum _Anchor { start, middle, end }

class _PlanPainter extends CustomPainter {
  _PlanPainter(this.l);
  final TawafPlanLabels l;

  late Canvas _c;

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  /// Text whose baseline-ish bottom sits at [p.dy], anchored like SVG text-anchor (left to right).
  void _text(
    String s,
    Offset p,
    _Anchor a, {
    Color color = HajjDrawingColors.ink,
    double size = 11,
    FontWeight weight = FontWeight.w600,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: DesignTokens.fontUi, color: color, fontSize: size, fontWeight: weight, height: 1),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final x = switch (a) {
      _Anchor.start => p.dx,
      _Anchor.middle => p.dx - tp.width / 2,
      _Anchor.end => p.dx - tp.width,
    };
    tp.paint(_c, Offset(x, p.dy - tp.height * 0.85));
  }

  void _dashedPath(Path path, Paint paint, double dash, double gap) {
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += dash + gap) {
        _c.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.save();
    canvas.scale(size.width / _G.width, size.height / _G.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, _G.width, _G.height), const Radius.circular(14)),
      _fill(HajjDrawingColors.bg),
    );
    // Path and arrows.
    _dashedPath(
      Path()..addOval(Rect.fromCenter(center: const Offset(_G.cx, _G.cy), width: _G.rx * 2, height: _G.ry * 2)),
      _stroke(HajjDrawingColors.path, 2),
      5,
      5,
    );
    for (final a in _G.arrows) {
      final p = Offset(_G.cx + math.cos(a) * _G.rx, _G.cy + math.sin(a) * _G.ry);
      final d = _G.heading(a);
      Offset pt(double ang, double r) => p + Offset(math.cos(ang) * r, math.sin(ang) * r);
      canvas.drawPath(
        Path()
          ..moveTo(pt(d, 6).dx, pt(d, 6).dy)
          ..lineTo(pt(d + 2.5, 12).dx, pt(d + 2.5, 12).dy)
          ..lineTo(pt(d - 2.5, 12).dx, pt(d - 2.5, 12).dy)
          ..close(),
        _fill(HajjDrawingColors.accent),
      );
    }
    const right = _G.kaabaLeft + _G.kaabaSize, bottom = _G.kaabaTop + _G.kaabaSize;
    // Hijr Ismail.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(right, _G.kaabaTop + _G.kaabaSize / 2), radius: 31),
      -math.pi / 2,
      math.pi,
      false,
      _stroke(HajjDrawingColors.hijr, 7),
    );
    _text(l.hijr, const Offset(right + 38, _G.kaabaTop + _G.kaabaSize / 2 + 4), _Anchor.start);
    // Kaaba.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(_G.kaabaLeft, _G.kaabaTop, _G.kaabaSize, _G.kaabaSize),
        const Radius.circular(3),
      ),
      _fill(const Color(0xFF1C1A17)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(_G.kaabaLeft + 5, _G.kaabaTop + 5, _G.kaabaSize - 10, _G.kaabaSize - 10),
        const Radius.circular(2),
      ),
      _stroke(HajjDrawingColors.gold, 2),
    );
    _text(
      l.kaaba,
      const Offset(_G.kaabaLeft + _G.kaabaSize / 2, _G.kaabaTop + _G.kaabaSize / 2 + 2),
      _Anchor.middle,
      color: HajjDrawingColors.bg,
      size: 12,
      weight: FontWeight.w700,
    );
    // Door, close to the Black Stone.
    canvas.drawRect(const Rect.fromLTWH(_G.kaabaLeft + 26, bottom - 7, 20, 7), _fill(HajjDrawingColors.gold));
    _text(
      l.door,
      const Offset(_G.kaabaLeft + 36, bottom - 10),
      _Anchor.middle,
      color: const Color(0xFFE8D6A8),
      size: 9,
    );
    // Maqam Ibrahim.
    final maqam = RRect.fromRectAndRadius(
      const Rect.fromLTWH(_G.kaabaLeft + 52, bottom + 18, 12, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(maqam, _fill(HajjDrawingColors.gold));
    canvas.drawRRect(maqam, _stroke(HajjDrawingColors.path, 1.5));
    _text(l.maqam, const Offset(_G.kaabaLeft + 58, bottom + 46), _Anchor.middle);
    // Corners.
    _text(l.yemeni, _G.yemeni + const Offset(-6, -6), _Anchor.end);
    _text(l.shami, _G.shami + const Offset(6, -6), _Anchor.start);
    _text(l.iraqi, _G.iraqi + const Offset(8, 16), _Anchor.start);
    for (final c in [_G.blackStone, _G.iraqi, _G.shami, _G.yemeni]) {
      canvas.drawCircle(c, 4, _fill(HajjDrawingColors.accent));
    }
    // Black Stone and the start of tawaf.
    final s = _G.startPoint();
    _dashedPath(
      Path()
        ..moveTo(_G.blackStone.dx, _G.blackStone.dy)
        ..lineTo(s.dx, s.dy),
      _stroke(HajjDrawingColors.accent, 2.5),
      4,
      3,
    );
    canvas.drawOval(Rect.fromCenter(center: _G.blackStone, width: 12, height: 14), _fill(const Color(0xFFC9CCD1)));
    canvas.drawOval(Rect.fromCenter(center: _G.blackStone, width: 8, height: 10), _fill(const Color(0xFF2B2B2B)));
    _text(
      l.blackStone,
      _G.blackStone + const Offset(-10, -4),
      _Anchor.end,
      color: HajjDrawingColors.strong,
      weight: FontWeight.w800,
    );
    canvas.drawCircle(s, 12, _fill(Colors.white));
    canvas.drawCircle(s, 10, _fill(HajjDrawingColors.accent));
    _text(
      l.start == TawafPlanLabels.ar.start ? '١' : '1',
      s + const Offset(0, 6),
      _Anchor.middle,
      color: Colors.white,
      size: 13,
      weight: FontWeight.w700,
    );
    _text(l.start, s + const Offset(0, 32), _Anchor.middle, color: HajjDrawingColors.strong, weight: FontWeight.w800);
    _text(
      l.direction,
      const Offset(_G.cx, _G.cy - _G.ry - 6),
      _Anchor.middle,
      color: const Color(0xFF7A6650),
      weight: FontWeight.w500,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanPainter old) => old.l != l;
}
