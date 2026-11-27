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

  Future<String?> _base(int page) async {
    final r = _root;
    if (r == null) return null;
    return '${(await r()).path}/qcf2/p$page';
  }

  /// Older builds kept the plain font (`p<page>.ttf`); new saves are gzipped (`p<page>.ttf.gz`, about a third
  /// smaller). Either one counts as saved, so a font that is on the device is never downloaded again.
  static bool _has(File f) => f.existsSync() && f.lengthSync() > 0;

  Future<Uint8List?> _readSaved(int page) async {
    final b = await _base(page);
    if (b == null) return null;
    final plain = File('$b.ttf');
    if (_has(plain)) return plain.readAsBytes();
    final gz = File('$b.ttf.gz');
    if (_has(gz)) {
      try {
        return Uint8List.fromList(gzip.decode(await gz.readAsBytes()));
      } catch (_) {
        await gz.delete().catchError((_) => gz); // broken save: fetch it again
      }
    }
    return null;
  }

  /// Whether the font of [page] is saved on the device.
  Future<bool> isSaved(int page) async {
    final b = await _base(page);
    return b != null && (_has(File('$b.ttf')) || _has(File('$b.ttf.gz')));
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
      final bytes = await _readSaved(page) ?? await _download(l, page);
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

  Future<Uint8List?> _download(PrintedLayout l, int page) async {
    final c = _client;
    if (c == null) return null;
    final res = await c.get(Uri.parse(l.fontUrl.replaceAll('{page}', '$page')));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    final b = await _base(page);
    if (b != null) {
      final f = File('$b.ttf.gz');
      await f.parent.create(recursive: true);
      final part = File('${f.path}.part');
      await part.writeAsBytes(gzip.encode(res.bodyBytes), flush: true);
      await part.rename(f.path);
      if (savedPages != null && savedPages! < pages) savedPages = savedPages! + 1;
    }
    return res.bodyBytes;
  }

  /// Pages whose font is on the device (null until [savedCount] has looked once).
  int? savedPages;

  /// Whether every page font is on the device (known after [savedCount]).
  bool get allSaved => savedPages == pages;

  /// How many page fonts are saved on the device (looked up once, then kept up to date).
  Future<int> savedCount({bool refresh = false}) async {
    if (savedPages != null && !refresh) return savedPages!;
    var n = 0;
    for (var p = 1; p <= pages; p++) {
      if (await isSaved(p)) n++;
    }
    savedPages = n;
    notifyListeners();
    return n;
  }

  /// How many pages the running download covers (with [bulkDone]).
  int bulkTotal = pages;

  /// Saves the fonts of all pages for reading without internet, once.
  Future<void> downloadAll() => downloadPages([for (var p = 1; p <= pages; p++) p]);

  /// Whether every page in [list] is saved.
  Future<bool> allSavedIn(Iterable<int> list) async {
    for (final p in list) {
      if (!await isSaved(p)) return false;
    }
    return true;
  }

  /// Saves the fonts of [list] (a surah, or the whole Mushaf): pages already saved are skipped, so tapping again
  /// after a cut connection carries on where it stopped. Four pages at a time.
  Future<void> downloadPages(List<int> list) async {
    if (bulkDone != null) return;
    final l = await loadLayout();
    if (l == null) return;
    bulkFailed = false;
    bulkDone = 0;
    bulkTotal = list.length;
    notifyListeners();
    var next = 0;
    var failed = false;
    Future<void> worker() async {
      while (!failed && next < list.length) {
        final p = list[next++];
        if (!await isSaved(p)) {
          Uint8List? b;
          try {
            b = await _download(l, p);
          } catch (_) {}
          if (b == null) {
            failed = true;
            return;
          }
        }
        bulkDone = bulkDone! + 1;
        if (bulkDone! % 4 == 0) notifyListeners();
      }
    }

    try {
      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    } finally {
      bulkFailed = failed;
      bulkDone = null;
      await savedCount(refresh: true);
    }
  }

  @visibleForTesting
  void debugSetProgress({int? saved, int? done, int total = pages, bool failed = false}) {
    savedPages = saved;
    bulkTotal = total;
    bulkDone = done;
    bulkFailed = failed;
    notifyListeners();
  }

  @visibleForTesting
  void debugMarkReady(PrintedLayout l, Iterable<int> pages) {
    layout = l;
    _loading = Future.value(l);
    _loaded.addAll(pages);
  }
}
