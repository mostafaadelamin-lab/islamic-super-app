import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app_services.dart';
import '../domain/mushaf_layout.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';

/// Font sizing for one Mushaf page: one font size for the whole page, chosen
/// so that the widest line fits the width with a minimum word gap and the
/// glyphs fit the line height. Lines are then justified by distributing the
/// remaining width between the words (no wrapping, no scaling per line).
class MushafMetrics {
  MushafMetrics._();

  static const refSize = 100.0;

  /// Minimum gap between words, in em.
  static const minGapEm = 0.22;

  /// Width of the ayah-number marker, in em.
  static const markerEm = 1.15;

  static final Map<String, double> _widths = {};
  static double? _refHeight;

  static TextStyle style(double size, Color color) =>
      TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: size, color: color, height: 1.0);

  static double _measure(String text) => _widths.putIfAbsent(text, () {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style(refSize, const Color(0xFF000000))),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    _refHeight ??= tp.height;
    final w = tp.width;
    tp.dispose();
    return w;
  });

  static double get _heightAtRef {
    if (_refHeight == null) _measure('بِسْمِ');
    return _refHeight!;
  }

  /// Natural width at [refSize] of a line's display words.
  static double lineRefWidth(List<String> displayWords) {
    var w = 0.0;
    for (final s in displayWords) {
      w += _measure(s);
    }
    return w;
  }

  /// Largest font size at which a line of [refWidth] (at [refSize]) with
  /// [words] words and [markers] ayah markers fits [width].
  static double fitWidth(double width, double refWidth, int words, int markers) {
    final em = refWidth / refSize + markerEm * markers + minGapEm * math.max(0, words + markers - 1);
    return em <= 0 ? double.infinity : width / em;
  }

  /// Largest font size whose glyph box fits [lineHeight].
  static double fitHeight(double lineHeight) => lineHeight * 0.92 * refSize / _heightAtRef;
}

/// One Madinah Mushaf page drawn from mushaf-lines.v1.json: 15 lines (8 on
/// pages 1–2), surah title bands, basmala lines and ayah markers, inside a
/// gold frame on paper. Every word is a canonical word from quran.v1.json; the
/// display glyph map (quran-render.json) is applied only to the drawn string.
class MushafPageView extends StatelessWidget {
  const MushafPageView({
    super.key,
    required this.page,
    this.selected,
    this.playing,
    this.onAyahTap,
    this.onBackgroundTap,
  });

  final int page;
  final AyahRef? selected;
  final AyahRef? playing;
  final ValueChanged<AyahRef>? onAyahTap;
  final VoidCallback? onBackgroundTap;

  /// Smallest line height before the page scrolls instead of shrinking.
  static const minLineHeight = 16.0;
  static const headerHeight = 26.0;
  static const footerHeight = 24.0;
  static const outerPad = 6.0;
  static const framePad = 10.0;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final q = s.content.quran;
    final layout = s.content.mushaf.page(page);
    final paper = AppTheme.of(context, 'paper');
    final ink = AppTheme.of(context, 'paperInk');
    final frame = AppTheme.of(context, 'frame');
    final names = q.surahsOnPage(page).map((n) => q.surah(n).nameAr).join(' · ');
    final l = context.l10n;

    return Container(
      key: Key('mushafPage-$page'),
      color: AppTheme.of(context, 'surface2'),
      child: LayoutBuilder(
        builder: (context, c) {
          const chrome = 2 * outerPad + headerHeight + footerHeight + 2 * framePad + 8;
          final lineH = math.max(minLineHeight, (c.maxHeight - chrome) / 15);
          final totalH = math.max(c.maxHeight, lineH * 15 + chrome);
          final innerW = c.maxWidth - 2 * outerPad - 2 * framePad - 8;
          final words = [
            for (final line in layout.lines)
              line.kind == MushafLineKind.text ? lineWords(q, line) : const <MushafWord>[],
          ];
          final display = [
            for (final w in words) [for (final x in w) s.content.renderMap.forDisplay(x.text)],
          ];
          var font = MushafMetrics.fitHeight(lineH);
          for (var i = 0; i < words.length; i++) {
            if (words[i].isEmpty) continue;
            final markers = words[i].where((w) => w.endsAyah).length;
            final ref = MushafMetrics.lineRefWidth(display[i]);
            font = math.min(font, MushafMetrics.fitWidth(innerW * 0.985, ref, words[i].length, markers));
          }
          if (layout.centered) font *= 0.94;
          final firstKeyed = <AyahRef>{};

          Widget textLine(int i) {
            final ws = words[i];
            final children = <Widget>[];
            for (var k = 0; k < ws.length; k++) {
              final w = ws[k];
              final isFirst = firstKeyed.add(w.ref);
              final hl = w.ref == playing
                  ? AppTheme.of(context, 'verseHighlight')
                  : (w.ref == selected ? AppTheme.of(context, 'accentSoft') : null);
              Widget word = Text(
                display[i][k],
                key: isFirst ? Key('pageAyah-${w.ref.surah}-${w.ref.ayah}') : null,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                softWrap: false,
                style: MushafMetrics.style(font, ink),
              );
              if (hl != null) {
                word = DecoratedBox(
                  decoration: BoxDecoration(color: hl, borderRadius: BorderRadius.circular(4)),
                  child: word,
                );
              }
              word = MetaData(metaData: w.ref, behavior: HitTestBehavior.opaque, child: word);
              if (layout.centered) {
                word = Padding(
                  padding: EdgeInsets.symmetric(horizontal: font * 0.15),
                  child: word,
                );
              }
              children.add(word);
              if (w.endsAyah) {
                children.add(
                  MetaData(
                    metaData: w.ref,
                    behavior: HitTestBehavior.opaque,
                    child: AyahMarker(number: w.ref.ayah, size: font * MushafMetrics.markerEm, color: frame, ink: ink),
                  ),
                );
              }
            }
            if (layout.centered || ws.length < 2) {
              return MergeSemantics(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: children),
                  ),
                ),
              );
            }
            return MergeSemantics(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children),
            );
          }

          Widget line(int i) {
            final ml = layout.lines[i];
            return switch (ml.kind) {
              MushafLineKind.sura => SurahBand(surah: ml.surah, font: font, height: lineH),
              MushafLineKind.basmala => Center(
                key: Key('basmala-${ml.surah}'),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    s.content.renderMap.forDisplay(q.text(const AyahRef(1, 1))),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    style: MushafMetrics.style(font, ink),
                  ),
                ),
              ),
              MushafLineKind.text => textLine(i),
            };
          }

          final lines = [
            for (var i = 0; i < layout.lines.length; i++)
              SizedBox(key: Key('mushafLine-$page-$i'), height: lineH, child: line(i)),
          ];

          final pageBody = Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(outerPad),
              child: Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: framePad),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              names,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Directionality(
                            textDirection: Directionality.of(context),
                            child: Text(
                              l.quranJuz(context.num(q.juzOfPage(page))),
                              style: TextStyle(color: ink, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: paper,
                        border: Border.all(color: frame, width: 2),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: framePad - 3, vertical: framePad - 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: frame.withValues(alpha: 0.6), width: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Column(
                          mainAxisAlignment: layout.centered ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: lines,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: footerHeight,
                    child: Center(
                      child: Directionality(
                        textDirection: Directionality.of(context),
                        child: Text(
                          l.quranPage(context.num(page)),
                          key: const Key('pageHeader'),
                          style: TextStyle(color: ink, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: totalH,
              child: _TapLayer(onAyahTap: onAyahTap, onBackgroundTap: onBackgroundTap, child: pageBody),
            ),
          );
        },
      ),
    );
  }
}

/// Finds the ayah under a tap by hit-testing for the MetaData around each word
/// (one gesture detector per page: words are not separate semantic buttons).
class _TapLayer extends StatefulWidget {
  const _TapLayer({required this.child, this.onAyahTap, this.onBackgroundTap});
  final Widget child;
  final ValueChanged<AyahRef>? onAyahTap;
  final VoidCallback? onBackgroundTap;

  @override
  State<_TapLayer> createState() => _TapLayerState();
}

class _TapLayerState extends State<_TapLayer> {
  final _key = GlobalKey();

  void _onTapUp(TapUpDetails d) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(d.globalPosition));
    for (final e in result.path) {
      final t = e.target;
      if (t is RenderMetaData && t.metaData is AyahRef) {
        widget.onAyahTap?.call(t.metaData as AyahRef);
        return;
      }
    }
    widget.onBackgroundTap?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTapUp: _onTapUp,
    child: KeyedSubtree(key: _key, child: widget.child),
  );
}

/// Ayah-end marker: a gold ring with the ayah number in Arabic-Indic digits.
class AyahMarker extends StatelessWidget {
  const AyahMarker({super.key, required this.number, required this.size, required this.color, required this.ink});
  final int number;
  final double size;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _MarkerPainter(color),
      child: Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: FittedBox(
          child: Text(
            toArabicIndic(number),
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: DesignTokens.fontUi, color: ink, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
      ),
    ),
  );
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = math.max(1, r * 0.09);
    canvas.drawCircle(c, r * 0.92, stroke);
    canvas.drawCircle(c, r * 0.74, stroke..strokeWidth = math.max(0.6, r * 0.05));
    // Eight small petals around the ring.
    final dot = Paint()..color = color;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.92, r * 0.08, dot);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color;
}

/// Surah title band: "سورة …" in an ornamented gold frame.
class SurahBand extends StatelessWidget {
  const SurahBand({super.key, required this.surah, required this.font, required this.height});
  final int surah;
  final double font;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = context.services.content.quran.surah(surah);
    final frame = AppTheme.of(context, 'frame');
    return Padding(
      key: Key('surahBanner-$surah'),
      padding: EdgeInsets.symmetric(vertical: height * 0.08),
      child: CustomPaint(
        painter: _BandPainter(frame, AppTheme.of(context, 'accentSoft')),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: height),
              child: Text(
                'سورة ${s.nameAr}',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: DesignTokens.fontQuran,
                  fontSize: math.max(10, font * 0.95),
                  height: 1.7,
                  color: AppTheme.of(context, 'paperInk'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.frame, this.fill);
  final Color frame;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.drawRRect(r, Paint()..color = fill);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = frame
      ..strokeWidth = 1.4;
    canvas.drawRRect(r, p);
    canvas.drawRRect(r.deflate(3), p..strokeWidth = 0.7);
    // Diamond ornaments at both ends.
    for (final x in [size.height * 0.55, size.width - size.height * 0.55]) {
      final c = Offset(x, size.height / 2);
      final d = size.height * 0.22;
      final path = Path()
        ..moveTo(c.dx, c.dy - d)
        ..lineTo(c.dx + d, c.dy)
        ..lineTo(c.dx, c.dy + d)
        ..lineTo(c.dx - d, c.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = frame);
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.frame != frame || old.fill != fill;
}

/// Book-like page turn for a PageView: pages stay in place; the page with
/// the higher index swings about the spine (right edge in RTL) like a leaf,
/// while the page under it is shaded.
class BookPage extends StatelessWidget {
  const BookPage({super.key, required this.index, required this.controller, required this.child});
  final int index;
  final PageController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (!controller.hasClients || !controller.position.hasContentDimensions) return child!;
        final page = controller.page ?? controller.initialPage.toDouble();
        final d = index - page; // > 0: this page lies on top, swinging in/out.
        if (d.abs() >= 1 || d == 0) return child!;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Cancel the PageView's own slide so that both pages stay put.
        final dx = d * c.maxWidth * (rtl ? 1 : -1);
        if (d < 0) {
          // The page underneath: shade it while the leaf covers it.
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Colors.black.withValues(alpha: 0.16 * (1 + d))),
                  ),
                ),
              ],
            ),
          );
        }
        final angle = d * math.pi / 2 * 0.98;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(rtl ? -angle : angle);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform(alignment: rtl ? Alignment.centerRight : Alignment.centerLeft, transform: m, child: child),
        );
      },
      child: child,
    ),
  );
}
