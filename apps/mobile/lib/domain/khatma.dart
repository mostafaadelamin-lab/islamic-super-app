// Quran khatma (completing the whole Mushaf on a plan): pure planning logic.
// The Mushaf pages [startPage..endPage] are split into `wirds` daily portions of
// whole pages, one wird per day from `startDate`. Same rules as the website
// (apps/web/src/lib/khatma.ts).

const mushafPages = 604;
const minKhatmaDays = 1;
const maxKhatmaDays = 365;
const minPagesPerDay = 1;
const maxPagesPerDay = 60;
const maxKhatmaName = 40;

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Whole days from [a] to [b] (b − a), by calendar date.
int daysBetween(DateTime a, DateTime b) => _day(b).difference(_day(a)).inHours ~/ 24;

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? _parseIso(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch(v)) return null;
  final p = v.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

class Khatma {
  const Khatma({
    required this.name,
    required this.startDate,
    this.startPage = 1,
    this.endPage = mushafPages,
    required this.wirds,
    this.done = 0,
    this.reminderMinutes,
  });

  /// A plan finishing in [days] days (pages spread as evenly as possible).
  factory Khatma.byDays(String name, DateTime start, int days) =>
      Khatma(name: name, startDate: _day(start), wirds: days.clamp(minKhatmaDays, maxKhatmaDays));

  /// A plan of about [pagesPerDay] pages a day.
  factory Khatma.byPages(String name, DateTime start, int pagesPerDay) => Khatma(
    name: name,
    startDate: _day(start),
    wirds: (mushafPages / pagesPerDay.clamp(minPagesPerDay, maxPagesPerDay)).ceil(),
  );

  final String name;
  final DateTime startDate;
  final int startPage;
  final int endPage;
  final int wirds;
  final int done;

  /// Daily reminder time as minutes after midnight, or null for none.
  final int? reminderMinutes;

  bool get finished => done >= wirds;
  DateTime get endDate => startDate.add(Duration(days: wirds - 1));

  Khatma copyWith({String? name, int? done, int? Function()? reminderMinutes}) => Khatma(
    name: name ?? this.name,
    startDate: startDate,
    startPage: startPage,
    endPage: endPage,
    wirds: wirds,
    done: done ?? this.done,
    reminderMinutes: reminderMinutes == null ? this.reminderMinutes : reminderMinutes(),
  );

  /// Pages (inclusive) of wird [i] (0-based).
  ({int from, int to}) wirdPages(int i) {
    final total = endPage - startPage + 1;
    return (from: startPage + (i * total) ~/ wirds, to: startPage + ((i + 1) * total) ~/ wirds - 1);
  }

  /// Share of the whole Mushaf read, 0..1.
  double get fraction => (done == 0 ? startPage - 1 : wirdPages(done - 1).to) / mushafPages;

  /// Days left until the planned last day, counting [today] (0 once past it).
  int remainingDays(DateTime today) {
    final d = daysBetween(today, endDate) + 1;
    return d < 0 ? 0 : d;
  }

  int _due(DateTime today) => (daysBetween(startDate, today) + 1).clamp(0, wirds);

  /// Wirds behind the plan (today's wird is not late yet).
  int behind(DateTime today) {
    final duePast = _due(today) - 1;
    final b = (duePast < 0 ? 0 : duePast) - done;
    return b < 0 ? 0 : b;
  }

  /// Wirds ahead of the plan.
  int ahead(DateTime today) {
    final a = done - _due(today);
    return a < 0 ? 0 : a;
  }

  /// Spreads the unread pages over the days left (at least one), starting [today].
  Khatma reschedule(DateTime today) {
    if (finished) return this;
    final from = wirdPages(done).from;
    final left = daysBetween(today, endDate) + 1;
    final pages = endPage - from + 1;
    final n = left < 1 ? 1 : left;
    return Khatma(
      name: name,
      startDate: _day(today),
      startPage: from,
      endPage: endPage,
      wirds: n < pages ? n : pages,
      reminderMinutes: reminderMinutes,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'startDate': _iso(startDate),
    'startPage': startPage,
    'endPage': endPage,
    'wirds': wirds,
    'done': done,
    'reminder': reminderMinutes,
  };

  static Khatma? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final start = _parseIso(raw['startDate']);
    final sp = raw['startPage'], ep = raw['endPage'], w = raw['wirds'], d = raw['done'];
    if (start == null || sp is! int || ep is! int || w is! int || d is! int) return null;
    if (sp < 1 || ep > mushafPages || ep < sp || w < 1 || w > ep - sp + 1 || d < 0 || d > w) return null;
    final r = raw['reminder'];
    final name = raw['name'] is String ? (raw['name'] as String).trim() : '';
    return Khatma(
      name: name.length > maxKhatmaName ? name.substring(0, maxKhatmaName) : name,
      startDate: start,
      startPage: sp,
      endPage: ep,
      wirds: w,
      done: d,
      reminderMinutes: r is int && r >= 0 && r < 24 * 60 ? r : null,
    );
  }
}

class FinishedKhatma {
  const FinishedKhatma(this.name, this.startDate, this.finishedDate, this.days);
  final String name;
  final DateTime startDate;
  final DateTime finishedDate;
  final int days;

  Map<String, Object?> toJson() => {
    'name': name,
    'startDate': _iso(startDate),
    'finishedDate': _iso(finishedDate),
    'days': days,
  };

  static FinishedKhatma? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final s = _parseIso(raw['startDate']), f = _parseIso(raw['finishedDate']);
    final d = raw['days'];
    if (s == null || f == null || d is! int) return null;
    return FinishedKhatma(raw['name'] is String ? raw['name'] as String : '', s, f, d);
  }
}

class KhatmaState {
  const KhatmaState({this.current, this.history = const []});
  final Khatma? current;
  final List<FinishedKhatma> history;

  /// Marks the current wird read; the last one moves the khatma to the history.
  KhatmaState completeWird(DateTime today) {
    final k = current;
    if (k == null) return this;
    final done = k.done + 1;
    if (done < k.wirds) {
      return KhatmaState(
        current: k.copyWith(done: done),
        history: history,
      );
    }
    return KhatmaState(
      history: [FinishedKhatma(k.name, k.startDate, _day(today), daysBetween(k.startDate, today) + 1), ...history],
    );
  }

  Map<String, Object?> toJson() => {
    'current': current?.toJson(),
    'history': [for (final h in history) h.toJson()],
  };

  static KhatmaState fromJson(Object? raw) {
    if (raw is! Map) return const KhatmaState();
    final h = raw['history'];
    return KhatmaState(
      current: Khatma.fromJson(raw['current']),
      history: h is List ? [for (final x in h) ?FinishedKhatma.fromJson(x)] : const [],
    );
  }
}
