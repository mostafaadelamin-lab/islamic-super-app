import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/prayer_schedule.dart';
import '../domain/quran.dart';

/// User preferences, persisted in shared_preferences.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs, {String defaultCityId = 'c1'}) : _defaultCityId = defaultCityId;

  static const defaultApiBaseUrl = 'http://10.0.2.2:8000';
  static const minFontSize = 18.0;
  static const maxFontSize = 40.0;
  static const defaultFontSize = 26.0;

  final SharedPreferences _prefs;
  final String _defaultCityId;

  Locale get locale => Locale(_prefs.getString('locale') ?? 'ar');
  bool get isArabic => locale.languageCode == 'ar';
  Future<void> setLocale(String code) async {
    if (code != 'ar' && code != 'en') throw ArgumentError(code);
    await _prefs.setString('locale', code);
    notifyListeners();
  }

  ThemeMode get themeMode => switch (_prefs.getString('theme')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  Future<void> setThemeMode(ThemeMode m) async {
    await _prefs.setString('theme', m.name);
    notifyListeners();
  }

  double get quranFontSize => (_prefs.getDouble('quranFontSize') ?? defaultFontSize).clamp(minFontSize, maxFontSize);
  Future<void> setQuranFontSize(double v) async {
    await _prefs.setDouble('quranFontSize', v.clamp(minFontSize, maxFontSize).roundToDouble());
    notifyListeners();
  }

  bool get showTranslation => _prefs.getBool('showTranslation') ?? false;
  Future<void> setShowTranslation(bool v) async {
    await _prefs.setBool('showTranslation', v);
    notifyListeners();
  }

  // --- Prayer ---------------------------------------------------------------
  String get cityId => _prefs.getString('cityId') ?? _defaultCityId;

  /// Selecting a city also selects that city's recommended method.
  Future<void> setCity(String id, String recommendedMethod) async {
    await _prefs.setString('cityId', id);
    await _prefs.setString('method', recommendedMethod);
    notifyListeners();
  }

  /// Null means "use the city's recommended method".
  String? get method => _prefs.getString('method');
  Future<void> setMethod(String m) async {
    await _prefs.setString('method', m);
    notifyListeners();
  }

  String get asr => _prefs.getString('asr') ?? 'standard';
  Future<void> setAsr(String a) async {
    await _prefs.setString('asr', a);
    notifyListeners();
  }

  Map<String, int> get adjustments {
    final raw = _prefs.getString('adjustments');
    if (raw == null) return const {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in m.entries) e.key: clampAdjustment((e.value as num).toInt())};
  }

  Future<void> setAdjustment(String key, int minutes) async {
    final m = Map<String, int>.of(adjustments)..[key] = clampAdjustment(minutes);
    m.removeWhere((_, v) => v == 0);
    await _prefs.setString('adjustments', jsonEncode(m));
    notifyListeners();
  }

  Future<void> resetAdjustments() async {
    await _prefs.remove('adjustments');
    notifyListeners();
  }

  // --- Reading position ------------------------------------------------------
  AyahRef? get lastRead {
    final s = _prefs.getInt('lastRead.surah');
    final a = _prefs.getInt('lastRead.ayah');
    return s == null || a == null ? null : AyahRef(s, a);
  }

  Future<void> setLastRead(AyahRef r) async {
    if (lastRead == r) return;
    await _prefs.setInt('lastRead.surah', r.surah);
    await _prefs.setInt('lastRead.ayah', r.ayah);
    notifyListeners();
  }

  // --- Account ----------------------------------------------------------------
  String get apiBaseUrl => _prefs.getString('apiBaseUrl') ?? defaultApiBaseUrl;
  Future<void> setApiBaseUrl(String url) async {
    await _prefs.setString('apiBaseUrl', url);
    notifyListeners();
  }
}
