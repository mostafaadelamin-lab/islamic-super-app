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
    final items = _itemsFor(s);
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

  static const _customKey = 'adhkar.custom';
  List<UserDhikr>? _custom;

  /// The user's own adhkar («أذكاري»), oldest first.
  List<UserDhikr> get custom {
    if (_custom != null) return _custom!;
    var list = <UserDhikr>[];
    final raw = _settings.rawJson(_customKey);
    if (raw != null) {
      try {
        list = [
          for (final x in jsonDecode(raw) as List<dynamic>) UserDhikr.fromJson(x as Map<String, dynamic>),
        ].where((d) => d.text.trim().isNotEmpty && d.sessions.isNotEmpty).toList();
      } on FormatException {
        list = [];
      } on TypeError {
        list = [];
      }
    }
    return _custom = List.unmodifiable(list);
  }

  List<Dhikr> _itemsFor(AdhkarSession s) => [
    ..._content.adhkar.forSession(s),
    for (final c in custom)
      if (c.sessions.contains(s)) c.toDhikr(),
  ];

  /// Adds a new dhikr (when [id] is null) or replaces the one with [id].
  Future<void> saveCustom({
    int? id,
    required String text,
    required int count,
    required Set<AdhkarSession> sessions,
  }) async {
    final t = text.trim();
    if (t.isEmpty || sessions.isEmpty) return;
    final list = [...custom];
    final nextId = list.isEmpty ? 1 : list.map((d) => d.id).reduce((a, b) => a > b ? a : b) + 1;
    final d = UserDhikr(id: id ?? nextId, text: t, count: count.clamp(1, UserDhikr.maxCount), sessions: sessions);
    final at = list.indexWhere((x) => x.id == d.id);
    if (at < 0) {
      list.add(d);
    } else {
      list[at] = d;
    }
    await _setCustom(list);
  }

  Future<void> deleteCustom(int id) async {
    await _setCustom([...custom.where((d) => d.id != id)]);
    for (final s in AdhkarSession.values) {
      final p = _progress[s];
      if (p != null && _loadedOn[s] == _todayStamp) {
        p.reset(UserDhikr(id: id, text: '', count: 1, sessions: const {}).toDhikr());
        await _save(s);
      }
    }
  }

  Future<void> _setCustom(List<UserDhikr> list) async {
    _custom = List.unmodifiable(list);
    // Rebuild today's lists, keeping the counts already made.
    for (final s in AdhkarSession.values) {
      final p = _progress[s];
      if (p != null && _loadedOn[s] == _todayStamp) _progress[s] = AdhkarProgress(_itemsFor(s), p.done);
    }
    notifyListeners();
    await _settings.setRawJson(_customKey, jsonEncode([for (final d in list) d.toJson()]));
  }

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
