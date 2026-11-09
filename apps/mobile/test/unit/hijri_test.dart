import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/hijri.dart';

void main() {
  // Expected values from ICU's islamic-umalqura calendar (Node.js Intl).
  test('Umm al-Qura dates', () {
    final a = hijriFor(DateTime.utc(2026, 1, 15), arabic: true);
    expect([a.day, a.month, a.year], [26, 7, 1447]);
    expect(a.monthName, 'رجب');
    final b = hijriFor(DateTime.utc(2026, 3, 20), arabic: false);
    expect([b.day, b.month, b.year], [1, 10, 1447]);
    expect(b.monthName, isNotEmpty);
    final c = hijriFor(DateTime.utc(2025, 6, 26), arabic: true);
    expect([c.day, c.month, c.year], [1, 1, 1447]);
    expect(c.monthName, 'محرم');
  });

  test('manual offset shifts the Umm al-Qura date (-2..+2)', () {
    // 2026-02-18 = 1 Ramadan 1447 by Umm al-Qura.
    final base = hijriFor(DateTime(2026, 2, 18), arabic: false, offsetDays: 0);
    expect([base.day, base.month, base.year], [1, 9, 1447]);
    final minus = hijriFor(DateTime(2026, 2, 18), arabic: false, offsetDays: -1);
    expect([minus.day, minus.month], [29, 8]);
    final plus = hijriFor(DateTime(2026, 2, 18), arabic: false, offsetDays: 1);
    expect([plus.day, plus.month], [2, 9]);
    final clamped = hijriFor(DateTime(2026, 2, 18), arabic: false, offsetDays: 9);
    expect([clamped.day, clamped.month], [3, 9]);
    hijriOffsetDays = 1;
    expect(hijriFor(DateTime(2026, 2, 18), arabic: false).day, 2);
    hijriOffsetDays = 0;
  });
}
