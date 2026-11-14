import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

import 'tawaf_plan.dart' show HajjDrawingColors;

typedef _L = StepsFlowLayout;

/// Numbered steps graphic of the Hajj/Umrah guide (owner, 2026-11-14): circles 1, 2, 3… in rows
/// of three, right to left on the first row and back on the next (a snake), joined by dotted
/// arrows. Same layout as apps/web/src/lib/steps-flow.ts.
class StepsFlowLayout {
  StepsFlowLayout._();
  static const width = 360.0;
  static const rowHeight = 140.0;
  static const radius = 30.0;
  static const _colsRtl = [300.0, 180.0, 60.0];

  static Offset position(int i) {
    final row = i ~/ 3, col = i % 3;
    final x = row.isEven ? _colsRtl[col] : _colsRtl[2 - col];
    return Offset(x, 50 + row * rowHeight);
  }

  static double height(int n) => (n / 3).ceil() * rowHeight - 20;

  /// The step whose circle or title is at [p] (layout units), or null.
  static int? hitTest(Offset p, int n) {
    for (var i = 0; i < n; i++) {
      final d = p - position(i);
      if (d.dx.abs() <= 60 && d.dy >= -50 && d.dy <= 90) return i;
    }
    return null;
  }

  /// "٨ ذو الحجة · يوم التروية" -> "يوم التروية".
  static String shortTitle(String title) => title.split('·').last.trim();

  /// At most two lines of similar length.
  static List<String> twoLines(String title) {
    final words = title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (title.length <= 12 || words.length < 2) return [title];
    var best = 1;
    var bestDiff = 1 << 30;
    for (var k = 1; k < words.length; k++) {
      final diff = (words.sublist(0, k).join(' ').length - words.sublist(k).join(' ').length).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = k;
      }
    }
    return [words.sublist(0, best).join(' '), words.sublist(best).join(' ')];
  }

  /// The dotted connector from step i to step i+1, with the end point and its heading.
  static (Path, Offset, double) connector(int i) {
    final a = position(i), b = position(i + 1);
    const r = radius + 6;
    if (a.dy == b.dy) {
      final dir = (b.dx - a.dx).sign;
      final ax = a.dx + dir * r, bx = b.dx - dir * r;
      final ctrl = Offset((ax + bx) / 2, a.dy - 26);
      final end = Offset(bx, b.dy);
      return (
        Path()
          ..moveTo(ax, a.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        end,
        math.atan2(end.dy - ctrl.dy, end.dx - ctrl.dx),
      );
    }
    final side = a.dx < width / 2 ? -1.0 : 1.0;
    final edge = a.dx + side * (radius + 28);
    final c2 = Offset(edge, b.dy - 30);
    final end = Offset(b.dx + side * r, b.dy);
    return (
      Path()
        ..moveTo(a.dx + side * r, a.dy)
        ..cubicTo(edge, a.dy + 30, c2.dx, c2.dy, end.dx, end.dy),
      end,
      math.atan2(end.dy - c2.dy, end.dx - c2.dx),
    );
  }
}

class StepsFlow extends StatelessWidget {
  const StepsFlow({super.key, required this.titles, required this.arabic, required this.label, this.onStep});
  final List<String> titles;
  final bool arabic;
  final String label;

  /// Tap on a step (index from 0), e.g. to show its explanation.
  final ValueChanged<int>? onStep;

  @override
  Widget build(BuildContext context) {
    final h = StepsFlowLayout.height(titles.length);
    final paint = CustomPaint(painter: _FlowPainter(titles, arabic));
    return Semantics(
      label: label,
      image: true,
      child: AspectRatio(
        aspectRatio: StepsFlowLayout.width / h,
        child: onStep == null
            ? paint
            : LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final p = Offset(
                      d.localPosition.dx * StepsFlowLayout.width / box.maxWidth,
                      d.localPosition.dy * h / box.maxHeight,
                    );
                    final i = StepsFlowLayout.hitTest(p, titles.length);
                    if (i != null) onStep!(i);
                  },
                  child: paint,
                ),
              ),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.titles, this.arabic);
  final List<String> titles;
  final bool arabic;

  static const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  String _num(int n) => arabic ? n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join() : '$n';

  void _text(Canvas c, String s, Offset center, double size, Color color, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: DesignTokens.fontUi, color: color, fontSize: size, fontWeight: w, height: 1.1),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 118);
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = _L.height(titles.length);
    canvas.save();
    canvas.scale(size.width / _L.width, size.height / h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, _L.width, h), const Radius.circular(14)),
      Paint()..color = HajjDrawingColors.bg,
    );
    final link = Paint()
      ..color = HajjDrawingColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < titles.length - 1; i++) {
      final (path, end, dir) = _L.connector(i);
      for (final m in path.computeMetrics()) {
        for (double d = 0; d < m.length - 6; d += 7) {
          canvas.drawPath(m.extractPath(d, d + 2), link);
        }
      }
      Offset pt(double ang, double r) => end + Offset(math.cos(ang) * r, math.sin(ang) * r);
      canvas.drawPath(
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(pt(dir + math.pi - 0.45, 11).dx, pt(dir + math.pi - 0.45, 11).dy)
          ..lineTo(pt(dir + math.pi + 0.45, 11).dx, pt(dir + math.pi + 0.45, 11).dy)
          ..close(),
        Paint()..color = HajjDrawingColors.accent,
      );
    }
    for (var i = 0; i < titles.length; i++) {
      final p = _L.position(i);
      canvas.drawCircle(p, _L.radius, Paint()..color = HajjDrawingColors.circle);
      canvas.drawCircle(
        p,
        _L.radius,
        Paint()
          ..color = HajjDrawingColors.path
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _text(canvas, _num(i + 1), p, 26, HajjDrawingColors.number, FontWeight.w800);
      final lines = _L.twoLines(_L.shortTitle(titles[i]));
      for (var k = 0; k < lines.length; k++) {
        _text(canvas, lines[k], p + Offset(0, _L.radius + 14 + k * 16), 12, HajjDrawingColors.ink, FontWeight.w700);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.titles != titles || old.arabic != arabic;
}
