// Which prayer notifications to schedule (pure logic; the plugin call lives in
// lib/data/notifications.dart): the adhan itself, an optional reminder some
// minutes before it, and an optional iqama alert some minutes after it.
import 'prayer_schedule.dart';

/// Kinds of prayer notification.
const adhanKind = 'adhan';
const preAdhanKind = 'pre';
const iqamaKind = 'iqama';
const sunriseKind = 'sunrise';

/// Start of the last third of the night (Maghrib to the next Fajr).
const lastThirdKind = 'lastThird';

/// Minutes offered for the reminder before the adhan (0 = off).
const preAdhanChoices = [0, 5, 10, 15, 20, 30];

/// The reminder before the adhan until the user changes it (owner 2026-11-22).
const defaultPreAdhanMinutes = 10;

/// Around each adhan the app sends none of its other reminders (owner 2026-11-22): from this many
/// minutes before it until the iqama (or this many minutes after it when the iqama alert is off).
const adhanQuietMinutes = 10;

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
    this.parts = 1,
  });

  /// Stable id (see [adhanNotificationId]) so re-planning the same day replaces
  /// the same notification instead of duplicating it.
  final int id;
  final String prayer;

  /// UTC instant the notification rings.
  final DateTime at;

  /// Local calendar date (y/m/d only).
  final DateTime date;

  /// [adhanKind], [preAdhanKind], [iqamaKind], [sunriseKind] or [lastThirdKind].
  final String kind;

  /// Minutes before ([preAdhanKind]) or after ([iqamaKind]) the adhan.
  final int minutes;

  /// iPhone: notifications this alert takes (the full adhan rings as several, back to back; 0 = it rings
  /// as a system alarm instead). Always 1 for the other kinds and on Android.
  final int parts;

  AdhanNotification withParts(int n) =>
      AdhanNotification(id: id, prayer: prayer, at: at, date: date, kind: kind, minutes: minutes, parts: n);

  @override
  String toString() => 'AdhanNotification($id, $kind, $prayer, $at${parts == 1 ? '' : ', parts $parts'})';
}

/// Adhan ids keep their original form yyyymmdd * 10 + prayer index (9 digits);
/// reminders and iqama alerts use yyyymmdd * 100 + 10/20 + prayer index (10
/// digits), so the ranges never overlap. All stay below 2^31.
int adhanNotificationId(DateTime date, String prayer, {String kind = adhanKind}) {
  final i = obligatoryPrayers.indexOf(prayer);
  if (i < 0 && kind != sunriseKind && kind != lastThirdKind) throw ArgumentError('not an obligatory prayer: $prayer');
  final ymd = date.year * 10000 + date.month * 100 + date.day;
  return switch (kind) {
    sunriseKind => (ymd * 100 + 30) % 0x7fffffff,
    lastThirdKind => (ymd * 100 + 31) % 0x7fffffff,
    preAdhanKind => (ymd * 100 + 10 + i) % 0x7fffffff,
    iqamaKind => (ymd * 100 + 20 + i) % 0x7fffffff,
    _ => (ymd * 10 + i) % 0x7fffffff,
  };
}

/// Start of the last third of the night between [maghrib] and the next [fajr].
DateTime lastThirdStart(DateTime maghrib, DateTime fajr) {
  final night = fajr.difference(maghrib);
  return maghrib.add(Duration(seconds: night.inSeconds * 2 ~/ 3));
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
  bool sunrise = false,
  bool lastThird = false,
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
    if (sunrise) {
      add(
        AdhanNotification(
          id: adhanNotificationId(date, 'sunrise', kind: sunriseKind),
          prayer: 'sunrise',
          at: d.day.utc['sunrise']!,
          date: date,
          kind: sunriseKind,
        ),
      );
    }
    if (lastThird) {
      // The night of [date] runs from its Maghrib to the next day's Fajr.
      final next = dayFor(DateTime.utc(date.year, date.month, date.day + 1));
      if (next != null) {
        add(
          AdhanNotification(
            id: adhanNotificationId(date, 'isha', kind: lastThirdKind),
            prayer: 'isha',
            at: lastThirdStart(d.day.utc['maghrib']!, next.day.utc['fajr']!),
            date: date,
            kind: lastThirdKind,
          ),
        );
      }
    }
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

/// iPhone: the id of part [k] (1-based after the first) of the full adhan whose first notification is
/// [adhanId]. iOS plays at most 30 s of a notification sound, so the whole adhan rings as notifications
/// back to back (part 0 keeps the adhan's own id). Ids yyyymmdd * 100 + 40..99 are free (reminders use
/// 10..31), five prayers x [maxAdhanParts] parts; the "try it now" notification (id 1) uses 120 + k.
int adhanPartId(int adhanId, int k) {
  if (k < 1 || k >= maxAdhanParts) throw RangeError.range(k, 1, maxAdhanParts - 1, 'k');
  if (adhanId < 1000) return 100 + adhanId * 20 + k;
  final ymd = adhanId ~/ 10;
  final i = adhanId % 10;
  return (ymd * 100 + 40 + i * maxAdhanParts + (k - 1)) % 0x7fffffff;
}

/// Most notifications one full adhan may take on iPhone (12 x up to 29 s = almost 6 minutes).
const maxAdhanParts = 12;

/// iPhone: fits the full adhans into the [max] pending notifications iOS allows. [all] is the plan for every
/// day (sorted, not capped); [partsFor] gives how many notifications [prayer]'s adhan takes (1 = the first
/// 30 s only, 0 = it rings as a system alarm and takes no notification). The adhans of the next [keep] are
/// upgraded to the full adhan, earliest first, as long as every alert of that window still fits; later days
/// fill what is left with the first 30 s only (the app renews the plan every time it opens).
/// Returns the alerts with [AdhanNotification.parts] set.
List<AdhanNotification> fitFullAdhan(
  List<AdhanNotification> all, {
  required int Function(String prayer) partsFor,
  required DateTime nowUtc,
  int max = 60,
  Duration keep = const Duration(hours: 48),
}) {
  int full(AdhanNotification n) => n.kind == adhanKind ? partsFor(n.prayer).clamp(0, maxAdhanParts) : 1;
  int one(AdhanNotification n) => n.kind == adhanKind && full(n) == 0 ? 0 : 1;
  final until = nowUtc.add(keep);
  final window = [
    for (final n in all)
      if (n.at.isBefore(until)) n,
  ];
  var used = window.fold<int>(0, (s, n) => s + one(n));
  final upgraded = <int>{};
  for (final n in window) {
    final extra = full(n) - one(n);
    if (extra <= 0) continue;
    if (used + extra > max) break;
    used += extra;
    upgraded.add(n.id);
  }
  final out = <AdhanNotification>[];
  var total = 0;
  for (final n in all) {
    final want = upgraded.contains(n.id) ? full(n) : one(n);
    if (total + want > max) break;
    out.add(n.withParts(want));
    total += want;
  }
  return out;
}
