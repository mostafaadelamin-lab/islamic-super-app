// Worship tracker: for each day, which of the five prayers were prayed,
// whether the user fasted, and a short note. Same rules as the website
// (apps/web/src/lib/worship.ts).

const worshipPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const maxWorshipNote = 200;
const _maxStreak = 1100;
final _isoDayRe = RegExp(r'^\d{4}-\d\d-\d\d$');

String worshipDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class WorshipDay {
  const WorshipDay({this.prayers = const {}, this.fasting = false, this.note = ''});
  final Set<String> prayers;
  final bool fasting;
  final String note;

  int get prayed => worshipPrayers.where(prayers.contains).length;
  bool get full => prayed == worshipPrayers.length;
  bool get isEmpty => prayers.isEmpty && !fasting && note.trim().isEmpty;

  Map<String, Object?> toJson() => {
    'prayers': {for (final p in prayers) p: true},
    'fasting': fasting,
    'note': note,
  };

  static WorshipDay fromJson(Object? raw) {
    if (raw is! Map) return const WorshipDay();
    final p = raw['prayers'];
    final note = raw['note'] is String ? raw['note'] as String : '';
    return WorshipDay(
      prayers: {
        if (p is Map)
          for (final k in worshipPrayers)
            if (p[k] == true) k,
      },
      fasting: raw['fasting'] == true,
      note: note.length > maxWorshipNote ? note.substring(0, maxWorshipNote) : note,
    );
  }
}

class WorshipStats {
  const WorshipStats(this.days, this.prayed, this.fullDays, this.fasted);
  final int days;
  final int prayed;
  final int fullDays;
  final int fasted;
  int get possible => days * worshipPrayers.length;
}

class WorshipLog {
  const WorshipLog([this.days = const {}]);
  final Map<String, WorshipDay> days;

  WorshipDay dayOf(DateTime d) => days[worshipDay(d)] ?? const WorshipDay();

  WorshipLog _with(DateTime d, WorshipDay v) {
    final key = worshipDay(d);
    final out = {...days}..remove(key);
    if (!v.isEmpty) out[key] = v;
    return WorshipLog(out);
  }

  WorshipLog togglePrayer(DateTime d, String key) {
    final cur = dayOf(d);
    final p = {...cur.prayers};
    if (!p.remove(key)) p.add(key);
    return _with(d, WorshipDay(prayers: p, fasting: cur.fasting, note: cur.note));
  }

  WorshipLog setFasting(DateTime d, bool on) {
    final cur = dayOf(d);
    return _with(d, WorshipDay(prayers: cur.prayers, fasting: on, note: cur.note));
  }

  WorshipLog setNote(DateTime d, String note) {
    final cur = dayOf(d);
    final n = note.length > maxWorshipNote ? note.substring(0, maxWorshipNote) : note;
    return _with(d, WorshipDay(prayers: cur.prayers, fasting: cur.fasting, note: n));
  }

  /// Totals over the [n] days ending on [last] (inclusive).
  WorshipStats statsFor(DateTime last, int n) {
    final list = [for (var i = 0; i < n; i++) dayOf(DateTime.utc(last.year, last.month, last.day - i))];
    return WorshipStats(
      n,
      list.fold(0, (a, d) => a + d.prayed),
      list.where((d) => d.full).length,
      list.where((d) => d.fasting).length,
    );
  }

  WorshipStats week(DateTime today) => statsFor(today, 7);

  /// A whole Gregorian month, up to [today] when it is the current month.
  WorshipStats month(int year, int month, DateTime today) {
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    final end = today.year == year && today.month == month ? today.day : lastDay;
    return statsFor(DateTime.utc(year, month, end), end);
  }

  /// Days in a row with all five prayers, ending today, or yesterday while
  /// today is not complete yet.
  int streak(DateTime today) {
    final start = dayOf(today).full ? 0 : 1;
    var n = 0;
    while (n < _maxStreak && dayOf(DateTime.utc(today.year, today.month, today.day - start - n)).full) {
      n++;
    }
    return n;
  }

  Map<String, Object?> toJson() => {
    'days': {for (final e in days.entries) e.key: e.value.toJson()},
  };

  static WorshipLog fromJson(Object? raw) {
    final d = raw is Map ? raw['days'] : null;
    if (d is! Map) return const WorshipLog();
    final out = <String, WorshipDay>{};
    for (final e in d.entries) {
      if (e.key is! String || !_isoDayRe.hasMatch(e.key as String)) continue;
      final v = WorshipDay.fromJson(e.value);
      if (!v.isEmpty) out[e.key as String] = v;
    }
    return WorshipLog(out);
  }
}
