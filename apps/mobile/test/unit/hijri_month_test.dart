import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/hijri.dart';
import 'package:rattil/domain/hijri_month.dart';

void main() {
  test('Hijri month days follow Umm al-Qura and the user offset', () {
    final today = DateTime.utc(2026, 3, 1); // Ramadan 1447
    final m = hijriMonthAround(today, 0, offsetDays: 0);
    expect((m.year, m.month), (1447, 9));
    expect(m.days.length, anyOf(29, 30));
    for (var i = 0; i < m.days.length; i++) {
      expect(hijriFor(m.days[i], arabic: false, offsetDays: 0).day, i + 1);
    }
    final shifted = hijriMonthAround(today, 0, offsetDays: 1);
    expect(shifted.days.first, m.days.first.subtract(const Duration(days: 1)));
    expect(hijriFor(shifted.days.first, arabic: false, offsetDays: 1).day, 1);
    final next = hijriMonthAround(today, 1, offsetDays: 0);
    expect((next.year, next.month), (1447, 10));
    expect(next.days.first, m.days.last.add(const Duration(days: 1)));
  });
}
