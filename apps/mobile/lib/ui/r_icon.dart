import 'package:flutter/material.dart';

import '../theme/rattil_icons.dart';

export '../theme/rattil_icons.dart';

/// Draws a Rattil line icon ([RIcons]) the way [Icon] draws a glyph: size and
/// colour come from the arguments or the surrounding [IconTheme], so it fits
/// anywhere an [Icon] does (nav bars, list tiles, buttons). Decorative: it adds
/// no semantics unless [semanticLabel] is given.
class RIcon extends StatelessWidget {
  const RIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel});
  final RIconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    var c = color ?? theme.color ?? const Color(0xFF000000);
    final opacity = theme.opacity;
    if (opacity != null && opacity < 1) c = c.withValues(alpha: c.a * opacity);
    Widget painted = CustomPaint(size: Size.square(s), painter: _RIconPainter(icon, c));
    if (icon.mirrorInRtl && Directionality.of(context) == TextDirection.rtl) {
      painted = Transform.flip(flipX: true, child: painted);
    }
    final box = SizedBox.square(dimension: s, child: painted);
    return semanticLabel == null
        ? ExcludeSemantics(child: box)
        : Semantics(
            label: semanticLabel,
            child: ExcludeSemantics(child: box),
          );
  }
}

class _RIconPainter extends CustomPainter {
  _RIconPainter(this.icon, this.color);
  final RIconData icon;
  final Color color;

  static final _cache = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cache.putIfAbsent(icon.path, () => parseSvgPath(icon.path));
    final k = size.width / 24;
    canvas.save();
    canvas.scale(k);
    if (icon.filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = RIcons.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RIconPainter old) => old.icon != icon || old.color != color;
}

/// Parses SVG path data (M L H V C S Q T A Z, absolute and relative) into a [Path].
Path parseSvgPath(String d) {
  final tokens = RegExp(
    r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = 'M';
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  double? cx, cy; // last control point (for S / T)
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + n();
        y = oy + n();
        path.moveTo(x, y);
        sx = x;
        sy = y;
        cx = cy = null;
        cmd = rel ? 'l' : 'L'; // further pairs are line-tos
      case 'L':
        x = ox + n();
        y = oy + n();
        path.lineTo(x, y);
        cx = cy = null;
      case 'H':
        x = ox + n();
        path.lineTo(x, y);
        cx = cy = null;
      case 'V':
        y = oy + n();
        path.lineTo(x, y);
        cx = cy = null;
      case 'C':
        final x1 = ox + n(), y1 = oy + n(), x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'S':
        final x1 = cx == null ? x : 2 * x - cx, y1 = cy == null ? y : 2 * y - cy;
        final x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'Q':
        final x1 = ox + n(), y1 = oy + n();
        x = ox + n();
        y = oy + n();
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x1;
        cy = y1;
      case 'T':
        final x1 = cx == null ? x : 2 * x - cx, y1 = cy == null ? y : 2 * y - cy;
        x = ox + n();
        y = oy + n();
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x1;
        cy = y1;
      case 'A':
        final rx = n(), ry = n(), rot = n();
        final large = n() != 0, sweep = n() != 0;
        x = ox + n();
        y = oy + n();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rot, // degrees
          largeArc: large,
          clockwise: sweep,
        );
        cx = cy = null;
      case 'Z':
        path.close();
        x = sx;
        y = sy;
        cx = cy = null;
    }
  }
  return path;
}

/// A section icon on a soft emerald rounded square, as on the website's
/// section tiles (.tile-icon): used for the "More" list and similar menus.
class RIconBadge extends StatelessWidget {
  const RIconBadge(this.icon, {super.key, this.size = 40});
  final RIconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(size * 0.3)),
      child: RIcon(icon, size: size * 0.55, color: scheme.primary),
    );
  }
}
