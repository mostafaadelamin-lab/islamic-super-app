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
