import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../app_services.dart';
import '../domain/hijri.dart';
import '../domain/prayer_schedule.dart';
import '../ui/prayer_model.dart';

/// Feeds the home-screen widget (Android: PrayerWidgetProvider, iOS: PrayerWidget):
/// seven days of prayer times and Hijri dates, so the widget keeps working when
/// the app is not opened. The small widget shows the next prayer, its time and a countdown; the wide
/// one adds the day, both dates and the six times (owner 2026-11-22).
class HomeWidgetSync {
  HomeWidgetSync(this.s);
  final AppServices s;

  static const appGroup = 'group.org.rattil.app';
  static const androidProvider = 'org.rattil.app.PrayerWidgetProvider';

  /// The medium widget (owner 2026-11-20): day, Hijri + Gregorian date, the six times, countdown.
  static const androidMediumProvider = 'org.rattil.app.PrayerWidgetMediumProvider';
  static const iosName = 'PrayerWidget';
  static const days = 7;

  /// Tests replace the platform calls.
  @visibleForTesting
  static Future<void> Function(String key, String value)? debugSave;

  String? _last;

  static const _names = {
    'fajr': ('الفجر', 'Fajr'),
    'dhuhr': ('الظهر', 'Dhuhr'),
    'asr': ('العصر', 'Asr'),
    'maghrib': ('المغرب', 'Maghrib'),
    'isha': ('العشاء', 'Isha'),
  };

  /// The widget data as JSON (also used by the tests).
  String build() {
    final inputs = PrayerInputs.resolve(s.content, s.settings);
    final schedule = PrayerSchedule(s.content.calculator);
    final ar = s.settings.locale.languageCode != 'en';
    final today = PrayerSchedule.localDate(inputs.location, s.clock().toUtc());
    final iqama = s.settings.iqamaPlan;
    final out = <Map<String, Object?>>[];
    for (var i = -1; i < days; i++) {
      final d = today.add(Duration(days: i));
      final day = inputs.day(schedule, d, s.settings.adjustments);
      if (day == null) continue;
      final h = hijriFor(d, arabic: ar);
      out.add({
        'd': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'h': ar ? '${h.day.toString().padLeft(2, '0')} ${h.monthName} ${h.year}' : '${h.day} ${h.monthName} ${h.year}',
        'p': [
          for (final e in _names.entries)
            [e.key, ar ? e.value.$1 : e.value.$2, day.day.utc[e.key]!.millisecondsSinceEpoch],
        ],
        // Sunrise for the medium widget's six times (it is shown, never counted down to).
        'sr': day.day.utc['sunrise']!.millisecondsSinceEpoch,
        // Iqama instants in the order of 'p' (owner 2026-11-22: the widgets count down to the iqama after the adhan).
        if (iqama != null)
          'iq': [
            for (final k in _names.keys) day.day.utc[k]!.add(Duration(minutes: iqama[k] ?? 0)).millisecondsSinceEpoch,
          ],
      });
    }
    // 'pal': the user's colour style, so the widgets use the app's colours (owner 2026-11-22).
    return jsonEncode({
      'v': 1,
      'lang': ar ? 'ar' : 'en',
      'c12': s.settings.clock12,
      'pal': s.settings.palette,
      'days': out,
    });
  }

  /// Writes the data and refreshes the widget when anything changed.
  Future<void> sync({bool force = false}) async {
    try {
      final data = build();
      if (!force && data == _last) return;
      _last = data;
      final save = debugSave;
      if (save != null) {
        await save('rattil.widget', data);
        return;
      }
      if (kIsWeb) return;
      await HomeWidget.setAppGroupId(appGroup);
      await HomeWidget.saveWidgetData<String>('rattil.widget', data);
      await HomeWidget.updateWidget(qualifiedAndroidName: androidProvider, iOSName: iosName);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await HomeWidget.updateWidget(qualifiedAndroidName: androidMediumProvider);
      }
      // Android: redraw at every prayer (the next prayer and the highlight move) and after midnight.
      if (defaultTargetPlatform == TargetPlatform.android) {
        final now = s.clock();
        final prayerTimes = <DateTime>[
          for (final d in (jsonDecode(data)['days'] as List))
            for (final p in (d['p'] as List))
              if ((p[2] as int) > now.millisecondsSinceEpoch) DateTime.fromMillisecondsSinceEpoch(p[2] as int),
          for (final d in (jsonDecode(data)['days'] as List))
            for (final t in (d['iq'] as List? ?? const []))
              if ((t as int) > now.millisecondsSinceEpoch) DateTime.fromMillisecondsSinceEpoch(t),
        ];
        final times = <DateTime>{
          ...prayerTimes,
          for (var d = 1; d <= days; d++) DateTime(now.year, now.month, now.day + d, 0, 0, 5),
        }.toList()..sort();
        await HomeWidget.scheduleWidgetUpdates(times.take(100).toList(), qualifiedAndroidName: androidProvider);
        await HomeWidget.scheduleWidgetUpdates(times.take(100).toList(), qualifiedAndroidName: androidMediumProvider);
      }
    } catch (e) {
      // No widget support (tests, desktop) or no widget placed: nothing to do.
      debugPrint('home widget: $e');
    }
  }
}
