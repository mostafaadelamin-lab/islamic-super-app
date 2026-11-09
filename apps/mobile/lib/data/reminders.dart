import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import 'notifications.dart';

/// Fixed notification ids of the repeating reminders (adhan ids are 9-10 digits).
abstract final class ReminderIds {
  static const khatma = 2001;
  static const adhkarMorning = 2002;
  static const adhkarEvening = 2003;
  static const friday = 2004;
  static const all = [khatma, adhkarMorning, adhkarEvening, friday];
}

/// One repeating reminder: every day at [minutes] after midnight, or weekly on [weekday] (1 = Monday).
class ReminderSpec {
  const ReminderSpec({required this.id, required this.title, required this.body, required this.minutes, this.weekday});
  final int id;
  final String title;
  final String body;
  final int minutes;
  final int? weekday;
}

/// Keeps the repeating reminders (khatma portion, adhkar, Friday) scheduled.
/// Each feature registers a [source] that returns its active reminders.
class ReminderScheduler {
  ReminderScheduler({required this.backend, required this.location, required this.clock, required this.locale});

  final NotificationsBackend backend;

  /// The prayer city's time zone (reminder times are local to it).
  final tz.Location Function() location;
  final DateTime Function() clock;
  final Locale Function() locale;
  final _sources = <List<ReminderSpec> Function(AppLocalizations l)>[];

  void addSource(List<ReminderSpec> Function(AppLocalizations l) source) => _sources.add(source);

  List<ReminderSpec> active() {
    final l = lookupAppLocalizations(locale());
    return [for (final s in _sources) ...s(l)];
  }

  /// Pending notifications the reminders take (one each: they repeat by themselves).
  int get activeCount => active().length;

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
        );
      }
    } catch (e) {
      debugPrint('reminder scheduling failed: $e');
    }
  }
}
