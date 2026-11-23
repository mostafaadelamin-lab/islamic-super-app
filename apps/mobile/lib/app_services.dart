import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
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
import 'data/printed_mushaf.dart';
import 'data/adhan_voice_files.dart';
import 'data/adhkar_audio_files.dart';
import 'data/location.dart';
import 'data/place_names.dart';
import 'data/car_browser.dart';
import 'data/carplay.dart';
import 'data/drive_mode.dart';
import 'data/media_session.dart';
import 'data/next_prayer_notice.dart';
import 'data/notifications.dart';
import 'data/recitation.dart';
import 'data/reminders.dart';
import 'domain/dhikr_reminders.dart';
import 'data/reels_feed.dart';
import 'data/sensors.dart';
import 'data/settings.dart';
import 'data/sharing.dart';
import 'data/hadith.dart';
import 'data/mp3quran.dart';
import 'data/tafsir.dart';
import 'data/tafsir_books.dart';
import 'data/word_meanings.dart';
import 'domain/prayer_schedule.dart';
import 'ui/prayer_model.dart' show PrayerInputs, resolveCity;
import 'domain/adhan_schedule.dart' show adhanQuietMinutes;

/// Everything screens need, created once in main() (or in a test).
class AppServices {
  AppServices({
    this.nextPrayer,
    required this.content,
    required this.settings,
    required this.bookmarks,
    required this.account,
    required this.clock,
    required this.recitation,
    required this.adhan,
    required this.adhanPreview,
    required this.dhikrPreview,
    required this.adhanVoices,
    required this.adhkarAudio,
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
    this.drive,
    DeviceSetup? deviceSetup,
    WordMeaningsStore? wordMeanings,
  }) : deviceSetup = deviceSetup ?? PlatformDeviceSetup(),
       wordMeanings = wordMeanings ?? WordMeaningsStore.asset(rootBundle);

  factory AppServices.create({
    required AppContent content,
    required SharedPreferences prefs,
    required http.Client httpClient,
    Clock? clock,
    AudioBackend Function()? audioBackend,
    NarrationBackend Function()? narrationBackend,
    NotificationsBackend? notifications,
    AdhanPlayer? adhanPlayer,
    AdhanSoundParts? adhanParts,
    CompassSensors? sensors,
    TafsirStore? tafsir,
    HadithLibrary? hadith,
    LocationProvider? location,
    ImageSharer? sharer,
    Future<Directory> Function()? storageRoot,
    Duration adhanRetryDelay = const Duration(seconds: 2),
    MediaSession? mediaSession,
    DeviceSetup? deviceSetup,
    WordMeaningsStore? wordMeanings,
    DrivePlayer Function()? drivePlayer,
    DriveCues Function()? driveCues,
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
      // Owner 2026-11-22: no other reminder from 10 minutes before each adhan until its iqama.
      quiet: () {
        final prayers = settings.adhanPrayers;
        if (prayers.isEmpty) return const [];
        final inputs = PrayerInputs.resolve(content, settings);
        final today = inputs.day(PrayerSchedule(content.calculator), localToday(), settings.adjustments);
        if (today == null) return const [];
        final iqama = settings.iqamaPlan;
        // A few minutes more each side: the repeating reminders keep their time for days while the prayer
        // times move a little every day.
        const drift = 3;
        return [
          for (final p in obligatoryPrayers)
            if (prayers.contains(p))
              (
                from: _minuteOfDay(today.local(p)) - adhanQuietMinutes - drift,
                to: _minuteOfDay(today.local(p)) + (iqama?[p] ?? adhanQuietMinutes) + drift,
              ),
        ];
      },
    );
    final khatma = KhatmaController(settings, localToday, onReminderChanged: reminders.sync);
    // iPhone (owner 2026-11-22): the adhan with its alerts takes its share of the 64 first.
    AdhanScheduler? adhanRef;
    int dhikrMax() => defaultTargetPlatform == TargetPlatform.iOS
        ? dhikrReminderMaxFor(iosCap: 60, adhanNeed: adhanRef?.iosNeed ?? 0)
        : dhikrReminderMaxAndroid;
    reminders.addSource((l) {
      if (!settings.dhikrRemindersOn) return const [];
      final items = [for (final id in settings.dhikrReminderIds) ?findDhikrReminder(id)];
      if (items.isEmpty) return const [];
      final plan = planDhikrSlots(
        from: settings.dhikrRemindersFrom,
        to: settings.dhikrRemindersTo,
        every: settings.dhikrRemindersEvery,
        max: dhikrMax(),
      );
      return [
        for (var i = 0; i < plan.slots.length; i++)
          ReminderSpec(
            id: ReminderIds.dhikrBase + i,
            title: l.dhikrRemNotifTitle,
            body: content.adhkar.items[items[i % items.length].index].text,
            minutes: plan.slots[i],
            sound: items[i % items.length].sound,
          ),
      ];
    });

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
    PrintedMushaf.instance.configure(client: httpClient, root: storageRoot ?? getApplicationSupportDirectory);
    TafsirBooks.instance.configure(
      client: httpClient,
      root: storageRoot ?? getApplicationSupportDirectory,
      ayahCounts: [for (final s in content.quran.surahs) s.ayahCount],
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
    final adhkarAudio = AdhkarAudioFiles(
      httpClient: httpClient,
      root: storageRoot ?? getApplicationSupportDirectory,
      retryDelay: adhanRetryDelay,
    );
    final media = RecitationMediaBridge(
      recitation: recitation,
      content: content,
      settings: settings,
      session: mediaSession ?? const NoMediaSession(),
      narration: narration,
    );
    final drive = DriveModeController(
      content: content,
      settings: settings,
      files: adhkarAudio,
      clips: DriveModeController.assetClips(rootBundle),
      player: drivePlayer,
      cues: driveCues,
    );
    media.attach(drive);
    final mp3quran = Mp3QuranClient(httpClient: httpClient, prefs: prefs, clock: c);
    if (mediaSession case final AudioServiceMediaSession a) {
      // The car screen: driving mode for the adhkar + radio, library, al-Sha'rawi, stories, nasheeds.
      final browser = CarBrowser(
        drive: drive,
        narration: narration,
        settings: settings,
        content: content,
        library: mp3quran,
      );
      a.browser = browser; // Android Auto
      if (defaultTargetPlatform == TargetPlatform.iOS) CarPlayBridge(browser, settings); // CarPlay
    }
    // Android: the next prayer on the lock screen, planned again after every adhan re-plan (which cancels
    // every notification).
    final nextPrayer = NextPrayerNotice.supported
        ? NextPrayerNotice(content: content, settings: settings, clock: c, ready: backend.init)
        : null;
    return AppServices(
      nextPrayer: nextPrayer,
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
      adhan: adhanRef = AdhanScheduler(
        content: content,
        settings: settings,
        backend: backend,
        reserved: () => reminders.pendingFor(ios: defaultTargetPlatform == TargetPlatform.iOS),
        afterReset: () async {
          await reminders.scheduleActive();
          await nextPrayer?.sync(force: true);
        },
        clock: c,
        // Android has no small cap on pending alarms, so a month ahead keeps the
        // adhan going even if the app is not opened; iOS keeps at most 64.
        days: defaultTargetPlatform == TargetPlatform.android ? 30 : 7,
        max: defaultTargetPlatform == TargetPlatform.android ? 150 : 60,
        voices: adhanVoices,
        // iPhone: the whole adhan rings as notifications back to back (or as an iOS 26 alarm).
        parts: adhanParts ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? NativeAdhanSoundParts() : null),
      ),
      adhanPreview: AdhanPreview(adhanPlayer ?? JustAudioAdhanPlayer(), source: adhanVoices.playable),
      dhikrPreview: AdhanPreview(
        adhanPlayer ?? JustAudioAdhanPlayer(),
        source: (id) async => findDhikrReminder(id)?.asset,
      ),
      adhanVoices: adhanVoices,
      adhkarAudio: adhkarAudio,
      tasbih: TasbihController(settings),
      adhkar: AdhkarController(content, settings, localToday),
      sensors: sensors ?? const DeviceCompassSensors(),
      tafsir: tafsir ?? TafsirStore.asset(rootBundle),
      hadith: hadith ?? HadithLibrary.asset(content.hadith, rootBundle),
      mp3quran: mp3quran,
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
      media: media,
      drive: drive,
      deviceSetup: deviceSetup,
      wordMeanings: wordMeanings,
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

  /// Android: the next prayer and its countdown on the lock screen (null in tests).
  final NextPrayerNotice? nextPrayer;

  /// In-app playback of the adhan recording (settings "listen" button).
  final AdhanPreview adhanPreview;

  /// The "listen" buttons of the dhikr reminders screen (ids from domain/dhikr_reminders.dart).
  final AdhanPreview dhikrPreview;

  /// The muezzin collection and the recordings downloaded from it.
  final AdhanVoiceFiles adhanVoices;

  /// Alafasy's morning / evening adhkar recordings, downloaded on first play.
  final AdhkarAudioFiles adhkarAudio;
  final TasbihController tasbih;
  final AdhkarController adhkar;
  final CompassSensors sensors;

  /// Tafsir al-Muyassar, loaded on first use.
  final TafsirStore tafsir;

  /// «معاني الكلمات» (السراج في بيان غريب القرآن), loaded on first use.
  final WordMeaningsStore wordMeanings;

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

  /// Driving mode for the morning / evening adhkar (counts out loud, car-screen controls).
  final DriveModeController? drive;
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

int _minuteOfDay(DateTime t) => t.hour * 60 + t.minute;
