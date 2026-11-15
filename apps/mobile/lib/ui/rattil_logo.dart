import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'r_icon.dart';

/// The Rattil mark inside the app, in the chosen colour style (owner 2026-11-15): the tile is the style's
/// brand gradient and the mihrab, star and Mushaf are its gold. Same drawing as the launcher icon
/// (assets in the platform folders), which stays one shared icon.
class RattilLogo extends StatelessWidget {
  const RattilLogo({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Rebuilt with the theme, so a new colour style repaints it.
    Theme.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.brand('dial1'), AppTheme.brand('dial2'), AppTheme.brand('dial3')],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: CustomPaint(
            painter: _MarkPainter(gold: AppTheme.brand('gold'), page: AppTheme.brand('heroAccent')),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.gold, required this.page});
  final Color gold;
  final Color page;

  static final _arch = parseSvgPath('M300 812V500C300 392 392 318 512 236C632 318 724 392 724 500V812');
  static final _star = parseSvgPath(
    'M512 330L523.5 364.3L555.8 348.2L539.7 380.5L574 392L539.7 403.5L555.8 435.8L523.5 419.7L512 454'
    'L500.5 419.7L468.2 435.8L484.3 403.5L450 392L484.3 380.5L468.2 348.2L500.5 364.3Z',
  );
  static final _rehal = parseSvgPath('M400 660L628 812M624 660L396 812');
  static final _book = parseSvgPath(
    'M512 566C466 534 414 524 368 534V676C414 666 466 676 512 708C558 676 610 666 656 676V534C610 524 558 534 512 566Z',
  );
  static final _spine = parseSvgPath('M512 566V708');

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024);
    canvas.drawCircle(const Offset(512, 512), 430, _stroke(gold.withValues(alpha: 0.14), 6));
    canvas.drawPath(_arch, _stroke(gold, 36));
    canvas.drawPath(_star, Paint()..color = gold);
    canvas.drawPath(_rehal, _stroke(gold, 26));
    canvas.drawPath(_book, Paint()..color = page);
    canvas.drawPath(_book, _stroke(gold, 20));
    canvas.drawPath(_spine, _stroke(Color.lerp(gold, Colors.black, 0.22)!, 14));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.gold != gold || old.page != page;
}
