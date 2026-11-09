import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/khatma.dart';

void main() {
  final d = DateTime.utc;

  test('wirds are contiguous whole pages covering 1..604', () {
    for (final days in [1, 7, 29, 30, 60, 365]) {
      final k = Khatma.byDays('x', d(2026, 11, 9), days);
      var next = 1;
      for (var i = 0; i < k.wirds; i++) {
        final p = k.wirdPages(i);
        expect(p.from, next);
        expect(p.to, greaterThanOrEqualTo(p.from));
        next = p.to + 1;
      }
      expect(next, mushafPages + 1);
    }
    expect(Khatma.byDays('x', d(2026, 11, 9), 30).wirdPages(0), (from: 1, to: 20));
    expect(Khatma.byPages('x', d(2026, 11, 9), 20).wirds, 31);
  });

  test('progress, behind/ahead and reschedule match the website rules', () {
    final k = Khatma.byDays('x', d(2026, 11, 1), 30).copyWith(done: 3);
    final today = d(2026, 11, 9);
    expect(k.endDate, d(2026, 11, 30));
    expect(k.remainingDays(today), 22);
    expect(k.behind(today), 5);
    expect(k.ahead(today), 0);
    expect(k.copyWith(done: 12).ahead(today), 3);
    expect(k.fraction, closeTo(k.wirdPages(2).to / 604, 1e-9));
    final r = k.reschedule(today);
    expect(r.startDate, today);
    expect(r.startPage, k.wirdPages(3).from);
    expect(r.wirds, 22);
    expect(r.behind(today), 0);
    expect(r.endDate, d(2026, 11, 30));
    expect(k.reschedule(d(2026, 12, 15)).wirds, 1);
  });

  test('finishing moves to history; JSON round trip and validation', () {
    var s = KhatmaState(current: Khatma.byDays('Ramadan', d(2026, 11, 1), 2));
    s = s.completeWird(d(2026, 11, 1));
    expect(s.current!.done, 1);
    s = s.completeWird(d(2026, 11, 3));
    expect(s.current, isNull);
    expect(s.history.single.days, 3);
    final back = KhatmaState.fromJson(
      KhatmaState(
        current: Khatma.byDays('a', d(2026, 11, 1), 10).copyWith(done: 4, reminderMinutes: () => 1230),
        history: s.history,
      ).toJson(),
    );
    expect(back.current!.done, 4);
    expect(back.current!.reminderMinutes, 1230);
    expect(back.history.single.name, 'Ramadan');
    expect(Khatma.fromJson({'startDate': 'x'}), isNull);
    expect(Khatma.fromJson({...Khatma.byDays('a', d(2026, 11, 1), 10).toJson(), 'done': 11}), isNull);
  });
}
