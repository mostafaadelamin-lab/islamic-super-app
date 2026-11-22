import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/sharawi.dart';
import 'package:rattil/ui/library_screen.dart' show OfflineButton;
import 'package:rattil/ui/sharawi_screen.dart';

import '../helpers.dart';

SharawiTafsir _read() => SharawiTafsir.parse(File('assets/content/sharawi.v1.json').readAsStringSync());

void main() {
  setUpAll(loadContent);

  test('lesson list: 1116 unique lessons, valid surahs and ayah ranges, archive.org https audio', () async {
    final t = _read();
    final quran = (await loadContent()).quran;
    expect(t.lessonCount, 1116);
    expect(t.surahs.first.surah, 0, reason: 'the introduction comes first');
    final ids = [
      for (final s in t.surahs) ...[for (final l in s.lessons) l.id],
    ];
    expect(ids.toSet().length, ids.length);
    expect(ids, orderedEquals([...ids]..sort()));
    for (final s in t.surahs) {
      expect(s.lessons, isNotEmpty);
      for (final l in s.lessons) {
        expect(l.url, startsWith('https://archive.org/download/'));
        expect(l.url, isNot(contains(' ')));
        expect(l.url, endsWith('.mp3'));
        expect(l.bytes, greaterThan(100000));
        if (l.hasRange) {
          final count = quran.surahs[s.surah - 1].ayahCount;
          expect(l.from! <= l.to! && l.to! <= count, isTrue, reason: '${s.surah}: ${l.from}-${l.to}');
        }
      }
    }
    final baqarah = t.bySurah(2)!;
    expect(baqarah.lessons.first.from, 1);
    expect(baqarah.lessons.last.to, 286);
  });

  testWidgets('surah list with search, a surah opens its lessons with download buttons', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final data = _read();
    await pushScreen(tester, SharawiScreen(loader: () async => data));
    expect(find.text('تفسير الشعراوي'), findsWidgets);
    expect(find.byKey(const Key('sharawiNote')), findsOneWidget);
    expect(find.byKey(const Key('sharawiSurah.0')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('sharawiSearch')), 'البقره');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sharawiSurah.2')), findsOneWidget);
    expect(find.byKey(const Key('sharawiSurah.0')), findsNothing);
    await tester.enterText(find.byKey(const Key('sharawiSearch')), 'الملك');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sharawiEmpty')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('sharawiSearch')), 'البقرة');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sharawiSurah.2')));
    await tester.pumpAndSettle();
    expect(find.byType(SharawiSurahScreen), findsOneWidget);
    expect(find.byKey(const Key('sharawi-9')), findsOneWidget);
    expect(find.text('الدرس ١'), findsOneWidget);
    expect(find.textContaining('الآية ١'), findsWidgets);
    expect(find.byType(OfflineButton), findsWidgets);
    await expectAccessible(tester);
  });

  testWidgets('a lesson plays with the lock-screen player under it: time, full length, seek bar, ±30 s', (tester) async {
    // The stream does not report its length (iOS, archive.org): the lesson's listed length is used.
    final backend = FakeNarrationBackend(length: null);
    await pumpApp(tester, size: tallPhone, narration: backend);
    final data = _read();
    await pushScreen(tester, SharawiSurahScreen(surah: data.bySurah(1)!));
    final first = data.bySurah(1)!.lessons.first;
    await tester.tap(find.byKey(Key('sharawi-${first.id}')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(Key('sharawi-${first.id}')), matching: find.byKey(const Key('inlinePlayer'))),
      findsOneWidget,
      reason: 'the player is right under the lesson playing',
    );
    expect(find.byKey(const Key('narrationBar')), findsNothing, reason: 'no second bar at the bottom');
    final total = tester.widget<Text>(find.byKey(const Key('inlineTotal'))).data!;
    expect(total, isNot('--:--'));
    final slider = tester.widget<Slider>(find.byKey(const Key('inlineSlider')));
    expect(slider.onChanged, isNotNull, reason: 'the user can move forward and back');
    expect(slider.max, first.seconds! * 1000);
    await tester.tap(find.byKey(const Key('inlineFwd30')));
    await tester.pump();
    expect(backend.calls.last, 'seek:30');
    await tester.tap(find.byKey(const Key('inlineBack30')));
    await tester.pump();
    expect(backend.calls.last, 'seek:0');
    // The full length arrives later from the player.
    backend.durations.add(Duration(seconds: first.seconds! + 7));
    await tester.pump();
    expect(tester.widget<Slider>(find.byKey(const Key('inlineSlider'))).max, (first.seconds! + 7) * 1000);
    await tester.tap(find.byKey(const Key('inlineStop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inlinePlayer')), findsNothing);
  });

  testWidgets('Sha\'rawi tafsir is its own entry under More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 5);
    await tester.scrollUntilVisible(find.byKey(const Key('more.sharawi')), 200);
    await tester.tap(find.byKey(const Key('more.sharawi')));
    // The real asset loads outside the fake clock; only check the route opened.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SharawiScreen), findsOneWidget);
  });
}
