import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/worship.dart';
import 'settings.dart';

/// The worship tracker log, persisted as JSON in the settings store.
class WorshipController extends ChangeNotifier {
  WorshipController(this._settings, this._today) {
    try {
      _log = WorshipLog.fromJson(jsonDecode(_settings.rawJson(_key) ?? 'null'));
    } catch (_) {
      _log = const WorshipLog();
    }
  }

  static const _key = 'worship';
  final SettingsController _settings;
  final DateTime Function() _today;
  late WorshipLog _log;

  WorshipLog get log => _log;
  DateTime get today => _today();

  Future<void> _set(WorshipLog l) async {
    _log = l;
    notifyListeners();
    await _settings.setRawJson(_key, jsonEncode(l.toJson()));
  }

  Future<void> togglePrayer(DateTime d, String key) => _set(_log.togglePrayer(d, key));
  Future<void> setFasting(DateTime d, bool on) => _set(_log.setFasting(d, on));
  Future<void> setNote(DateTime d, String note) => _set(_log.setNote(d, note));
}
