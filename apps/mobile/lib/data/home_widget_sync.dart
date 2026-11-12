import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../app_services.dart';
import '../domain/hijri.dart';
import '../domain/prayer_schedule.dart';
import '../ui/prayer_model.dart';

/// Feeds the home-screen widget (Android: PrayerWidgetProvider, iOS: PrayerWidget):
/// seven days of prayer times and Hijri dates, so the widget keeps working when
/// the app is not opened. The widget itself shows the clock, the next prayer and a
/// countdown ring that fills from the previous prayer to the next one.
class HomeWidgetSync {
  HomeWidgetSync(this.s);
  final AppServices s;

  static const appGroup = 'group.org.rattil.app';
  static const androidProvider = 'org.rattil.app.PrayerWidgetProvider';
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
      });
    }
    return jsonEncode({'v': 1, 'lang': ar ? 'ar' : 'en', 'days': out});
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
      // Android: redraw at every prayer (next prayer + ring) and every 10 minutes (ring).
      if (defaultTargetPlatform == TargetPlatform.android) {
        final now = s.clock();
        final times = <DateTime>{
          for (var m = 10; m <= 24 * 60; m += 10) now.add(Duration(minutes: m)),
          for (final d in (jsonDecode(data)['days'] as List))
            for (final p in (d['p'] as List))
              if ((p[2] as int) > now.millisecondsSinceEpoch) DateTime.fromMillisecondsSinceEpoch(p[2] as int),
        }.toList()..sort();
        await HomeWidget.scheduleWidgetUpdates(times.take(200).toList(), qualifiedAndroidName: androidProvider);
      }
    } catch (e) {
      // No widget support (tests, desktop) or no widget placed: nothing to do.
      debugPrint('home widget: $e');
    }
  }
}
