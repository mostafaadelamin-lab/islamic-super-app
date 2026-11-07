import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rattil/app.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/notifications.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/sensors.dart';
import 'package:rattil/data/tafsir.dart';
import 'package:rattil/domain/qibla.dart';
import 'package:rattil/domain/tafsir.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Repo root, resolved from apps/mobile (the cwd of `flutter test`).
final repoRoot = Directory.current.parent.parent.path;

Map<String, dynamic> readRepoJson(String rel) =>
    jsonDecode(File('$repoRoot/$rel').readAsStringSync()) as Map<String, dynamic>;

Map<String, dynamic> readAppJson(String rel) => jsonDecode(File(rel).readAsStringSync()) as Map<String, dynamic>;

AppContent? _content;

/// Loads the bundled assets through rootBundle once (call from setUpAll).
Future<AppContent> loadContent({bool realFonts = true}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  if (realFonts) await loadRealFonts();
  _tafsir ??= TafsirContent.parse(await rootBundle.loadString(TafsirStore.assetKey, cache: false));
  return _content ??= await AppContent.load(rootBundle);
}

TafsirContent? _tafsir;

/// The bundled Tafsir al-Muyassar, decoded by [loadContent].
TafsirContent get testTafsir => _tafsir!;

bool _fontsLoaded = false;

/// Registers the app's bundled fonts (and Material Icons) with the engine so
/// that Arabic text is actually drawn in tests (the default test font has no
/// Arabic glyphs, which would make contrast checks and screenshots meaningless).
Future<void> loadRealFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final f in manifest) {
    final family = (f as Map<String, dynamic>)['family'] as String;
    final loader = FontLoader(family.startsWith('packages/') ? family.split('/').last : family);
    for (final a in f['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load((a as Map<String, dynamic>)['asset'] as String));
    }
    await loader.load();
  }
}

class MockHttpClient extends Mock implements http.Client {}

void registerHttpFallbacks() {
  registerFallbackValue(http.Request('GET', Uri.parse('http://x')));
}

/// Fixed instant used by widget tests: 2026-01-15 10:00 UTC (12:00 in Cairo).
final fixedNow = DateTime.utc(2026, 1, 15, 10, 0);

class TestApp {
  TestApp(this.services, this.prefs);
  final AppServices services;
  final SharedPreferences prefs;
}

Future<TestApp> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  String locale = 'ar',
  DateTime Function()? clock,
  http.Client? httpClient,
  AppContent? content,
  double textScale = 1.0,
  Size? size,
  FakeAudioBackend? audio,
  FakeNotifications? notifications,
  CompassSensors? sensors,
  TafsirStore? tafsir,
}) async {
  final c = content ?? _content!;
  SharedPreferences.setMockInitialValues({'locale': locale, ...prefs});
  final p = await SharedPreferences.getInstance();
  final services = AppServices.create(
    content: c,
    prefs: p,
    httpClient: httpClient ?? MockHttpClient(),
    clock: clock ?? () => fixedNow,
    audioBackend: () => audio ?? FakeAudioBackend(),
    notifications: notifications ?? FakeNotifications(),
    sensors: sensors ?? FakeSensors.none(),
    tafsir: tafsir ?? TafsirStore.preloaded(_tafsir!),
  );
  if (size != null) {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
  }
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view).copyWith(textScaler: TextScaler.linear(textScale)),
      child: RattilApp(services: services),
    ),
  );
  await tester.pumpAndSettle();
  return TestApp(services, p);
}

/// Taps the bottom-navigation destination with [index] (0..4).
Future<void> goToTab(WidgetTester tester, int index) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination)).at(index),
  );
  await tester.pumpAndSettle();
}

/// Tap-target and label guidelines always; the text-contrast guideline only
/// when [contrast] is true. textContrastGuideline samples rendered pixels and
/// is only reliable with the solid-glyph test font (no real fonts loaded),
/// which has no Arabic glyphs — so contrast is checked on English screens
/// (same theme colours) and analytically in theme_contrast_test.dart.
Future<void> expectAccessible(WidgetTester tester, {bool contrast = false}) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  if (contrast) await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

/// A tall viewport for guideline checks, so that no content is hidden behind
/// the navigation bar (the contrast guideline samples on-screen pixels and
/// would otherwise measure text that is occluded).
const tallPhone = Size(420, 2400);

/// Taps the AppBar back button (locale-independent, unlike pageBack()).
Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}

/// Content with an extra city inside the Arctic circle (Tromsø), for polar tests.
AppContent withPolarCity(AppContent c) => AppContent(
  quran: c.quran,
  mushaf: c.mushaf,
  reciters: c.reciters,
  adhkar: c.adhkar,
  hajj: c.hajj,
  integrity: c.integrity,
  prayerConfig: c.prayerConfig,
  cities: [
    ...c.cities,
    const City(
      id: 'polar',
      nameAr: 'ترومسو',
      nameEn: 'Tromsø',
      countryAr: 'النرويج',
      lat: 69.6492,
      lng: 18.9553,
      tz: 'Europe/Oslo',
      method: 'mwl',
    ),
  ],
  renderMap: c.renderMap,
  normalizer: c.normalizer,
  versions: c.versions,
);

/// Pushes [screen] on the app's navigator (the route future is not awaited:
/// it only completes when the route is popped).
Future<void> pushScreen(WidgetTester tester, Widget screen) async {
  unawaited(
    tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => screen)),
  );
  await tester.pumpAndSettle();
}

/// Opens Settings (More tab → Settings) — the M2 navigation moved Settings
/// from the 5th tab into "More".
Future<void> openSettings(WidgetTester tester) async {
  await goToTab(tester, 4);
  await tester.tap(find.byKey(const Key('more.settings')));
  await tester.pumpAndSettle();
}

/// Opens Bookmarks (More tab → Bookmarks) — formerly the 4th tab.
Future<void> openBookmarks(WidgetTester tester) async {
  await goToTab(tester, 4);
  await tester.tap(find.byKey(const Key('more.bookmarks')));
  await tester.pumpAndSettle();
}

/// Records what the recitation controller asks the audio engine to do. Tests
/// end a file with [finish] and make loading fail with [failNext].
class FakeAudioBackend implements AudioBackend {
  final loaded = <String>[];
  final calls = <String>[];
  final _completed = StreamController<void>.broadcast();
  bool failNext = false;

  @override
  Future<void> load(String url) async {
    calls.add('load');
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    loaded.add(url);
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> stop() async => calls.add('stop');

  /// The current file played to its end.
  void finish() => _completed.add(null);

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() => _completed.close();
}

class FakeNotifications implements NotificationsBackend {
  FakeNotifications({this.grant = true});
  bool grant;
  final scheduled = <({int id, String title, String body, DateTime at})>[];
  int cancels = 0;
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
    scheduled.clear();
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime atUtc,
  }) async => scheduled.add((id: id, title: title, body: body, at: atUtc));
}

class FakeSensors implements CompassSensors {
  FakeSensors(this.accelerometer, this.magnetometer);

  /// A device without sensors: both streams stay silent.
  factory FakeSensors.none() => FakeSensors(const Stream.empty(), const Stream.empty());

  @override
  final Stream<Vec3> accelerometer;
  @override
  final Stream<Vec3> magnetometer;
}
