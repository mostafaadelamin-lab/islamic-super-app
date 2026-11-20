import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/tafsir_books.dart';
import 'package:rattil/domain/tafsir_books.dart';
import 'package:rattil/ui/ayah_study.dart';
import 'package:rattil/ui/more_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

// Owner 2026-11-20: tap an ayah -> al-Muyassar by default, or al-Sa'di, Ibn Kathir, al-Tabari, al-Baghawi,
// al-Qurtubi; and the gharib, i'rab, sarf, balagha and fawa'id of the ayah. «التفسير» in More: every book,
// compare, search. Texts verbatim from content/tafsir/dist and content/irab/dist.
Map<String, dynamic> _gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync()))) as Map<String, dynamic>;

void main() {
  late Map<String, dynamic> saadi;
  late Map<String, dynamic> irab;
  final requests = <String>[];

  setUpAll(() async {
    await loadContent();
    saadi = _gz('../../content/tafsir/dist/saadi.v1.json.gz');
    irab = _gz('../../content/irab/dist/jadwal.v1.json.gz');
  });

  setUp(() {
    requests.clear();
    TafsirBooks.instance.resetForTests();
    studyChoice.value = (TafsirBookId.muyassar, StudyTab.tafsir);
  });

  /// Serves the website's per-surah files from the repository's books.
  http.Client site() => MockClient((req) async {
    requests.add(req.url.path);
    final t = RegExp(r'/data/tafsir/saadi/(\d+)\.json$').firstMatch(req.url.path);
    if (t != null) {
      return http.Response.bytes(utf8.encode(jsonEncode((saadi['surahs'] as List)[int.parse(t[1]!) - 1])), 200);
    }
    final i = RegExp(r'/data/irab/jadwal/(\d+)\.json$').firstMatch(req.url.path);
    if (i != null) {
      return http.Response.bytes(utf8.encode(jsonEncode((irab['surahs'] as List)[int.parse(i[1]!) - 1])), 200);
    }
    return http.Response('', 404);
  });

  List<dynamic> sectionOf(Map<String, dynamic> book, int s, int a) => ((book['surahs'] as List)[s - 1] as List)
      .cast<List<dynamic>>()
      .firstWhere((x) => (x[0] as int) <= a && a <= (x[1] as int));

  test('the books cover every ayah; search ignores tashkeel and keeps the text verbatim', () {
    expect(saadi['schema'], 'tafsir-book.v1');
    expect((saadi['surahs'] as List), hasLength(114));
    final surahs = [
      for (var s = 1; s <= 114; s++)
        parseBookSurah(jsonEncode((saadi['surahs'] as List)[s - 1]), testTafsir.surahs[s - 1].length),
    ];
    expect(sectionFor(surahs[1], 255, (x) => (x.from, x.to)).text, sectionOf(saadi, 2, 255)[2]);
    expect(normalizeArabic('ٱلْحَمْدُ'), 'الحمد');
    final hits = searchSections(surahs, 'المربي');
    expect(hits, isNotEmpty);
    expect(hits.first.match, 'المربي');
    expect(() => parseBookSurah('[[1,2,"x"]]', 3), throwsFormatException);
  });

  testWidgets('ayah menu: al-Muyassar first, then al-Sa\'di and the i\'rab parts, verbatim', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), httpClient: site());
    await pushScreen(tester, const PageReaderScreen(initialPage: 42));
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahTafsir')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('tafsirTitle'))).data, 'التفسير الميسر');
    expect(requests, isEmpty, reason: 'al-Muyassar is in the app');

    await tester.ensureVisible(find.byKey(const Key('tafsirBook.saadi')));
    await tester.tap(find.byKey(const Key('tafsirBook.saadi')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('tafsirTitle'))).data, 'تفسير السعدي');
    final text = tester.widget<Text>(find.byKey(const Key('tafsirText')));
    expect(text.textSpan!.toPlainText(), sectionOf(saadi, 2, 255)[2]);
    expect(requests, ['/data/tafsir/saadi/2.json']);

    await tester.ensureVisible(find.byKey(const Key('studyTab.irab')));
    await tester.tap(find.byKey(const Key('studyTab.irab')));
    await tester.pumpAndSettle();
    final sec = sectionOf(irab, 2, 255);
    expect(tester.widget<Text>(find.byKey(const Key('tafsirText'))).textSpan!.toPlainText(), sec[2]);
    await tester.ensureVisible(find.byKey(const Key('studyTab.balagha')));
    await tester.tap(find.byKey(const Key('studyTab.balagha')));
    await tester.pumpAndSettle();
    if ((sec[4] as String).isEmpty) {
      expect(find.byKey(const Key('studyEmpty')), findsOneWidget);
    } else {
      expect(tester.widget<Text>(find.byKey(const Key('tafsirText'))).textSpan!.toPlainText(), sec[4]);
    }
    await tester.ensureVisible(find.byKey(const Key('studyTab.gharib')));
    await tester.tap(find.byKey(const Key('studyTab.gharib')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('studyWords')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('More > «التفسير»: the books, compare and search', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), httpClient: site());
    await pushScreen(tester, const MoreScreen());
    await tester.tap(find.byKey(const Key('more.tafsir')));
    await tester.pumpAndSettle();
    for (final b in TafsirBookId.values) {
      expect(find.byKey(Key('tafsirLib.book.${b.id}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('tafsirLib.compare')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('compare.muyassar')), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tafsirLib.search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tafsirSearchField')), 'المربي');
    await tester.tap(find.byKey(const Key('tafsirSearchGo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchHits')), findsOneWidget);
    expect(find.byKey(const Key('hit-1-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
