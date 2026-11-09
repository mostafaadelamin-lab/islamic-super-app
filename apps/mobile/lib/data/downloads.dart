import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/quran.dart';
import 'content.dart';

/// Recitations saved on the device for listening without internet: one MP3 per
/// ayah (the same everyayah.com files the player streams), stored under
/// `<root>/recitations/<reciter>/<SSSAAA>.mp3`. A surah counts as downloaded
/// once its `<SSS>.done` marker is written after the last file.
class RecitationDownloads extends ChangeNotifier {
  RecitationDownloads({required this.content, required this.httpClient, required this.root});

  final AppContent content;
  final http.Client httpClient;

  /// The app's private storage folder (path_provider in the app, a temp dir in tests).
  final Future<Directory> Function() root;

  /// Surahs being downloaded now: "reciter/surah" → fraction done (0..1).
  final Map<String, double> progress = {};
  final Set<String> _cancelled = {};

  static String _sss(int n) => n.toString().padLeft(3, '0');
  static String _key(String reciter, int surah) => '$reciter/$surah';

  Future<Directory> _dir(String reciter) async => Directory('${(await root()).path}/recitations/$reciter');

  /// Local file of [ref] for [reciter] when the surah it is played in
  /// ([forSurah], default its own: the basmala file 1:1 is played before other
  /// surahs) is fully downloaded, else null.
  Future<String?> localFile(String reciter, AyahRef ref, {int? forSurah}) async {
    final d = await _dir(reciter);
    if (!File('${d.path}/${_sss(forSurah ?? ref.surah)}.done').existsSync()) return null;
    final f = File('${d.path}/${_sss(ref.surah)}${_sss(ref.ayah)}.mp3');
    return f.existsSync() ? f.path : null;
  }

  Future<bool> isDownloaded(String reciter, int surah) async =>
      File('${(await _dir(reciter)).path}/${_sss(surah)}.done').existsSync();

  bool isDownloading(String reciter, int surah) => progress.containsKey(_key(reciter, surah));

  /// Downloads every ayah of [surah] (and the opening basmala file) for
  /// [reciter]. Throws on a network error; files already saved are kept so a
  /// retry continues where it stopped.
  Future<void> downloadSurah(String reciter, int surah) async {
    final key = _key(reciter, surah);
    if (progress.containsKey(key)) return;
    _cancelled.remove(key);
    final d = await _dir(reciter);
    await d.create(recursive: true);
    final n = content.quran.surah(surah).ayahCount;
    final refs = [if (surah != 1) const AyahRef(1, 1), for (var a = 1; a <= n; a++) AyahRef(surah, a)];
    progress[key] = 0;
    notifyListeners();
    try {
      for (var i = 0; i < refs.length; i++) {
        if (_cancelled.contains(key)) return;
        final r = refs[i];
        final f = File('${d.path}/${_sss(r.surah)}${_sss(r.ayah)}.mp3');
        if (!f.existsSync() || f.lengthSync() == 0) {
          final res = await httpClient.get(Uri.parse(content.reciters.url(reciter, r)));
          if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
            throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(content.reciters.url(reciter, r)));
          }
          await f.writeAsBytes(res.bodyBytes, flush: true);
        }
        progress[key] = (i + 1) / refs.length;
        notifyListeners();
      }
      await File('${d.path}/${_sss(surah)}.done').writeAsString('ok');
    } finally {
      progress.remove(key);
      notifyListeners();
    }
  }

  void cancel(String reciter, int surah) => _cancelled.add(_key(reciter, surah));

  /// Removes [surah]'s files (the shared basmala file 001001 stays while
  /// al-Fatiha or another surah still uses it).
  Future<void> deleteSurah(String reciter, int surah) async {
    final d = await _dir(reciter);
    if (!d.existsSync()) return;
    final prefix = _sss(surah);
    final files = d.listSync().whereType<File>().toList();
    final othersNeedBasmala = files.any((f) => f.path.endsWith('.done') && !f.uri.pathSegments.last.startsWith(prefix));
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      if (name == '001001.mp3' && othersNeedBasmala) continue;
      if (name.startsWith(prefix)) f.deleteSync();
    }
    notifyListeners();
  }

  /// Downloaded surahs per reciter, with the bytes they use.
  Future<List<({String reciter, int surah, int bytes})>> list() async {
    final base = Directory('${(await root()).path}/recitations');
    if (!base.existsSync()) return const [];
    final out = <({String reciter, int surah, int bytes})>[];
    for (final r in base.listSync().whereType<Directory>()) {
      final files = r.listSync().whereType<File>().toList();
      for (final done in files.where((f) => f.path.endsWith('.done'))) {
        final sss = done.uri.pathSegments.last.substring(0, 3);
        final bytes = files
            .where((f) => f.uri.pathSegments.last.startsWith(sss) && f.path.endsWith('.mp3'))
            .fold(0, (a, f) => a + f.lengthSync());
        out.add((reciter: r.uri.pathSegments.where((s) => s.isNotEmpty).last, surah: int.parse(sss), bytes: bytes));
      }
    }
    out.sort((a, b) => a.reciter == b.reciter ? a.surah.compareTo(b.surah) : a.reciter.compareTo(b.reciter));
    return out;
  }

  /// Everything saved, in bytes.
  Future<int> totalBytes() async {
    final base = Directory('${(await root()).path}/recitations');
    if (!base.existsSync()) return 0;
    return base.listSync(recursive: true).whereType<File>().fold<int>(0, (a, f) => a + f.lengthSync());
  }

  Future<void> deleteAll() async {
    final base = Directory('${(await root()).path}/recitations');
    if (base.existsSync()) await base.delete(recursive: true);
    notifyListeners();
  }
}
