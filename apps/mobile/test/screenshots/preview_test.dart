// Preview pictures of the 1.2.1 screens for the owner (iPhone 6.9" size, 2x).
// Output: $RATTIL_SCREENSHOT_DIR/preview, or build/screenshots/preview.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/tasbih_screen.dart';
import 'package:rattil/ui/zakat_screen.dart';

import '../helpers.dart';
import '../widget/dhikr_extras_test.dart' show FakeUrlAudio;

final _zakatScroll = find.descendant(of: find.byKey(const Key('zakatList')), matching: find.byType(Scrollable)).first;

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/preview');
  const size = Size(440, 956);

  Future<void> shot(WidgetTester tester, String name) async {
    // The whole view (the routes and any sheet over them), with real soft shadows (the test default
    // paints them as solid black bands); the flag is put back before the test ends.
    final view = tester.binding.renderViews.first;
    void repaint(RenderObject o) {
      o.markNeedsPaint();
      o.visitChildren(repaint);
    }

    debugDisableShadows = false;
    repaint(view);
    await tester.pump();
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(Offset.zero & view.size, pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    debugDisableShadows = true;
    repaint(view);
    await tester.pump();
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
  }

  final prefs = <String, Object>{'theme': 'light'};

  testWidgets('preview: home tiles and the radio with its player', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await shot(tester, '01_home_tiles');
    await tester.ensureVisible(find.byKey(const Key('radio.play')));
    await tester.tap(find.byKey(const Key('radio.play')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('radio.station')));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await shot(tester, '02_home_radio_player');
  });

  testWidgets('preview: dhikr player under the dhikr', (tester) async {
    tester.view.devicePixelRatio = 1;
    final fake = FakeUrlAudio();
    debugUrlAudioFactory = () => fake;
    addTearDown(() => debugUrlAudioFactory = null);
    final app = await pumpApp(tester, size: size, prefs: prefs);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('dhikrListen')).first);
    await tester.pumpAndSettle();
    fake.durationC.add(const Duration(seconds: 74));
    fake.positionC.add(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(find.byKey(const Key('dhikrListen')).first), alignment: 0.55);
    await tester.pumpAndSettle();
    await shot(tester, '03_dhikr_player');
    await DhikrPlayer.instance.stop();
    await tester.pumpAndSettle();
  });

  testWidgets('preview: zakat on one screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, const ZakatScreen());
    await tester.enterText(find.byKey(const Key('zakat.money')), '400000');
    await tester.scrollUntilVisible(find.byKey(const Key('zakat.gold')), 200, scrollable: _zakatScroll);
    await tester.enterText(find.byKey(const Key('zakat.gold')), '100');
    await tester.scrollUntilVisible(find.byKey(const Key('zakat.goldPrice')), 200, scrollable: _zakatScroll);
    await tester.enterText(find.byKey(const Key('zakat.goldPrice')), '4000');
    await tester.scrollUntilVisible(find.byKey(const Key('zakat.animals')), 300, scrollable: _zakatScroll);
    await tester.enterText(find.byKey(const Key('zakat.animals')), '50');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('zakatSection-money')), -300, scrollable: _zakatScroll);
    await tester.pumpAndSettle();
    await shot(tester, '04_zakat_top');
    await tester.scrollUntilVisible(find.byKey(const Key('zakatTotal')), 400, scrollable: _zakatScroll);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await shot(tester, '05_zakat_total');
  });

  for (final (name, color, style) in [
    ('06_tasbih_glossy', 'emerald', 'glossy'),
    ('07_tasbih_marble', 'slate', 'marble'),
    ('08_tasbih_wood', 'brown', 'wood'),
    ('09_tasbih_pearl', 'rose', 'pearl'),
    ('10_tasbih_crystal', 'sky', 'crystal'),
  ]) {
    testWidgets('preview: tasbih $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        size: size,
        prefs: {
          ...prefs,
          'tasbih.v2':
              '{"phrase":"tasbih","counters":{"tasbih":{"count":12,"total":45,"rounds":1,"target":33}},'
              '"mode":"beads","color":"$color","style":"$style","vibrate":true}',
        },
      );
      await pushScreen(tester, const TasbihScreen());
      await shot(tester, name);
      if (style == 'glossy') {
        await tester.tap(find.byKey(const Key('tasbihLook')));
        await tester.pumpAndSettle();
        await shot(tester, '11_tasbih_look_sheet');
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tasbihChangeDhikr')));
        await tester.pumpAndSettle();
        await shot(tester, '12_tasbih_dhikr_list');
      }
    });
  }

  PageReaderScreenState reader(WidgetTester t) => t.state<PageReaderScreenState>(find.byType(PageReaderScreen));

  testWidgets('preview: mushaf page turn, highlight, whole surah, ayah list buttons', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, const PageReaderScreen(initialPage: 10));
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('mushafPageView'))));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(25, 0));
      await tester.pump();
    }
    await shot(tester, '13_mushaf_turn');
    await g.moveBy(const Offset(-150, 0));
    await g.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pageAyah-2-63')));
    await tester.pumpAndSettle();
    await shot(tester, '14_mushaf_highlight');
    await tester.tap(find.byKey(const Key('readerTab-surah')));
    await tester.pumpAndSettle();
    await shot(tester, '15_whole_surah');
    await tester.tap(find.byKey(const Key('readerTab-tafsir')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('ayahListPageButtons')),
      500,
      scrollable: find.descendant(of: find.byKey(const Key('readerBody')), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await shot(tester, '16_tafsir_next_page');
    expect(reader(tester).page, 10);
  });

  testWidgets('preview: mushaf held sideways without full screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(956, 440), prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, const PageReaderScreen(initialPage: 154));
    await shot(tester, '17_mushaf_landscape');
    await tester.tap(find.byKey(const Key('pageAyah-7-31')));
    await tester.pumpAndSettle();
    await shot(tester, '18_mushaf_landscape_ayah');
    await tester.tap(find.byKey(const Key('audioTafsirToggle')));
    await tester.pumpAndSettle();
    await shot(tester, '19_mushaf_landscape_tafsir');
    await tester.ensureVisible(find.byKey(const Key('readerFull')));
    await tester.tap(find.byKey(const Key('readerFull')));
    await tester.pumpAndSettle();
    await shot(tester, '20_mushaf_landscape_full');
  });
}
