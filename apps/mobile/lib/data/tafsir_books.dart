import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/tafsir_books.dart';

/// The tafsir books other than al-Muyassar (which is in the app), and «الجدول» (i'rab, sarf, balagha,
/// fawa'id), fetched from the website one surah at a time and kept on the device. A whole book can be
/// downloaded at once from «التفسير» in More, for reading without the internet and for search.
///
/// On the device: `<support>`/tafsir/`<book>`/`<n>`.json (one file per surah, exactly as on the website) and
/// `<support>`/tafsir/`<book>`/complete once every surah is saved.
class TafsirBooks extends ChangeNotifier {
  TafsirBooks._();
  static final instance = TafsirBooks._();

  static const base = 'https://rattilwasalli.com/data';

  /// The «الجدول» files share the store; its folder name.
  static const irabId = 'irab-jadwal';

  http.Client? _client;
  Future<Directory> Function()? _root;
  List<int> _ayahCounts = const [];

  /// Called once at start-up with the app's HTTP client, storage folder and each surah's ayah count.
  void configure({
    required http.Client client,
    required Future<Directory> Function() root,
    required List<int> ayahCounts,
  }) {
    _client = client;
    _root = root;
    _ayahCounts = ayahCounts;
  }

  final Map<String, Future<List<BookSection>>> _books = {};
  final Map<int, Future<List<IrabSection>>> _irab = {};

  /// Book id -> surahs saved so far while a whole-book download runs.
  final Map<String, int> progress = {};
  final Set<String> failed = {};

  String _remote(String id, int surah) =>
      id == irabId ? '$base/irab/jadwal/$surah.json' : '$base/tafsir/$id/$surah.json';

  Future<Directory?> _dir(String id) async {
    final r = _root;
    if (r == null) return null;
    return Directory('${(await r()).path}/tafsir/$id');
  }

  /// The surah file: from the device if saved, else from the website (then saved).
  Future<String> _surahJson(String id, int surah, {bool waitForDisk = false}) async {
    final dir = await _dir(id);
    final f = dir == null ? null : File('${dir.path}/$surah.json');
    if (f != null && f.existsSync() && f.lengthSync() > 0) return f.readAsString();
    final client = _client;
    if (client == null) throw StateError('tafsir books not configured');
    final res = await client.get(Uri.parse(_remote(id, surah))).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw HttpException('${res.statusCode}', uri: Uri.parse(_remote(id, surah)));
    final body = utf8.decode(res.bodyBytes);
    if (f != null) {
      // The reader does not wait for the disk; a whole-book download does (it then marks the book complete).
      final saving = _save(f, body);
      if (waitForDisk) {
        await saving;
      } else {
        unawaited(saving);
      }
    }
    return body;
  }

  static Future<void> _save(File f, String body) async {
    try {
      await f.parent.create(recursive: true);
      final tmp = File('${f.path}.part');
      await tmp.writeAsString(body, flush: true);
      await tmp.rename(f.path);
    } catch (e) {
      debugPrint('tafsir save: $e');
    }
  }

  int _count(int surah) => _ayahCounts[surah - 1];

  /// One surah of a book (not al-Muyassar).
  Future<List<BookSection>> surah(TafsirBookId book, int surah) {
    final key = '${book.id}/$surah';
    return _books[key] ??= () async {
      try {
        final json = await _surahJson(book.id, surah);
        return parseBookSurah(json, _ayahCounts.isEmpty ? _lastTo(json) : _count(surah));
      } catch (e) {
        unawaited(_books.remove(key));
        rethrow;
      }
    }();
  }

  /// One surah of «الجدول».
  Future<List<IrabSection>> irabSurah(int surah) {
    return _irab[surah] ??= () async {
      try {
        final json = await _surahJson(irabId, surah);
        return parseIrabSurah(json, _ayahCounts.isEmpty ? _lastTo(json) : _count(surah));
      } catch (e) {
        unawaited(_irab.remove(surah));
        rethrow;
      }
    }();
  }

  /// Tests without the Quran's ayah counts: the last section's end.
  static int _lastTo(String json) => ((jsonDecode(json) as List<dynamic>).last as List<dynamic>)[1] as int;

  /// Whether every surah of [id] is saved on the device.
  Future<bool> isSaved(String id) async {
    final dir = await _dir(id);
    return dir != null && File('${dir.path}/complete').existsSync();
  }

  /// Downloads every surah of [id] (book id or [irabId]), skipping saved ones. Progress in [progress].
  Future<bool> download(String id) async {
    if (progress.containsKey(id)) return false;
    final dir = await _dir(id);
    if (dir == null) return false;
    failed.remove(id);
    progress[id] = 0;
    notifyListeners();
    try {
      for (var s = 1; s <= 114; s++) {
        await _surahJson(id, s, waitForDisk: true);
        progress[id] = s;
        notifyListeners();
      }
      await File('${dir.path}/complete').writeAsString('1');
      return true;
    } catch (e) {
      debugPrint('tafsir download $id: $e');
      failed.add(id);
      return false;
    } finally {
      progress.remove(id);
      notifyListeners();
    }
  }

  /// Removes a downloaded book from the device.
  Future<void> remove(String id) async {
    final dir = await _dir(id);
    if (dir != null && dir.existsSync()) await dir.delete(recursive: true);
    _books.removeWhere((k, _) => k.startsWith('$id/'));
    if (id == irabId) _irab.clear();
    notifyListeners();
  }

  /// Every surah of a saved book (for search), read off the UI thread.
  Future<List<List<BookSection>>> wholeBook(TafsirBookId book) async {
    final dir = await _dir(book.id);
    if (dir == null) throw StateError('no storage');
    return compute(_readAll, (dir.path, _ayahCounts));
  }

  static List<List<BookSection>> _readAll((String, List<int>) a) {
    final (path, counts) = a;
    return [
      for (var s = 1; s <= 114; s++)
        () {
          final json = File('$path/$s.json').readAsStringSync();
          return parseBookSurah(json, counts.isEmpty ? _lastTo(json) : counts[s - 1]);
        }(),
    ];
  }

  @visibleForTesting
  void resetForTests() {
    _books.clear();
    _irab.clear();
    progress.clear();
    failed.clear();
  }
}
