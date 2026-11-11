import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A realistic prayer-bead strand (owner, 2026-11-11: "a real modern misbaha, not a graphic"):
/// glossy amber beads on a silk cord, the imam bead and a tassel. Each count slides one bead
/// down from the upper group to the lower group. Tap or swipe down to count.
class RealMisbaha extends StatefulWidget {
  const RealMisbaha({super.key, required this.count, required this.target, required this.onCount, this.bead});
  final int count;
  final int target;
  final VoidCallback onCount;

  /// Bead base colour (amber by default).
  final Color? bead;

  @override
  State<RealMisbaha> createState() => _RealMisbahaState();
}

class _RealMisbahaState extends State<RealMisbaha> with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void didUpdateWidget(RealMisbaha old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) _drop.forward(from: 0);
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('misbaha'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onCount,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 50) widget.onCount();
      },
      child: AnimatedBuilder(
        animation: _drop,
        builder: (context, _) => CustomPaint(
          painter: _MisbahaPainter(
            count: widget.count,
            target: widget.target,
            t: _drop.isAnimating ? Curves.easeIn.transform(_drop.value) : 1,
            bead: widget.bead ?? const Color(0xFFB8641E),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MisbahaPainter extends CustomPainter {
  _MisbahaPainter({required this.count, required this.target, required this.t, required this.bead});
  final int count;
  final int target;
  final double t;
  final Color bead;

  static const _shown = 11; // beads drawn in each group

  void _drawBead(Canvas c, Offset o, double r) {
    // Soft shadow on the backdrop.
    c.drawCircle(
      o + Offset(r * 0.18, r * 0.28),
      r * 1.02,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
    );
    final hsl = HSLColor.fromColor(bead);
    final light = hsl.withLightness((hsl.lightness + 0.28).clamp(0, 1)).toColor();
    final deep = hsl.withLightness((hsl.lightness - 0.22).clamp(0, 1)).toColor();
    // Body: lit from the upper left, darker rim (a polished stone/amber look).
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.05,
          colors: [light, bead, deep, Colors.black.withValues(alpha: 0.85)],
          stops: const [0.0, 0.45, 0.85, 1.0],
        ).createShader(Rect.fromCircle(center: o, radius: r)),
    );
    // Inner glow (light passing through amber).
    c.drawCircle(
      o + Offset(r * 0.2, r * 0.3),
      r * 0.45,
      Paint()
        ..color = light.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
    );
    // Specular highlight.
    c.drawOval(
      Rect.fromCenter(center: o + Offset(-r * 0.35, -r * 0.42), width: r * 0.62, height: r * 0.38),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCenter(center: o + Offset(-r * 0.35, -r * 0.42), width: r * 0.62, height: r * 0.38)),
    );
    // Drill hole hint where the cord enters.
    c.drawCircle(o + Offset(0, -r * 0.93), r * 0.12, Paint()..color = Colors.black.withValues(alpha: 0.45));
  }

  void _cord(Canvas c, Offset a, Offset b, double w) {
    c.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0xFF3B2A1A)
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      a.translate(-w * 0.2, 0),
      b.translate(-w * 0.2, 0),
      Paint()
        ..color = const Color(0xFFD9B87A).withValues(alpha: 0.5)
        ..strokeWidth = w * 0.35,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = math.min(size.width * 0.075, size.height / ((_shown * 2 + 5) * 2.0 * 0.92));
    final step = r * 1.84;
    final top = r * 1.2;
    final gapTop = top + _shown * step;
    final gap = r * 2.6;
    final lowerStart = gapTop + gap;

    _cord(canvas, Offset(cx, 0), Offset(cx, lowerStart + _shown * step + r * 2), r * 0.16);

    final inRound = target <= 0 ? 0 : count % target;
    final remaining = target - inRound;
    final upper = math.min(_shown, remaining);
    final lower = math.min(_shown, inRound);
    final moving = t < 1 && inRound > 0;

    // Upper group: beads still to count, resting on each other above the gap.
    for (var i = 0; i < upper; i++) {
      _drawBead(canvas, Offset(cx, gapTop - (i + 0.5) * step), r);
    }
    // Lower group: counted beads stacked from the gap down.
    final lowerDrawn = moving ? lower - 1 : lower;
    for (var i = 0; i < lowerDrawn; i++) {
      _drawBead(canvas, Offset(cx, lowerStart + (lowerDrawn - 1 - i + 0.5) * step + (moving ? step * t : 0)), r);
    }
    // The bead in motion across the gap.
    if (moving) {
      final from = gapTop - 0.5 * step;
      final to = lowerStart + 0.5 * step;
      _drawBead(canvas, Offset(cx, from + (to - from) * t), r);
    }
    // Imam bead (elongated) and tassel at the bottom.
    final imamY = lowerStart + _shown * step + r * 1.6;
    final imam = Rect.fromCenter(center: Offset(cx, imamY), width: r * 1.5, height: r * 2.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(imam, Radius.circular(r * 0.75)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            HSLColor.fromColor(bead).withLightness(0.62).toColor(),
            bead,
            HSLColor.fromColor(bead).withLightness(0.2).toColor(),
          ],
        ).createShader(imam),
    );
    final tasselTop = imam.bottom;
    final tassel = Paint()
      ..color = const Color(0xFF7A1F1F)
      ..strokeWidth = 1.4;
    for (var i = -6; i <= 6; i++) {
      final dx = i * r * 0.09;
      canvas.drawLine(
        Offset(cx + dx * 0.3, tasselTop),
        Offset(cx + dx, math.min(size.height, tasselTop + r * 3.2)),
        tassel,
      );
    }
  }

  @override
  bool shouldRepaint(_MisbahaPainter o) => o.count != count || o.target != target || o.t != t || o.bead != bead;
}
