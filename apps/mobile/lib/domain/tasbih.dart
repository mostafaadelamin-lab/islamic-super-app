import 'dart:math' as math;

/// Tasbih counter state (pure). A round is [target] taps; [total] counts every
/// tap ever made until reset.
class TasbihState {
  const TasbihState({this.count = 0, this.total = 0, this.rounds = 0, this.target = 33});

  final int count;
  final int total;
  final int rounds;
  final int target;

  static const targets = [33, 99, 100, 1000];

  /// One tap. When [count] reaches [target] a round is completed and the
  /// counter starts again from zero.
  TasbihState tap() {
    final c = count + 1;
    if (c >= target) return TasbihState(count: 0, total: total + 1, rounds: rounds + 1, target: target);
    return TasbihState(count: c, total: total + 1, rounds: rounds, target: target);
  }

  /// True when the last tap completed a round (count wrapped to zero).
  bool completedRoundFrom(TasbihState before) => rounds > before.rounds;

  TasbihState withTarget(int t) => TasbihState(count: count >= t ? 0 : count, total: total, rounds: rounds, target: t);

  TasbihState reset() => TasbihState(target: target);

  Map<String, int> toJson() => {'count': count, 'total': total, 'rounds': rounds, 'target': target};

  factory TasbihState.fromJson(Map<String, dynamic> j) {
    final t = (j['target'] as num?)?.toInt() ?? 33;
    final target = t < 1 ? 33 : t;
    final c = (j['count'] as num?)?.toInt() ?? 0;
    return TasbihState(
      count: c < 0 || c >= target ? 0 : c,
      total: ((j['total'] as num?)?.toInt() ?? 0).clamp(0, 1 << 31),
      rounds: ((j['rounds'] as num?)?.toInt() ?? 0).clamp(0, 1 << 31),
      target: target,
    );
  }
}

/// A dhikr the user added (id "c1", "c2", ...).
class CustomDhikr {
  const CustomDhikr(this.id, this.text);
  final String id;
  final String text;
}

enum TasbihMode { button, beads }

/// Built-in adhkar (keys shared with the website) and their wording.
const tasbihPhrases = {
  'tasbih': 'سبحان الله',
  'tahmid': 'الحمد لله',
  'takbir': 'الله أكبر',
  'tahlil': 'لا إله إلا الله',
  'istighfar': 'أستغفر الله',
};

/// Bead colours (same values as the website); default is the emerald of colour style 1 (since 2026-11-15).
const tasbihColors = {
  'brown': 0xFF8A5A2B,
  'emerald': 0xFF0F5C4A,
  'gold': 0xFFA77B22,
  'teal': 0xFF1F7A7A,
  'sky': 0xFF2C6E9E,
  'indigo': 0xFF4B4F9E,
  'plum': 0xFF7A3E73,
  'rose': 0xFFA8455A,
  'amber': 0xFFB5651D,
  'slate': 0xFF4A5A63,
};

const maxCustomAdhkar = 20;
const maxCustomText = 80;
const tasbihHistoryDays = 60;

String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _isoDayRe = RegExp(r'^\d{4}-\d\d-\d\d$');
final _customIdRe = RegExp(r'^c\d{1,6}$');

/// Every dhikr's counter, the user's own adhkar, display options and the per-day history.
class TasbihBook {
  const TasbihBook({
    this.phrase = 'tasbih',
    this.counters = const {},
    this.custom = const [],
    this.mode = TasbihMode.beads,
    this.color = 'emerald',
    this.sound = false,
    this.vibrate = true,
    this.history = const {},
  });

  final String phrase;
  final Map<String, TasbihState> counters;
  final List<CustomDhikr> custom;
  final TasbihMode mode;
  final String color;
  final bool sound;
  final bool vibrate;

  /// Taps per day ("YYYY-MM-DD") and dhikr.
  final Map<String, Map<String, int>> history;

  TasbihState get current => counters[phrase] ?? const TasbihState();
  List<String> get ids => [...tasbihPhrases.keys, for (final c in custom) c.id];

  /// Wording of dhikr [id].
  String textOf(String id) =>
      tasbihPhrases[id] ?? custom.firstWhere((c) => c.id == id, orElse: () => const CustomDhikr('', '')).text;

  TasbihBook copyWith({
    String? phrase,
    Map<String, TasbihState>? counters,
    List<CustomDhikr>? custom,
    TasbihMode? mode,
    String? color,
    bool? sound,
    bool? vibrate,
    Map<String, Map<String, int>>? history,
  }) => TasbihBook(
    phrase: phrase ?? this.phrase,
    counters: counters ?? this.counters,
    custom: custom ?? this.custom,
    mode: mode ?? this.mode,
    color: color ?? this.color,
    sound: sound ?? this.sound,
    vibrate: vibrate ?? this.vibrate,
    history: history ?? this.history,
  );

  TasbihBook withCurrent(TasbihState s) => copyWith(counters: {...counters, phrase: s});

  Map<String, Map<String, int>> _addHistory(DateTime today, int delta) {
    final day = isoDay(today);
    final cutoff = isoDay(DateTime.utc(today.year, today.month, today.day - tasbihHistoryDays));
    final out = {
      for (final e in history.entries)
        if (e.key.compareTo(cutoff) > 0 && e.key != day) e.key: e.value,
    };
    final row = {...?history[day]};
    final n = (row[phrase] ?? 0) + delta;
    if (n > 0) {
      row[phrase] = n;
    } else {
      row.remove(phrase);
    }
    if (row.isNotEmpty) out[day] = row;
    return out;
  }

  /// One tap on [today]; returns the new book and whether it completed a round.
  (TasbihBook, bool) tap(DateTime today) {
    final before = current;
    final after = before.tap();
    return (withCurrent(after).copyWith(history: _addHistory(today, 1)), after.completedRoundFrom(before));
  }

  TasbihBook undo(DateTime today) {
    final c = current;
    if (c.count == 0) return this;
    return withCurrent(
      TasbihState(count: c.count - 1, total: c.total > 0 ? c.total - 1 : 0, rounds: c.rounds, target: c.target),
    ).copyWith(history: _addHistory(today, -1));
  }

  /// Adds the user's own dhikr and selects it; unchanged when empty or the list is full.
  TasbihBook addCustom(String text) {
    var clean = text.trim();
    if (clean.length > maxCustomText) clean = clean.substring(0, maxCustomText);
    if (clean.isEmpty || custom.length >= maxCustomAdhkar) return this;
    final n = custom.fold(0, (m, c) => math.max(m, int.parse(c.id.substring(1)))) + 1;
    return copyWith(custom: [...custom, CustomDhikr('c$n', clean)], phrase: 'c$n');
  }

  TasbihBook removeCustom(String id) => copyWith(
    custom: [
      for (final c in custom)
        if (c.id != id) c,
    ],
    counters: {
      for (final e in counters.entries)
        if (e.key != id) e.key: e.value,
    },
    history: {
      for (final e in history.entries)
        if (e.value.keys.any((k) => k != id))
          e.key: {
            for (final r in e.value.entries)
              if (r.key != id) r.key: r.value,
          },
    },
    phrase: phrase == id ? 'tasbih' : phrase,
  );

  /// History rows, newest day first.
  List<(String day, String id, int count)> historyRows() => [
    for (final day in (history.keys.toList()..sort((a, b) => b.compareTo(a))))
      for (final e in history[day]!.entries) (day, e.key, e.value),
  ];

  Map<String, Object?> toJson() => {
    'phrase': phrase,
    'counters': {for (final e in counters.entries) e.key: e.value.toJson()},
    'custom': [
      for (final c in custom) {'id': c.id, 'text': c.text},
    ],
    'mode': mode.name,
    'color': color,
    'sound': sound,
    'vibrate': vibrate,
    'history': history,
  };

  static TasbihBook fromJson(Object? raw) {
    if (raw is! Map) return const TasbihBook();
    final custom = <CustomDhikr>[];
    final rc = raw['custom'];
    if (rc is List) {
      for (final c in rc) {
        if (custom.length >= maxCustomAdhkar) break;
        if (c is Map && c['id'] is String && c['text'] is String && _customIdRe.hasMatch(c['id'] as String)) {
          var text = (c['text'] as String).trim();
          if (text.isEmpty) continue;
          if (text.length > maxCustomText) text = text.substring(0, maxCustomText);
          custom.add(CustomDhikr(c['id'] as String, text));
        }
      }
    }
    final ids = {...tasbihPhrases.keys, for (final c in custom) c.id};
    final phrase = raw['phrase'] is String && ids.contains(raw['phrase']) ? raw['phrase'] as String : 'tasbih';
    final counters = <String, TasbihState>{};
    final rcount = raw['counters'];
    if (rcount is Map) {
      for (final e in rcount.entries) {
        if (ids.contains(e.key) && e.value is Map) {
          counters[e.key as String] = TasbihState.fromJson(Map<String, dynamic>.from(e.value as Map));
        }
      }
    }
    final history = <String, Map<String, int>>{};
    final rh = raw['history'];
    if (rh is Map) {
      for (final e in rh.entries) {
        if (e.key is! String || !_isoDayRe.hasMatch(e.key as String) || e.value is! Map) continue;
        final row = <String, int>{
          for (final r in (e.value as Map).entries)
            if (ids.contains(r.key) && r.value is int && (r.value as int) > 0) r.key as String: r.value as int,
        };
        if (row.isNotEmpty) history[e.key as String] = row;
      }
    }
    return TasbihBook(
      phrase: phrase,
      counters: counters,
      custom: custom,
      mode: raw['mode'] == 'button' ? TasbihMode.button : TasbihMode.beads,
      color: raw['color'] is String && tasbihColors.containsKey(raw['color']) ? raw['color'] as String : 'emerald',
      sound: raw['sound'] == true,
      vibrate: raw['vibrate'] != false,
      history: history,
    );
  }
}
