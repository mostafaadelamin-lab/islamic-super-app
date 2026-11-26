import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/location.dart';

import '../helpers.dart';

/// First run (owner 2026-11-14): feature tour, then location, adhan notifications,
/// exact alarms, battery and "adhan when the phone is silent".
void main() {
  setUpAll(loadContent);

  const firstRun = <String, Object>{'onboarding.done': false};

  Future<void> toSetup(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('tourNext')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('setupPage')), findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(find.byKey(key), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('first start: Skip still asks for location and adhan alerts, then Start; remembered', (tester) async {
    final notifications = FakeNotifications();
    final app = await pumpApp(
      tester,
      prefs: firstRun,
      size: tallPhone,
      notifications: notifications,
      location: const FakeLocation(LocationFound(30.0445, 31.2357)),
    );
    expect(find.byKey(const Key('onboarding')), findsOneWidget);
    expect(find.text('أهلًا بك في «رتّل وصلِّ»'), findsOneWidget);
    expect(find.byKey(const Key('navBar')), findsNothing);
    await tester.tap(find.byKey(const Key('tourSkip')));
    await tester.pumpAndSettle();
    // Owner: right after install the app asks for the location and to turn on the adhan.
    expect(find.byKey(const Key('setupPage')), findsOneWidget);
    expect(app.services.settings.cityId, 'gps');
    expect(notifications.permissionRequests, 1);
    expect(app.services.settings.adhanEnabled, isTrue);
    await tester.tap(find.byKey(const Key('tourStart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('navBar')), findsOneWidget);
    expect(app.prefs.getBool('onboarding.done'), isTrue);
  });

  testWidgets('a later start goes straight to the home screen', (tester) async {
    await pumpApp(tester, size: tallPhone);
    expect(find.byKey(const Key('onboarding')), findsNothing);
    expect(find.byKey(const Key('navBar')), findsOneWidget);
  });

  testWidgets('Android setup: location, adhan, battery, silent switch, then Start', (tester) async {
    final notifications = FakeNotifications();
    final device = FakeDeviceSetup(notifications: false, exact: false);
    final app = await pumpApp(
      tester,
      prefs: firstRun,
      size: tallPhone,
      locale: 'en',
      notifications: notifications,
      deviceSetup: device,
      location: const FakeLocation(LocationFound(30.0445, 31.2357)),
    );
    // The tour's slides, in order.
    for (final title in [
      'Welcome to Rattil wa Salli',
      'Your data stays yours',
      'The Holy Quran',
      'Prayer times and adhan',
    ]) {
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.byKey(const Key('tourNext')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('tourBack')));
    await tester.pumpAndSettle();
    expect(find.text('Prayer times and adhan'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('tourNext')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('setupPage')), findsOneWidget);
    expect(find.byKey(const Key('tourSkip')), findsNothing);

    // Location and notifications are asked as soon as the setup page opens.
    expect(app.services.settings.cityId, 'gps');
    expect(
      find.descendant(of: find.byKey(const Key('setupLocation')), matching: find.byKey(const Key('stepDone'))),
      findsOneWidget,
    );

    expect(notifications.permissionRequests, 1);
    expect(app.services.settings.adhanEnabled, isTrue);
    // The system still says notifications are off: a button opens its settings.
    await tapVisible(tester, const Key('setupNotifSettings'));
    expect(device.opened, ['notifications']);
    device.opened.clear();

    // Exact alarms and battery open the system screens (no direct battery dialog).
    await tapVisible(tester, const Key('setupExactAction'));
    await tapVisible(tester, const Key('setupBatteryAction'));
    await tapVisible(tester, const Key('setupAppPage'));
    expect(device.opened, ['exact', 'battery', 'app']);

    // Adhan when the phone is silent: on by default (owner 2026-11-27), the switch turns it off.
    expect(app.services.settings.adhanPlayOnSilent, isTrue);
    await tapVisible(tester, const Key('setupSilent'));
    expect(app.services.settings.adhanPlayOnSilent, isFalse);

    // The prayer widget and, for the lock screen, the next-prayer notice (on by default).
    await tester.scrollUntilVisible(find.byKey(const Key('lockNotice')), 200, scrollable: find.byType(Scrollable).last);
    expect(find.byKey(const Key('prayerWidgetCard')), findsOneWidget);
    expect(app.services.settings.lockNotice, isTrue);
    await tapVisible(tester, const Key('lockNotice'));
    expect(app.services.settings.lockNotice, isFalse);

    await tester.tap(find.byKey(const Key('tourStart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('navBar')), findsOneWidget);
    expect(app.prefs.getBool('onboarding.done'), isTrue);
  });

  testWidgets('location refused: says so and offers the city list', (tester) async {
    await pumpApp(
      tester,
      prefs: firstRun,
      size: tallPhone,
      locale: 'en',
      location: const FakeLocation(LocationDenied()),
    );
    await toSetup(tester);
    expect(find.text('Location was not allowed. You can choose your city instead.'), findsOneWidget);
    expect(find.byKey(const Key('setupLocationCity')), findsOneWidget);
  });

  testWidgets('iPhone: no battery or exact-alarm steps; explains the silent switch honestly', (tester) async {
    await pumpApp(
      tester,
      prefs: firstRun,
      size: tallPhone,
      locale: 'en',
      deviceSetup: FakeDeviceSetup(isAndroid: false, isIos: true, exact: false),
    );
    await toSetup(tester);
    expect(find.byKey(const Key('setupBattery')), findsNothing);
    expect(find.byKey(const Key('setupExact')), findsNothing);
    expect(find.byKey(const Key('setupSilent')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('setupSilentIos')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Apple allows it only for emergency and health apps'), findsOneWidget);
    // Apple lets no app add a widget: the steps for the home and lock screens instead.
    await tester.scrollUntilVisible(
      find.byKey(const Key('setupWidgetIos')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Lock Screen → Add Widgets'), findsOneWidget);
    expect(find.byKey(const Key('lockNotice')), findsNothing);
  });

  testWidgets('Arabic tour and setup are accessible', (tester) async {
    await pumpApp(tester, prefs: firstRun, size: tallPhone);
    await expectAccessible(tester);
    await toSetup(tester);
    await expectAccessible(tester);
  });

  testWidgets('Settings: every permission inside the settings, and the tour again', (tester) async {
    final device = FakeDeviceSetup();
    await pumpApp(tester, size: const Size(440, 4000), locale: 'en', deviceSetup: device);
    await openSettings(tester);
    // Owner (2026-11-24): all permissions together in the settings, each with its explanation.
    expect(find.byKey(const Key('settingsPermissions')), findsOneWidget);
    expect(find.byKey(const Key('setupBattery')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('tourTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tourTile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding')), findsOneWidget);
    // Replay: the tour only, no setup page; Done closes it.
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('tourNext')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('setupPage')), findsNothing);
    await tester.tap(find.byKey(const Key('tourStart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding')), findsNothing);
    expect(find.byKey(const Key('settingsPermissions')), findsOneWidget);
  });
}
