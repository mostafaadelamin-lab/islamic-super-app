// Preview pictures of the tafsir books and ayah studies (owner 2026-11-20).
// Output: $RATTIL_SCREENSHOT_DIR/tafsir-books, or build/screenshots/tafsir-books.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/tafsir_books.dart';
import 'package:rattil/domain/tafsir_books.dart';
import 'package:rattil/ui/ayah_study.dart';
import 'package:rattil/ui/more_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

Map<String, dynamic> _gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync()))) as Map<String, dynamic>;

void main() {
  final books = <String, Map<String, dynamic>>{};
  late Map<String, dynamic> irab;
  setUpAll(() async {
    await loadContent();
    irab = _gz('../../content/irab/dist/jadwal.v1.json.gz');
  });
  setUp(() {
    TafsirBooks.instance.resetForTests();
    studyChoice.value = (TafsirBookId.muyassar, StudyTab.tafsir);
  });
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/tafsir-books');

  http.Client site() => MockClient((req) async {
    final t = RegExp(r'/data/tafsir/([a-z-]+)/(\d+)\.json$').firstMatch(req.url.path);
    if (t != null) {
      final book = books[t[1]!] ??= _gz('../../content/tafsir/dist/${t[1]}.v1.json.gz');
      return http.Response.bytes(utf8.encode(jsonEncode((book['surahs'] as List)[int.parse(t[2]!) - 1])), 200);
    }
    final i = RegExp(r'/data/irab/jadwal/(\d+)\.json$').firstMatch(req.url.path);
    if (i != null) {
      return http.Response.bytes(utf8.encode(jsonEncode((irab['surahs'] as List)[int.parse(i[1]!) - 1])), 200);
    }
    return http.Response('', 404);
  });

  Future<void> shot(WidgetTester tester, String name) async {
    final view = tester.binding.renderViews.first;
    void repaint(RenderObject o) {
      o.markNeedsPaint();
      o.visitChildren(repaint);
    }

    debugDisableShadows = false;
    repaint(view);
    await tester.pump();
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(Offset.zero & view.size, pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    debugDisableShadows = true;
    repaint(view);
    await tester.pump();
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  const size = Size(440, 956);
  const prefs = {'theme': 'light', 'reader.hintShown': 9};

  testWidgets('preview: ayah tabs (al-Muyassar, al-Sa\'di, i\'rab, balagha)', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend(), httpClient: site());
    await pushScreen(tester, const PageReaderScreen(initialPage: 42));
    await tester.tap(find.byKey(const Key('pageAyah-2-255')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahTafsir')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-1-ayah-muyassar');
    await tapKey(tester, 'tafsirBook.saadi');
    await shot(tester, 'app-2-ayah-saadi');
    await tapKey(tester, 'studyTab.irab');
    await shot(tester, 'app-3-ayah-irab');
    await tapKey(tester, 'studyTab.balagha');
    await shot(tester, 'app-4-ayah-balagha');
  });

  testWidgets('preview: «التفسير» in More, compare, search', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend(), httpClient: site());
    await pushScreen(tester, const MoreScreen());
    await tapKey(tester, 'more.tafsir');
    await shot(tester, 'app-5-library');
    await tapKey(tester, 'tafsirLib.compare');
    await shot(tester, 'app-6-compare');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tapKey(tester, 'tafsirLib.search');
    await tester.enterText(find.byKey(const Key('tafsirSearchField')), 'المربي');
    await tester.tap(find.byKey(const Key('tafsirSearchGo')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-7-search');
  });
}
