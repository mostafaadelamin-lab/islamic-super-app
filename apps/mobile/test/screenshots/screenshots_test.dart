// Renders key screens with the real bundled fonts (Amiri Quran, IBM Plex Sans
// Arabic, Material Icons) and writes PNG screenshots. Output directory:
// $RATTIL_SCREENSHOT_DIR, or build/screenshots by default.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/hajj_hub_screen.dart';
import 'package:rattil/ui/hajj_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/quran_index.dart';
import 'package:rattil/ui/surah_reader_screen.dart';
import 'package:rattil/ui/tasbih_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory(Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots');
  const phone = Size(412, 915);

  /// [overlay]: capture the whole view, including modal sheets drawn above the current route.
  Future<void> shot(WidgetTester tester, String name, {bool overlay = false}) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: find.byType(MaterialApp), matching: find.byType(RepaintBoundary)).first,
    );
    final view = tester.binding.renderViews.first;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = overlay
          ? await (view.debugLayer! as OffsetLayer).toImage(Offset.zero & view.size, pixelRatio: 2)
          : await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(10000), reason: 'a real, non-empty image');
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes);
  }

  testWidgets('colour styles 1 and 2, light and dark (owner 2026-11-15)', (tester) async {
    tester.view.devicePixelRatio = 1;
    for (final palette in ['emerald', 'madinah']) {
      for (final mode in ['light', 'dark']) {
        await pumpApp(tester, size: const Size(390, 860), prefs: {'palette': palette, 'theme': mode});
        await shot(tester, 'style_${palette}_${mode}_home');
      }
    }
    await pumpApp(tester, size: tallPhone, prefs: {'palette': 'madinah', 'theme': 'light'});
    await openSettings(tester);
    await shot(tester, 'style_settings');
  });

  testWidgets('Hajj & Umrah section: guide, official crowd links, live audio (owner, 2026-11-14)', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(390, 1100));
    await shot(tester, 'hajj_hub_home');
    await pushScreen(tester, const HajjHubScreen());
    await shot(tester, 'hajj_hub');
  });

  testWidgets('Hajj steps per type and a step explained (owner, 2026-11-14)', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(390, 1000));
    await pushScreen(tester, const HajjScreen());
    await tester.tap(find.byKey(const Key('hajjTab-hajj')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('hajjTypes')));
    await tester.pumpAndSettle();
    await shot(tester, 'hajj_types_tamattu', overlay: true);
    await tester.tap(find.byKey(const Key('hajjType-qiran')));
    await tester.pumpAndSettle();
    await shot(tester, 'hajj_types_qiran', overlay: true);
    final flow = tester.getRect(find.byKey(const Key('stepsFlow-hajj-qiran')));
    await tester.tapAt(flow.topLeft + Offset(300 * flow.width / 360, (50 + 2 * 140) * flow.height / (5 * 140 - 20)));
    await tester.pumpAndSettle();
    await shot(tester, 'hajj_types_sheet', overlay: true);
  });

  for (final theme in ['light', 'dark']) {
    testWidgets('icon set screenshots ($theme): home, nav, More, prayer, Quran, settings', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, size: const Size(390, 1640), prefs: {'theme': theme});
      await shot(tester, 'icons_${theme}_01_home');
      await pumpApp(tester, size: const Size(390, 1240), prefs: {'theme': theme});
      await goToTab(tester, 5);
      await shot(tester, 'icons_${theme}_02_more');
      await goToTab(tester, 2);
      await shot(tester, 'icons_${theme}_03_prayer');
      await goToTab(tester, 1);
      await shot(tester, 'icons_${theme}_04_quran');
      await goToTab(tester, 3);
      await shot(tester, 'icons_${theme}_05_adhkar');
    });
  }

  testWidgets('Mushaf full screen (ar): portrait pages, controls after a tap, a phone held sideways', (tester) async {
    PageReaderScreen.startFullScreen = true;
    addTearDown(() => PageReaderScreen.startFullScreen = false);
    for (final p in [1, 3, 604]) {
      await pumpApp(tester, size: const Size(390, 844), prefs: {'theme': 'light'});
      await pushScreen(tester, PageReaderScreen(initialPage: p));
      await shot(tester, 'mushaf_full_p$p');
    }
    await pumpApp(tester, size: const Size(390, 844), prefs: {'theme': 'light'});
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    await tester.tap(find.byKey(const Key('pageAyah-2-10')));
    await tester.pumpAndSettle();
    await shot(tester, 'mushaf_full_p3_controls');
    await pumpApp(tester, size: const Size(844, 390), prefs: {'theme': 'light'});
    await pushScreen(tester, const PageReaderScreen(initialPage: 4));
    await shot(tester, 'mushaf_full_landscape_p4');
  });

  testWidgets('iPad screenshots (ar)', (tester) async {
    tester.view.devicePixelRatio = 1;
    for (final size in const [Size(1194, 834), Size(834, 1194)]) {
      final tag = size.width > size.height ? 'landscape' : 'portrait';
      await pumpApp(tester, size: size, prefs: {'theme': 'light'});
      await shot(tester, 'ipad_${tag}_01_home');
      await goToTab(tester, 1);
      await shot(tester, 'ipad_${tag}_02_surah_list');
      await pushScreen(tester, const PageReaderScreen(initialPage: 50));
      await shot(tester, 'ipad_${tag}_03_mushaf');
      await goBack(tester);
      await pushScreen(tester, const SurahReaderScreen(surah: 1));
      await shot(tester, 'ipad_${tag}_04_surah_reader');
      await goBack(tester);
      await goToTab(tester, 2);
      await shot(tester, 'ipad_${tag}_05_prayer');
    }
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('home after the owner mockup ($locale): light and dark, whole page', (tester) async {
      tester.view.devicePixelRatio = 1;
      for (final theme in ['light', 'dark']) {
        await pumpApp(tester, locale: locale, size: const Size(390, 1640), prefs: {'theme': theme});
        await shot(tester, '${locale}_home_mockup${theme == 'dark' ? '_dark' : ''}');
      }
    });

    testWidgets('screenshots ($locale, light)', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        locale: locale,
        size: phone,
        prefs: {
          'theme': 'light',
          'lastRead.surah': 2,
          'lastRead.ayah': 255,
          'showTranslation': locale == 'en',
          'bookmarks.v1':
              '[{"id":"b-2-255","surah":2,"ayah":255,"updatedAt":2,"deleted":false},'
              '{"id":"b-36-1","surah":36,"ayah":1,"updatedAt":1,"deleted":false}]',
        },
      );
      await shot(tester, '${locale}_01_home');
      await goToTab(tester, 1);
      await shot(tester, '${locale}_02_surah_list');
      await pushScreen(tester, const SurahReaderScreen(surah: 1));
      await shot(tester, '${locale}_03_surah_reader');
      await goBack(tester);
      await pushScreen(tester, const PageReaderScreen(initialPage: 604));
      await shot(tester, '${locale}_04_mushaf_page_604');
      await goBack(tester);
      await goToTab(tester, 2);
      await shot(tester, '${locale}_05_prayer');
      await openBookmarks(tester);
      await shot(tester, '${locale}_06_bookmarks');
      await goBack(tester);
      await goToTab(tester, 5);
      await tester.scrollUntilVisible(
        find.byKey(const Key('more.settings')),
        200,
        scrollable: find.descendant(of: find.byKey(const Key('moreList')), matching: find.byType(Scrollable)),
      );
      await tester.tap(find.byKey(const Key('more.settings')));
      await tester.pumpAndSettle();
      await shot(tester, '${locale}_07_settings');
    });

    testWidgets('M2 screenshots ($locale): home, Mushaf page 3, tafsir, adhkar, tasbih, hajj', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        locale: locale,
        size: const Size(390, 844),
        prefs: {
          'theme': 'light',
          'lastRead.surah': 2,
          'lastRead.ayah': 6,
          'tasbih.v1': '{"count":12,"total":45,"rounds":1,"target":33}',
        },
      );
      await shot(tester, '${locale}_m2_home');
      await pushScreen(tester, const PageReaderScreen(initialPage: 3));
      await shot(tester, '${locale}_m2_mushaf_page_3');
      await goBack(tester);
      await pushScreen(tester, const PageReaderScreen(initialPage: 1));
      await shot(tester, '${locale}_m2_mushaf_page_1');
      await goBack(tester);
      await pushScreen(tester, const PageReaderScreen(initialPage: 42));
      await tester.tap(find.byKey(const Key('pageAyah-2-255')));
      await tester.pumpAndSettle();
      await shot(tester, '${locale}_m2_tafsir', overlay: true);
      await tester.tapAt(const Offset(195, 40)); // dismiss the sheet
      await tester.pumpAndSettle();
      await goBack(tester);
      await goToTab(tester, 3);
      await shot(tester, '${locale}_m2_adhkar');
      await goToTab(tester, 5);
      await shot(tester, '${locale}_m2_more');
      await pushScreen(tester, const TasbihScreen());
      await shot(tester, '${locale}_m2_tasbih');
      await goBack(tester);
      await pushScreen(tester, const HajjScreen());
      await shot(tester, '${locale}_m2_hajj');
    });

    testWidgets('M2 screenshots ($locale): recitation highlight and tafsir with recitation', (tester) async {
      tester.view.devicePixelRatio = 1;
      for (final theme in ['light', 'dark']) {
        final app = await pumpApp(
          tester,
          locale: locale,
          size: const Size(390, 844),
          prefs: {'theme': theme},
          audio: FakeAudioBackend(),
        );
        await pushScreen(tester, const PageReaderScreen(initialPage: 2));
        await app.services.recitation.playFrom(const AyahRef(2, 3));
        await tester.pumpAndSettle();
        final suffix = theme == 'dark' ? '_dark' : '';
        await shot(tester, '${locale}_m2_recitation_highlight$suffix', overlay: true);
        await app.services.settings.setTafsirWithRecitation(true);
        await tester.pumpAndSettle();
        await shot(tester, '${locale}_m2_recitation_tafsir$suffix', overlay: true);
        await app.services.recitation.stop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('M2 screenshots ($locale, dark): Mushaf page 50, home', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, locale: locale, size: const Size(390, 844), prefs: {'theme': 'dark'});
      await shot(tester, '${locale}_m2_home_dark');
      await pushScreen(tester, const PageReaderScreen(initialPage: 50));
      await shot(tester, '${locale}_m2_mushaf_page_50_dark');
    });

    testWidgets('screenshots ($locale, dark)', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, locale: locale, size: phone, prefs: {'theme': 'dark'});
      await goToTab(tester, 1);
      await pushScreen(tester, const SurahReaderScreen(surah: 2, initialAyah: 1));
      await shot(tester, '${locale}_08_surah_reader_dark');
      await goBack(tester);
      await goToTab(tester, 2);
      await shot(tester, '${locale}_09_prayer_dark');
    });
  }

  for (final theme in ['light', 'dark']) {
    testWidgets('Quran index screenshots ($theme): surahs and quarters', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, size: phone, prefs: {'theme': theme, 'lastRead.surah': 1, 'lastRead.ayah': 3});
      await goToTab(tester, 1);
      await shot(tester, 'index_${theme}_01_surahs');
      await tester.tap(find.byKey(const Key('tabQuarters')));
      await tester.pumpAndSettle();
      await shot(tester, 'index_${theme}_02_quarters');
      if (theme == 'light') {
        await tester.enterText(find.byKey(const Key('surahFilter')), 'الكهف');
        await tester.pumpAndSettle();
        await shot(tester, 'index_${theme}_03_quarters_search');
        await tester.tap(find.byKey(const Key('clearSearch')));
        await tester.tap(find.byKey(const Key('tabSurahs')));
        await tester.pumpAndSettle();
        unawaited(showQuranIndexSheet(tester.element(find.byType(QuranIndexView)), currentPage: 300));
        await tester.pumpAndSettle();
        await shot(tester, 'index_${theme}_04_sheet', overlay: true);
      }
    });
  }
}
