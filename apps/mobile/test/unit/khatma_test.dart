import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/khatma.dart';

void main() {
  test('counts each page once, ignores out-of-range pages, finds the first unread page', () {
    var k = Khatma(startedAt: DateTime(2026, 11, 9));
    for (final p in [1, 2, 2, 4, 0, 605]) {
      k = k.markRead(p);
    }
    expect(k.read, {1, 2, 4});
    expect(k.done, 3);
    expect(k.left, 601);
    expect(k.percent, 0);
    expect(k.next, 3);
  });

  test('complete only when all 604 pages are read', () {
    var k = Khatma(startedAt: DateTime(2026));
    for (var p = 1; p <= 603; p++) {
      k = k.markRead(p);
    }
    expect(k.percent, 99);
    expect(k.next, 604);
    k = k.markRead(604);
    expect(k.percent, 100);
    expect(k.next, isNull);
  });

  test('encodes and decodes (sorted, invalid entries dropped)', () {
    final k = Khatma(startedAt: DateTime.fromMillisecondsSinceEpoch(5000), read: [9, 3]);
    expect(k.encoded, ['3', '9']);
    final d = Khatma.decode(5000, ['9', 'x', '3', '700']);
    expect(d.read, {3, 9});
    expect(d.startedAt.millisecondsSinceEpoch, 5000);
  });
}
