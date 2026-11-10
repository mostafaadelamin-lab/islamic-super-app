import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/hadith.dart';
import '../domain/text.dart';

/// Reads the bundled hadith books part by part (500 hadiths a file), only when they are opened.
class HadithLibrary {
  /// [isolate]: decode large part files off the UI thread (off in widget tests, where isolates
  /// don't run under the fake clock).
  HadithLibrary(this.catalog, this._read, {this.isolate = true});

  factory HadithLibrary.asset(HadithCatalog catalog, AssetBundle bundle) =>
      HadithLibrary(catalog, (key) => bundle.loadString(key, cache: false));

  static const catalogAsset = 'assets/hadith/books.v1.json';

  final HadithCatalog catalog;
  final Future<String> Function(String key) _read;
  final bool isolate;
  final _parts = <String, Future<List<String>>>{};

  static List<String> _decode(String raw) => [
    for (final t in (jsonDecode(raw) as Map<String, dynamic>)['ahadith'] as List<dynamic>) t as String,
  ];

  /// The texts of part [k] of [book] (kept in memory once read; a failed read is retried next time).
  Future<List<String>> part(String book, int k) {
    final key = '$book/$k';
    return _parts[key] ??= _read('assets/hadith/$key.json').then(
      (raw) => isolate && raw.length > 100000 ? compute(_decode, raw) : _decode(raw),
      onError: (Object e, StackTrace st) {
        _parts.remove(key);
        return Future<List<String>>.error(e, st);
      },
    );
  }

  /// Hadiths [from]..[to] (inclusive, clamped to the book).
  Future<List<HadithItem>> range(HadithBook book, int from, int to) async {
    final a = from < 1 ? 1 : from;
    final b = to > book.count ? book.count : to;
    if (b < a) return const [];
    final first = catalog.chunkOf(a);
    final parts = await Future.wait([for (var k = first; k <= catalog.chunkOf(b); k++) part(book.id, k)]);
    final start = first * catalog.chunkSize + 1;
    final all = parts.expand((p) => p).toList();
    return [
      for (var i = 0; i < all.length; i++)
        if (start + i >= a && start + i <= b) HadithItem(start + i, all[i]),
    ];
  }

  /// Hadiths of [book] containing every word of [query], ignoring diacritics; at most [hadithSearchLimit].
  Future<List<HadithItem>> search(
    HadithBook book,
    String query,
    SearchNormalizer norm, {
    void Function(int done, int total)? onProgress,
  }) async {
    final words = norm.normalize(query).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final hits = <HadithItem>[];
    for (var k = 0; k < book.chunks && hits.length < hadithSearchLimit; k++) {
      final texts = await part(book.id, k);
      for (var i = 0; i < texts.length && hits.length < hadithSearchLimit; i++) {
        final t = norm.normalize(texts[i]);
        if (words.every(t.contains)) hits.add(HadithItem(k * catalog.chunkSize + i + 1, texts[i]));
      }
      onProgress?.call(k + 1, book.chunks);
    }
    return hits;
  }
}
