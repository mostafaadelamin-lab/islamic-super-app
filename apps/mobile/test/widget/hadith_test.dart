import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/hadith.dart';
import 'package:rattil/domain/hadith.dart';
import 'package:rattil/ui/hadith_screen.dart';

import '../helpers.dart';

List<String> _part(String book, int k) => [
  for (final t in (readAppJson('assets/hadith/$book/$k.json')['ahadith'] as List<dynamic>)) t as String,
];

void main() {
  late AppContent content;
  late HadithCatalog catalog;
  late HadithLibrary library;
  setUpAll(() async {
    content = await loadContent();
    catalog = content.hadith;
    library = testHadith(content);
  });

  group('hadith books (Open-Hadith-Data)', () {
    test('nine books, pinned source, pending review, same files as content/hadith/dist', () {
      expect(catalog.books.map((b) => b.id), [
        'bukhari',
        'muslim',
        'abudawud',
        'tirmidhi',
        'nasai',
        'ibnmajah',
        'malik',
        'ahmad',
        'darimi',
      ]);
      expect(catalog.book('bukhari')!.count, 7008);
      expect(catalog.reviewStatus, 'pending');
      expect(catalog.licence, contains('ODbL'));
      expect(readAppJson('assets/hadith/books.v1.json'), readRepoJson('content/hadith/dist/books.v1.json'));
    });

    test('bundled texts are exactly the source (sha-256 per book)', () {
      for (final b in catalog.books) {
        final texts = [for (var k = 0; k < b.chunks; k++) ..._part(b.id, k)];
        expect(texts, hasLength(b.count), reason: b.id);
        expect(sha256.convert(utf8.encode(texts.join('\n'))).toString(), b.textSha256, reason: b.id);
      }
    });

    test('ranges across parts, clamped to the book', () async {
      final malik = catalog.book('malik')!;
      final r = await library.range(malik, 498, 503);
      expect(r.map((h) => h.n), [498, 499, 500, 501, 502, 503]);
      expect(r[3].text, _part('malik', 1).first);
      expect(await library.range(malik, malik.count + 1, malik.count + 9), isEmpty);
      expect((await library.range(malik, malik.count, malik.count + 9)).single.n, malik.count);
      expect(hadithPageStart(1), 1);
      expect(hadithPageStart(20), 1);
      expect(hadithPageStart(21), 21);
    });

    test('search ignores diacritics and stops at the limit', () async {
      final bukhari = catalog.book('bukhari')!;
      final done = <int>[];
      final hits = await library.search(
        bukhari,
        'انما الاعمال بالنيات',
        content.normalizer,
        onProgress: (d, _) => done.add(d),
      );
      expect(hits.first.n, 1);
      expect(done.last, bukhari.chunks);
      expect(await library.search(bukhari, '  ', content.normalizer), isEmpty);
      expect(await library.search(catalog.book('malik')!, 'الله', content.normalizer), hasLength(hadithSearchLimit));
    });

    test('saved keys must name a book and a number inside it', () {
      expect(catalog.parseKey('bukhari:7008')?.$2, 7008);
      expect(catalog.parseKey('bukhari:7009'), isNull);
      expect(catalog.parseKey('bukhari:0'), isNull);
      expect(catalog.parseKey('nope:1'), isNull);
      expect(catalog.parseKey('bukhari'), isNull);
    });
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('hadith: open a book, page, jump, save and see it saved ($locale)', (tester) async {
      final app = await pumpApp(tester, locale: locale, size: tallPhone);
      await pushScreen(tester, const HadithScreen());
      expect(find.byKey(const Key('hadithAttribution')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hadithBook-malik')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hadith-1')), findsOneWidget);
      final first = _part('malik', 0).first.trim();
      expect(find.text(first), findsOneWidget);

      await tester.tap(find.byKey(const Key('hadithNext')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hadith-2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('hadithTools')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hadithGo')), locale == 'ar' ? '١٥٩٤' : '1594');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hadith-1594')), findsOneWidget);

      await tester.tap(find.byKey(const Key('hadithFav-1594')));
      await tester.pumpAndSettle();
      expect(app.services.settings.hadithFavourites, ['malik:1594']);

      await goBack(tester);
      await tester.tap(find.byKey(const Key('hadithFavourites')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hadith-1594')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hadithFav-1594')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hadithFavEmpty')), findsOneWidget);
    });
  }

  testWidgets('hadith search shows the results and goes back to the book', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, HadithBookScreen(book: catalog.book('bukhari')!));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hadithTools')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hadithQuery')), 'إنما الأعمال بالنيات');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hadithResults')), findsOneWidget);
    expect(find.byKey(const Key('hadith-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hadith1Share')));
    await tester.tap(find.byKey(const Key('hadithClear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hadithRange')), findsOneWidget);
  });

  testWidgets('More opens the hadith books', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 4);
    await tester.tap(find.byKey(const Key('more.hadith')));
    await tester.pumpAndSettle();
    expect(find.byType(HadithScreen), findsOneWidget);
  });

  test('a part that fails to read is retried', () async {
    var fail = true;
    final lib = HadithLibrary(catalog, (key) async {
      if (fail) throw const FileSystemException('x');
      return File(key).readAsStringSync();
    }, isolate: false);
    await expectLater(lib.part('malik', 0), throwsA(isA<FileSystemException>()));
    fail = false;
    expect(await lib.part('malik', 0), hasLength(500));
  });
}
