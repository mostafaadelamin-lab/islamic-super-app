import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/adhkar.dart';
import '../domain/tasbih.dart';
import 'content.dart';
import 'settings.dart';

/// Tasbih: every dhikr's counter, the user's own adhkar, options and history,
/// persisted in shared_preferences ("tasbih.v2"; the single counter of
/// "tasbih.v1" is carried over to the first dhikr).
class TasbihController extends ChangeNotifier {
  TasbihController(this._settings, {DateTime Function()? today}) : _today = today ?? DateTime.now {
    try {
      final v2 = _settings.rawJson(_key);
      if (v2 != null) {
        _book = TasbihBook.fromJson(jsonDecode(v2));
        return;
      }
      final v1 = _settings.rawJson(_legacyKey);
      if (v1 != null) {
        _book = TasbihBook(counters: {'tasbih': TasbihState.fromJson(jsonDecode(v1) as Map<String, dynamic>)});
      }
    } on FormatException {
      _book = const TasbihBook();
    } on TypeError {
      _book = const TasbihBook();
    }
  }

  static const _key = 'tasbih.v2';
  static const _legacyKey = 'tasbih.v1';
  final SettingsController _settings;
  final DateTime Function() _today;
  TasbihBook _book = const TasbihBook();

  TasbihBook get book => _book;

  /// The selected dhikr's counter.
  TasbihState get state => _book.current;

  Future<void> _set(TasbihBook b) async {
    _book = b;
    notifyListeners();
    await _settings.setRawJson(_key, jsonEncode(b.toJson()));
  }

  /// Returns true when this tap completed a round.
  Future<bool> tap() async {
    final (b, round) = _book.tap(_today());
    await _set(b);
    return round;
  }

  Future<void> undo() => _set(_book.undo(_today()));
  Future<void> setTarget(int t) => _set(_book.withCurrent(state.withTarget(t)));
  Future<void> reset() => _set(_book.withCurrent(state.reset()));
  Future<void> select(String id) => _set(_book.ids.contains(id) ? _book.copyWith(phrase: id) : _book);
  Future<void> addCustom(String text) => _set(_book.addCustom(text));
  Future<void> removeCustom(String id) => _set(_book.removeCustom(id));
  Future<void> setMode(TasbihMode m) => _set(_book.copyWith(mode: m));
  Future<void> setColor(String c) => _set(tasbihColors.containsKey(c) ? _book.copyWith(color: c) : _book);
  Future<void> setStyle(BeadStyle v) => _set(_book.copyWith(style: v));
  Future<void> setSound(bool on) => _set(_book.copyWith(sound: on));
  Future<void> setVibrate(bool on) => _set(_book.copyWith(vibrate: on));
  Future<void> clearHistory() => _set(_book.copyWith(history: const {}));
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
