import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hajj_guide.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// One 3D picture of the Hajj & Umrah guide (owner 2026-11-16), drawn from hajj-scenes.v1.json with the
/// colours of the chosen style (scene-roles.v1.json); the website draws the same shapes as SVG.
class HajjSceneView extends StatelessWidget {
  const HajjSceneView({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final all = context.services.content.hajjScenes;
    final scene = all.scenes[id];
    if (scene == null) return const SizedBox.shrink();
    final b = Theme.of(context).brightness;
    final colours = SceneColours(all.roles, b);
    return Container(
      key: Key('hajjScene-$id'),
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
      padding: const EdgeInsets.all(DesignTokens.spaceXs),
      decoration: BoxDecoration(
        color: AppTheme.token(b, 'surface2'),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Semantics(
        image: true,
        label: scene.title,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: scene.w / scene.h,
              child: CustomPaint(painter: HajjScenePainter(scene, colours, AppTheme.palette)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolves roles to colours of the current style and brightness.
class SceneColours {
  SceneColours(this.roles, this.brightness);
  final Map<String, RoleColour> roles;
  final Brightness brightness;
  final _cache = <String, Color>{};

  Color of(String role) => _cache.putIfAbsent(role, () {
    final c = roles[role];
    if (c == null) throw StateError('hajj scene: no colour for role $role');
    return resolve(c);
  });

  Color resolve(RoleColour c) => switch (c) {
    TokenColour(:final name) => AppTheme.token(brightness, name),
    BrandColour(:final name) => AppTheme.brand(name),
    FixedColour(:final rgba) => Color((rgba & 0xff) << 24 | rgba >> 8),
    MixColour(:final a, :final b, :final p) => Color.lerp(resolve(b), resolve(a), p)!,
  };
}

class HajjScenePainter extends CustomPainter {
  HajjScenePainter(this.scene, this.colours, this.style);
  final HajjScene scene;
  final SceneColours colours;

  /// Changes with the colour style, so the picture repaints.
  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / scene.w, size.height / scene.h);
    for (final s in scene.shapes) {
      switch (s.type) {
        case 'poly':
          final path = _poly(s.points, close: true);
          canvas.drawPath(path, Paint()..color = colours.of(s.fill!));
          if (s.stroke != null) canvas.drawPath(path, _stroke(s));
        case 'ell':
          final r = Rect.fromCenter(center: Offset(s.n('cx'), s.n('cy')), width: s.n('rx') * 2, height: s.n('ry') * 2);
          canvas.drawOval(r, Paint()..color = colours.of(s.fill!));
          if (s.stroke != null) canvas.drawOval(r, _stroke(s));
        case 'circle':
          final c = Offset(s.n('cx'), s.n('cy'));
          canvas.drawCircle(c, s.n('r'), Paint()..color = colours.of(s.fill!));
          if (s.stroke != null) canvas.drawCircle(c, s.n('r'), _stroke(s));
        case 'dome':
          final cx = s.n('cx'), cy = s.n('cy'), rx = s.n('rx');
          final path = Path()
            ..moveTo(cx - rx, cy)
            ..arcToPoint(Offset(cx + rx, cy), radius: Radius.elliptical(rx, s.n('h')))
            ..arcToPoint(Offset(cx - rx, cy), radius: Radius.elliptical(rx, s.n('ry')))
            ..close();
          canvas.drawPath(path, Paint()..color = colours.of(s.fill!));
          canvas.drawPath(
            path,
            Paint()
              ..color = colours.of(s.stroke!)
              ..style = PaintingStyle.stroke,
          );
        case 'line':
          _line(canvas, s);
        case 'text':
          _text(canvas, s);
      }
    }
    canvas.restore();
  }

  Paint _stroke(SceneShape s) => Paint()
    ..color = colours.of(s.stroke!)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s.strokeWidth
    ..strokeJoin = StrokeJoin.round;

  static Path _poly(List<double> p, {required bool close}) {
    final path = Path()..moveTo(p[0], p[1]);
    for (var i = 2; i + 1 < p.length; i += 2) {
      path.lineTo(p[i], p[i + 1]);
    }
    if (close) path.close();
    return path;
  }

  void _line(Canvas canvas, SceneShape s) {
    final p = s.points;
    final paint = _stroke(s)..strokeCap = StrokeCap.round;
    final path = _poly(p, close: false);
    final dash = s.dash;
    if (dash == null || dash.length < 2) {
      canvas.drawPath(path, paint);
    } else {
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        var on = true;
        var k = 0;
        while (d < m.length) {
          final len = dash[k % dash.length];
          if (on) canvas.drawPath(m.extractPath(d, math.min(d + len, m.length)), paint);
          d += len;
          on = !on;
          k++;
        }
      }
    }
    if (s.arrow && p.length >= 4) {
      // Same arrow head as the website's SVG marker: 5 stroke widths long, its tip 1.5 widths past the end.
      final end = Offset(p[p.length - 2], p[p.length - 1]);
      final dir = end - Offset(p[p.length - 4], p[p.length - 3]);
      final a = math.atan2(dir.dy, dir.dx);
      final w = s.strokeWidth;
      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.rotate(a);
      final head = Path()
        ..moveTo(1.5 * w, 0)
        ..lineTo(-3.5 * w, -2.5 * w)
        ..lineTo(-3.5 * w, 2.5 * w)
        ..close();
      canvas.drawPath(head, Paint()..color = colours.of(s.stroke!));
      canvas.restore();
    }
  }

  void _text(Canvas canvas, SceneShape s) {
    final weight = (s.j['w'] as num?)?.toInt() ?? 500;
    TextPainter painter(Paint? fg, Color? colour) => TextPainter(
      text: TextSpan(
        text: s.text,
        style: TextStyle(
          fontFamily: DesignTokens.fontUi,
          fontSize: s.n('size'),
          fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
          color: colour,
          foreground: fg,
          height: 1,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();
    final halo = painter(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = AppTheme.token(colours.brightness, 'surface2'),
      null,
    );
    final body = painter(null, colours.of(s.fill!));
    // SVG puts the baseline at y; centre horizontally on x.
    final base = body.computeDistanceToActualBaseline(ui.TextBaseline.alphabetic);
    final at = Offset(s.n('x') - body.width / 2, s.n('y') - base);
    halo.paint(canvas, at);
    body.paint(canvas, at);
  }

  @override
  bool shouldRepaint(HajjScenePainter old) =>
      old.scene != scene || old.style != style || old.colours.brightness != colours.brightness;
}
