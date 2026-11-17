import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/adhan_voices.dart';

/// The muezzins and the recordings downloaded for them. Only the defaults are
/// bundled; any other recording is downloaded once, when the user picks or
/// plays it, and kept in the app's own storage (`adhan/<id>.mp3`) so the adhan
/// sounds without internet afterwards.
class AdhanVoiceFiles extends ChangeNotifier {
  AdhanVoiceFiles({
    required http.Client httpClient,
    required Future<Directory> Function() root,
    this.retryDelay = const Duration(seconds: 2),
  }) : _http = httpClient,
       _root = root;

  final http.Client _http;
  final Future<Directory> Function() _root;

  /// Wait between attempts (the server often answers 502 at the first try).
  final Duration retryDelay;
  static const _attempts = 4;

  /// A real recording is never this small (an error page is).
  static const _minBytes = 20 * 1024;

  Directory? _dir;
  final Set<String> _have = {};
  final Set<String> _downloading = {};
  final Set<String> _failed = {};

  bool isDownloading(String id) => _downloading.contains(id);
  bool hasFailed(String id) => _failed.contains(id);

  /// Bundled voices are always there; others once downloaded.
  bool isReady(String id) => (findAdhanVoice(id)?.bundled ?? false) || _have.contains(id);

  /// Every muezzin, bundled first in the list order.
  Future<List<AdhanVoice>> catalog() async => allAdhanVoices;

  /// A voice by id, or null.
  Future<AdhanVoice?> voice(String id) async => findAdhanVoice(id);

  Future<Directory> _folder() async {
    final d = _dir ??= Directory('${(await _root()).path}/adhan');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// Finds the recordings downloaded earlier.
  Future<void> init() async {
    try {
      final d = await _folder();
      for (final f in d.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.endsWith('.mp3') && f.lengthSync() >= _minBytes) _have.add(name.substring(0, name.length - 4));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('adhan voices: no storage ($e)');
    }
  }

  /// Path of a downloaded recording (synchronous, for the alarm planner), or null.
  String? localPath(String id) => _have.contains(id) && _dir != null ? '${_dir!.path}/$id.mp3' : null;

  /// What the in-app player plays: the bundled asset or the downloaded file (downloading it first).
  Future<String?> playable(String id) async {
    final b = findAdhanVoice(id);
    if (b != null && b.bundled) return b.asset;
    if (!_have.contains(id) && !await download(id)) return null;
    return localPath(id);
  }

  /// What the Android alarm plays: a res/raw name or the downloaded file's
  /// path. A voice that is not on the phone falls back to the default one.
  String nativeVoice(String id, {required bool fajr}) {
    final b = findAdhanVoice(id);
    if (b != null && b.bundled) return b.raw!;
    return localPath(id) ?? findAdhanVoice(fajr ? defaultFajrVoice : defaultAdhanVoice)!.raw!;
  }

  /// Downloads, quietly, the chosen muezzins that are not on the phone yet (e.g. after an update that stopped
  /// bundling them). Each is tried once per app start.
  Future<void> fetchMissing(Iterable<String> ids) async {
    for (final id in ids.toSet()) {
      if (!isReady(id) && !_tried.contains(id)) {
        _tried.add(id);
        await download(id);
      }
    }
  }

  final Set<String> _tried = {};

  /// Downloads a muezzin's recording (website first, then its original source); true when it is on the phone.
  Future<bool> download(String id) async {
    if (isReady(id)) return true;
    final uris = findAdhanVoice(id)?.downloadUris ?? const <Uri>[];
    if (uris.isEmpty || _downloading.contains(id)) return false;
    _downloading.add(id);
    _failed.remove(id);
    notifyListeners();
    try {
      final d = await _folder();
      for (var attempt = 1; attempt <= _attempts; attempt++) {
        try {
          // Alternate between the addresses, so one that is down does not use up every attempt.
          final uri = uris[(attempt - 1) % uris.length];
          final res = await _http.get(uri).timeout(const Duration(minutes: 2));
          final bytes = res.bodyBytes;
          if (res.statusCode == 200 && bytes.length >= _minBytes && _looksLikeMp3(bytes)) {
            final tmp = File('${d.path}/$id.part');
            tmp.writeAsBytesSync(bytes, flush: true);
            tmp.renameSync('${d.path}/$id.mp3');
            _have.add(id);
            return true;
          }
        } catch (e) {
          debugPrint('adhan voice $id, attempt $attempt: $e');
        }
        if (attempt < _attempts) await Future<void>.delayed(retryDelay);
      }
      _failed.add(id);
      return false;
    } catch (e) {
      _failed.add(id);
      debugPrint('adhan voice $id: $e');
      return false;
    } finally {
      _downloading.remove(id);
      notifyListeners();
    }
  }

  /// Removes a downloaded recording (not the bundled ones).
  Future<void> delete(String id) async {
    final p = localPath(id);
    _have.remove(id);
    if (p != null) {
      try {
        await File(p).delete();
      } catch (_) {}
    }
    notifyListeners();
  }

  static bool _looksLikeMp3(Uint8List b) =>
      (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) || // "ID3"
      (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0); // MPEG frame sync
}
