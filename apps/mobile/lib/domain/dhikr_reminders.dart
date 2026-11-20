/// «تنبيهات الأذكار» (owner 2026-11-20): short adhkar the user picks, shown every N minutes
/// between two times of the day. The notification sound is the dhikr itself, one reading by
/// Sheikh Mishary Alafasy cut from the morning adhkar recording (tools/dhikr_reminder_clips.py),
/// so the phone says it aloud when the ringer is on and only shows it when the phone is silent.
library;

import 'dart:math' as math;

class DhikrReminderItem {
  const DhikrReminderItem(this.id, this.index);

  final String id;

  /// Index of the text in adhkar.v1.json (Hisn al-Muslim wording).
  final int index;

  /// Android res/raw name and iOS `Runner/<sound>.caf` (both cut by tools/dhikr_reminder_clips.py).
  String get sound => 'dhikr_$id';

  /// The in-app "listen" clip.
  String get asset => 'assets/audio/dhikr/dhikr_$id.m4a';
}

/// Every dhikr here has a recorded clip; keep in step with tools/dhikr_reminder_clips.py and web lib/dhikr-reminders.ts.
const dhikrReminderItems = [
  DhikrReminderItem('salat', 28), // اللهم صل وسلم على نبينا محمد
  DhikrReminderItem('subhan', 33), // سبحان الله وبحمده
  DhikrReminderItem('istighfar', 32), // أستغفر الله وأتوب إليه
  DhikrReminderItem('tahlil', 27), // لا إله إلا الله وحده لا شريك له...
  DhikrReminderItem('hasbi', 16), // حسبي الله لا إله إلا هو...
  DhikrReminderItem('subhanadad', 30), // سبحان الله وبحمده عدد خلقه...
  DhikrReminderItem('hayy', 21), // يا حي يا قيوم برحمتك أستغيث...
  DhikrReminderItem('radeetu', 20), // رضيت بالله ربا...
];

DhikrReminderItem? findDhikrReminder(String id) {
  for (final d in dhikrReminderItems) {
    if (d.id == id) return d;
  }
  return null;
}

const defaultDhikrReminderIds = ['salat', 'subhan', 'istighfar'];

/// The interval choices on the screen (minutes); any other value is a custom one.
const dhikrReminderIntervals = [15, 30, 60, 120];
const dhikrReminderMinEvery = 5;
const dhikrReminderMaxEvery = 12 * 60;

/// iOS keeps at most 64 pending notifications for the app, shared with the adhan,
/// so the daily dhikr reminders take at most this many there.
const dhikrReminderMaxIos = 24;

/// Android has no such small cap; this only bounds the ids.
const dhikrReminderMaxAndroid = 96;

const _day = 24 * 60;

/// The times (minutes after midnight) of the daily reminders: every [every] minutes from
/// [from] to [to] (both included; the window may cross midnight; from == to = all day).
/// When that gives more than [max] reminders, they are spread evenly over the window
/// instead, at the smallest whole 5 minutes that fits; [every] in the result says which.
({List<int> slots, int every}) planDhikrSlots({
  required int from,
  required int to,
  required int every,
  required int max,
}) {
  var step = every.clamp(dhikrReminderMinEvery, dhikrReminderMaxEvery);
  final allDay = from == to;
  final span = allDay ? _day : (to - from) % _day;
  int count(int s) => allDay ? (span / s).ceil() : span ~/ s + 1;
  if (count(step) > max) {
    step = math.max(step, ((span / (allDay ? max : math.max(1, max - 1))) / 5).ceil() * 5);
    while (count(step) > max) {
      step += 5;
    }
  }
  return (slots: [for (var i = 0; i < count(step); i++) (from + i * step) % _day], every: step);
}
