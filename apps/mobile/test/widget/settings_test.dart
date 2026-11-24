import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/ui/about_screen.dart';
import 'package:rattil/ui/contact_screen.dart';
import 'package:rattil/ui/prayer_screen.dart';
import 'package:rattil/theme/design_tokens.dart';
import 'package:rattil/ui/settings_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  Future<TestApp> open(WidgetTester tester, {String locale = 'ar', Map<String, Object> prefs = const {}}) async {
    final app = await pumpApp(tester, locale: locale, prefs: prefs, size: tallPhone);
    await openSettings(tester);
    return app;
  }

  testWidgets('colour style and light/dark (owner 2026-11-15): style 2 and dark are kept and applied', (tester) async {
    final app = await open(tester);
    Color primary() => Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.primary;
    // «ليل المدينة» is the default since 1.2.8 (owner 2026-11-17).
    expect(primary(), DesignTokens.palettes['madinah']!['light']!['primary']);
    await tester.ensureVisible(find.byKey(const Key('palette.emerald')));
    await tester.tap(find.byKey(const Key('palette.emerald')));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('palette'), 'emerald');
    expect(primary(), DesignTokens.palettes['emerald']!['light']!['primary']);
    await tester.tap(find.byKey(const Key('palette.madinah')));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('palette'), 'madinah');
    await tester.tap(find.text('داكن'));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('theme'), 'dark');
    expect(primary(), DesignTokens.palettes['madinah']!['dark']!['primary']);
    // Still on the settings screen after the change (no navigation reset).
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('palette.emerald')));
    await tester.pumpAndSettle();
    expect(primary(), DesignTokens.palettes['emerald']!['dark']!['primary']);
  });

  testWidgets('a colour style saved before 1.2.8 gives way once to «ليل المدينة»', (tester) async {
    await open(tester, prefs: {'palette': 'emerald'});
    Color primary() => Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.primary;
    expect(primary(), DesignTokens.palettes['madinah']!['light']!['primary']);
  });

  testWidgets('a colour style picked after 1.2.8 is kept', (tester) async {
    await open(tester, prefs: {'palette': 'emerald', 'paletteV2': true});
    Color primary() => Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.primary;
    expect(primary(), DesignTokens.palettes['emerald']!['light']!['primary']);
  });

  testWidgets('language switch: ar -> en -> ar, direction follows, choice persists', (tester) async {
    final app = await open(tester);
    expect(Directionality.of(tester.element(find.byType(SettingsScreen))), TextDirection.rtl);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('locale'), 'en');
    expect(find.text('Settings'), findsWidgets);
    expect(Directionality.of(tester.element(find.byType(SettingsScreen))), TextDirection.ltr);
    expect(Localizations.localeOf(tester.element(find.byType(SettingsScreen))).languageCode, 'en');
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(app.prefs.getString('locale'), 'ar');
    expect(find.text('الإعدادات'), findsWidgets);
    expect(Directionality.of(tester.element(find.byType(SettingsScreen))), TextDirection.rtl);
  });

  testWidgets('settings persist across an app restart (same storage)', (tester) async {
    final app = await open(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    // "Restart": a brand-new widget tree and services reading the same prefs.
    await tester.pumpWidget(const SizedBox());
    final restarted = AppServices.create(
      content: app.services.content,
      prefs: app.prefs,
      httpClient: MockHttpClient(),
      clock: () => fixedNow,
    );
    await tester.pumpWidget(RattilApp(services: restarted));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('system theme follows the platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await open(tester, locale: 'en');
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.dark);
  });

  testWidgets('settings list: prayer/location auto switches, rate, share, FAQ, contact, our apps, about', (
    tester,
  ) async {
    final app = await open(tester);
    for (final k in ['prayerAuto', 'rateTile', 'shareTile', 'faqTile', 'contactTile', 'ourAppsTile', 'aboutTile']) {
      await tester.scrollUntilVisible(find.byKey(Key(k)), 200, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    expect(find.byKey(const Key('accountTile')), findsNothing);
    expect(app.services.settings.prayerAuto, isTrue);
    await tester.scrollUntilVisible(
      find.byKey(const Key('prayerAuto')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('prayerAuto')));
    await tester.pumpAndSettle();
    expect(app.services.settings.prayerAuto, isFalse);
    expect(find.byKey(const Key('prayerManualTile')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('contactTile')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('contactTile')));
    await tester.pumpAndSettle();
    expect(find.byType(ContactScreen), findsOneWidget);
    expect(find.textContaining('@'), findsNothing, reason: 'no email address is shown');
    await goBack(tester);
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    // No sources or credits in the app (owner 2026-11-20).
    expect(find.byKey(const Key('adhanCredits')), findsNothing);
    expect(find.textContaining('Wikimedia'), findsNothing);
  });

  testWidgets('about: free-forever statement, no content sources (owner 2026-11-15)', (tester) async {
    await open(tester, locale: 'en');
    await tester.scrollUntilVisible(find.byKey(const Key('aboutTile')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    expect(find.text('A free app made for the sake of Allah: no charge and no ads.'), findsOneWidget);
    // Content sources hidden from the app (owner, 2026-11-15); kept in docs/CONTENT_SOURCES.md.
    expect(find.textContaining('hafsData_v18'), findsNothing);
    expect(find.textContaining('Saheeh International'), findsNothing);
    expect(find.text('Version ${AboutScreen.appVersion}'), findsOneWidget);
  });

  testWidgets('about in Arabic', (tester) async {
    await open(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('aboutTile')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    expect(find.text('تطبيق مجاني تم إنشاؤه لوجه الله تعالى، بدون مقابل وبدون إعلانات.'), findsOneWidget);
    expect(find.text('مصادر المحتوى'), findsNothing);
    expect(find.text('الإصدار ١.٢.٢٠'), findsOneWidget);
  });

  testWidgets('Hijri date adjustment: +/- within -2..+2, persisted', (tester) async {
    final app = await pumpApp(tester, locale: 'en', size: tallPhone);
    await pushScreen(tester, const PrayerScreen(settingsMode: true));
    final plus = find.byKey(const Key('hijriOffsetPlus'));
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(app.prefs.getInt('hijriOffset'), 1);
    expect(find.textContaining('+1'), findsOneWidget);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
    final minus = find.byKey(const Key('hijriOffsetMinus'));
    for (var i = 0; i < 4; i++) {
      await tester.tap(minus);
      await tester.pumpAndSettle();
    }
    expect(app.prefs.getInt('hijriOffset'), -2);
    expect(tester.widget<IconButton>(minus).onPressed, isNull);
    await app.services.settings.setHijriOffset(0);
  });
}
