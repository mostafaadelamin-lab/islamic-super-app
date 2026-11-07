import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'data/account.dart';
import 'data/bookmarks.dart';
import 'data/content.dart';
import 'data/devotions.dart';
import 'data/notifications.dart';
import 'data/recitation.dart';
import 'data/sensors.dart';
import 'data/settings.dart';
import 'data/tafsir.dart';
import 'domain/prayer_schedule.dart';

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
    required this.tasbih,
    required this.adhkar,
    required this.sensors,
    required this.tafsir,
  });

  factory AppServices.create({
    required AppContent content,
    required SharedPreferences prefs,
    required http.Client httpClient,
    Clock? clock,
    AudioBackend Function()? audioBackend,
    NotificationsBackend? notifications,
    CompassSensors? sensors,
    TafsirStore? tafsir,
  }) {
    final c = clock ?? DateTime.now;
    final settings = SettingsController(prefs, defaultCityId: content.cities.first.id);
    final bookmarks = BookmarksController(prefs, clock: c);
    DateTime localToday() {
      final city = content.city(settings.cityId) ?? content.cities.first;
      return PrayerSchedule.localDate(tz.getLocation(city.tz), c().toUtc());
    }

    return AppServices(
      content: content,
      settings: settings,
      bookmarks: bookmarks,
      account: AccountController(prefs, settings, bookmarks, httpClient, clock: c),
      clock: c,
      recitation: RecitationController(
        content: content,
        settings: settings,
        backendFactory: audioBackend ?? JustAudioBackend.new,
      ),
      adhan: AdhanScheduler(
        content: content,
        settings: settings,
        backend: notifications ?? LocalNotificationsBackend(),
        clock: c,
      ),
      tasbih: TasbihController(settings),
      adhkar: AdhkarController(content, settings, localToday),
      sensors: sensors ?? const DeviceCompassSensors(),
      tafsir: tafsir ?? TafsirStore.asset(rootBundle),
    );
  }

  final AppContent content;
  final SettingsController settings;
  final BookmarksController bookmarks;
  final AccountController account;
  final Clock clock;
  final RecitationController recitation;
  final AdhanScheduler adhan;
  final TasbihController tasbih;
  final AdhkarController adhkar;
  final CompassSensors sensors;

  /// Tafsir al-Muyassar, loaded on first use.
  final TafsirStore tafsir;
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
