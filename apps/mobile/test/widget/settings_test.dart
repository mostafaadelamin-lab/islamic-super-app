import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/ui/about_screen.dart';
import 'package:rattil/ui/account_screen.dart';
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
    await tester.tap(find.text('Dark'));
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
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
  });

  testWidgets('theme selector: light, dark, system', (tester) async {
    final app = await open(tester, locale: 'en');
    MaterialApp mat() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(mat().themeMode, ThemeMode.system);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(mat().themeMode, ThemeMode.dark);
    expect(app.prefs.getString('theme'), 'dark');
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.dark);
    final bg = Theme.of(tester.element(find.byType(SettingsScreen))).scaffoldBackgroundColor;
    expect(bg, DesignTokens.dark['bg'], reason: 'dark bg token (emerald palette: 0xFF0C1714)');
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(mat().themeMode, ThemeMode.light);
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).scaffoldBackgroundColor, DesignTokens.light['bg']);
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(mat().themeMode, ThemeMode.system);
    expect(app.prefs.getString('theme'), 'system');
  });

  testWidgets('system theme follows the platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await open(tester, locale: 'en');
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.dark);
  });

  testWidgets('Quran font size slider: 18..40, persists, updates preview', (tester) async {
    final app = await open(tester, locale: 'en');
    final slider = tester.widget<Slider>(find.byKey(const Key('fontSizeSlider')));
    expect(slider.min, 18);
    expect(slider.max, 40);
    expect(slider.value, 26);
    final rect = tester.getRect(find.byKey(const Key('fontSizeSlider')));
    await tester.tapAt(Offset(rect.right - 2, rect.center.dy));
    await tester.pumpAndSettle();
    expect(app.prefs.getDouble('quranFontSize'), 40);
    expect(tester.widget<Text>(find.byKey(const Key('fontSizeValue'))).data, '40');
    Text preview() =>
        tester.widget<Text>(find.descendant(of: find.byKey(const Key('fontPreview')), matching: find.byType(Text)));
    expect(preview().style!.fontSize, 40);
    await tester.tapAt(Offset(rect.left + 2, rect.center.dy));
    await tester.pumpAndSettle();
    expect(app.prefs.getDouble('quranFontSize'), 18);
    expect(preview().style!.fontSize, 18);
  });

  testWidgets('slider supports accessibility increase/decrease actions', (tester) async {
    final handle = tester.ensureSemantics();
    final app = await open(tester, locale: 'en');
    final node = tester.getSemantics(find.byKey(const Key('fontSizeSlider')));
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(node.id, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(app.prefs.getDouble('quranFontSize'), greaterThan(26));
    handle.dispose();
  });

  testWidgets('out-of-range stored font size is clamped', (tester) async {
    await open(tester, locale: 'en', prefs: {'quranFontSize': 99.0});
    expect(tester.widget<Slider>(find.byKey(const Key('fontSizeSlider'))).value, 40);
  });

  testWidgets('translation switch persists', (tester) async {
    final app = await open(tester, locale: 'en');
    await tester.tap(find.byKey(const Key('translationSwitch')));
    await tester.pumpAndSettle();
    expect(app.prefs.getBool('showTranslation'), isTrue);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('translationSwitch'))).value, isTrue);
  });

  testWidgets('account and about entries open their screens', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('accountTile')));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    await goBack(tester);
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('about: free-forever statement and content sources/licences', (tester) async {
    await open(tester, locale: 'en');
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    expect(find.text('This app is completely free: no ads, no subscriptions, no purchases.'), findsOneWidget);
    expect(find.textContaining('CC BY 4.0'), findsOneWidget);
    expect(find.textContaining('Saheeh International'), findsOneWidget);
    expect(find.textContaining('Waqf General Public License'), findsOneWidget);
    expect(find.textContaining('SIL Open Font License'), findsOneWidget);
    expect(find.textContaining('adhan-js'), findsOneWidget);
    expect(find.textContaining('IANA'), findsOneWidget);
    expect(find.text('Quran 1.0.0 · Pages 1405H-1'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });

  testWidgets('about in Arabic', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    expect(find.text('التطبيق مجاني بالكامل: بلا إعلانات ولا اشتراكات ولا مشتريات.'), findsOneWidget);
    expect(find.text('مصادر المحتوى'), findsOneWidget);
    expect(find.text('الإصدار ١.٠.٠'), findsOneWidget);
  });
}
