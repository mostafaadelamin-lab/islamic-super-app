import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/worship_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  testWidgets('records the day, shows totals and streak, picks another day and month', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(tester, const WorshipScreen());
    final w = app.services.worship;
    final today = w.today;
    for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      await tester.ensureVisible(find.byKey(Key('worship.$p')));
      await tester.tap(find.byKey(Key('worship.$p')));
      await tester.pump();
    }
    expect(w.log.dayOf(today).full, isTrue);
    expect(find.text('Days in a row with all five prayers: 1'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('worship.fasting')));
    await tester.tap(find.byKey(const Key('worship.fasting')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('worship.note')), 'Monday fast');
    await tester.pump();
    expect(w.log.dayOf(today).fasting, isTrue);
    expect(w.log.dayOf(today).note, 'Monday fast');
    expect(find.textContaining('5 of 35 prayers'), findsOneWidget);
    final yesterday = DateTime.utc(today.year, today.month, today.day - 1);
    if (yesterday.month == today.month) {
      final k = Key(
        'worship.day-${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      );
      await tester.ensureVisible(find.byKey(k));
      await tester.tap(find.byKey(k));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('worship.fajr')));
      await tester.tap(find.byKey(const Key('worship.fajr')));
      await tester.pump();
      expect(w.log.dayOf(yesterday).prayers, {'fajr'});
    }
    await tester.ensureVisible(find.byKey(const Key('worship.prev')));
    await tester.tap(find.byKey(const Key('worship.prev')));
    await tester.pump();
    final tester2 = tester.widget<IconButton>(find.byKey(const Key('worship.next')));
    expect(tester2.onPressed, isNotNull);
  });
}
