import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/tafsir.dart';

/// Loads Tafsir al-Muyassar on first use, not at start-up: the file is about
/// 2.5 MB, so it is read only when an ayah sheet first asks for it, and decoded
/// in a background isolate so the UI does not stall.
class TafsirStore {
  TafsirStore(this._loader);

  /// Reads the bundled asset and decodes it off the UI thread.
  factory TafsirStore.asset(AssetBundle bundle, {String key = assetKey}) =>
      TafsirStore(() async => compute(TafsirContent.parse, await bundle.loadString(key, cache: false)));

  /// An already decoded tafsir (tests).
  factory TafsirStore.preloaded(TafsirContent content) => TafsirStore(() async => content).._loaded = content;

  static const assetKey = 'assets/content/tafsir-muyassar.v1.json';

  final Future<TafsirContent> Function() _loader;
  Future<TafsirContent>? _future;
  TafsirContent? _loaded;

  /// The tafsir if it has finished loading, else null.
  TafsirContent? get loaded => _loaded;

  /// Starts loading (once) and completes with the tafsir. A failed load is
  /// retried on the next call.
  Future<TafsirContent> load() => _future ??= _loader().then(
    (c) => _loaded = c,
    onError: (Object e, StackTrace st) {
      _future = null;
      return Future<TafsirContent>.error(e, st);
    },
  );
}
