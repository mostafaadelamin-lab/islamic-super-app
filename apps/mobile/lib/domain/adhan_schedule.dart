// Which prayer notifications to schedule (pure logic; the plugin call lives in
// lib/data/notifications.dart): the adhan itself, an optional reminder some
// minutes before it, and an optional iqama alert some minutes after it.
import 'prayer_schedule.dart';

/// Kinds of prayer notification.
const adhanKind = 'adhan';
const preAdhanKind = 'pre';
const iqamaKind = 'iqama';

/// Minutes offered for the reminder before the adhan (0 = off).
const preAdhanChoices = [0, 5, 10, 15, 20, 30];

/// Minutes allowed between the adhan and the iqama.
const minIqama = 1;
const maxIqama = 60;

/// Usual waits between adhan and iqama in mosques; the user changes them to match their mosque.
const defaultIqamaMinutes = {'fajr': 20, 'dhuhr': 15, 'asr': 15, 'maghrib': 10, 'isha': 15};

class AdhanNotification {
  const AdhanNotification({
    required this.id,
    required this.prayer,
    required this.at,
    required this.date,
    this.kind = adhanKind,
    this.minutes = 0,
  });

  /// Stable id (see [adhanNotificationId]) so re-planning the same day replaces
  /// the same notification instead of duplicating it.
  final int id;
  final String prayer;

  /// UTC instant the notification rings.
  final DateTime at;

  /// Local calendar date (y/m/d only).
  final DateTime date;

  /// [adhanKind], [preAdhanKind] or [iqamaKind].
  final String kind;

  /// Minutes before ([preAdhanKind]) or after ([iqamaKind]) the adhan.
  final int minutes;

  @override
  String toString() => 'AdhanNotification($id, $kind, $prayer, $at)';
}

/// Adhan ids keep their original form yyyymmdd * 10 + prayer index (9 digits);
/// reminders and iqama alerts use yyyymmdd * 100 + 10/20 + prayer index (10
/// digits), so the ranges never overlap. All stay below 2^31.
int adhanNotificationId(DateTime date, String prayer, {String kind = adhanKind}) {
  final i = obligatoryPrayers.indexOf(prayer);
  if (i < 0) throw ArgumentError('not an obligatory prayer: $prayer');
  final ymd = date.year * 10000 + date.month * 100 + date.day;
  return switch (kind) {
    preAdhanKind => (ymd * 100 + 10 + i) % 0x7fffffff,
    iqamaKind => (ymd * 100 + 20 + i) % 0x7fffffff,
    _ => (ymd * 10 + i) % 0x7fffffff,
  };
}

int clampIqama(int v) => v < minIqama ? minIqama : (v > maxIqama ? maxIqama : v);

/// Plans notifications for the five prayers on [days] consecutive local dates
/// starting at [today], keeping only prayers in [enabled] and instants strictly
/// after [nowUtc]. [dayFor] returns that date's times, or null when they
/// cannot be calculated (polar day/night), in which case the day is skipped.
/// With [preMinutes] > 0 a reminder rings that long before each adhan; with
/// [iqama] set, an iqama alert rings the given minutes after it.
/// The result is sorted by time and capped at [max]: iOS keeps at most 64
/// pending notifications per app, and all kinds share that one budget (more
/// kinds simply means fewer days ahead).
List<AdhanNotification> planAdhanNotifications({
  required DateTime nowUtc,
  required DateTime today,
  required Set<String> enabled,
  required LocalPrayerDay? Function(DateTime date) dayFor,
  int days = 7,
  int max = 60,
  int preMinutes = 0,
  Map<String, int>? iqama,
}) {
  final out = <AdhanNotification>[];
  if (enabled.isEmpty) return out;
  void add(AdhanNotification n) {
    if (n.at.isAfter(nowUtc)) out.add(n);
  }

  for (var i = 0; i < days; i++) {
    final date = DateTime.utc(today.year, today.month, today.day + i);
    final d = dayFor(date);
    if (d == null) continue;
    for (final p in obligatoryPrayers) {
      if (!enabled.contains(p)) continue;
      final at = d.day.utc[p]!;
      add(AdhanNotification(id: adhanNotificationId(date, p), prayer: p, at: at, date: date));
      if (preMinutes > 0) {
        add(
          AdhanNotification(
            id: adhanNotificationId(date, p, kind: preAdhanKind),
            prayer: p,
            at: at.subtract(Duration(minutes: preMinutes)),
            date: date,
            kind: preAdhanKind,
            minutes: preMinutes,
          ),
        );
      }
      if (iqama != null) {
        final m = clampIqama(iqama[p] ?? defaultIqamaMinutes[p]!);
        add(
          AdhanNotification(
            id: adhanNotificationId(date, p, kind: iqamaKind),
            prayer: p,
            at: at.add(Duration(minutes: m)),
            date: date,
            kind: iqamaKind,
            minutes: m,
          ),
        );
      }
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > max ? out.sublist(0, max) : out;
}
