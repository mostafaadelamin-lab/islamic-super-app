import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/prayer_schedule.dart';
import '../l10n/app_localizations.dart';
import '../ui/prayer_model.dart';
import 'content.dart';
import 'settings.dart';

/// One state of the lock-screen notice: shown at [showAt] (null = now), counting down to [next].
class NextPrayerSlot {
  const NextPrayerSlot({
    required this.id,
    required this.showAt,
    required this.next,
    required this.title,
    required this.body,
  });
  final int id;
  final DateTime? showAt;
  final DateTime next;
  final String title;
  final String body;
}

/// Android (owner 2026-11-21): phones have no lock-screen widgets, so a quiet notification that stays on
/// the lock screen shows the next prayer, its time, a live countdown (the system counts it) and that day's
/// five times. One is shown now; one more is scheduled at each prayer of the next [days] days, each removing
/// itself ([AndroidNotificationDetails.timeoutAfter]) when the next one appears. Ids [firstId]... are
/// re-planned with the adhan (which cancels every notification first) and whenever the inputs change.
class NextPrayerNotice {
  NextPrayerNotice({required this.content, required this.settings, required this.clock, this.ready, this.days = 7});

  /// Initialises the notifications plugin (the adhan backend's init) before the first notice.
  final Future<void> Function()? ready;

  final AppContent content;
  final SettingsController settings;
  final DateTime Function() clock;
  final int days;

  static const firstId = 4099;
  static const maxSlots = 60;

  final _plugin = FlutterLocalNotificationsPlugin();
  String? _last;

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _names = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// The notices to show (pure; tests call it).
  List<NextPrayerSlot> plan() {
    if (!settings.lockNotice) return const [];
    final l = lookupAppLocalizations(Locale(settings.locale.languageCode));
    final ar = settings.isArabic;
    final inputs = PrayerInputs.resolve(content, settings);
    final schedule = PrayerSchedule(content.calculator);
    final now = clock().toUtc();
    final today = PrayerSchedule.localDate(inputs.location, now);
    final times = <(String, DateTime, LocalPrayerDay)>[];
    for (var i = 0; i < days + 1; i++) {
      final d = inputs.day(schedule, today.add(Duration(days: i)), settings.adjustments);
      if (d == null) continue;
      for (final p in _names) {
        times.add((p, d.day.utc[p]!, d));
      }
    }
    String name(String p) => switch (p) {
      'fajr' => l.prayerFajr,
      'dhuhr' => l.prayerDhuhr,
      'asr' => l.prayerAsr,
      'maghrib' => l.prayerMaghrib,
      _ => l.prayerIsha,
    };
    String clockOf(DateTime t) =>
        formatClock(tz.TZDateTime.from(t, inputs.location), h12: settings.clock12, arabic: ar);
    NextPrayerSlot slot(int id, DateTime? at, (String, DateTime, LocalPrayerDay) n) => NextPrayerSlot(
      id: id,
      showAt: at,
      next: n.$2,
      title: l.lockNoticeTitle(name(n.$1), clockOf(n.$2)),
      body: [for (final p in _names) '${name(p)} ${n.$3.clock(p, h12: settings.clock12, arabic: ar)}'].join(' · '),
    );
    final out = <NextPrayerSlot>[];
    final upcoming = [
      for (final t in times)
        if (t.$2.isAfter(now)) t,
    ];
    if (upcoming.isEmpty) return out;
    out.add(slot(firstId, null, upcoming.first));
    for (var i = 0; i + 1 < upcoming.length && out.length < maxSlots; i++) {
      // At each prayer, the countdown moves on to the one after it.
      out.add(slot(firstId + 1 + i, upcoming[i].$2, upcoming[i + 1]));
    }
    return out;
  }

  /// Shows and schedules the notices when anything changed (or when [force]).
  Future<void> sync({bool force = false}) async {
    if (!supported) return;
    try {
      await ready?.call();
      final slots = plan();
      final sig = [for (final s in slots) '${s.id}|${s.showAt}|${s.next}|${s.title}|${s.body}'].join('\n');
      if (!force && sig == _last) return;
      _last = sig;
      for (var id = firstId; id <= firstId + maxSlots; id++) {
        await _plugin.cancel(id: id);
      }
      final now = clock().toUtc();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      for (final s in slots) {
        final from = s.showAt ?? now;
        final details = NotificationDetails(android: _details(s.next, s.next.difference(from)));
        if (s.showAt == null) {
          await _plugin.show(id: s.id, title: s.title, body: s.body, notificationDetails: details);
        } else {
          await _plugin.zonedSchedule(
            id: s.id,
            title: s.title,
            body: s.body,
            scheduledDate: tz.TZDateTime.from(s.showAt!, tz.UTC),
            notificationDetails: details,
            androidScheduleMode: exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    } catch (e) {
      _last = null;
      debugPrint('next prayer notice: $e');
    }
  }

  static AndroidNotificationDetails _details(DateTime next, Duration until) => AndroidNotificationDetails(
    'next_prayer',
    'الصلاة القادمة · Next prayer',
    channelDescription: 'The next prayer and the time left, on the lock screen',
    importance: Importance.low,
    priority: Priority.low,
    playSound: false,
    enableVibration: false,
    silent: true,
    onlyAlertOnce: true,
    ongoing: true,
    autoCancel: false,
    showWhen: true,
    when: next.millisecondsSinceEpoch,
    usesChronometer: true,
    chronometerCountDown: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.status,
    // Gone when the next notice (at that prayer) takes over.
    timeoutAfter: until.inMilliseconds + 1000,
  );
}
