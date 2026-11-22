import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../domain/dhikr_reminders.dart';
import 'notifications.dart';

/// Fixed notification ids of the repeating reminders (adhan ids are 9-10 digits).
abstract final class ReminderIds {
  static const khatma = 2001;
  static const adhkarMorning = 2002;
  static const adhkarEvening = 2003;
  static const friday = 2004;

  /// The dhikr reminders take dhikrBase .. dhikrBase + dhikrReminderMaxAndroid - 1.
  static const dhikrBase = 3000;
  static final all = [
    khatma,
    adhkarMorning,
    adhkarEvening,
    friday,
    for (var i = 0; i < dhikrReminderMaxAndroid; i++) dhikrBase + i,
  ];
}

/// One repeating reminder: every day at [minutes] after midnight, or weekly on [weekday] (1 = Monday).
class ReminderSpec {
  const ReminderSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.minutes,
    this.weekday,
    this.sound,
  });
  final int id;

  /// A dhikr clip (res/raw / Runner .caf name) instead of the phone tone.
  final String? sound;
  final String title;
  final String body;
  final int minutes;
  final int? weekday;
}

/// Keeps the repeating reminders (khatma portion, adhkar, Friday) scheduled.
/// Each feature registers a [source] that returns its active reminders.
class ReminderScheduler {
  ReminderScheduler({
    required this.backend,
    required this.location,
    required this.clock,
    required this.locale,
    this.quiet,
  });

  /// Times of day (minutes after midnight, `from` to `to`, may cross midnight) when no reminder rings:
  /// around each adhan until its iqama (owner 2026-11-22). Dhikr reminders there are left out; any other
  /// reminder moves to the end of the quiet time.
  final List<({int from, int to})> Function()? quiet;

  final NotificationsBackend backend;

  /// The prayer city's time zone (reminder times are local to it).
  final tz.Location Function() location;
  final DateTime Function() clock;
  final Locale Function() locale;
  final _sources = <List<ReminderSpec> Function(AppLocalizations l)>[];

  void addSource(List<ReminderSpec> Function(AppLocalizations l) source) => _sources.add(source);

  List<ReminderSpec> active() {
    final l = lookupAppLocalizations(locale());
    return quietened([for (final s in _sources) ...s(l)], quiet?.call() ?? const []);
  }

  /// Pending notifications the reminders take (one each: they repeat by themselves).
  int get activeCount => active().length;

  /// The pending notifications the reminders take from the adhan's share: on Android the
  /// dhikr reminders do not count (no small cap there), on iOS everything counts (64 in all).
  int pendingFor({required bool ios}) => ios ? activeCount : active().where((r) => r.sound == null).length;

  /// Cancels every reminder id, then schedules the active ones.
  Future<void> sync() async {
    try {
      for (final id in ReminderIds.all) {
        await backend.cancel(id);
      }
      await scheduleActive();
    } catch (e) {
      debugPrint('reminder scheduling failed: $e');
    }
  }

  /// Schedules the active reminders (after the adhan scheduler cancelled everything).
  Future<void> scheduleActive() async {
    try {
      final loc = location();
      final now = clock().toUtc();
      for (final r in active()) {
        await backend.scheduleRepeating(
          id: r.id,
          title: r.title,
          body: r.body,
          hour: r.minutes ~/ 60,
          minute: r.minutes % 60,
          location: loc,
          nowUtc: now,
          weekday: r.weekday,
          sound: r.sound,
        );
      }
    } catch (e) {
      debugPrint('reminder scheduling failed: $e');
    }
  }
}

/// [specs] kept out of the [quiet] times: a dhikr reminder (id from [ReminderIds.dhikrBase]) inside one is
/// dropped, any other moves to the minute the quiet time ends.
List<ReminderSpec> quietened(List<ReminderSpec> specs, List<({int from, int to})> quiet) {
  if (quiet.isEmpty) return specs;
  const day = 24 * 60;
  int? endOf(int m) {
    for (final q in quiet) {
      final span = (q.to - q.from) % day;
      if ((m - q.from) % day <= span) return q.to % day;
    }
    return null;
  }

  final out = <ReminderSpec>[];
  for (final r in specs) {
    var end = endOf(r.minutes);
    if (end == null) {
      out.add(r);
      continue;
    }
    if (r.id >= ReminderIds.dhikrBase) continue;
    // Quiet times may touch (Maghrib's iqama close to Isha): move on until outside all of them.
    for (var i = 0; i < quiet.length; i++) {
      final next = endOf((end! + 1) % day);
      if (next == null) break;
      end = next;
    }
    out.add(
      ReminderSpec(
        id: r.id,
        title: r.title,
        body: r.body,
        minutes: (end! + 1) % day,
        weekday: r.weekday,
        sound: r.sound,
      ),
    );
  }
  return out;
}
