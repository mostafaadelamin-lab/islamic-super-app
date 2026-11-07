import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/adhan_schedule.dart';
import '../domain/prayer_schedule.dart';
import '../l10n/app_localizations.dart';
import '../ui/prayer_model.dart';
import 'content.dart';
import 'settings.dart';

/// What the adhan scheduler needs from a notification plugin.
abstract class NotificationsBackend {
  Future<void> init();

  /// Asks the user (Android 13+ / iOS); true when notifications are allowed.
  Future<bool> requestPermission();
  Future<void> cancelAll();
  Future<void> schedule({required int id, required String title, required String body, required DateTime atUtc});
}

class LocalNotificationsBackend implements NotificationsBackend {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _exact = false;

  static const _channel = AndroidNotificationDetails(
    'adhan',
    'Adhan',
    channelDescription: 'Prayer time notifications',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    _exact = await android?.canScheduleExactNotifications() ?? false;
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission() ?? false;
      if (ok && !_exact) {
        // Exact alarms keep the adhan on the minute; without them Android may delay it.
        await android.requestExactAlarmsPermission();
        _exact = await android.canScheduleExactNotifications() ?? false;
      }
      return ok;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true, badge: false) ?? false;
    return false;
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> schedule({required int id, required String title, required String body, required DateTime atUtc}) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(atUtc, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: _exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

/// Keeps the scheduled adhan notifications in line with the settings: the
/// next [days] days for the enabled prayers of the selected city.
class AdhanScheduler {
  AdhanScheduler({
    required this.content,
    required this.settings,
    required this.backend,
    required this.clock,
    this.days = 7,
  });

  final AppContent content;
  final SettingsController settings;
  final NotificationsBackend backend;
  final DateTime Function() clock;
  final int days;
  String? _lastSignature;
  List<AdhanNotification> _lastPlan = const [];

  List<AdhanNotification> get lastPlan => _lastPlan;

  String get _signature => [
    settings.adhanPrayers.toList()..sort(),
    settings.cityId,
    settings.method,
    settings.asr,
    settings.adjustments,
    settings.locale.languageCode,
    PrayerSchedule.localDate(tz.UTC, clock().toUtc()),
  ].join('|');

  /// Plans with the same inputs as the prayer screen.
  List<AdhanNotification> plan() {
    final enabled = settings.adhanPrayers;
    if (enabled.isEmpty) return const [];
    final ctx = PrayerInputs.resolve(content, settings);
    final schedule = PrayerSchedule(content.calculator);
    final now = clock().toUtc();
    return planAdhanNotifications(
      nowUtc: now,
      today: PrayerSchedule.localDate(ctx.location, now),
      enabled: enabled,
      days: days,
      dayFor: (d) => ctx.day(schedule, d, settings.adjustments),
    );
  }

  /// Re-plans when anything relevant changed (or when [force]).
  Future<void> sync({bool force = false}) async {
    if (!settings.adhanConfigured) return;
    final sig = _signature;
    if (!force && sig == _lastSignature) return;
    _lastSignature = sig;
    try {
      final items = plan();
      _lastPlan = items;
      await backend.cancelAll();
      if (items.isEmpty) return;
      final l = lookupAppLocalizations(Locale(settings.locale.languageCode));
      final city = (content.city(settings.cityId) ?? content.cities.first).name(settings.isArabic);
      for (final n in items) {
        final name = _prayerName(l, n.prayer);
        await backend.schedule(id: n.id, title: l.adhanTitle(name), body: l.adhanBody(name, city), atUtc: n.at);
      }
    } catch (e) {
      // A plugin failure must never break the app; the next sync retries.
      _lastSignature = null;
      debugPrint('adhan scheduling failed: $e');
    }
  }

  static String _prayerName(AppLocalizations l, String key) => switch (key) {
    'fajr' => l.prayerFajr,
    'dhuhr' => l.prayerDhuhr,
    'asr' => l.prayerAsr,
    'maghrib' => l.prayerMaghrib,
    _ => l.prayerIsha,
  };
}
