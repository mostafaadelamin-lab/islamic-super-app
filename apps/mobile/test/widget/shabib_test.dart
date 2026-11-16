import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/shabib.dart';
import 'package:rattil/ui/library_screen.dart' show OfflineButton;
import 'package:rattil/ui/shabib_screen.dart';

import '../helpers.dart';

ShabibRecitations _read() => ShabibRecitations.parse(File('assets/content/shabib.v1.json').readAsStringSync());

void main() {
  setUpAll(loadContent);

  test('track list: 16 murattal + 70 mujawwad, unique ids, valid surahs, https mp3', () {
    final d = _read();
    expect(d.murattal, hasLength(16));
    expect(d.mujawwad, hasLength(70));
    final all = [...d.murattal, ...d.mujawwad];
    expect({for (final x in all) x.id}.length, all.length);
    for (final x in all) {
      expect(x.url, startsWith('https://'));
      expect(x.url, isNot(contains(' ')));
      expect(x.url, endsWith('.mp3'));
      expect(x.seconds, greaterThan(0));
      for (final n in x.surahs) {
        expect(n >= 1 && n <= 114, isTrue);
      }
    }
    expect(d.murattal.where((x) => x.part), isNotEmpty);
    expect(d.mujawwad.where((x) => x.part), isEmpty);
  });

  testWidgets('murattal and mujawwad lists with search and download buttons', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final data = _read();
    await pushScreen(tester, ShabibScreen(loader: () async => data));
    expect(find.text('محمد أحمد شبيب'), findsWidgets);
    expect(find.byKey(const Key('shabibNote')), findsOneWidget);
    expect(find.text('ما تيسّر من سورة البقرة'), findsOneWidget);
    expect(find.text('سورة الإخلاص'), findsOneWidget);
    expect(find.byType(OfflineButton), findsWidgets);
    await tester.tap(find.textContaining('تلاوات مجودة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shabibSearch')), 'يوسف');
    await tester.pumpAndSettle();
    final yusuf = data.mujawwad.where((x) => x.surahs.contains(12)).toList();
    for (final x in yusuf) {
      expect(find.byKey(Key('shabib-${x.id}')), findsOneWidget);
    }
    expect(find.text('ما تيسّر من سورة البقرة'), findsNothing);
    await tester.enterText(find.byKey(const Key('shabibSearch')), 'الملك');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shabibEmpty')), findsOneWidget);
    await expectAccessible(tester);
  });

  testWidgets('the player sits under the recitation playing, not in a bar away from it (owner 2026-11-16)', (
    tester,
  ) async {
    final app = await pumpApp(tester, narration: FakeNarrationBackend(), size: tallPhone);
    final data = _read();
    await pushScreen(tester, ShabibScreen(loader: () async => data));
    final first = data.murattal.first;
    await tester.tap(find.byKey(Key('shabib-${first.id}')));
    await tester.pumpAndSettle();
    expect(app.services.narration.episode?.url, first.url);
    expect(
      find.descendant(of: find.byKey(Key('shabib-${first.id}')), matching: find.byKey(const Key('inlinePlayer'))),
      findsOneWidget,
    );
    expect(find.byKey(const Key('narrationBar')), findsNothing);
  });

  testWidgets('not a section of its own under More (owner 2026-11-16: he sits inside the recitation library)', (
    tester,
  ) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 5);
    await tester.scrollUntilVisible(find.byKey(const Key('more.library')), 200);
    expect(find.byKey(const Key('more.shabib')), findsNothing);
  });
}
