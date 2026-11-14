import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/devotions.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/tasbih.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('counts to the target, then completes a round and starts again', () {
    var s = const TasbihState();
    for (var i = 0; i < 32; i++) {
      s = s.tap();
    }
    expect(s.count, 32);
    expect(s.rounds, 0);
    final before = s;
    s = s.tap();
    expect(s.count, 0);
    expect(s.rounds, 1);
    expect(s.total, 33);
    expect(s.completedRoundFrom(before), isTrue);
    expect(s.tap().completedRoundFrom(s), isFalse);
  });

  test('changing the target keeps a count below it and resets one above it', () {
    final s = TasbihState(count: 50, total: 50, target: 100);
    expect(s.withTarget(1000).count, 50);
    expect(s.withTarget(33).count, 0);
    expect(s.withTarget(33).total, 50);
    expect(s.reset().count, 0);
    expect(s.reset().target, 100);
    expect(s.reset().total, 0);
  });

  test('JSON round trip and repair of bad stored values', () {
    final s = const TasbihState(count: 5, total: 70, rounds: 2, target: 33);
    final r = TasbihState.fromJson(s.toJson());
    expect([r.count, r.total, r.rounds, r.target], [5, 70, 2, 33]);
    final bad = TasbihState.fromJson({'count': 99, 'target': 33, 'total': -4});
    expect(bad.count, 0);
    expect(bad.total, 0);
    expect(TasbihState.fromJson({'target': 0}).target, 33);
  });

  test('controller persists every tap and restores after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final t = TasbihController(SettingsController(prefs));
    await t.setTarget(99);
    for (var i = 0; i < 100; i++) {
      await t.tap();
    }
    expect(t.state.count, 1);
    expect(t.state.rounds, 1);
    final restarted = TasbihController(SettingsController(prefs));
    expect(restarted.state.count, 1);
    expect(restarted.state.total, 100);
    expect(restarted.state.target, 99);
    await restarted.reset();
    expect(TasbihController(SettingsController(prefs)).state.total, 0);
  });

  test('corrupt storage falls back to a fresh counter', () async {
    SharedPreferences.setMockInitialValues({'tasbih.v1': 'not json'});
    final t = TasbihController(SettingsController(await SharedPreferences.getInstance()));
    expect(t.state.count, 0);
    expect(t.state.target, 33);
  });

  group('TasbihBook', () {
    final d1 = DateTime(2026, 11, 9), d2 = DateTime(2026, 11, 10);

    test('a counter per dhikr and a per-day history', () {
      var b = const TasbihBook();
      b = b.tap(d1).$1.tap(d1).$1;
      b = b.copyWith(phrase: 'takbir');
      expect(b.current.count, 0);
      b = b.withCurrent(b.current.withTarget(100)).tap(d2).$1;
      expect(b.counters['tasbih']!.count, 2);
      expect(b.counters['takbir']!.target, 100);
      expect(b.historyRows(), [('2026-11-10', 'takbir', 1), ('2026-11-09', 'tasbih', 2)]);
      b = b.undo(d2);
      expect(b.current.count, 0);
      expect(b.history.containsKey('2026-11-10'), isFalse);
      expect(identical(b.undo(d2), b), isTrue);
    });

    test('round completion, 60-day history window', () {
      var b = TasbihBook(counters: {'tasbih': const TasbihState(count: 32)});
      final (next, round) = b.tap(DateTime(2026, 1, 1));
      expect(round, isTrue);
      expect(next.current.rounds, 1);
      b = next.tap(DateTime(2026, 3, 15)).$1;
      expect(b.history.keys, ['2026-03-15']);
    });

    test('custom adhkar: add, limits, remove', () {
      var b = const TasbihBook().addCustom('  اللهم صل على محمد ');
      expect(b.custom.single.id, 'c1');
      expect(b.phrase, 'c1');
      expect(b.textOf('c1'), 'اللهم صل على محمد');
      b = b.tap(d1).$1;
      expect(identical(b.addCustom('  '), b), isTrue);
      b = b.addCustom('x' * 200);
      expect(b.custom[1].text.length, maxCustomText);
      b = b.copyWith(phrase: 'c1').removeCustom('c1');
      expect(b.phrase, 'tasbih');
      expect(b.custom.map((c) => c.id), ['c2']);
      expect(b.history, isEmpty);
      expect(b.counters.containsKey('c1'), isFalse);
    });

    test('JSON round trip and repair', () {
      final b = const TasbihBook(
        mode: TasbihMode.beads,
        color: 'plum',
        sound: true,
        vibrate: false,
      ).addCustom('ذكر').tap(d1).$1;
      final r = TasbihBook.fromJson(b.toJson());
      expect(r.toJson(), b.toJson());
      final bad = TasbihBook.fromJson({
        'phrase': 'zz',
        'custom': [
          {'id': 'bad', 'text': 'x'},
          {'id': 'c2', 'text': ' '},
        ],
        'counters': {
          'nope': {'count': 1},
        },
        'mode': 'x',
        'color': 'neon',
        'history': {
          'junk': {'tasbih': 1},
          '2026-11-09': {'tasbih': -1, 'takbir': 3},
        },
      });
      expect(bad.phrase, 'tasbih');
      expect(bad.custom, isEmpty);
      expect(bad.counters, isEmpty);
      expect(bad.mode, TasbihMode.beads);
      expect(bad.color, 'brown');
      expect(bad.history, {
        '2026-11-09': {'takbir': 3},
      });
    });

    test('controller migrates the old single counter and persists options', () async {
      SharedPreferences.setMockInitialValues({'tasbih.v1': '{"count":12,"total":45,"rounds":1,"target":33}'});
      final prefs = await SharedPreferences.getInstance();
      final t = TasbihController(SettingsController(prefs), today: () => d1);
      expect(t.state.count, 12);
      await t.addCustom('سبحان الله وبحمده');
      await t.tap();
      await t.setMode(TasbihMode.beads);
      await t.setColor('gold');
      await t.setColor('neon');
      final again = TasbihController(SettingsController(prefs), today: () => d1);
      expect(again.book.phrase, 'c1');
      expect(again.state.count, 1);
      expect(again.book.counters['tasbih']!.total, 45);
      expect(again.book.mode, TasbihMode.beads);
      expect(again.book.color, 'gold');
      await again.clearHistory();
      expect(again.book.history, isEmpty);
    });
  });
}
