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
}
