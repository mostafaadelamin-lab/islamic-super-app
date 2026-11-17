import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/tasbih.dart';

/// A prayer-bead strand drawn by the app (owner, 2026-11-11: "a real modern misbaha, not a graphic";
/// 2026-11-17: big beads in the middle of the screen, several bead styles, the colour really changes).
/// Large beads on a cord: an upper group, a stretch of twisted cord, and a lower group. Each count slides
/// the lowest upper bead down across the cord to the lower group. Tap or swipe down to count.
/// Every bead is painted here (gradients and strokes); no images are used.
class RealMisbaha extends StatefulWidget {
  const RealMisbaha({
    super.key,
    required this.count,
    required this.target,
    required this.onCount,
    this.bead,
    this.style = BeadStyle.glossy,
  });
  final int count;
  final int target;
  final VoidCallback onCount;

  /// Bead base colour.
  final Color? bead;
  final BeadStyle style;

  @override
  State<RealMisbaha> createState() => _RealMisbahaState();
}

class _RealMisbahaState extends State<RealMisbaha> with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));

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
          painter: MisbahaPainter(
            count: widget.count,
            t: _drop.isAnimating ? Curves.easeInOut.transform(_drop.value) : 1,
            bead: widget.bead ?? const Color(0xFF8A5A2B),
            style: widget.style,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class MisbahaPainter extends CustomPainter {
  MisbahaPainter({required this.count, required this.t, required this.bead, required this.style});
  final int count;

  /// Progress of the bead sliding down (1 = at rest).
  final double t;
  final Color bead;
  final BeadStyle style;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final r = math.min(w * 0.36, h / 10.5);
    final x = w / 2;
    final upperEnd = h * 0.52; // lower edge of the upper group
    final lowerStart = h * 0.76; // upper edge of the lower group
    c.save();
    c.clipRect(Offset.zero & size);

    // The cord: thin through the beads, twisted where it shows between the groups.
    final cord = Paint()
      ..color = const Color(0xFF2A2420)
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x, 0), Offset(x, h), cord);
    final twist = Paint()
      ..color = const Color(0xFF55483E)
      ..strokeWidth = r * 0.05;
    for (var y = upperEnd; y < lowerStart; y += r * 0.22) {
      c.drawLine(Offset(x - r * 0.08, y), Offset(x + r * 0.08, y + r * 0.12), twist);
    }

    // Upper group: j = 0 is the bead on its way down.
    final step = 2 * r * 1.02;
    for (var j = (upperEnd / step).ceil() + 1; j >= 1; j--) {
      final y = upperEnd - r - step * j + step * t;
      _bead(c, Offset(x, y), r, count + j);
    }
    // Lower group.
    for (var m = (h - lowerStart) ~/ step + 1; m >= 0; m--) {
      final y = lowerStart + r + step * m + step * t - step;
      _bead(c, Offset(x, y), r, count - m);
    }
    // The moving bead, drawn last so it passes over the cord.
    final y0 = upperEnd - r + (lowerStart - upperEnd) * t;
    _bead(c, Offset(x, y0), r, count);
    c.restore();
  }

  void _bead(Canvas c, Offset o, double r, int seed) {
    // Soft shadow.
    c.drawCircle(
      o + Offset(r * 0.06, r * 0.10),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );
    final rect = Rect.fromCircle(center: o, radius: r);
    final hsl = HSLColor.fromColor(bead);
    Color lift(double d) => hsl.withLightness((hsl.lightness + d).clamp(0.0, 1.0)).toColor();
    switch (style) {
      case BeadStyle.glossy:
        c.drawCircle(
          o,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.05,
              colors: [lift(0.30), bead, lift(-0.20)],
              stops: const [0, 0.55, 1],
            ).createShader(rect),
        );
      case BeadStyle.marble:
        c.drawCircle(
          o,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 1.1,
              colors: [Colors.white, lift(0.42), lift(0.25)],
            ).createShader(rect),
        );
        c.save();
        c.clipPath(Path()..addOval(rect));
        final rnd = math.Random(seed * 7919);
        for (var k = 0; k < 5; k++) {
          final p = Path()..moveTo(o.dx - r + rnd.nextDouble() * r * 0.4, o.dy - r + rnd.nextDouble() * 2 * r);
          var cx = p.getBounds().left;
          var cy = p.getBounds().top;
          for (var s = 0; s < 4; s++) {
            final nx = cx + r * (0.4 + rnd.nextDouble() * 0.3);
            final ny = cy + r * (rnd.nextDouble() - 0.5) * 0.9;
            p.quadraticBezierTo(
              (cx + nx) / 2 + r * (rnd.nextDouble() - 0.5) * 0.3,
              (cy + ny) / 2 + r * (rnd.nextDouble() - 0.5) * 0.5,
              nx,
              ny,
            );
            cx = nx;
            cy = ny;
          }
          c.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * (0.008 + rnd.nextDouble() * 0.018)
              ..color = lift(-0.10).withValues(alpha: 0.22 + rnd.nextDouble() * 0.28),
          );
        }
        c.restore();
      case BeadStyle.wood:
        c.drawCircle(
          o,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.2, -0.3),
              radius: 1.1,
              colors: [lift(0.12), bead, lift(-0.16)],
            ).createShader(rect),
        );
        c.save();
        c.clipPath(Path()..addOval(rect));
        final rnd = math.Random(seed * 104729);
        final grain = Paint()
          ..style = PaintingStyle.stroke
          ..color = lift(-0.22).withValues(alpha: 0.45);
        final cx = o.dx + r * (rnd.nextDouble() - 0.5) * 0.6;
        for (var k = 1; k < 9; k++) {
          grain.strokeWidth = r * (0.025 + rnd.nextDouble() * 0.03);
          c.drawOval(
            Rect.fromCenter(center: Offset(cx, o.dy + r * 1.6), width: r * 0.5 * k, height: r * 0.9 * k),
            grain,
          );
        }
        c.restore();
      case BeadStyle.pearl:
        c.drawCircle(
          o,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 1.0,
              colors: [Colors.white, Color.lerp(Colors.white, bead, 0.18)!, Color.lerp(Colors.white, bead, 0.45)!],
              stops: const [0, 0.6, 1],
            ).createShader(rect),
        );
        c.drawCircle(
          o,
          r,
          Paint()
            ..shader = SweepGradient(
              colors: [
                const Color(0x00FFFFFF),
                const Color(0x33FFC0E0),
                const Color(0x00FFFFFF),
                const Color(0x33B0E0FF),
                const Color(0x00FFFFFF),
              ],
            ).createShader(rect),
        );
      case BeadStyle.crystal:
        c.drawCircle(o, r, Paint()..color = bead.withValues(alpha: 0.55));
        c.drawCircle(
          o,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(0.3, 0.45),
              radius: 0.9,
              colors: [lift(0.35).withValues(alpha: 0.85), bead.withValues(alpha: 0)],
            ).createShader(rect),
        );
        c.drawCircle(
          o,
          r * 0.96,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.06
            ..color = Colors.white.withValues(alpha: 0.45),
        );
    }
    // Shine.
    c.drawOval(
      Rect.fromCenter(center: o + Offset(-r * 0.34, -r * 0.42), width: r * 0.62, height: r * 0.36),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: style == BeadStyle.wood ? 0.35 : 0.85),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCenter(center: o + Offset(-r * 0.34, -r * 0.42), width: r * 0.62, height: r * 0.36)),
    );
    // Rim.
    c.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = Colors.black.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(MisbahaPainter old) => old.count != count || old.t != t || old.bead != bead || old.style != style;
}

/// A small bead of [style] and [color] (style and colour pickers).
class BeadSwatch extends StatelessWidget {
  const BeadSwatch({super.key, required this.color, required this.style, this.size = 40});
  final Color color;
  final BeadStyle style;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SwatchPainter(color, style));
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.color, this.style);
  final Color color;
  final BeadStyle style;

  @override
  void paint(Canvas c, Size size) => MisbahaPainter(
    count: 3,
    t: 1,
    bead: color,
    style: style,
  )._bead(c, size.center(Offset.zero), size.width * 0.44, 3);

  @override
  bool shouldRepaint(_SwatchPainter old) => old.color != color || old.style != style;
}
