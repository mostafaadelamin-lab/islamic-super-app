import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/ui/adhkar_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(() => loadContent(realFonts: false));

  testWidgets('«أذكاري»: add a dhikr with its count to the morning, count it, edit it, delete it', (tester) async {
    final app = await pumpApp(tester);
    final s = app.services;
    await s.settings.setAdhkarCards(false);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    final before = s.adhkar.progress(AdhkarSession.morning).items.length;

    await tester.ensureVisible(find.byKey(const Key('customDhikrAdd')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrAdd')));
    await tester.pumpAndSettle();
    // Save is off until something is written.
    expect(tester.widget<FilledButton>(find.byKey(const Key('customDhikrSave'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('customDhikrText')), 'قراءة سورة الملك');
    await tester.ensureVisible(find.byKey(const Key('customDhikrQuick-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrQuick-3')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('customDhikrPlus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrPlus')));
    await tester.pump();
    expect(find.text('٤ مرة'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('customDhikrSave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrSave')));
    await tester.pumpAndSettle();

    final morning = s.adhkar.progress(AdhkarSession.morning);
    expect(morning.items.length, before + 1);
    final mine = morning.items.last;
    expect(mine.custom, isTrue);
    expect(mine.text, 'قراءة سورة الملك');
    expect(mine.meta.count, 4);
    // Only in the morning.
    expect(s.adhkar.progress(AdhkarSession.evening).items.where((d) => d.custom), isEmpty);
    // Kept on the device.
    expect(s.settings.rawJson('adhkar.custom'), contains('قراءة سورة الملك'));

    await tester.scrollUntilVisible(find.byKey(Key('dhikrTap-${mine.index}')), 300);
    expect(find.byKey(const Key('customAdhkarHeader')), findsOneWidget);
    await tester.ensureVisible(find.byKey(Key('dhikrTap-${mine.index}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('dhikrTap-${mine.index}')));
    await tester.pumpAndSettle();
    expect(s.adhkar.progress(AdhkarSession.morning).countOf(mine), 1);

    // Edit: both sessions, keep the count made today.
    await tester.scrollUntilVisible(find.byKey(const Key('customDhikrEdit-1')), 200);
    await tester.ensureVisible(find.byKey(const Key('customDhikrEdit-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrEdit-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الاثنين'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('customDhikrSave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrSave')));
    await tester.pumpAndSettle();
    expect(s.adhkar.progress(AdhkarSession.evening).items.where((d) => d.custom).length, 1);
    expect(s.adhkar.progress(AdhkarSession.morning).countOf(mine), 1);

    // Delete (after asking).
    await tester.scrollUntilVisible(find.byKey(const Key('customDhikrDelete-1')), 200);
    await tester.ensureVisible(find.byKey(const Key('customDhikrDelete-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrDelete-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('customDhikrDeleteYes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrDeleteYes')));
    await tester.pumpAndSettle();
    expect(s.adhkar.custom, isEmpty);
    expect(s.adhkar.progress(AdhkarSession.morning).items.length, before);
  });

  testWidgets('the big «أضف ذكرًا من عندك» button is at the end of the list', (tester) async {
    final app = await pumpApp(tester);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.evening));
    await tester.scrollUntilVisible(find.byKey(const Key('customDhikrAddBig')), 400);
    await tester.ensureVisible(find.byKey(const Key('customDhikrAddBig')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrAddBig')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('customDhikrText')), findsOneWidget);
    // Opened from the evening list: evening is chosen.
    await tester.enterText(find.byKey(const Key('customDhikrText')), 'ذكر');
    await tester.ensureVisible(find.byKey(const Key('customDhikrSave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customDhikrSave')));
    await tester.pumpAndSettle();
    expect(app.services.adhkar.custom.single.sessions, {AdhkarSession.evening});
  });

  test('a broken saved list is ignored', () {
    expect(
      UserDhikr.fromJson({
        'id': 2,
        'text': 'x',
        'count': 5000,
        'sessions': ['morning', 'nope'],
      }).count,
      UserDhikr.maxCount,
    );
  });
}
