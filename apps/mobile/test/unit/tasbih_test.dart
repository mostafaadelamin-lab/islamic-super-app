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
}
