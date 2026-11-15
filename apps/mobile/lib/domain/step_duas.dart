import 'adhkar.dart';
import 'quran.dart';

/// What is said at each place of Umrah and Hajj (owner 2026-11-15: every dua and ayah in full where it is
/// said). Read from content/pilgrimage/step-duas.v1.json, which holds references only: a Hisn al-Muslim
/// chapter (its whole text, or an exact part of it) or a Quran ayah. Nothing here is new religious text.
enum SayKind { dua, hadith, note }

class SayItem {
  const SayItem({required this.kind, this.text, this.ayah});
  final SayKind kind;

  /// Hisn al-Muslim text, verbatim (null for an ayah).
  final String? text;

  /// The ayah to show in full from the canonical Quran text.
  final AyahRef? ayah;
}

class SayGroup {
  const SayGroup(this.title, this.say);

  /// The Hisn al-Muslim chapter title.
  final String title;
  final List<SayItem> say;
}

class _Rule {
  const _Rule(this.contains, this.places, this.stop);
  final String contains;
  final List<String> places;
  final bool stop;
}

class StepDuas {
  const StepDuas(this._places, this._rules);

  static const empty = StepDuas({}, []);

  /// Resolves the references against [hisn]; a part that is not in its chapter is a format error.
  factory StepDuas.fromJson(Map<String, dynamic> j, List<HisnChapter> hisn) {
    HisnChapter chapter(int id) =>
        (id >= 1 && id <= hisn.length) ? hisn[id - 1] : throw FormatException('step-duas: no Hisn chapter $id');
    SayKind kind(String k) => SayKind.values.firstWhere((x) => x.name == k, orElse: () => SayKind.note);
    final places = <String, List<SayGroup>>{
      for (final e in (j['places'] as Map<String, dynamic>).entries)
        e.key: List.unmodifiable([
          for (final g in (e.value as List<dynamic>).cast<Map<String, dynamic>>())
            SayGroup(
              chapter(g['hisn'] as int).title,
              List.unmodifiable([
                for (final x in (g['say'] as List<dynamic>).cast<Map<String, dynamic>>())
                  if (x['quran'] case [final int s, final int a])
                    SayItem(kind: kind(x['kind'] as String), ayah: AyahRef(s, a))
                  else
                    SayItem(
                      kind: kind(x['kind'] as String),
                      text: _text(chapter(x['hisn'] as int), x['part'] as String?),
                    ),
              ]),
            ),
        ]),
    };
    final rules = [
      for (final r in (j['rules'] as List<dynamic>).cast<Map<String, dynamic>>())
        _Rule(r['contains'] as String, (r['places'] as List<dynamic>).cast<String>(), r['stop'] == true),
    ];
    return StepDuas(Map.unmodifiable(places), List.unmodifiable(rules));
  }

  static String _text(HisnChapter c, String? part) {
    final full = c.items.join('\n');
    if (part == null) return full;
    if (!full.contains(part)) throw FormatException('step-duas: part not in Hisn chapter ${c.index + 1}: $part');
    return part;
  }

  final Map<String, List<SayGroup>> _places;
  final List<_Rule> _rules;

  /// The places of a step, from the words of its title (same rules as the website).
  List<String> placesFor(String title) {
    final out = <String>[];
    for (final r in _rules) {
      if (!title.contains(r.contains)) continue;
      for (final p in r.places) {
        if (!out.contains(p)) out.add(p);
      }
      if (r.stop) break;
    }
    return out;
  }

  /// Everything said at the step's places, each group under its Hisn al-Muslim heading.
  List<SayGroup> forStep(String title) => [for (final p in placesFor(title)) ...?_places[p]];
}
