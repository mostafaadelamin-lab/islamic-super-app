import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/reminders.dart';
import 'package:rattil/domain/dhikr_reminders.dart';

ReminderSpec spec(int id, int minutes) => ReminderSpec(id: id, title: 't', body: 'b', minutes: minutes);

void main() {
  // Owner 2026-11-22: no other reminder from 10 minutes before each adhan until its iqama.
  const quiet = [(from: 12 * 60 - 13, to: 12 * 60 + 18), (from: 15 * 60, to: 15 * 60 + 30)];

  test('dhikr reminders inside a quiet time are left out, the others stay', () {
    final out = quietened([spec(ReminderIds.dhikrBase, 11 * 60), spec(ReminderIds.dhikrBase + 1, 12 * 60)], quiet);
    expect(out.map((r) => r.minutes), [11 * 60]);
  });

  test('other reminders move to just after the quiet time', () {
    final out = quietened([spec(ReminderIds.adhkarEvening, 15 * 60 + 5), spec(ReminderIds.khatma, 9 * 60)], quiet);
    expect(out.map((r) => r.minutes), [15 * 60 + 31, 9 * 60]);
  });

  test('a quiet time that crosses midnight', () {
    final out = quietened(
      [spec(ReminderIds.dhikrBase, 5), spec(ReminderIds.friday, 23 * 60 + 58)],
      const [(from: 23 * 60 + 50, to: 20)],
    );
    expect(out.single.minutes, 21);
  });

  test('iPhone: the adhan comes first, the dhikr reminders get what is left', () {
    expect(dhikrReminderMaxFor(iosCap: 60, adhanNeed: 10), dhikrReminderMaxIos);
    expect(dhikrReminderMaxFor(iosCap: 60, adhanNeed: 45), 11);
    expect(dhikrReminderMaxFor(iosCap: 60, adhanNeed: 70), 0);
    expect(planDhikrSlots(from: 480, to: 1380, every: 30, max: 0).slots, isEmpty);
  });
}
