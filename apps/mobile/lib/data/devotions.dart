import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/adhkar.dart';
import '../domain/tasbih.dart';
import 'content.dart';
import 'settings.dart';

/// Tasbih counter persisted in shared_preferences ("tasbih.v1").
class TasbihController extends ChangeNotifier {
  TasbihController(this._settings) {
    final raw = _settings.rawJson(_key);
    if (raw != null) {
      try {
        _state = TasbihState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        _state = const TasbihState();
      } on TypeError {
        _state = const TasbihState();
      }
    }
  }

  static const _key = 'tasbih.v1';
  final SettingsController _settings;
  TasbihState _state = const TasbihState();

  TasbihState get state => _state;

  /// Returns true when this tap completed a round.
  Future<bool> tap() async {
    final before = _state;
    _state = _state.tap();
    notifyListeners();
    await _save();
    return _state.completedRoundFrom(before);
  }

  Future<void> setTarget(int t) async {
    _state = _state.withTarget(t);
    notifyListeners();
    await _save();
  }

  Future<void> reset() async {
    _state = _state.reset();
    notifyListeners();
    await _save();
  }

  Future<void> _save() => _settings.setRawJson(_key, jsonEncode(_state.toJson()));
}

/// Morning/evening adhkar counters for today, persisted per session and reset
/// automatically on a new local day.
class AdhkarController extends ChangeNotifier {
  AdhkarController(this._content, this._settings, this._today);

  final AppContent _content;
  final SettingsController _settings;

  /// Local date (y-m-d) used to reset yesterday's counters.
  final DateTime Function() _today;
  final Map<AdhkarSession, AdhkarProgress> _progress = {};

  static String _key(AdhkarSession s) => 'adhkar.progress.${s.name}';
  String get _todayStamp {
    final d = _today();
    return '${d.year}-${d.month}-${d.day}';
  }

  AdhkarProgress progress(AdhkarSession s) {
    final stamp = _todayStamp;
    final existing = _progress[s];
    if (existing != null && _loadedOn[s] == stamp) return existing;
    final items = _content.adhkar.forSession(s);
    Map<int, int>? done;
    final raw = _settings.rawJson(_key(s));
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if (j['date'] == stamp) {
          done = {
            for (final e in (j['done'] as Map<String, dynamic>).entries) int.parse(e.key): (e.value as num).toInt(),
          };
        }
      } on FormatException {
        done = null;
      } on TypeError {
        done = null;
      }
    }
    _loadedOn[s] = stamp;
    return _progress[s] = AdhkarProgress(items, done);
  }

  final Map<AdhkarSession, String> _loadedOn = {};

  Future<void> tap(AdhkarSession s, Dhikr d) async {
    if (progress(s).tap(d)) {
      notifyListeners();
      await _save(s);
    }
  }

  Future<void> reset(AdhkarSession s) async {
    progress(s).resetAll();
    notifyListeners();
    await _save(s);
  }

  Future<void> _save(AdhkarSession s) => _settings.setRawJson(
    _key(s),
    jsonEncode({
      'date': _todayStamp,
      'done': {for (final e in progress(s).done.entries) '${e.key}': e.value},
    }),
  );
}
