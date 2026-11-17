import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sheikh Mishary Alafasy's morning and evening adhkar recordings. Since 1.2.1 they are not bundled (to keep
/// the app small): each is downloaded once, the first time it is played, from the website (the same files the
/// website plays) and kept in the app's own storage (`adhkar/<name>.mp3`), so it plays offline afterwards.
class AdhkarAudioFiles {
  AdhkarAudioFiles({
    required http.Client httpClient,
    required Future<Directory> Function() root,
    this.retryDelay = const Duration(seconds: 2),
  }) : _http = httpClient,
       _root = root;

  final http.Client _http;
  final Future<Directory> Function() _root;
  final Duration retryDelay;
  static const _attempts = 3;

  /// A real recording is never this small (an error page is).
  static const _minBytes = 200 * 1024;

  static const base = 'https://rattilwasalli.com/audio';

  Future<Directory> _folder() async {
    final d = Directory('${(await _root()).path}/adhkar');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// The downloaded file of [name], or null when it is not on the phone yet.
  Future<String?> local(String name) async {
    try {
      final f = File('${(await _folder()).path}/$name.mp3');
      return f.existsSync() && f.lengthSync() >= _minBytes ? f.path : null;
    } catch (e) {
      debugPrint('adhkar audio: no storage ($e)');
      return null;
    }
  }

  /// The file of [name], downloading it first when needed; null when it could not be downloaded.
  Future<String?> fetch(String name) async {
    final have = await local(name);
    if (have != null) return have;
    final d = await _folder();
    for (var attempt = 1; attempt <= _attempts; attempt++) {
      try {
        final res = await _http.get(Uri.parse('$base/$name.mp3')).timeout(const Duration(minutes: 5));
        final bytes = res.bodyBytes;
        if (res.statusCode == 200 && bytes.length >= _minBytes && _looksLikeMp3(bytes)) {
          final tmp = File('${d.path}/$name.part');
          tmp.writeAsBytesSync(bytes, flush: true);
          final out = tmp.renameSync('${d.path}/$name.mp3');
          return out.path;
        }
        debugPrint('adhkar audio $name: HTTP ${res.statusCode}, ${bytes.length} bytes');
      } catch (e) {
        debugPrint('adhkar audio $name, attempt $attempt: $e');
      }
      if (attempt < _attempts) await Future<void>.delayed(retryDelay);
    }
    return null;
  }

  static bool _looksLikeMp3(Uint8List b) =>
      (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) || // "ID3"
      (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0); // MPEG frame sync
}
