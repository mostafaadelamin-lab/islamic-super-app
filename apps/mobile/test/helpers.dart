import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/bookmarks_screen.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rattil/app.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/device_setup.dart';
import 'package:rattil/data/drive_mode.dart';
import 'package:rattil/domain/drive_mode.dart';
import 'package:rattil/data/location.dart';
import 'package:rattil/data/notifications.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/sensors.dart';
import 'package:rattil/data/sharing.dart';
import 'package:rattil/data/hadith.dart';
import 'package:rattil/data/tafsir.dart';
import 'package:rattil/data/word_meanings.dart';
import 'package:rattil/domain/qibla.dart';
import 'package:rattil/domain/tafsir.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:rattil/ui/r_icon.dart';

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
  _meanings ??= WordMeaningsContent.parse(await rootBundle.loadString(WordMeaningsStore.assetKey, cache: false));
  return _content ??= await AppContent.load(rootBundle);
}

TafsirContent? _tafsir;
WordMeaningsContent? _meanings;

/// The bundled word meanings («السراج في بيان غريب القرآن»), decoded by [loadContent].
WordMeaningsContent get testMeanings => _meanings!;

/// The bundled hadith books, read straight from apps/mobile/assets (no isolates in widget tests).
HadithLibrary testHadith(AppContent c) =>
    HadithLibrary(c.hadith, (key) async => gunzipText(File(key).readAsBytesSync()), isolate: false);

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

/// Empty app storage for tests (path_provider has no plugin there).
Directory? _testStorage;

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
  FakeNarrationBackend? narration,
  FakeNotifications? notifications,
  FakeAdhanPlayer? adhanPlayer,
  CompassSensors? sensors,
  TafsirStore? tafsir,
  HadithLibrary? hadith,
  LocationProvider? location,
  FakeSharer? sharer,
  Directory? storage,
  DeviceSetup? deviceSetup,
  DrivePlayer? drivePlayer,
  DriveCues? driveCues,
}) async {
  final c = content ?? _content!;
  // The first-run tour is tested on its own (onboarding_test.dart); other tests start on the home screen.
  SharedPreferences.setMockInitialValues({
    'locale': locale,
    'onboarding.done': true,
    'reader.guideDone': true,
    // Tests read fixed 24-hour times; the 12-hour default (owner 2026-11-20) is tested in prayer_screen_test.
    'clock': '24',
    // Tests draw the standard Mushaf font; the printed look (default, owner 2026-11-20) is tested in kids_ruqyah_test.
    'mushaf.printed': false,
    ...prefs,
  });
  final p = await SharedPreferences.getInstance();
  final services = AppServices.create(
    content: c,
    prefs: p,
    httpClient: httpClient ?? MockHttpClient(),
    clock: clock ?? () => fixedNow,
    audioBackend: () => audio ?? FakeAudioBackend(),
    storageRoot: () async => storage ?? (_testStorage ??= Directory.systemTemp.createTempSync('rattil-test')),
    adhanRetryDelay: Duration.zero,
    narrationBackend: () => narration ?? FakeNarrationBackend(),
    notifications: notifications ?? FakeNotifications(),
    adhanPlayer: adhanPlayer ?? FakeAdhanPlayer(),
    sensors: sensors ?? FakeSensors.none(),
    tafsir: tafsir ?? TafsirStore.preloaded(_tafsir!),
    wordMeanings: WordMeaningsStore.preloaded(_meanings!),
    hadith: hadith ?? testHadith(c),
    location: location ?? const FakeLocation(LocationUnavailable()),
    sharer: sharer ?? FakeSharer(),
    deviceSetup: deviceSetup ?? FakeDeviceSetup(),
    drivePlayer: () => drivePlayer ?? TestDrivePlayer(),
    driveCues: () => driveCues ?? TestDriveCues(),
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

/// Records what would be shared instead of opening the share sheet.
class FakeSharer implements ImageSharer {
  final images = <({int bytes, String fileName, String? text})>[];
  final texts = <String>[];
  @override
  Future<void> sharePng(Uint8List png, {required String fileName, String? text}) async =>
      images.add((bytes: png.length, fileName: fileName, text: text));
  @override
  Future<void> shareText(String text) async => texts.add(text);
}

/// "Use my location" answers [result] without touching the platform.
class FakeLocation implements LocationProvider {
  const FakeLocation(this.result);
  final LocationResult result;
  @override
  Future<LocationResult> current({bool precise = false}) async => result;
}

/// Taps the navigation destination with [index] (0..4): the bottom bar on a
/// phone, the side rail on a tablet.
Future<void> goToTab(WidgetTester tester, int index) async {
  final bar = find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination));
  if (bar.evaluate().isNotEmpty) {
    await tester.tap(bar.at(index));
  } else {
    await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.byType(RIcon)).at(index));
  }
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
  stepDuas: c.stepDuas,
  hajjGuide: c.hajjGuide,
  hajjScenes: c.hajjScenes,
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
  reels: c.reels,
  stories: c.stories,
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
  await goToTab(tester, 5);
  await tester.tap(find.byKey(const Key('more.settings')));
  await tester.pumpAndSettle();
}

/// Opens Bookmarks (More tab → Bookmarks) — formerly the 4th tab.
Future<void> openBookmarks(WidgetTester tester) async {
  await pushScreen(tester, const BookmarksScreen());
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

  double speed = 1.0;
  @override
  Future<void> setSpeed(double s) async => speed = s;

  /// The current file played to its end.
  void finish() => _completed.add(null);

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() => _completed.close();
}

/// Narrated-episode engine for tests: records calls; [emit] moves the position,
/// [finish] ends the file, [failNext] makes the next load fail.
class FakeNarrationBackend implements NarrationBackend {
  FakeNarrationBackend({this.length = const Duration(minutes: 25)});
  final Duration length;
  final loaded = <String>[];
  final calls = <String>[];
  final _pos = StreamController<Duration>.broadcast();
  final _done = StreamController<void>.broadcast();
  bool failNext = false;

  @override
  Future<Duration?> load(String url) async {
    calls.add('load');
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    loaded.add(url);
    return length;
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration to) async => calls.add('seek:${to.inSeconds}');

  @override
  Future<void> stop() async => calls.add('stop');

  void emit(Duration p) => _pos.add(p);
  void finish() => _done.add(null);

  @override
  Stream<Duration> get position => _pos.stream;

  @override
  Stream<void> get completed => _done.stream;

  @override
  Future<void> dispose() async {
    await _pos.close();
    await _done.close();
  }
}

class FakeNotifications implements NotificationsBackend {
  FakeNotifications({this.grant = true});
  bool grant;
  final scheduled = <({int id, String title, String body, DateTime at, String sound})>[];
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
    repeating.clear();
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime atUtc,
    String sound = 'adhan',
  }) async => scheduled.add((id: id, title: title, body: body, at: atUtc, sound: sound));

  final repeating = <int, ({String title, String body, int hour, int minute, int? weekday})>{};

  @override
  Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required tz.Location location,
    required DateTime nowUtc,
    int? weekday,
  }) async => repeating[id] = (title: title, body: body, hour: hour, minute: minute, weekday: weekday);

  @override
  Future<void> cancel(int id) async {
    repeating.remove(id);
    scheduled.removeWhere((n) => n.id == id);
  }
}

class FakeAdhanPlayer implements AdhanPlayer {
  int plays = 0;
  int stops = 0;
  String? lastAsset;
  final _done = StreamController<void>.broadcast();

  /// Simulates the recording reaching its end.
  void finish() => _done.add(null);

  @override
  Future<void> play(String asset) async {
    plays++;
    lastAsset = asset;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> get completed => _done.stream;
}

class FakeSensors implements CompassSensors {
  FakeSensors(this.accelerometer, this.magnetometer, {this.systemHeading, this.quality});

  /// A device without sensors: both streams stay silent.
  factory FakeSensors.none() => FakeSensors(const Stream.empty(), const Stream.empty());

  @override
  final Stream<double>? systemHeading;
  @override
  final Stream<CompassQuality>? quality;

  @override
  final Stream<Vec3> accelerometer;
  @override
  final Stream<Vec3> magnetometer;
}

/// Permission state for the first-run setup, without the platform.
class FakeDeviceSetup implements DeviceSetup {
  FakeDeviceSetup({
    this.isAndroid = true,
    this.isIos = false,
    this.location = false,
    this.notifications = true,
    this.exact = true,
    this.battery = false,
  });

  @override
  bool isAndroid;
  @override
  bool isIos;
  bool location;
  bool notifications;
  bool exact;
  bool battery;
  final opened = <String>[];

  @override
  Future<bool> locationAllowed() async => location;
  @override
  Future<bool> notificationsAllowed() async => notifications;
  @override
  Future<bool> exactAlarmsAllowed() async => exact;
  @override
  Future<bool> batteryUnrestricted() async => battery;
  @override
  Future<void> openExactAlarmSettings() async => opened.add('exact');
  @override
  Future<void> openBatterySettings() async => opened.add('battery');
  @override
  Future<void> openAppSettings() async => opened.add('app');
  @override
  Future<void> openNotificationSettings() async => opened.add('notifications');
}

/// Driving mode player for widget tests: a clip "plays" until [end] (or stop).
class TestDrivePlayer implements DrivePlayer {
  String? loaded;
  final played = <DriveClip>[];
  Completer<void>? _c;
  @override
  Future<void> load(String source) async => loaded = source;
  @override
  Future<void> playClip(DriveClip clip) {
    played.add(clip);
    return (_c = Completer<void>()).future;
  }

  void end() {
    _c?.complete();
    _c = null;
  }

  @override
  Future<void> stop() async => end();
  @override
  Future<void> dispose() async => end();
}

class TestDriveCues implements DriveCues {
  final log = <String>[];
  @override
  Future<void> tick() async => log.add('tick');
  @override
  Future<void> done() async => log.add('done');
  @override
  Future<void> say(int n, {required bool arabic}) async => log.add('say $n');
  @override
  Future<void> dispose() async {}
}
