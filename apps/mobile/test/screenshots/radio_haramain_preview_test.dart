// Preview pictures of the home Quran radio card with «صوتي» on the audio stations and the two Haramain
// «مباشر الآن فيديو» buttons (owner 2026-11-28). The live video is a stand-in here (no WebView in tests):
// build/makkah-thumb.jpg when present. Output: $RATTIL_SCREENSHOT_DIR/radio-haramain, or build/screenshots/radio-haramain.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/domain/reels.dart';
import 'package:rattil/ui/home_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/radio-haramain');
  final thumb = File('build/makkah-thumb.jpg');

  final img = thumb.existsSync() ? MemoryImage(thumb.readAsBytesSync()) : null;
  Widget live(BuildContext context, LiveChannel c) => img != null
      ? Image(image: img, fit: BoxFit.cover)
      : const ColoredBox(color: Colors.black, child: SizedBox.expand());

  Future<void> shot(WidgetTester tester, String name) async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(Offset.zero & view.size, pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
  }

  testWidgets('preview: radio card closed, list open, Makkah video', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(
      tester,
      size: const Size(390, 700),
      prefs: {'theme': 'light'},
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    await pushScreen(
      tester,
      Scaffold(
        appBar: AppBar(title: const Text('الرئيسية')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: QuranRadioCard(livePlayerBuilder: live),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shot(tester, 'app-1-card');
    await tester.tap(find.byKey(const Key('radio.station')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-2-list');
    await tester.tap(find.text('إذاعة القرآن الكريم من القاهرة').last);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(MemoryImage(thumb.readAsBytesSync()), tester.element(find.byType(Scaffold).last)),
    );
    await tester.tap(find.byKey(const Key('radio.live-makkah')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'app-3-makkah-video');
  });
}
