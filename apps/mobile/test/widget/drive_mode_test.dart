import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/drive_mode.dart';
import 'package:rattil/ui/adhkar_screen.dart';

import '../helpers.dart';

/// App storage with both adhkar recordings already downloaded (fake bytes, big enough).
Directory driveStorage() {
  final d = Directory.systemTemp.createTempSync('rattil-drive');
  Directory('${d.path}/adhkar').createSync();
  for (final n in ['adhkar_morning_alafasy', 'adhkar_evening_alafasy']) {
    File('${d.path}/adhkar/$n.mp3').writeAsBytesSync(List.filled(300 * 1024, 0xFF));
  }
  return d;
}

Future<void> back(WidgetTester tester) async {
  await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() => loadContent(realFonts: false));
  // A cached asset load from an earlier test never finishes in this test's fake clock.
  setUp(() => rootBundle.evict(DriveClips.asset));

  testWidgets('Adhkar tab → listen while driving: big counter, next / previous / pause, count goes up by itself', (
    tester,
  ) async {
    final player = TestDrivePlayer();
    final cues = TestDriveCues();
    final app = await pumpApp(tester, storage: driveStorage(), drivePlayer: player, driveCues: cues);
    await pushScreen(tester, const AdhkarScreen());
    await tester.scrollUntilVisible(find.byKey(const Key('adhkarDrive.morning')), 200);
    await tester.ensureVisible(find.byKey(const Key('adhkarDrive.morning')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adhkarDrive.morning')));
    await settle(tester);

    final drive = app.services.drive!;
    expect(drive.session, AdhkarSession.morning);
    expect(drive.isPlaying, isTrue);
    expect(player.loaded, endsWith('adhkar/adhkar_morning_alafasy.mp3'));
    expect(find.byKey(const Key('driveText')), findsOneWidget);
    expect(find.byKey(const Key('driveCarHint')), findsOneWidget);

    // Go to the first dhikr said 3 times; each clip that ends adds one to the count.
    final three = drive.items.indexWhere((it) => it.count == 3);
    unawaited(drive.jumpTo(three));
    await settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('driveCount'))).data, '١');
    player.end();
    await settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('driveCount'))).data, '٢');
    expect(cues.log.last, 'tick');
    player.end();
    await settle(tester);
    player.end();
    await settle(tester);
    expect(cues.log.last, 'done');
    expect(drive.index, three + 1);

    // Pause keeps the count; play goes on.
    await tester.tap(find.byKey(const Key('drivePlayPause')));
    await settle(tester);
    expect(drive.isPlaying, isFalse);
    await tester.tap(find.byKey(const Key('drivePlayPause')));
    await settle(tester);
    expect(drive.isPlaying, isTrue);

    await tester.tap(find.byKey(const Key('driveNext')));
    await settle(tester);
    expect(drive.index, three + 2);
    await tester.tap(find.byKey(const Key('drivePrevious')));
    await settle(tester);
    expect(drive.index, three + 1);

    // Settings: spoken count every 10.
    await tester.tap(find.byKey(const Key('driveSettings')));
    await settle(tester);
    await tester.tap(find.text('كل ١٠'));
    await settle(tester);
    expect(app.services.settings.driveSayEvery, 10);
    await drive.stop();
  });

  testWidgets('morning adhkar screen has the driving-mode button', (tester) async {
    final app = await pumpApp(tester, storage: driveStorage());
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.evening));
    await tester.tap(find.byKey(const Key('adhkarDriveMode')));
    await settle(tester);
    expect(app.services.drive!.session, AdhkarSession.evening);
    expect(find.text('وضع القيادة · أذكار المساء'), findsOneWidget);
    await app.services.drive!.stop();
  });

  testWidgets('leaving the driving screen: the bar stays on the adhkar screen and the home screen, ✕ stops it', (
    tester,
  ) async {
    final player = TestDrivePlayer();
    final app = await pumpApp(tester, storage: driveStorage(), drivePlayer: player, driveCues: TestDriveCues());
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    expect(find.byKey(const Key('driveBar')), findsNothing);
    await tester.tap(find.byKey(const Key('adhkarDriveMode')));
    await settle(tester);
    final drive = app.services.drive!;
    for (var i = 0; i < 60 && !drive.isPlaying; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(drive.isPlaying, isTrue);

    // Back to the adhkar screen: still playing, and the bar is there.
    await back(tester);
    await settle(tester);
    expect(drive.isPlaying, isTrue);
    expect(find.byKey(const Key('driveBar')), findsOneWidget);
    expect(find.text('وضع القيادة · أذكار الصباح'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('driveBarInfo'))).data, contains('الذكر ١ من'));

    // Pause / play from the bar.
    await tester.tap(find.byKey(const Key('driveBarToggle')));
    await settle(tester);
    expect(drive.isPlaying, isFalse);
    await tester.tap(find.byKey(const Key('driveBarToggle')));
    await settle(tester);
    expect(drive.isPlaying, isTrue);

    // Next dhikr from the bar.
    await tester.tap(find.byKey(const Key('driveBarNext')));
    await settle(tester);
    expect(drive.index, 1);

    // Back to the home screen: the bar is there too.
    await back(tester);
    await settle(tester);
    expect(find.byKey(const Key('driveBar')), findsOneWidget);

    // Tapping its title opens the driving screen again.
    await tester.tap(find.byKey(const Key('driveBarOpen')));
    await settle(tester);
    expect(find.byKey(const Key('driveText')), findsOneWidget);
    await back(tester);
    await settle(tester);

    // ✕ stops driving mode and the bar goes away.
    await tester.tap(find.byKey(const Key('driveBarStop')));
    await settle(tester);
    expect(drive.isActive, isFalse);
    expect(drive.isPlaying, isFalse);
    expect(find.byKey(const Key('driveBar')), findsNothing);
  });
}
