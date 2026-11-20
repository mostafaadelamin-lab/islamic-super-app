import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../domain/quran.dart';

/// "شكل المصحف المطبوع" (owner, 2026-11-20): each page drawn with the King Fahd
/// Complex's own font for that page (QCF v2), line by line like the printed Madinah
/// Mushaf. The layout (assets/content/mushaf-printed.v1.json, tools/mushaf_printed_build.py)
/// holds only the fonts' drawing codes with the ayah of every word; the Quran text is
/// not stored there and is never changed. Fonts are fetched once per page and kept.
sealed class PrintedLine {
  const PrintedLine();
}

/// "سورة …" title band.
class PrintedBand extends PrintedLine {
  const PrintedBand(this.surah);
  final int surah;
}

class PrintedBasmala extends PrintedLine {
  const PrintedBasmala(this.surah);
  final int surah;
}

class PrintedWord {
  const PrintedWord(this.ref, this.glyph, this.isEnd);
  final AyahRef ref;
  final String glyph;

  /// The ayah-end ornament with its number (drawn by the page font).
  final bool isEnd;
}

class PrintedText extends PrintedLine {
  const PrintedText(this.words);
  final List<PrintedWord> words;
}

class PrintedLayout {
  PrintedLayout(this._pages, this.fontUrl);
  final List<List<PrintedLine>> _pages;
  final String fontUrl;

  List<PrintedLine> page(int n) => _pages[n - 1];

  static PrintedLayout parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return PrintedLayout([
      for (final p in j['pages'] as List)
        [
          for (final l in p as List)
            if ((l as List).first == 'S')
              PrintedBand(l[1] as int)
            else if (l.first == 'B')
              PrintedBasmala(l[1] as int)
            else
              PrintedText([
                for (final w in l) PrintedWord(AyahRef((w as List)[0] as int, w[1] as int), w[2] as String, w[3] == 1),
              ]),
        ],
    ], j['fontUrl'] as String);
  }
}

/// Loads the layout once and the page fonts on demand (cached on the device).
class PrintedMushaf extends ChangeNotifier {
  PrintedMushaf._();
  static final instance = PrintedMushaf._();

  static const asset = 'assets/content/mushaf-printed.v1.json';
  static const pages = 604;

  http.Client? _client;
  Future<Directory> Function()? _root;

  /// Called once at start-up with the app's storage folder and HTTP client.
  void configure({required http.Client client, required Future<Directory> Function() root}) {
    _client = client;
    _root = root;
  }

  PrintedLayout? layout;
  Future<PrintedLayout?>? _loading;
  final Set<int> _loaded = {};
  final Map<int, Future<bool>> _pending = {};

  /// Pages downloaded so far during "download all" (null when not running).
  int? bulkDone;
  bool bulkFailed = false;

  static String family(int page) => 'QCF2P$page';

  bool isReady(int page) => layout != null && _loaded.contains(page);

  Future<PrintedLayout?> loadLayout([AssetBundle? bundle]) => _loading ??= () async {
    try {
      layout = PrintedLayout.parse(await (bundle ?? rootBundle).loadString(asset));
      notifyListeners();
    } catch (e) {
      debugPrint('printed mushaf layout: $e');
    }
    return layout;
  }();

  Future<File?> _file(int page) async {
    final r = _root;
    if (r == null) return null;
    return File('${(await r()).path}/qcf2/p$page.ttf');
  }

  /// Whether the font of [page] is saved on the device.
  Future<bool> isSaved(int page) async {
    final f = await _file(page);
    return f != null && f.existsSync() && f.lengthSync() > 0;
  }

  /// Makes the font of [page] (and the layout) ready; true when the page can be drawn.
  Future<bool> ensure(int page) {
    if (isReady(page)) return Future.value(true);
    return _pending[page] ??= _ensure(page).whenComplete(() => _pending.remove(page));
  }

  Future<bool> _ensure(int page) async {
    final l = await loadLayout();
    if (l == null) return false;
    try {
      final f = await _file(page);
      Uint8List? bytes;
      if (f != null && f.existsSync() && f.lengthSync() > 0) {
        bytes = await f.readAsBytes();
      } else {
        bytes = await _download(l, page, f);
      }
      if (bytes == null) return false;
      final loader = FontLoader(family(page))..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      _loaded.add(page);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('printed mushaf font p$page: $e');
      return false;
    }
  }

  Future<Uint8List?> _download(PrintedLayout l, int page, File? f) async {
    final c = _client;
    if (c == null) return null;
    final res = await c.get(Uri.parse(l.fontUrl.replaceAll('{page}', '$page')));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    if (f != null) {
      await f.parent.create(recursive: true);
      final part = File('${f.path}.part');
      await part.writeAsBytes(res.bodyBytes, flush: true);
      await part.rename(f.path);
    }
    return res.bodyBytes;
  }

  /// How many page fonts are saved on the device.
  Future<int> savedCount() async {
    var n = 0;
    for (var p = 1; p <= pages; p++) {
      if (await isSaved(p)) n++;
    }
    return n;
  }

  /// Saves the fonts of all pages for reading without internet.
  Future<void> downloadAll() async {
    if (bulkDone != null) return;
    final l = await loadLayout();
    if (l == null) return;
    bulkFailed = false;
    bulkDone = 0;
    notifyListeners();
    try {
      for (var p = 1; p <= pages; p++) {
        final f = await _file(p);
        if (!(f != null && f.existsSync() && f.lengthSync() > 0)) {
          final b = await _download(l, p, f);
          if (b == null) throw const HttpException('font');
        }
        bulkDone = p;
        if (p % 4 == 0) notifyListeners();
      }
    } catch (_) {
      bulkFailed = true;
    } finally {
      bulkDone = null;
      notifyListeners();
    }
  }

  @visibleForTesting
  void debugMarkReady(PrintedLayout l, Iterable<int> pages) {
    layout = l;
    _loading = Future.value(l);
    _loaded.addAll(pages);
  }
}
