import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  String items(List<List<Object>> l) => jsonEncode([
    for (final i in l)
      {'id': 'b-${i[0]}-${i[1]}', 'surah': i[0], 'ayah': i[1], 'updatedAt': i[2], 'deleted': i.length > 3},
  ]);

  testWidgets('empty state', (tester) async {
    await pumpApp(tester);
    await goToTab(tester, 3);
    expect(find.byKey(const Key('bookmarksEmpty')), findsOneWidget);
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);
  });

  testWidgets('lists live bookmarks newest first; tombstones hidden', (tester) async {
    await pumpApp(
      tester,
      prefs: {
        'bookmarks.v1': items([
          [1, 1, 10],
          [2, 255, 30],
          [36, 1, 20],
          [3, 3, 40, true],
        ]),
      },
    );
    await goToTab(tester, 3);
    final tiles = tester.widgetList<ListTile>(
      find.descendant(of: find.byKey(const Key('bookmarkList')), matching: find.byType(ListTile)),
    );
    final keys = tiles.map((t) => t.key).whereType<ValueKey<String>>().map((k) => k.value).toList();
    expect(keys, ['bm-b-2-255', 'bm-b-36-1', 'bm-b-1-1']);
    expect(find.byKey(const Key('bm-b-3-3')), findsNothing);
    expect(find.text('البقرة : ٢٥٥'), findsOneWidget);
  });

  testWidgets('delete button removes the bookmark (kept as a tombstone for sync)', (tester) async {
    final app = await pumpApp(
      tester,
      prefs: {
        'bookmarks.v1': items([
          [1, 1, 10],
        ]),
      },
    );
    await goToTab(tester, 3);
    expect(find.byTooltip('حذف علامة الفاتحة : ١'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bmDelete-b-1-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bm-b-1-1')), findsNothing);
    expect(find.byKey(const Key('bookmarksEmpty')), findsOneWidget);
    expect(app.services.bookmarks.all['b-1-1']!.deleted, isTrue);
    expect(app.services.bookmarks.dirty, contains('b-1-1'));
  });

  testWidgets('tapping a bookmark opens the reader at that ayah', (tester) async {
    await pumpApp(
      tester,
      prefs: {
        'bookmarks.v1': items([
          [18, 10, 10],
        ]),
      },
    );
    await goToTab(tester, 3);
    await tester.tap(find.byKey(const Key('bm-b-18-10')));
    await tester.pumpAndSettle();
    final r = tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen));
    expect((r.surah, r.initialAyah), (18, 10));
  });

  testWidgets('bookmark added in the reader appears in the list', (tester) async {
    await pumpApp(tester);
    await goToTab(tester, 1);
    await tester.tap(find.byKey(const Key('surah-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bookmark-1-5')));
    await tester.pumpAndSettle();
    await goBack(tester);
    await goToTab(tester, 3);
    expect(find.byKey(const Key('bm-b-1-5')), findsOneWidget);
  });

  testWidgets('continue-reading tile is on the bookmarks screen', (tester) async {
    await pumpApp(tester, prefs: {'lastRead.surah': 36, 'lastRead.ayah': 5});
    await goToTab(tester, 3);
    await tester.tap(find.text('متابعة القراءة'));
    await tester.pumpAndSettle();
    final r = tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen));
    expect((r.surah, r.initialAyah), (36, 5));
  });
}
