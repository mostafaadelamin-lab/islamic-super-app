import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/reminders.dart';
import 'package:rattil/domain/khatma.dart';
import 'package:rattil/ui/khatma_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/reader_widgets.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  Future<TestApp> open(WidgetTester tester, {FakeNotifications? notifications, String locale = 'en'}) async {
    final app = await pumpApp(tester, locale: locale, size: tallPhone, notifications: notifications);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const KhatmaScreen())));
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('create a 30-day khatma, read and mark portions done', (tester) async {
    final app = await open(tester);
    expect(find.text('You have not completed a khatma yet.'), findsOneWidget);
    expect(find.textContaining('30 portions, about 21 pages a day'), findsOneWidget);
    await tester.tap(find.byKey(const Key('khatmaStart')));
    await tester.pumpAndSettle();
    expect(app.services.khatma.current!.wirds, 30);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Current portion (1 of 30)'), findsOneWidget);
    expect(find.textContaining('From surah Al-Fatihah ayah 1, page 1 to surah'), findsWidgets);
    await tester.tap(find.byKey(const Key('khatmaDone')));
    await tester.pumpAndSettle();
    expect(app.services.khatma.current!.done, 1);
    expect(find.text('Current portion (2 of 30)'), findsOneWidget);
    expect(find.text('3%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('khatmaRead')));
    await tester.pumpAndSettle();
    expect(tester.widget<PageReaderScreen>(find.byType(PageReaderScreen)).initialPage, 21);
  });

  testWidgets('pages-per-day mode and presets', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('khatmaPreset-7')));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 portions, about 87 pages a day'), findsOneWidget);
    await tester.tap(find.text('Pages per day'));
    await tester.pumpAndSettle();
    expect(find.textContaining('31 portions, about 20 pages a day'), findsOneWidget);
  });

  testWidgets('late plan: behind banner and reschedule', (tester) async {
    final app = await open(tester);
    // fixedNow is 2026-01-15 in Cairo; a plan started on the 1st with one portion read.
    await app.services.khatma.start(Khatma.byDays('K', DateTime.utc(2026, 1, 1), 30).copyWith(done: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('khatmaBehind')), findsOneWidget);
    expect(find.text('13 days behind the plan.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('khatmaReschedule')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('khatmaBehind')), findsNothing);
    expect(app.services.khatma.current!.startDate, DateTime.utc(2026, 1, 15));
  });

  testWidgets('daily reminder is a repeating notification; delete cancels it', (tester) async {
    final n = FakeNotifications();
    final app = await open(tester, notifications: n);
    await tester.tap(find.byKey(const Key('khatmaStart')));
    await tester.pumpAndSettle();
    await app.services.khatma.setReminder(20 * 60 + 30);
    await tester.pumpAndSettle();
    expect(n.repeating[ReminderIds.khatma]?.hour, 20);
    expect(n.repeating[ReminderIds.khatma]?.minute, 30);
    expect(find.byKey(const Key('khatmaReminderTime')), findsOneWidget);
    expect(app.services.reminders.activeCount, 1);
    await tester.scrollUntilVisible(find.byKey(const Key('khatmaDelete')), 200);
    await tester.tap(find.byKey(const Key('khatmaDelete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('khatmaDeleteOk')));
    await tester.pumpAndSettle();
    expect(app.services.khatma.current, isNull);
    expect(n.repeating, isEmpty);
  });

  testWidgets('Arabic: finishing adds to the history', (tester) async {
    final app = await open(tester, locale: 'ar');
    await app.services.khatma.start(Khatma.byDays('ختمتي', DateTime.utc(2026, 1, 14), 2).copyWith(done: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('khatmaDone')));
    await tester.pumpAndSettle();
    expect(find.textContaining('خُتمت في ١٥ يناير ٢٠٢٦ خلال ٢ يومًا'), findsOneWidget);
  });

  testWidgets('the mushaf khatma sheet links to the full planner', (tester) async {
    await pumpApp(tester, locale: 'en', size: tallPhone);
    await pushScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('openSheet'),
            onPressed: () => showKhatmaSheet(context, onGo: (_) {}),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('openSheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('khatmaPlanner')));
    await tester.pumpAndSettle();
    expect(find.byType(KhatmaScreen), findsOneWidget);
    expect(find.byKey(const Key('khatmaSheet')), findsNothing);
  });

  testWidgets('reading the last page of today\'s portion in the mushaf marks the portion done', (tester) async {
    final app = await pumpApp(tester, locale: 'en', size: tallPhone);
    await app.services.khatma.start(Khatma.byDays('Mine', app.services.khatma.today, 30));
    final end = app.services.khatma.current!.wirdPages(0).to;
    await pushScreen(tester, PageReaderScreen(initialPage: end));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(app.services.khatma.current!.done, 1);
  });
}
