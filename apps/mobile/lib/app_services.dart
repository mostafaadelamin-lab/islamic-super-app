import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'data/account.dart';
import 'data/bookmarks.dart';
import 'data/content.dart';
import 'data/devotions.dart';
import 'data/location.dart';
import 'data/notifications.dart';
import 'data/recitation.dart';
import 'data/sensors.dart';
import 'data/settings.dart';
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
    required this.tasbih,
    required this.adhkar,
    required this.sensors,
    required this.tafsir,
    required this.narration,
    required this.sleepTimer,
    this.location = const GeolocatorLocation(),
  });

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
    LocationProvider? location,
  }) {
    final c = clock ?? DateTime.now;
    final settings = SettingsController(prefs, defaultCityId: content.cities.first.id);
    final bookmarks = BookmarksController(prefs, clock: c);
    DateTime localToday() {
      final city = resolveCity(content, settings);
      return PrayerSchedule.localDate(tz.getLocation(city.tz), c().toUtc());
    }

    final recitation = RecitationController(
      content: content,
      settings: settings,
      backendFactory: audioBackend ?? JustAudioBackend.new,
    );
    final narration = NarrationController(
      settings: settings,
      recitation: recitation,
      backendFactory: narrationBackend ?? JustAudioNarrationBackend.new,
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
        backend: notifications ?? LocalNotificationsBackend(),
        clock: c,
        // Android has no small cap on pending alarms, so a month ahead keeps the
        // adhan going even if the app is not opened; iOS keeps at most 64.
        days: defaultTargetPlatform == TargetPlatform.android ? 30 : 7,
        max: defaultTargetPlatform == TargetPlatform.android ? 150 : 60,
      ),
      adhanPreview: AdhanPreview(adhanPlayer ?? JustAudioAdhanPlayer()),
      tasbih: TasbihController(settings),
      adhkar: AdhkarController(content, settings, localToday),
      sensors: sensors ?? const DeviceCompassSensors(),
      tafsir: tafsir ?? TafsirStore.asset(rootBundle),
      location: location ?? const GeolocatorLocation(),
    );
  }

  final AppContent content;
  final SettingsController settings;
  final BookmarksController bookmarks;
  final AccountController account;
  final Clock clock;
  final RecitationController recitation;
  final AdhanScheduler adhan;

  /// In-app playback of the adhan recording (settings "listen" button).
  final AdhanPreview adhanPreview;
  final TasbihController tasbih;
  final AdhkarController adhkar;
  final CompassSensors sensors;

  /// Tafsir al-Muyassar, loaded on first use.
  final TafsirStore tafsir;

  /// Narrated story episodes (audio only) and the sleep timer.
  final NarrationController narration;
  final SleepTimerController sleepTimer;

  /// Device position for "use my location".
  final LocationProvider location;
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
