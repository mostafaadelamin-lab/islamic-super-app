import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// What the reader picked on the celebration screen.
enum CelebrationChoice { back, again }

/// Strong vibration when the adhkar are finished (no sound, owner 2026-11-27).
@visibleForTesting
Future<void> Function() celebrationVibrate = () async {
  for (var i = 0; i < 5; i++) {
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();
    await Future<void>.delayed(const Duration(milliseconds: 140));
  }
};

/// Owner 2026-11-27 (option 1): after the last dhikr, a full screen with a crescent and gold stars falling,
/// a strong vibration and no sound; «رجوع» or «من جديد».
Future<CelebrationChoice> showAdhkarCelebration(BuildContext context, String subtitle) async {
  unawaited(celebrationVibrate());
  final r = await Navigator.of(context).push<CelebrationChoice>(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => AdhkarCelebration(subtitle: subtitle),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ),
  );
  return r ?? CelebrationChoice.back;
}

class AdhkarCelebration extends StatefulWidget {
  const AdhkarCelebration({super.key, required this.subtitle});
  final String subtitle;

  @override
  State<AdhkarCelebration> createState() => _AdhkarCelebrationState();
}

class _AdhkarCelebrationState extends State<AdhkarCelebration> with TickerProviderStateMixin {
  late final _fall = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  final _stars = List.generate(28, (i) {
    final r = math.Random(i * 7919 + 13);
    return (
      x: r.nextDouble(),
      size: 10 + r.nextDouble() * 18,
      speed: 0.6 + r.nextDouble() * 0.9,
      phase: r.nextDouble(),
    );
  });

  static const _gold = Color(0xFFE8C77A);

  @override
  void dispose() {
    _fall.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final moon = CurvedAnimation(
      parent: _pop,
      curve: const Interval(0, 0.7, curve: Curves.elasticOut),
    );
    final text = CurvedAnimation(
      parent: _pop,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    return Scaffold(
      key: const Key('adhkarCelebration'),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.1,
            colors: [Color(0xFF2B5590), Color(0xFF1D3A64), Color(0xFF0F2140)],
          ),
        ),
        child: Stack(
          children: [
            // The falling stars (behind everything, never catch taps).
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _fall,
                builder: (context, _) => Stack(
                  children: [
                    for (final s in _stars)
                      () {
                        final t = (_fall.value * s.speed + s.phase) % 1.0;
                        return Positioned(
                          left: s.x * size.width,
                          top: -30 + t * (size.height + 60),
                          child: Transform.rotate(
                            angle: t * math.pi * 2,
                            child: CustomPaint(size: Size.square(s.size), painter: _StarPainter()),
                          ),
                        );
                      }(),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(scale: moon, child: const _Crescent(size: 150)),
                      const SizedBox(height: DesignTokens.spaceXl),
                      FadeTransition(
                        opacity: text,
                        child: Column(
                          children: [
                            Text(
                              l.adhkarDoneTitle,
                              key: const Key('celebrationTitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                fontFamily: DesignTokens.fontUi,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spaceSm),
                            Text(
                              '${widget.subtitle} ✓',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontFamily: DesignTokens.fontUi,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spaceXl),
                            Wrap(
                              spacing: DesignTokens.spaceSm,
                              runSpacing: DesignTokens.spaceSm,
                              alignment: WrapAlignment.center,
                              children: [
                                FilledButton(
                                  key: const Key('celebrationBack'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _gold,
                                    foregroundColor: const Color(0xFF1B1300),
                                    minimumSize: const Size(120, 48),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(CelebrationChoice.back),
                                  child: Text(l.adhkarDoneBack),
                                ),
                                OutlinedButton.icon(
                                  key: const Key('celebrationAgain'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
                                    minimumSize: const Size(120, 48),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(CelebrationChoice.again),
                                  icon: const RIcon(RIcons.reset, color: Colors.white, size: 18),
                                  label: Text(l.adhkarDoneAgain),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A gold crescent with a soft glow.
class _Crescent extends StatelessWidget {
  const _Crescent({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CrescentPainter());
}

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0x66E8C77A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()..addOval(Rect.fromCircle(center: c.translate(-r * 0.55, -r * 0.18), radius: r));
    canvas.drawPath(Path.combine(PathOperation.difference, moon, bite), Paint()..color = const Color(0xFFE8C77A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A four-pointed gold star (drawn, so it never depends on a font having the glyph).
class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final k = r * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + k, c.dy - k)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + k, c.dy + k)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - k, c.dy + k)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - k, c.dy - k)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE8C77A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
