import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Our own simple drawings for each Hajj/Umrah step (no photos or borrowed
/// art): picked from the step's title.
enum HajjScene {
  ihram,
  tawaf,
  sai,
  halq,
  madinah,
  mina,
  arafah,
  nahr,
  jamarat,
  farewell,
  types,
  pillars,
  miqat,
  forbidden,
  talbiya,
}

HajjScene? hajjSceneFor(String? title) {
  if (title == null) return null;
  const map = {
    'محظورات': HajjScene.forbidden,
    'المواقيت': HajjScene.miqat,
    'التلبية': HajjScene.talbiya,
    'الإحرام': HajjScene.ihram,
    'الطواف': HajjScene.tawaf,
    'السعي': HajjScene.sai,
    'الحلق': HajjScene.halq,
    'المدينة': HajjScene.madinah,
    'التروية': HajjScene.mina,
    'عرفة': HajjScene.arafah,
    'النحر': HajjScene.nahr,
    'التشريق': HajjScene.jamarat,
    'الوداع': HajjScene.farewell,
    'أنواع': HajjScene.types,
    'أركان': HajjScene.pillars,
  };
  for (final e in map.entries) {
    if (title.contains(e.key)) return e.value;
  }
  return null;
}

/// The drawing on a soft sky band, [height] tall.
class HajjArt extends StatelessWidget {
  const HajjArt({super.key, required this.scene, this.height = 120});
  final HajjScene scene;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0xFF1C2A33), const Color(0xFF2A2620)]
              : [const Color(0xFFE6F1F5), const Color(0xFFF7EEDC)],
        ),
      ),
      child: CustomPaint(
        painter: _ScenePainter(scene, primary: scheme.primary, gold: scheme.secondary, dark: dark),
        size: Size.infinite,
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, {required this.primary, required this.gold, required this.dark});
  final HajjScene scene;
  final Color primary;
  final Color gold;
  final bool dark;

  late Canvas _c;
  late Size _s;

  Paint _fill(Color c) => Paint()..color = c;
  Paint _line(Color c, [double w = 2.5]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  Color get _sand => dark ? const Color(0xFF5A4C35) : const Color(0xFFE3CFA4);
  Color get _ink => dark ? const Color(0xFFE8E2D4) : const Color(0xFF3B3326);
  Color get _cloth => dark ? const Color(0xFFF2F0EA) : Colors.white;

  double get w => _s.width;
  double get h => _s.height;
  double get ground => h * 0.82;

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    _s = size;
    // Ground.
    _c.drawRect(Rect.fromLTRB(0, ground, w, h), _fill(_sand));
    final cx = w / 2;
    switch (scene) {
      case HajjScene.ihram:
        _person(Offset(cx - 30, ground), 1);
        _person(Offset(cx + 30, ground), 1);
        _signPost(Offset(cx - 110, ground));
      case HajjScene.tawaf:
        _orbit(Offset(cx, ground - 30), 120, 34, 7);
        _kaaba(Offset(cx, ground - 6), 46);
      case HajjScene.sai:
        _hill(Offset(cx - 120, ground), 70, 34);
        _hill(Offset(cx + 120, ground), 70, 34);
        final y = ground - 12;
        _c.drawLine(Offset(cx - 80, y), Offset(cx + 80, y), _line(primary, 3));
        _arrowHead(Offset(cx + 80, y), 0);
        _arrowHead(Offset(cx - 80, y), math.pi);
        for (var i = 0; i < 7; i++) {
          _c.drawCircle(Offset(cx - 60 + i * 20.0, y - 14), 3.5, _fill(gold));
        }
      case HajjScene.halq:
        _scissors(Offset(cx, h * 0.45), 1.1);
      case HajjScene.madinah:
        _mosque(Offset(cx, ground));
      case HajjScene.mina:
        for (var i = -2; i <= 2; i++) {
          _tent(Offset(cx + i * 58.0, ground), 46 - (i.abs() * 4.0));
        }
      case HajjScene.arafah:
        _sun(Offset(cx + 110, h * 0.32), 16);
        _hill(Offset(cx, ground), 170, 54);
        _c.drawRect(Rect.fromCenter(center: Offset(cx, ground - 64), width: 8, height: 22), _fill(_cloth));
        for (var i = -3; i <= 3; i++) {
          if (i == 0) continue;
          _personSmall(Offset(cx + i * 34.0, ground));
        }
      case HajjScene.nahr:
        _jamrah(Offset(cx - 70, ground), 64);
        _pebbles(Offset(cx - 30, ground - 50), toLeft: true);
        _personSmall(Offset(cx, ground));
        _kaaba(Offset(cx + 100, ground), 40);
      case HajjScene.jamarat:
        _jamrah(Offset(cx - 90, ground), 44);
        _jamrah(Offset(cx, ground), 54);
        _jamrah(Offset(cx + 90, ground), 64);
        for (var i = 0; i < 7; i++) {
          _c.drawCircle(Offset(cx - 60 + i * 20.0, ground + 8), 3, _fill(_ink));
        }
      case HajjScene.farewell:
        _orbit(Offset(cx - 30, ground - 30), 100, 30, 0);
        _kaaba(Offset(cx - 30, ground - 6), 40);
        final y = ground - 30;
        _c.drawLine(Offset(cx + 40, y), Offset(cx + 140, y), _line(primary, 3));
        _arrowHead(Offset(cx + 140, y), 0);
      case HajjScene.types:
        for (var i = 0; i < 3; i++) {
          final x = cx + (i - 1) * 80.0;
          final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, h * 0.5), width: 60, height: 72),
            const Radius.circular(12),
          );
          _c.drawRRect(r, _fill(_cloth));
          _c.drawRRect(r, _line(gold, 2));
          for (var k = 0; k <= i; k++) {
            _c.drawCircle(Offset(x - i * 8.0 + k * 16.0, h * 0.5), 5, _fill(primary));
          }
        }
      case HajjScene.pillars:
        for (var i = 0; i < 4; i++) {
          final x = cx + (i - 1.5) * 64;
          _c.drawCircle(Offset(x, h * 0.48), 22, _fill(primary));
          final p = Path()
            ..moveTo(x - 9, h * 0.48)
            ..lineTo(x - 2, h * 0.48 + 8)
            ..lineTo(x + 10, h * 0.48 - 8);
          _c.drawPath(p, _line(Colors.white, 3.5));
        }
      case HajjScene.miqat:
        final c = Offset(cx, h * 0.5);
        _dashedCircle(c, 46);
        _kaaba(c + const Offset(0, 14), 26);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          _pin(c + Offset(math.cos(a) * 46 * 1.6, math.sin(a) * 46 * 0.85));
        }
      case HajjScene.forbidden:
        final c = Offset(cx, h * 0.47);
        _scissors(c, 0.7);
        _c.drawCircle(c, 40, _line(const Color(0xFFC0392B), 5));
        _c.drawLine(c + const Offset(-28, 28), c + const Offset(28, -28), _line(const Color(0xFFC0392B), 5));
      case HajjScene.talbiya:
        _person(Offset(cx - 20, ground), 1);
        for (var i = 1; i <= 3; i++) {
          _c.drawArc(
            Rect.fromCircle(center: Offset(cx - 8, ground - 64), radius: 12.0 * i),
            -math.pi / 3,
            2 * math.pi / 3,
            false,
            _line(gold, 2.5),
          );
        }
    }
  }

  void _kaaba(Offset bottom, double size) {
    final r = Rect.fromLTWH(bottom.dx - size / 2, bottom.dy - size, size, size);
    _c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _fill(const Color(0xFF151515)));
    _c.drawRect(Rect.fromLTWH(r.left, r.top + size * 0.22, size, size * 0.1), _fill(gold));
    _c.drawRect(
      Rect.fromLTWH(r.left + size * 0.62, r.bottom - size * 0.42, size * 0.18, size * 0.32),
      _fill(gold.withValues(alpha: 0.8)),
    );
  }

  void _orbit(Offset c, double rx, double ry, int dots) {
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    _c.drawOval(rect, _line(primary.withValues(alpha: 0.6), 2));
    // Anti-clockwise, with the Kaaba on the left as in tawaf.
    for (final a in [math.pi * 0.15, math.pi * 1.15]) {
      final p = c + Offset(math.cos(a) * rx, math.sin(a) * ry);
      final dir = math.atan2(-math.cos(a) * ry, math.sin(a) * rx) + math.pi;
      _arrowHead(p, dir);
    }
    for (var i = 0; i < dots; i++) {
      final a = math.pi + i * 2 * math.pi / dots;
      _c.drawCircle(c + Offset(math.cos(a) * rx, math.sin(a) * ry), 4, _fill(gold));
    }
  }

  void _arrowHead(Offset p, double angle) {
    const len = 10.0;
    final path = Path()
      ..moveTo(p.dx + math.cos(angle) * 4, p.dy + math.sin(angle) * 4)
      ..lineTo(p.dx + math.cos(angle + 2.5) * len, p.dy + math.sin(angle + 2.5) * len)
      ..lineTo(p.dx + math.cos(angle - 2.5) * len, p.dy + math.sin(angle - 2.5) * len)
      ..close();
    _c.drawPath(path, _fill(primary));
  }

  void _person(Offset feet, double k) {
    final head = feet + Offset(0, -62 * k);
    _c.drawCircle(head, 8 * k, _fill(_ink.withValues(alpha: 0.85)));
    // Two white cloths: lower wrap and upper wrap over one shoulder.
    final lower = RRect.fromRectAndRadius(
      Rect.fromLTRB(feet.dx - 13 * k, feet.dy - 30 * k, feet.dx + 13 * k, feet.dy - 4 * k),
      const Radius.circular(4),
    );
    _c.drawRRect(lower, _fill(_cloth));
    _c.drawRRect(lower, _line(_ink.withValues(alpha: 0.4), 1.2));
    final upper = Path()
      ..moveTo(feet.dx - 14 * k, feet.dy - 30 * k)
      ..lineTo(feet.dx - 12 * k, feet.dy - 50 * k)
      ..quadraticBezierTo(feet.dx, feet.dy - 56 * k, feet.dx + 12 * k, feet.dy - 50 * k)
      ..lineTo(feet.dx + 14 * k, feet.dy - 30 * k)
      ..close();
    _c.drawPath(upper, _fill(_cloth));
    _c.drawPath(upper, _line(_ink.withValues(alpha: 0.4), 1.2));
    // Bare right shoulder.
    _c.drawCircle(feet + Offset(10 * k, -49 * k), 4 * k, _fill(const Color(0xFFC89F7A)));
    _c.drawLine(feet + Offset(-6 * k, -4 * k), feet + Offset(-6 * k, 0), _line(_ink, 2));
    _c.drawLine(feet + Offset(6 * k, -4 * k), feet + Offset(6 * k, 0), _line(_ink, 2));
  }

  void _personSmall(Offset feet) {
    _c.drawCircle(feet + const Offset(0, -26), 4, _fill(_ink.withValues(alpha: 0.8)));
    _c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(feet.dx - 6, feet.dy - 21, feet.dx + 6, feet.dy), const Radius.circular(3)),
      _fill(_cloth),
    );
  }

  void _signPost(Offset foot) {
    _c.drawLine(foot, foot + const Offset(0, -56), _line(_ink, 3));
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(foot.dx - 22, foot.dy - 66, 44, 18), const Radius.circular(4));
    _c.drawRRect(r, _fill(primary));
  }

  void _hill(Offset base, double width, double height) {
    final p = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..quadraticBezierTo(base.dx, base.dy - height * 2, base.dx + width / 2, base.dy)
      ..close();
    _c.drawPath(p, _fill(Color.lerp(_sand, _ink, 0.25)!));
  }

  void _scissors(Offset c, double k) {
    final p = _line(_ink, 4 * k);
    _c.drawLine(c + Offset(-30 * k, -26 * k), c + Offset(26 * k, 24 * k), p);
    _c.drawLine(c + Offset(30 * k, -26 * k), c + Offset(-26 * k, 24 * k), p);
    _c.drawCircle(c + Offset(-32 * k, 30 * k), 10 * k, _line(gold, 4 * k));
    _c.drawCircle(c + Offset(32 * k, 30 * k), 10 * k, _line(gold, 4 * k));
    _c.drawCircle(c, 3 * k, _fill(gold));
  }

  void _mosque(Offset base) {
    final green = dark ? const Color(0xFF3E9B6A) : const Color(0xFF2E7D57);
    _c.drawRect(Rect.fromLTRB(base.dx - 90, base.dy - 34, base.dx + 90, base.dy), _fill(_cloth));
    _c.drawRect(
      Rect.fromLTRB(base.dx - 90, base.dy - 34, base.dx + 90, base.dy),
      _line(_ink.withValues(alpha: 0.3), 1),
    );
    _c.drawArc(
      Rect.fromCircle(center: Offset(base.dx + 20, base.dy - 34), radius: 26),
      math.pi,
      math.pi,
      true,
      _fill(green),
    );
    _c.drawLine(Offset(base.dx + 20, base.dy - 60), Offset(base.dx + 20, base.dy - 72), _line(gold, 2));
    for (final x in [base.dx - 70, base.dx + 76]) {
      _c.drawRect(Rect.fromLTRB(x - 6, base.dy - 84, x + 6, base.dy - 34), _fill(_cloth));
      _c.drawRect(Rect.fromLTRB(x - 6, base.dy - 84, x + 6, base.dy - 34), _line(_ink.withValues(alpha: 0.3), 1));
      final cap = Path()
        ..moveTo(x - 7, base.dy - 84)
        ..lineTo(x, base.dy - 98)
        ..lineTo(x + 7, base.dy - 84)
        ..close();
      _c.drawPath(cap, _fill(green));
    }
    for (var i = 0; i < 5; i++) {
      final x = base.dx - 50 + i * 22.0;
      _c.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x - 5, base.dy - 22, 10, 16),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        _fill(gold.withValues(alpha: 0.7)),
      );
    }
  }

  void _tent(Offset base, double size) {
    final p = Path()
      ..moveTo(base.dx - size / 2, base.dy)
      ..lineTo(base.dx, base.dy - size * 0.8)
      ..lineTo(base.dx + size / 2, base.dy)
      ..close();
    _c.drawPath(p, _fill(_cloth));
    _c.drawPath(p, _line(_ink.withValues(alpha: 0.35), 1.2));
    _c.drawLine(Offset(base.dx, base.dy - size * 0.8), Offset(base.dx, base.dy - size * 0.95), _line(gold, 2));
  }

  void _sun(Offset c, double r) {
    _c.drawCircle(c, r, _fill(gold.withValues(alpha: 0.9)));
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      _c.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r + 4),
        c + Offset(math.cos(a), math.sin(a)) * (r + 10),
        _line(gold, 2),
      );
    }
  }

  void _jamrah(Offset base, double height) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTRB(base.dx - 12, base.dy - height, base.dx + 12, base.dy),
      const Radius.circular(6),
    );
    _c.drawRRect(r, _fill(Color.lerp(_sand, _ink, 0.45)!));
  }

  void _pebbles(Offset start, {required bool toLeft}) {
    for (var i = 0; i < 4; i++) {
      final p = start + Offset((toLeft ? -1 : 1) * i * 9.0, i * 4.0 - 4);
      _c.drawCircle(p, 2.6, _fill(_ink));
    }
  }

  void _dashedCircle(Offset c, double r) {
    const n = 28;
    for (var i = 0; i < n; i += 2) {
      _c.drawArc(
        Rect.fromCenter(center: c, width: r * 3.2, height: r * 1.7),
        i * 2 * math.pi / n,
        2 * math.pi / n,
        false,
        _line(primary.withValues(alpha: 0.5), 2),
      );
    }
  }

  void _pin(Offset p) {
    final path = Path()
      ..moveTo(p.dx, p.dy + 10)
      ..quadraticBezierTo(p.dx - 9, p.dy - 2, p.dx - 7, p.dy - 7)
      ..arcToPoint(Offset(p.dx + 7, p.dy - 7), radius: const Radius.circular(8))
      ..quadraticBezierTo(p.dx + 9, p.dy - 2, p.dx, p.dy + 10)
      ..close();
    _c.drawPath(path, _fill(primary));
    _c.drawCircle(p + const Offset(0, -5), 2.5, _fill(Colors.white));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.scene != scene || old.primary != primary || old.dark != dark;
}
