// Which adhan notifications to schedule (pure logic; the plugin call lives in
// lib/data/notifications.dart).
import 'prayer_schedule.dart';

class AdhanNotification {
  const AdhanNotification({required this.id, required this.prayer, required this.at, required this.date});

  /// Stable id: yyyymmdd * 10 + prayer index, mod 2^31 (so re-planning the same
  /// day replaces the same notification instead of duplicating it).
  final int id;
  final String prayer;

  /// UTC instant of the prayer.
  final DateTime at;

  /// Local calendar date (y/m/d only).
  final DateTime date;

  @override
  String toString() => 'AdhanNotification($id, $prayer, $at)';
}

int adhanNotificationId(DateTime date, String prayer) {
  final i = obligatoryPrayers.indexOf(prayer);
  if (i < 0) throw ArgumentError('not an obligatory prayer: $prayer');
  final ymd = date.year * 10000 + date.month * 100 + date.day;
  return (ymd * 10 + i) % 0x7fffffff;
}

/// Plans notifications for the five prayers on [days] consecutive local dates
/// starting at [today], keeping only prayers in [enabled] that are strictly
/// after [nowUtc]. [dayFor] returns that date's times, or null when they
/// cannot be calculated (polar day/night), in which case the day is skipped.
/// The result is sorted by time and capped at [max] (iOS keeps at most 64
/// pending notifications per app).
List<AdhanNotification> planAdhanNotifications({
  required DateTime nowUtc,
  required DateTime today,
  required Set<String> enabled,
  required LocalPrayerDay? Function(DateTime date) dayFor,
  int days = 7,
  int max = 60,
}) {
  final out = <AdhanNotification>[];
  if (enabled.isEmpty) return out;
  for (var i = 0; i < days; i++) {
    final date = DateTime.utc(today.year, today.month, today.day + i);
    final d = dayFor(date);
    if (d == null) continue;
    for (final p in obligatoryPrayers) {
      if (!enabled.contains(p)) continue;
      final at = d.day.utc[p]!;
      if (!at.isAfter(nowUtc)) continue;
      out.add(AdhanNotification(id: adhanNotificationId(date, p), prayer: p, at: at, date: date));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > max ? out.sublist(0, max) : out;
}
