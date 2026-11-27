import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/ui/video_search_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  const page =
      'var ytInitialData = {"contents":[{"videoRenderer":{"videoId":"abcdefghijk","thumbnail":{},'
      '"title":{"runs":[{"text":"تلاوة سورة الكهف"}]},"ownerText":{"runs":[{"text":"قناة",'
      '"navigationEndpoint":{"browseEndpoint":{"browseId":"UCaaaaaaaaaaaaaaaaaaaaaa"}}}]}}}]};';

  testWidgets('search shows Islamic videos and remembers the search; history chips search again', (tester) async {
    final calls = <Uri>[];
    final app = await pumpApp(
      tester,
      size: tallPhone,
      httpClient: MockClient((req) async {
        calls.add(req.url);
        return req.url.path == '/results' ? http.Response.bytes(utf8.encode(page), 200) : http.Response('', 404);
      }),
    );
    await pushScreen(tester, const VideoSearchScreen());
    await tester.enterText(find.byKey(const Key('videos.searchField')), 'الكهف');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('videos.hit.abcdefghijk')), findsOneWidget);
    expect(app.services.reelsFeed.searchHistory, ['الكهف']);
    expect(find.byKey(const Key('videos.history.الكهف')), findsOneWidget);
    calls.clear();
    await tester.tap(find.descendant(of: find.byKey(const Key('videos.history.الكهف')), matching: find.text('الكهف')));
    await tester.pumpAndSettle();
    expect(calls.where((u) => u.path == '/results'), hasLength(1));
    await tester.tap(find.byKey(const Key('videos.clearHistory')));
    await tester.pumpAndSettle();
    expect(app.services.reelsFeed.searchHistory, isEmpty);
    expect(find.byKey(const Key('videos.history.الكهف')), findsNothing);
  });

  testWidgets('offline: says search is not available', (tester) async {
    await pumpApp(tester, size: tallPhone, httpClient: MockClient((_) async => throw Exception('offline')));
    await pushScreen(tester, const VideoSearchScreen(initialQuery: 'تلاوة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('videos.none')), findsOneWidget);
    expect(find.textContaining('تعذّر البحث'), findsOneWidget);
  });
}
