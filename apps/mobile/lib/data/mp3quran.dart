import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mp3quran.dart';

/// Reads mp3quran.net's API (reciters, riwayat, radios) for the app's language and keeps the
/// answers on the device, so the library opens offline and is refreshed at most once a week.
class Mp3QuranClient {
  Mp3QuranClient({
    required http.Client httpClient,
    required SharedPreferences prefs,
    DateTime Function()? clock,
    this.maxAge = const Duration(days: 7),
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient,
       _prefs = prefs,
       _clock = clock ?? DateTime.now;

  static const base = 'https://www.mp3quran.net/api/v3';
  static String cacheKey(String lang) => 'mp3quran.cache.$lang';

  final http.Client _http;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final Duration maxAge;
  final Duration timeout;

  /// API language: "ar" or "eng".
  static String apiLanguage(bool arabic) => arabic ? 'ar' : 'eng';

  Future<Object?> _get(String path, String lang) async {
    final res = await _http.get(Uri.parse('$base/$path?language=$lang')).timeout(timeout);
    if (res.statusCode != 200) throw http.ClientException('$path ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  (DateTime, Map<String, dynamic>)? _cached(String lang) {
    final raw = _prefs.getString(cacheKey(lang));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (DateTime.parse(j['at'] as String), j);
    } on Object {
      return null;
    }
  }

  static Mp3Library _library(Map<String, dynamic> j) =>
      Mp3Library.fromApi(reciters: j['reciters'], riwayat: j['riwayat'], radios: j['radios']);

  /// The library: from the device if fresh (or [refresh] is false and the network fails),
  /// else from the API. Throws only when there is neither a network answer nor a saved copy.
  Future<Mp3Library> load(String lang, {bool refresh = false}) async {
    final cached = _cached(lang);
    if (!refresh && cached != null && _clock().difference(cached.$1) < maxAge) return _library(cached.$2);
    try {
      final answers = await Future.wait([_get('reciters', lang), _get('riwayat', lang), _get('radios', lang)]);
      final j = {'at': _clock().toIso8601String(), 'reciters': answers[0], 'riwayat': answers[1], 'radios': answers[2]};
      final lib = _library(j);
      if (lib.reciters.isEmpty && lib.radios.isEmpty) throw const FormatException('empty answer');
      await _prefs.setString(cacheKey(lang), jsonEncode(j));
      return lib;
    } on Object {
      if (cached != null) return _library(cached.$2);
      rethrow;
    }
  }
}
