import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One explained word: the word as the book prints it, and its meaning.
typedef WordMeaning = ({String word, String meaning});

/// «معاني الكلمات» (owner 2026-11-17): the difficult words of each ayah with their meanings from
/// «السراج في بيان غريب القرآن» (Muhammad al-Khudairi), via the Quranpedia.net data dump
/// (content/word-meanings/dist/siraj.v1.json, schema word-meanings.v1). Text kept exactly as stored.
class WordMeaningsContent {
  WordMeaningsContent({required this.nameAr, required this.authorAr, required this.surahs});

  factory WordMeaningsContent.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 'word-meanings.v1') throw FormatException('not a word-meanings.v1 file: ${j['schema']}');
    final surahs = [
      for (final s in j['surahs'] as List<dynamic>)
        List<List<WordMeaning>>.unmodifiable([
          for (final a in s as List<dynamic>)
            List<WordMeaning>.unmodifiable([
              for (final w in a as List<dynamic>) (word: (w as List<dynamic>)[0] as String, meaning: w[1] as String),
            ]),
        ]),
    ];
    if (surahs.length != 114) throw FormatException('word meanings have ${surahs.length} surahs, expected 114');
    return WordMeaningsContent(
      nameAr: j['nameAr'] as String,
      authorAr: j['authorAr'] as String,
      surahs: List.unmodifiable(surahs),
    );
  }

  /// Decodes the raw JSON file (top-level so it can run in a background isolate).
  static WordMeaningsContent parse(String json) =>
      WordMeaningsContent.fromJson(jsonDecode(json) as Map<String, dynamic>);

  final String nameAr;
  final String authorAr;

  /// surahs[s - 1][a - 1] lists the explained words of ayah s:a (often none).
  final List<List<List<WordMeaning>>> surahs;

  int get wordCount => surahs.fold(0, (n, s) => n + s.fold(0, (m, a) => m + a.length));

  /// The explained words of [surah]:[ayah]; empty when there are none or no such ayah.
  List<WordMeaning> words(int surah, int ayah) {
    if (surah < 1 || surah > surahs.length) return const [];
    final s = surahs[surah - 1];
    if (ayah < 1 || ayah > s.length) return const [];
    return s[ayah - 1];
  }
}

/// Loads the word meanings on first use (about 0.6 MB), decoded off the UI thread.
class WordMeaningsStore {
  WordMeaningsStore(this._loader);

  factory WordMeaningsStore.asset(AssetBundle bundle, {String key = assetKey}) =>
      WordMeaningsStore(() async => compute(WordMeaningsContent.parse, await bundle.loadString(key, cache: false)));

  factory WordMeaningsStore.preloaded(WordMeaningsContent content) =>
      WordMeaningsStore(() async => content).._loaded = content;

  static const assetKey = 'assets/content/word-meanings-siraj.v1.json';

  final Future<WordMeaningsContent> Function() _loader;
  Future<WordMeaningsContent>? _future;
  WordMeaningsContent? _loaded;

  WordMeaningsContent? get loaded => _loaded;

  /// Starts loading (once); a failed load is retried on the next call.
  Future<WordMeaningsContent> load() => _future ??= _loader().then(
    (c) => _loaded = c,
    onError: (Object e, StackTrace st) {
      _future = null;
      return Future<WordMeaningsContent>.error(e, st);
    },
  );
}
