import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/reminders.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/ui/adhkar_celebration.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/dhikr_tools.dart';
import 'package:rattil/ui/hisn_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  test('every Hisn chapter but the introduction is in exactly one section', () async {
    final c = await loadContent();
    final ids = [for (final x in c.adhkar.sections) ...x.chapters];
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), {for (var i = 2; i <= c.adhkar.hisn.length; i++) i});
  });

  test('report text quotes at most 80 characters and keeps the dhikr unchanged in a share', () {
    final long = 'ا' * 200;
    expect(dhikrReportBody('Intro', 'Where', long), contains('«${'ا' * 80}…»'));
    expect(dhikrShareBody('سبحان الله', 'Hisn'), 'سبحان الله\n\n— Hisn');
  });

  testWidgets('Hisn sections filter the chapters; chapter cards, share and report', (tester) async {
    final sharer = FakeSharer();
    final app = await pumpApp(tester, size: tallPhone, sharer: sharer);
    await pushScreen(tester, const HisnScreen());
    await tester.scrollUntilVisible(
      find.byKey(const Key('hisnSection-travel')),
      120,
      scrollable: find.descendant(of: find.byKey(const Key('hisnSections')), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.byKey(const Key('hisnSection-travel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hisn-97')), findsOneWidget, reason: 'دعاء السفر');
    expect(find.byKey(const Key('hisn-2')), findsNothing);
    await tester.tap(find.byKey(const Key('hisn-97')));
    await tester.pumpAndSettle();
    final chapter = app.services.content.adhkar.hisn[97];
    await tester.tap(find.byKey(const Key('hisn0Share')));
    await tester.pump();
    expect(sharer.texts.single, startsWith(chapter.items[0]));
    expect(sharer.texts.single, contains('الباب ٩٨'));
    await tester.tap(find.byKey(const Key('hisn0Report')));
    await tester.pumpAndSettle();
    final title = tester.widget<TextFormField>(find.byKey(const Key('contactTitle'))).controller!.text;
    final message = tester.widget<TextFormField>(find.byKey(const Key('contactMessage'))).controller!.text;
    expect(title, 'خطأ في ذكر');
    expect(message, contains('أظن أن في هذا الذكر خطأ'));
    expect(message, contains('الباب ٩٨'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adhkarViewMode')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhkarCards, isFalse, reason: 'cards are the default now');
    await tester.tap(find.byKey(const Key('adhkarViewMode')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhkarCards, isTrue);
    expect(find.byKey(const Key('cardPager')), findsOneWidget);
    expect(find.text('١ / ١'), findsOneWidget);
  });

  testWidgets('adhkar cards move on when a dhikr is complete', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await app.services.settings.setAdhkarCards(true);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    final first = app.services.adhkar.progress(AdhkarSession.morning).items.first;
    expect(find.byKey(Key('dhikr-${first.index}')), findsOneWidget);
    for (var k = 0; k < first.meta.count; k++) {
      await tester.tap(find.byKey(Key('dhikrTap-${first.index}')));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('٢ /'), findsOneWidget);
  });

  testWidgets('finishing the last morning dhikr: celebration (vibration, no sound), «رجوع» goes back', (tester) async {
    var buzzed = 0;
    celebrationVibrate = () async => buzzed++;
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    final items = app.services.adhkar.progress(AdhkarSession.morning).items;
    // Everything but the last tap of the last dhikr, done in the store directly.
    for (final d in items) {
      final n = d == items.last ? d.meta.count - 1 : d.meta.count;
      for (var k = 0; k < n; k++) {
        await app.services.adhkar.tap(AdhkarSession.morning, d);
      }
    }
    await tester.pumpAndSettle();
    expect(find.byType(AdhkarSessionScreen), findsOneWidget, reason: 'not finished yet: stays open');
    await app.services.adhkar.tap(AdhkarSession.morning, items.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AdhkarSessionScreen), findsOneWidget, reason: 'the done tick shows for a moment');
    await tester.pump(adhkarAutoExitDelay);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('adhkarCelebration')), findsOneWidget);
    expect(find.text('تقبّل الله منك'), findsOneWidget);
    expect(buzzed, 1);
    await tester.tap(find.byKey(const Key('celebrationBack')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('adhkarCelebration')), findsNothing);
    expect(find.byType(AdhkarSessionScreen), findsNothing, reason: 'back to the list it came from');
  });

  testWidgets('celebration «من جديد» starts the list again and stays on it', (tester) async {
    celebrationVibrate = () async {};
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.evening));
    final items = app.services.adhkar.progress(AdhkarSession.evening).items;
    for (final d in items) {
      final n = d == items.last ? d.meta.count - 1 : d.meta.count;
      for (var k = 0; k < n; k++) {
        await app.services.adhkar.tap(AdhkarSession.evening, d);
      }
    }
    await tester.pumpAndSettle();
    await app.services.adhkar.tap(AdhkarSession.evening, items.last);
    await tester.pump();
    await tester.pump(adhkarAutoExitDelay);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('celebrationAgain')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(AdhkarSessionScreen), findsOneWidget);
    expect(app.services.adhkar.progress(AdhkarSession.evening).completedItems, 0);
  });

  testWidgets('a list already finished today opens normally and does not close by itself', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    for (final d in app.services.adhkar.progress(AdhkarSession.evening).items) {
      for (var k = 0; k < d.meta.count; k++) {
        await app.services.adhkar.tap(AdhkarSession.evening, d);
      }
    }
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.evening));
    await tester.pump(adhkarAutoExitDelay * 2);
    await tester.pumpAndSettle();
    expect(find.byType(AdhkarSessionScreen), findsOneWidget);
  });

  testWidgets('a Hisn chapter celebrates after its last counter is done, then goes back', (tester) async {
    celebrationVibrate = () async {};
    final app = await pumpApp(tester, size: tallPhone);
    await app.services.settings.setAdhkarCards(true);
    final chapter = app.services.content.adhkar.hisn[97];
    expect(chapter.items.length, 1);
    await pushScreen(tester, HisnChapterScreen(chapter: chapter));
    final target = countStatedIn(chapter.items[0]);
    for (var k = 0; k < target; k++) {
      await tester.tap(find.byKey(const Key('hisnCounter-0')));
      await tester.pump();
    }
    expect(find.byType(HisnChapterScreen), findsOneWidget);
    await tester.pump(adhkarAutoExitDelay);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('celebrationBack')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(HisnChapterScreen), findsNothing);
  });

  testWidgets('morning and evening reminders are scheduled daily at the chosen time', (tester) async {
    final notes = FakeNotifications();
    final app = await pumpApp(tester, size: tallPhone, notifications: notes, locale: 'en');
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarReminders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminderMorning')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhkarReminder(true), 6 * 60 + 30);
    final r = notes.repeating[ReminderIds.adhkarMorning]!;
    expect((r.hour, r.minute, r.weekday), (6, 30, null));
    expect(r.title, 'Morning adhkar');
    await tester.tap(find.byKey(const Key('reminderMorning')));
    await tester.pumpAndSettle();
    expect(notes.repeating.containsKey(ReminderIds.adhkarMorning), isFalse);
  });
}
