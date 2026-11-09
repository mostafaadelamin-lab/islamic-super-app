import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/downloads_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  testWidgets('the downloads screen lists every surah with a download button', (tester) async {
    await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(tester, const DownloadsScreen());
    expect(find.text('Downloaded recitations'), findsOneWidget);
    expect(find.byKey(const Key('download-1')), findsOneWidget);
    expect(find.byKey(const Key('downloadStart-1')), findsOneWidget);
  });

  testWidgets('the mini player changes the playback speed', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, size: tallPhone, locale: 'en', audio: audio);
    await app.services.recitation.playFrom(const AyahRef(1, 1));
    await tester.pump();
    final speed = find.byKey(const Key('audioSpeed'));
    expect(find.descendant(of: speed, matching: find.text('1×')), findsOneWidget);
    await tester.tap(speed);
    await tester.pump();
    expect(app.services.settings.audioSpeed, 1.25);
    expect(audio.speed, 1.25);
    expect(find.descendant(of: speed, matching: find.text('1.25×')), findsOneWidget);
  });
}
