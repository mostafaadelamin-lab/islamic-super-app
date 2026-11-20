import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/reminders.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/dhikr_reminders.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/dhikr_reminders_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  group('planDhikrSlots', () {
    test('every 30 minutes from 8:00 to 23:00, both ends included', () {
      final p = planDhikrSlots(from: 8 * 60, to: 23 * 60, every: 30, max: 96);
      expect(p.every, 30);
      expect(p.slots.length, 31);
      expect(p.slots.first, 480);
      expect(p.slots.last, 23 * 60);
    });

    test('a window over midnight wraps', () {
      final p = planDhikrSlots(from: 22 * 60, to: 60, every: 60, max: 96);
      expect(p.slots, [22 * 60, 23 * 60, 0, 60]);
    });

    test('too many for the cap: spread evenly at whole 5 minutes (iOS)', () {
      final p = planDhikrSlots(from: 8 * 60, to: 23 * 60, every: 15, max: dhikrReminderMaxIos);
      expect(p.slots.length, lessThanOrEqualTo(dhikrReminderMaxIos));
      expect(p.every % 5, 0);
      expect(p.every, 40); // 900 min / 23 gaps = 39.1 -> 40
    });

    test('from == to means all day', () {
      final p = planDhikrSlots(from: 0, to: 0, every: 60, max: 96);
      expect(p.slots.length, 24);
    });
  });

  test('every dhikr has its clip in all four formats', () {
    for (final d in dhikrReminderItems) {
      expect(File('android/app/src/main/res/raw/${d.sound}.ogg').existsSync(), isTrue, reason: d.id);
      expect(File('ios/Runner/${d.sound}.caf').existsSync(), isTrue, reason: d.id);
      expect(File(d.asset).existsSync(), isTrue, reason: d.id);
      expect(File('../web/public/audio/dhikr/${d.sound}.mp3').existsSync(), isTrue, reason: d.id);
      expect(File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(), contains('${d.sound}.caf in Resources'));
    }
  });

  testWidgets('turning on schedules the chosen adhkar in turn, each with its own spoken clip', (tester) async {
    final notes = FakeNotifications();
    final app = await pumpApp(tester, size: tallPhone, notifications: notes, prefs: {'dhikrRem.every': 60});
    await pushScreen(tester, const DhikrRemindersScreen());
    await tester.tap(find.byKey(const Key('dhikrRemOn')));
    await tester.pumpAndSettle();
    expect(app.services.settings.dhikrRemindersOn, isTrue);
    final dhikr = {
      for (final e in notes.repeating.entries)
        if (e.key >= ReminderIds.dhikrBase) e.key: e.value,
    };
    // 8:00 .. 23:00 every hour = 16 reminders, salat / subhan / istighfar in turn.
    expect(dhikr.length, 16);
    final first = dhikr[ReminderIds.dhikrBase]!;
    expect((first.hour, first.minute), (8, 0));
    expect(first.sound, 'dhikr_salat');
    expect(first.body, app.services.content.adhkar.items[28].text);
    expect(dhikr[ReminderIds.dhikrBase + 1]!.sound, 'dhikr_subhan');
    expect(dhikr[ReminderIds.dhikrBase + 2]!.sound, 'dhikr_istighfar');
    expect(dhikr[ReminderIds.dhikrBase + 3]!.sound, 'dhikr_salat');
    expect(find.byKey(const Key('dhikrRemSummary')), findsOneWidget);

    // Unpick two: only salat is left; turning off clears them all.
    await tester.tap(find.byKey(const Key('dhikrRem-subhan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dhikrRem-istighfar')));
    await tester.pumpAndSettle();
    expect(
      notes.repeating.entries.where((e) => e.key >= ReminderIds.dhikrBase).map((e) => e.value.sound).toSet(),
      {'dhikr_salat'},
    );
    await tester.tap(find.byKey(const Key('dhikrRemEvery-30')));
    await tester.pumpAndSettle();
    expect(notes.repeating.keys.where((k) => k >= ReminderIds.dhikrBase).length, 31);
    await tester.tap(find.byKey(const Key('dhikrRemOn')));
    await tester.pumpAndSettle();
    expect(notes.repeating.keys.where((k) => k >= ReminderIds.dhikrBase), isEmpty);
  });

  testWidgets('custom interval and the listen button', (tester) async {
    final player = FakeAdhanPlayer();
    final app = await pumpApp(tester, size: tallPhone, adhanPlayer: player);
    await pushScreen(tester, const DhikrRemindersScreen());
    await tester.tap(find.byKey(const Key('dhikrRemEveryCustom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('dhikrRemCustomField')), '45');
    await tester.tap(find.byKey(const Key('dhikrRemCustomOk')));
    await tester.pumpAndSettle();
    expect(app.services.settings.dhikrRemindersEvery, 45);
    await tester.tap(find.byKey(const Key('dhikrRemListen-hasbi')));
    await tester.pumpAndSettle();
    expect(player.lastAsset, 'assets/audio/dhikr/dhikr_hasbi.m4a');
  });

  testWidgets('the adhkar reminders sheet opens the dhikr reminders screen', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarReminders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openDhikrReminders')));
    await tester.pumpAndSettle();
    expect(find.byType(DhikrRemindersScreen), findsOneWidget);
  });
}
