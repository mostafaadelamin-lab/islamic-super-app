import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'r_icon.dart';

/// The Rattil mark inside the app, in the chosen colour style: the tile is the style's brand gradient and
/// the mihrab, crescent and Mushaf are its gold. Logo «crescent in the mihrab» (owner pick 2026-11-17).
/// Same drawing as the launcher icon (assets in the platform folders), which stays one shared icon.
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
            painter: _MarkPainter(
              gold: AppTheme.brand('gold'),
              goldSoft: AppTheme.brand('goldSoft'),
              page: AppTheme.brand('heroAccent'),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.gold, required this.goldSoft, required this.page});
  final Color gold;
  final Color goldSoft;
  final Color page;

  static final _arch = parseSvgPath('M282 800V512C282 398 384 314 512 226C640 314 742 398 742 512V800');
  static final _crescent = parseSvgPath('M531.1 328.2A84 84 0 1 0 588.9 443.8A66 66 0 0 1 531.1 328.2Z');
  static final _star = parseSvgPath(
    'M584.0 330.0L580.2 342.8L568.4 336.4L574.8 348.2L562.0 352.0L574.8 355.8L568.4 367.6L580.2 361.2L584'
    '.0 374.0L587.8 361.2L599.6 367.6L593.2 355.8L606.0 352.0L593.2 348.2L599.6 336.4L587.8 342.8Z',
  );
  static final _book = parseSvgPath(
    'M512 640C458 602 392 592 330 604V770C392 758 458 768 512 806C566 768 632 758 694 770V604C632 592 566'
    ' 602 512 640Z',
  );
  static final _spine = parseSvgPath('M512 640V806');
  static final _lines = parseSvgPath(
    'M372 652C412 646 452 652 488 670M372 700C412 694 452 700 488 718M536 670C572 652 612 646 652 652M536'
    ' 718C572 700 612 694 652 700',
  );

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
    canvas.drawPath(_arch, _stroke(gold, 44));
    canvas.drawPath(_crescent, Paint()..color = gold);
    canvas.drawPath(_star, Paint()..color = goldSoft);
    canvas.drawPath(_book, Paint()..color = page);
    canvas.drawPath(_book, _stroke(gold, 22));
    canvas.drawPath(_spine, _stroke(Color.lerp(gold, Colors.black, 0.22)!, 14));
    canvas.drawPath(_lines, _stroke(gold.withValues(alpha: 0.55), 10));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.gold != gold || old.goldSoft != goldSoft || old.page != page;
}
