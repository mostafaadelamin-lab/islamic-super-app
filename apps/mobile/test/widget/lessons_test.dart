import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/domain/lessons.dart';
import 'package:rattil/ui/lessons_screen.dart';
import 'package:rattil/ui/library_screen.dart' show OfflineButton;

import '../helpers.dart';

LessonCatalog _read() => LessonCatalog.parse(File('assets/content/lessons.v1.json').readAsStringSync());

void main() {
  setUpAll(loadContent);

  test('catalog: every series has a topic, a sheikh, unique ids and https archive.org audio', () {
    final c = _read();
    expect(c.series.length, greaterThanOrEqualTo(45));
    expect(c.lessonCount, greaterThan(1900));
    expect(c.series.map((s) => s.id).toSet().length, c.series.length);
    for (final topic in [
      'aqeedah', 'seerah', 'fiqh', 'hadith', 'hearts', 'stories', 'quran', //
      'family', 'akhlaq', 'adab', 'muamalat', 'tahara', 'akhira',
    ]) {
      expect(c.filter(topic: topic), isNotEmpty, reason: topic);
    }
    for (final g in ['azhar', 'egypt', 'saudi']) {
      expect(c.filter(group: g).length, greaterThanOrEqualTo(5), reason: g);
    }
    // Owner 2026-11-23: all of Sheikh Omar Abdelkafy's series.
    expect(c.series.where((s) => s.sheikh.id == 'kafy').length, greaterThanOrEqualTo(15));
    for (final s in c.series) {
      expect(s.episodes, isNotEmpty, reason: s.id);
      final urls = s.episodes.map((e) => e.url).toSet();
      expect(urls.length, s.episodes.length, reason: '${s.id}: no lesson twice');
      for (final e in s.episodes) {
        expect(e.url, startsWith('https://archive.org/download/'));
        expect(e.url, isNot(contains(' ')));
        expect(e.url.toLowerCase(), endsWith('.mp3'));
        // No source/site names or Latin junk in the titles shown.
        if (e.title != null) expect(RegExp('[A-Za-z]').hasMatch(e.title!), isFalse, reason: e.title);
      }
    }
    final end = c.byId('nihaya-hassan')!;
    expect(end.episodes.length, 29);
    expect(end.episodes[18].title, 'خروج الدجال');
    final prophets = c.byId('anbiya-shaarawi')!;
    expect(prophets.episodes.first.title, contains('مقدمة'));
    expect(prophets.episodes[1].title, contains('ادم'));
  });

  testWidgets('series cards filter by scholars and topic, search finds a sheikh, a card opens its lessons', (
    tester,
  ) async {
    await pumpApp(tester, size: tallPhone);
    final data = _read();
    await pushScreen(tester, LessonsScreen(loader: () async => data));
    expect(find.text('سلاسل الدروس'), findsWidgets);
    expect(find.byKey(const Key('lessonsNote')), findsOneWidget);
    expect(find.byKey(const Key('lessonsSeries.seerah-hassan')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lessonsGroup.saudi')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonsSeries.seerah-hassan')), findsNothing);
    expect(find.byKey(const Key('lessonsSeries.riyadh-uthaymeen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lessonsGroup.azhar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonsSeries.anbiya-shaarawi')), findsOneWidget);
    expect(find.byKey(const Key('lessonsSeries.riyadh-uthaymeen')), findsNothing);
    await tester.tap(find.byKey(const Key('lessonsGroup.all')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('lessonsTopic.akhira')));
    await tester.tap(find.byKey(const Key('lessonsTopic.akhira')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonsSeries.nihaya-hassan')), findsOneWidget);
    expect(find.byKey(const Key('lessonsSeries.dar-akhira-kafy')), findsOneWidget);
    expect(find.byKey(const Key('lessonsSeries.seerah-hassan')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('lessonsTopic.all')));
    await tester.tap(find.byKey(const Key('lessonsTopic.all')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('lessonsSearch')), 'عبد الكافي');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonsSeries.dar-akhira-kafy')), findsOneWidget);
    expect(find.byKey(const Key('lessonsSeries.safwa-kafy')), findsOneWidget, reason: 'all topics again');
    expect(find.byKey(const Key('lessonsSeries.seerah-hassan')), findsNothing);
    await tester.enterText(find.byKey(const Key('lessonsSearch')), 'لا يوجد شيء كهذا');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonsEmpty')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('lessonsSearch')), 'أحداث النهاية');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lessonsSeries.nihaya-hassan')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonSeriesScreen), findsOneWidget);
    expect(find.text('الدرس ١'), findsOneWidget);
    expect(find.textContaining('الموت'), findsWidgets);
    expect(find.byType(OfflineButton), findsWidgets);
    expect(find.byKey(const Key('lessonsDownloadAll')), findsOneWidget);
    expect(find.byKey(const Key('lessonsContinueBtn')), findsOneWidget);
    await expectAccessible(tester);
  });

  testWidgets('a lesson plays with the player under it, gets ✓ at its end, and "continue" goes back to it', (
    tester,
  ) async {
    final backend = FakeNarrationBackend();
    await pumpApp(tester, size: tallPhone, narration: backend);
    final data = _read();
    final s = data.byId('awlad-yaqoub')!;
    await pushScreen(tester, LessonSeriesScreen(series: s));
    final second = s.episodeId(s.episodes[1]);
    await tester.tap(find.byKey(Key('lesson-$second')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inlinePlayer')), findsOneWidget);
    expect(find.byKey(const Key('narrationBar')), findsNothing, reason: 'no second bar at the bottom');
    expect(backend.loaded.last, s.episodes[1].url);
    // Heard to the end: ✓, and the next lesson starts.
    backend.finish();
    await tester.pumpAndSettle();
    expect(find.byKey(Key('lessonDone-$second')), findsOneWidget);
    expect(backend.loaded.last, s.episodes[2].url);
    final settings = tester.element(find.byType(LessonSeriesScreen)).services.settings;
    expect(settings.episodeDone('${s.playerSeries}/$second'), isTrue);
    expect(settings.lastLessonSeries, s.id);
    expect(find.text('أكمل الدرس ٣'), findsOneWidget);
    // Long-press removes the ✓.
    await tester.tap(find.byKey(const Key('inlineStop')));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(Key('lesson-$second')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('lessonDone-$second')), findsNothing);
  });

  testWidgets('lesson series is its own entry under More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 5);
    await tester.scrollUntilVisible(find.byKey(const Key('more.lessons')), 200);
    await tester.tap(find.byKey(const Key('more.lessons')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LessonsScreen), findsOneWidget);
  });
}
