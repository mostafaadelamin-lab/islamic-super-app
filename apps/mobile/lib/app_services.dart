import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'data/account.dart';
import 'data/bookmarks.dart';
import 'data/content.dart';
import 'data/devotions.dart';
import 'data/device_setup.dart';
import 'data/khatma_store.dart';
import 'data/worship_store.dart';
import 'data/downloads.dart';
import 'data/adhan_voice_files.dart';
import 'data/location.dart';
import 'data/place_names.dart';
import 'data/media_session.dart';
import 'data/notifications.dart';
import 'data/recitation.dart';
import 'data/reminders.dart';
import 'data/reels_feed.dart';
import 'data/sensors.dart';
import 'data/settings.dart';
import 'data/sharing.dart';
import 'data/hadith.dart';
import 'data/mp3quran.dart';
import 'data/tafsir.dart';
import 'domain/prayer_schedule.dart';
import 'ui/prayer_model.dart' show resolveCity;

/// Everything screens need, created once in main() (or in a test).
class AppServices {
  AppServices({
    required this.content,
    required this.settings,
    required this.bookmarks,
    required this.account,
    required this.clock,
    required this.recitation,
    required this.adhan,
    required this.adhanPreview,
    required this.adhanVoices,
    required this.tasbih,
    required this.adhkar,
    required this.sensors,
    required this.tafsir,
    required this.hadith,
    required this.mp3quran,
    required this.narration,
    required this.sleepTimer,
    this.location = const GeolocatorLocation(),
    required this.placeNames,
    required this.khatma,
    required this.worship,
    required this.downloads,
    required this.reminders,
    this.sharer = const SystemImageSharer(),
    required this.reelsFeed,
    this.media,
    DeviceSetup? deviceSetup,
  }) : deviceSetup = deviceSetup ?? PlatformDeviceSetup();

  factory AppServices.create({
    required AppContent content,
    required SharedPreferences prefs,
    required http.Client httpClient,
    Clock? clock,
    AudioBackend Function()? audioBackend,
    NarrationBackend Function()? narrationBackend,
    NotificationsBackend? notifications,
    AdhanPlayer? adhanPlayer,
    CompassSensors? sensors,
    TafsirStore? tafsir,
    HadithLibrary? hadith,
    LocationProvider? location,
    ImageSharer? sharer,
    Future<Directory> Function()? storageRoot,
    Duration adhanRetryDelay = const Duration(seconds: 2),
    MediaSession? mediaSession,
    DeviceSetup? deviceSetup,
  }) {
    final c = clock ?? DateTime.now;
    final settings = SettingsController(prefs, defaultCityId: content.cities.first.id);
    final bookmarks = BookmarksController(prefs, clock: c);
    DateTime localToday() {
      final city = resolveCity(content, settings);
      return PrayerSchedule.localDate(tz.getLocation(city.tz), c().toUtc());
    }

    final backend = notifications ?? LocalNotificationsBackend();
    final reminders = ReminderScheduler(
      backend: backend,
      location: () => tz.getLocation(resolveCity(content, settings).tz),
      clock: c,
      locale: () => settings.locale,
    );
    final khatma = KhatmaController(settings, localToday, onReminderChanged: reminders.sync);
    reminders.addSource(khatma.reminders);
    reminders.addSource((l) {
      final m = settings.fridayReminder;
      if (m == null) return const [];
      return [
        ReminderSpec(
          id: ReminderIds.friday,
          title: l.alertFridayTitle,
          body: l.alertFridayBody,
          minutes: m,
          weekday: DateTime.friday,
        ),
      ];
    });
    reminders.addSource(
      (l) => [
        for (final morning in [true, false])
          if (settings.adhkarReminder(morning) case final m?)
            ReminderSpec(
              id: morning ? ReminderIds.adhkarMorning : ReminderIds.adhkarEvening,
              title: morning ? l.alertAdhkarMorningTitle : l.alertAdhkarEveningTitle,
              body: morning ? l.alertAdhkarMorningBody : l.alertAdhkarEveningBody,
              minutes: m,
            ),
      ],
    );
    final adhanVoices = AdhanVoiceFiles(
      httpClient: httpClient,
      root: storageRoot ?? getApplicationSupportDirectory,
      retryDelay: adhanRetryDelay,
    );
    final downloads = RecitationDownloads(
      content: content,
      httpClient: httpClient,
      root: storageRoot ?? getApplicationSupportDirectory,
    );
    final recitation = RecitationController(
      content: content,
      settings: settings,
      backendFactory: audioBackend ?? JustAudioBackend.new,
      localFile: (reciter, item) async {
        try {
          return await downloads.localFile(reciter, item.audioRef, forSurah: item.ref.surah);
        } catch (_) {
          return null; // no storage (tests, restricted device): stream instead
        }
      },
    );
    final narration = NarrationController(
      settings: settings,
      recitation: recitation,
      backendFactory: narrationBackend ?? JustAudioNarrationBackend.new,
      offlineFile: downloads.offlineFile,
    );
    return AppServices(
      content: content,
      settings: settings,
      bookmarks: bookmarks,
      account: AccountController(prefs, settings, bookmarks, httpClient, clock: c),
      clock: c,
      recitation: recitation,
      narration: narration,
      sleepTimer: SleepTimerController(
        clock: c,
        onFire: () async {
          await recitation.stop();
          await narration.pause();
        },
      ),
      adhan: AdhanScheduler(
        content: content,
        settings: settings,
        backend: backend,
        reserved: () => reminders.activeCount,
        afterReset: reminders.scheduleActive,
        clock: c,
        // Android has no small cap on pending alarms, so a month ahead keeps the
        // adhan going even if the app is not opened; iOS keeps at most 64.
        days: defaultTargetPlatform == TargetPlatform.android ? 30 : 7,
        max: defaultTargetPlatform == TargetPlatform.android ? 150 : 60,
        voices: adhanVoices,
      ),
      adhanPreview: AdhanPreview(adhanPlayer ?? JustAudioAdhanPlayer(), source: adhanVoices.playable),
      adhanVoices: adhanVoices,
      tasbih: TasbihController(settings),
      adhkar: AdhkarController(content, settings, localToday),
      sensors: sensors ?? const DeviceCompassSensors(),
      tafsir: tafsir ?? TafsirStore.asset(rootBundle),
      hadith: hadith ?? HadithLibrary.asset(content.hadith, rootBundle),
      mp3quran: Mp3QuranClient(httpClient: httpClient, prefs: prefs, clock: c),
      location: location ?? const GeolocatorLocation(),
      placeNames: PlaceNames(httpClient),
      khatma: khatma,
      worship: WorshipController(settings, localToday),
      downloads: downloads,
      reminders: reminders,
      sharer: sharer ?? const SystemImageSharer(),
      reelsFeed: ReelsFeedController(
        sources: content.reelSources,
        suggestionPool: content.reelSuggestions,
        httpClient: httpClient,
        prefs: prefs,
        clock: c,
      ),
      media: RecitationMediaBridge(
        recitation: recitation,
        content: content,
        settings: settings,
        session: mediaSession ?? const NoMediaSession(),
        narration: narration,
      ),
      deviceSetup: deviceSetup,
    );
  }

  /// Permission / background status for the first-run setup (see device_setup.dart).
  final DeviceSetup deviceSetup;

  final AppContent content;
  final SettingsController settings;
  final BookmarksController bookmarks;
  final AccountController account;
  final Clock clock;
  final RecitationController recitation;
  final AdhanScheduler adhan;

  /// In-app playback of the adhan recording (settings "listen" button).
  final AdhanPreview adhanPreview;

  /// The muezzin collection and the recordings downloaded from it.
  final AdhanVoiceFiles adhanVoices;
  final TasbihController tasbih;
  final AdhkarController adhkar;
  final CompassSensors sensors;

  /// Tafsir al-Muyassar, loaded on first use.
  final TafsirStore tafsir;

  /// The hadith books, read part by part when opened.
  final HadithLibrary hadith;

  /// Recitations library and Quran radios (mp3quran.net), cached on the device.
  final Mp3QuranClient mp3quran;

  /// Narrated story episodes (audio only) and the sleep timer.
  final NarrationController narration;
  final SleepTimerController sleepTimer;

  /// Device position for "use my location".
  /// Area names for the home screen (OpenStreetMap reverse geocoding).
  final PlaceNames placeNames;
  final LocationProvider location;

  /// Quran khatma plan and history.
  final KhatmaController khatma;

  /// Worship tracker (prayers, fasting, notes per day).
  final WorshipController worship;

  /// Recitations saved for listening offline.
  final RecitationDownloads downloads;

  /// Repeating reminders (khatma portion, adhkar, Friday).
  final ReminderScheduler reminders;

  /// System share sheet for images and text.
  final ImageSharer sharer;

  /// Newest Shorts from the trusted channels (fetched when the reels open).
  final ReelsFeedController reelsFeed;

  /// Lock-screen / notification controls for the recitation (and background playback on Android).
  final RecitationMediaBridge? media;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.services != services;
}

extension ServicesX on BuildContext {
  AppServices get services => AppScope.of(this);
}
