import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Per-dhikr recordings kept on the phone for listening without internet (owner 2026-11-27: every dhikr
/// that can be heard can be downloaded, one by one or all at once). Files live in the app's own storage as
/// `dhikr/<id>.mp3`, named by the recording's number in its URL.
class DhikrClips extends ChangeNotifier {
  DhikrClips({required http.Client httpClient, required Future<Directory> Function() root})
    : _http = httpClient,
      _root = root;

  final http.Client _http;
  final Future<Directory> Function() _root;

  /// A real recording is never this small (an error page is).
  static const _minBytes = 8 * 1024;
  static const _concurrency = 3;

  String? _dir;
  final Set<String> _saved = {};
  final Map<String, int> _sizes = {};

  /// Recordings being downloaded one by one now (by URL).
  final Set<String> busy = {};

  /// The "download all" now running: which group, how many done of how many.
  String? batch;
  int batchDone = 0;
  int batchTotal = 0;

  /// The last "download all" stopped on a network error.
  String? batchFailed;
  bool _cancel = false;

  /// The recording's number in its URL (`…/123.mp3` → "123").
  static String? idOf(String url) => RegExp(r'(\d+)\.mp3$').firstMatch(url)?.group(1);

  Future<Directory> _folder() async {
    final d = Directory('${(await _root()).path}/dhikr');
    if (!d.existsSync()) d.createSync(recursive: true);
    _dir = d.path;
    return d;
  }

  Future<void>? _scan;

  /// Reads which recordings are already on the phone (once).
  Future<void> ready() => _scan ??= () async {
    try {
      final d = await _folder();
      for (final f in d.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!name.endsWith('.mp3')) continue;
        final len = f.lengthSync();
        if (len < _minBytes) continue;
        final id = name.substring(0, name.length - 4);
        _saved.add(id);
        _sizes[id] = len;
      }
    } catch (e) {
      debugPrint('dhikr clips: no storage ($e)');
    }
    notifyListeners();
  }();

  bool isSaved(String url) => _saved.contains(idOf(url));
  int savedCount([Iterable<String>? urls]) =>
      urls == null ? _saved.length : urls.map(idOf).toSet().where(_saved.contains).length;
  int get bytes => _sizes.values.fold(0, (a, b) => a + b);

  /// The saved file of [url], or null when it is not on the phone.
  String? localPath(String url) {
    final id = idOf(url);
    if (id == null || _dir == null || !_saved.contains(id)) return null;
    return '$_dir/$id.mp3';
  }

  Future<bool> _fetch(String url) async {
    final id = idOf(url);
    if (id == null) return false;
    if (_saved.contains(id)) return true;
    final d = await _folder();
    final res = await _http.get(Uri.parse(url)).timeout(const Duration(minutes: 2));
    final b = res.bodyBytes;
    if (res.statusCode != 200 || b.length < _minBytes || !_looksLikeMp3(b)) {
      throw HttpException('HTTP ${res.statusCode}, ${b.length} bytes', uri: Uri.parse(url));
    }
    final tmp = File('${d.path}/$id.part');
    // Sync file calls: quick for a small clip, and they also finish inside widget tests.
    tmp.writeAsBytesSync(b, flush: true);
    tmp.renameSync('${d.path}/$id.mp3');
    _saved.add(id);
    _sizes[id] = b.length;
    return true;
  }

  /// Downloads one recording; false when it could not be downloaded.
  Future<bool> download(String url) async {
    await ready();
    if (isSaved(url) || busy.contains(url)) return true;
    busy.add(url);
    notifyListeners();
    try {
      return await _fetch(url);
    } catch (e) {
      debugPrint('dhikr clip $url: $e');
      return false;
    } finally {
      busy.remove(url);
      notifyListeners();
    }
  }

  /// Downloads every recording of [urls] (group [key]); files already saved are kept, so a retry goes on
  /// where it stopped. One "download all" at a time.
  Future<bool> downloadAll(String key, Iterable<String> urls) async {
    await ready();
    if (batch != null) return false;
    final todo = {for (final u in urls) idOf(u): u}..removeWhere((id, _) => id == null || _saved.contains(id));
    final list = todo.values.toList();
    batch = key;
    batchFailed = null;
    batchDone = 0;
    batchTotal = list.length;
    _cancel = false;
    notifyListeners();
    var failed = false;
    var next = 0;
    Future<void> worker() async {
      while (!_cancel && !failed && next < list.length) {
        final u = list[next++];
        try {
          await _fetch(u);
          batchDone++;
        } catch (e) {
          debugPrint('dhikr clip $u: $e');
          failed = true;
        }
        notifyListeners();
      }
    }

    await Future.wait([for (var i = 0; i < _concurrency; i++) worker()]);
    if (failed) batchFailed = key;
    batch = null;
    notifyListeners();
    return !failed && !_cancel;
  }

  void cancel() {
    _cancel = true;
    notifyListeners();
  }

  Future<void> delete(String url) async {
    final id = idOf(url);
    if (id == null) return;
    await _folder();
    final f = File('$_dir/$id.mp3');
    if (f.existsSync()) f.deleteSync();
    _saved.remove(id);
    _sizes.remove(id);
    notifyListeners();
  }

  /// Removes [urls] (every saved recording when null).
  Future<void> deleteAll([Iterable<String>? urls]) async {
    await _folder();
    final ids = urls == null ? {..._saved} : urls.map(idOf).whereType<String>().toSet();
    for (final id in ids) {
      final f = File('$_dir/$id.mp3');
      if (f.existsSync()) f.deleteSync();
      _saved.remove(id);
      _sizes.remove(id);
    }
    notifyListeners();
  }

  static bool _looksLikeMp3(Uint8List b) =>
      (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) || // "ID3"
      (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0); // MPEG frame sync
}
