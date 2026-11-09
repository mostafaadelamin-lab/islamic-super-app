import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/worship.dart';

WorshipLog full(WorshipLog l, DateTime d) => worshipPrayers.fold(l, (a, p) => a.togglePrayer(d, p));

void main() {
  final today = DateTime.utc(2026, 11, 9);
  DateTime day(int d, [int m = 11]) => DateTime.utc(2026, m, d);

  test('toggles prayers, fasting and a note; an empty day is dropped', () {
    var l = const WorshipLog().togglePrayer(today, 'fajr');
    expect(l.dayOf(today).prayers, {'fajr'});
    l = l.togglePrayer(today, 'fajr');
    expect(l.days, isEmpty);
    l = l.setFasting(day(8), true).setNote(day(8), 'x' * 300);
    expect(l.dayOf(day(8)).note.length, maxWorshipNote);
    expect(l.setFasting(day(8), false).setNote(day(8), ' ').days, isEmpty);
  });

  test('weekly and monthly totals and the streak', () {
    var l = full(const WorshipLog(), today).togglePrayer(day(3), 'asr').setFasting(day(2), true);
    l = full(l, day(31, 10));
    final w = l.week(today);
    expect([w.days, w.prayed, w.possible, w.fullDays, w.fasted], [7, 6, 35, 1, 0]);
    final m = l.month(2026, 11, today);
    expect([m.days, m.prayed, m.fullDays, m.fasted], [9, 6, 1, 1]);
    expect(l.month(2026, 10, today).days, 31);

    var s = full(full(full(const WorshipLog(), day(6)), day(7)), day(8));
    expect(s.streak(today), 3);
    s = full(s, today);
    expect(s.streak(today), 4);
    expect(s.togglePrayer(day(7), 'isha').streak(today), 2);
  });

  test('JSON round trip and repair', () {
    final l = full(const WorshipLog(), today).setNote(day(8), 'note');
    final r = WorshipLog.fromJson(l.toJson());
    expect(r.toJson(), l.toJson());
    final bad = WorshipLog.fromJson({
      'days': {
        '2026-11-09': {
          'prayers': {'fajr': true, 'sunrise': true, 'dhuhr': 'yes'},
          'fasting': 1,
        },
        '2026-11-08': {'prayers': {}},
        'bad': {'fasting': true},
      },
    });
    expect(bad.days.keys, ['2026-11-09']);
    expect(bad.dayOf(today).prayers, {'fajr'});
    expect(bad.dayOf(today).fasting, isFalse);
  });
}
