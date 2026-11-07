// The selected / playing ayah highlight is drawn behind the text, translucent,
// and confined to its own line: it never hides a letter or a mark of its own
// line or of the lines above and below (light and dark).
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/theme/app_theme.dart';
import 'package:rattil/ui/mushaf_page.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  const capture = Key('capture');

  /// Shows [page] with [playing] highlighted (null: no highlight).
  Future<ValueNotifier<AyahRef?>> showPage(WidgetTester tester, int page, {String theme = 'light'}) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(tester, size: const Size(390, 844), prefs: {'theme': theme});
    final playing = ValueNotifier<AyahRef?>(null);
    await pushScreen(
      tester,
      Scaffold(
        body: RepaintBoundary(
          key: capture,
          child: ValueListenableBuilder<AyahRef?>(
            valueListenable: playing,
            builder: (_, p, _) => MushafPageView(page: page, playing: p),
          ),
        ),
      ),
    );
    return playing;
  }

  Future<(Uint8List, int)> grab(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
    return (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      final w = image.width;
      image.dispose();
      return (data!.buffer.asUint8List(), w);
    }))!;
  }

  List<(Rect, int)> highlights(WidgetTester tester) {
    final origin = tester.getTopLeft(find.byKey(capture));
    return [
      for (final e in find.byWidgetPredicate((w) => '${w.key}'.contains("'highlight-")).evaluate())
        (
          tester.getRect(find.byWidget(e.widget)).shift(-origin),
          int.parse(RegExp(r'highlight-\d+-\d+-(\d+)-').firstMatch('${e.widget.key}')!.group(1)!),
        ),
    ];
  }

  for (final (page, ref) in [(1, const AyahRef(1, 7)), (2, const AyahRef(2, 3))]) {
    for (final theme in ['light', 'dark']) {
      testWidgets(
        'page $page, ${ref.surah}:${ref.ayah} playing ($theme): highlight stays in its line, behind the text',
        (tester) async {
          final playing = await showPage(tester, page, theme: theme);
          final (before, width) = await grab(tester);
          playing.value = ref;
          await tester.pumpAndSettle();
          final (after, _) = await grab(tester);

          // Geometry: every highlight box lies inside its own line and touches no other line.
          final hl = highlights(tester);
          expect(hl, isNotEmpty);
          final origin = tester.getTopLeft(find.byKey(capture));
          final lineCount = page <= 2 ? 8 : 15;
          final lines = [
            for (var i = 0; i < lineCount; i++) tester.getRect(find.byKey(Key('mushafLine-$page-$i'))).shift(-origin),
          ];
          for (final (r, i) in hl) {
            expect(r.top, greaterThanOrEqualTo(lines[i].top - 0.5), reason: 'line $i');
            expect(r.bottom, lessThanOrEqualTo(lines[i].bottom + 0.5), reason: 'line $i');
            for (var j = 0; j < lineCount; j++) {
              if (j == i) continue;
              final overlap = r.intersect(lines[j]);
              expect(overlap.isEmpty || overlap.height <= 0.5, isTrue, reason: 'highlight in line $i overlaps line $j');
            }
          }

          // Translucent.
          final box = tester.widget<Container>(find.byWidgetPredicate((w) => '${w.key}'.contains("'highlight-")).first);
          expect((box.decoration! as BoxDecoration).color!.a, lessThan(1.0));

          // Pixels: outside the highlight boxes nothing changes (neighbouring lines intact);
          // inside, every pixel of ink is still ink (no glyph or mark is covered).
          final ink = AppTheme.of(tester.element(find.byType(MushafPageView)), 'paperInk');
          final ir = (ink.r * 255).round(), ig = (ink.g * 255).round(), ib = (ink.b * 255).round();
          double dist(Uint8List px, int o) {
            final dr = px[o] - ir, dg = px[o + 1] - ig, db = px[o + 2] - ib;
            return (dr * dr + dg * dg + db * db).toDouble();
          }

          var changedOutside = 0, inkPixels = 0, inkLost = 0;
          final height = before.length ~/ (4 * width);
          for (var y = 0; y < height; y++) {
            for (var x = 0; x < width; x++) {
              final o = (y * width + x) * 4;
              final inside = hl.any((h) => h.$1.inflate(1).contains(Offset(x + 0.5, y + 0.5)));
              if (!inside) {
                if (before[o] != after[o] || before[o + 1] != after[o + 1] || before[o + 2] != after[o + 2]) {
                  changedOutside++;
                }
              } else if (dist(before, o) < 30 * 30) {
                inkPixels++;
                if (dist(after, o) >= 60 * 60) inkLost++;
              }
            }
          }
          expect(changedOutside, 0, reason: 'nothing outside the highlight changes');
          expect(inkPixels, greaterThan(200), reason: 'the highlighted ayah has ink to check');
          expect(inkLost, 0, reason: 'no ink pixel is covered by the highlight');

          // Paint order: the highlight layer is the first child of the stack, under the text.
          final stack = tester.widget<Stack>(
            find.ancestor(of: find.byKey(const Key('mushafHighlightLayer')), matching: find.byType(Stack)).first,
          );
          expect(stack.children, hasLength(2));
          expect(
            find.descendant(
              of: find.byWidget(stack.children.first),
              matching: find.byKey(const Key('mushafHighlightLayer')),
            ),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('a selected ayah uses the same layer (behind the text, inside its lines)', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(tester, size: const Size(320, 568));
    await pushScreen(tester, const Scaffold(body: MushafPageView(page: 3, selected: AyahRef(2, 10))));
    final boxes = find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'highlight-2-10-"));
    expect(boxes, findsWidgets);
    for (final e in boxes.evaluate()) {
      final line = int.parse(RegExp(r'highlight-2-10-(\d+)-').firstMatch('${e.widget.key}')!.group(1)!);
      final r = tester.getRect(find.byWidget(e.widget));
      final l = tester.getRect(find.byKey(Key('mushafLine-3-$line')));
      expect(r.top, greaterThanOrEqualTo(l.top - 0.5));
      expect(r.bottom, lessThanOrEqualTo(l.bottom + 0.5));
    }
    expect(find.ancestor(of: boxes.first, matching: find.byType(IgnorePointer)), findsWidgets);
  });
}
