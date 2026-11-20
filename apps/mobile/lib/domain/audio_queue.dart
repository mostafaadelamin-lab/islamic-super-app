// Recitation queue logic (pure Dart, no plugins): reciters from
// packages/shared-schemas/audio/reciters.json, per-ayah URL building and the
// order of files to play, including the basmala rule.
import 'quran.dart';

class Reciter {
  const Reciter({required this.folder, required this.nameAr, required this.nameEn, this.surahUrl});
  final String folder;
  final String nameAr;
  final String nameEn;

  /// Reciters recorded as one file per surah (with ayah timings) instead of one
  /// file per ayah: the surah file URL with `{sss}` for the surah number.
  final String? surahUrl;

  bool get isTimed => surahUrl != null;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

/// Where each ayah starts and ends inside the surah files of a timed reciter
/// (packages/shared-schemas/audio/ayah-timings.json): per surah
/// `[start of ayah 1, end of ayah 1, end of ayah 2, …]` in milliseconds.
class AyahTimings {
  const AyahTimings(this._bySurah);

  factory AyahTimings.fromJson(List<dynamic> j) => AyahTimings(
    List.unmodifiable([
      for (final s in j) List<int>.unmodifiable([for (final v in s as List<dynamic>) (v as num).toInt()]),
    ]),
  );

  final List<List<int>> _bySurah;

  /// Opening before ayah 1 shorter than this holds no basmala (just a breath).
  static const basmalaMinMs = 2500;

  /// The part of the surah file to play for [item], or null when there is
  /// nothing to play (a basmala the file does not have, or no timings).
  ({int startMs, int endMs})? segment(QueueItem item) {
    final s = item.ref.surah;
    if (s < 1 || s > _bySurah.length) return null;
    final t = _bySurah[s - 1];
    if (item.isBasmala) return t.isNotEmpty && t[0] >= basmalaMinMs ? (startMs: 0, endMs: t[0]) : null;
    final a = item.ref.ayah;
    if (a < 1 || a >= t.length) return null;
    return (startMs: t[a - 1], endMs: t[a]);
  }
}

class ReciterCatalog {
  ReciterCatalog({required this.urlTemplate, required this.defaultFolder, required this.reciters});

  factory ReciterCatalog.fromJson(Map<String, dynamic> j) => ReciterCatalog(
    urlTemplate: j['urlTemplate'] as String,
    defaultFolder: j['default'] as String,
    reciters: List.unmodifiable([
      for (final r in j['reciters'] as List<dynamic>)
        Reciter(
          folder: (r as Map<String, dynamic>)['folder'] as String,
          nameAr: r['ar'] as String,
          nameEn: r['en'] as String,
          surahUrl: r['surahUrl'] as String?,
        ),
    ]),
  );

  /// Ayah timings of the timed reciters, by folder (filled from ayah-timings.json).
  final Map<String, AyahTimings> timings = {};

  void addTimings(Map<String, dynamic> j) {
    final by = j['reciters'] as Map<String, dynamic>;
    by.forEach((k, v) => timings[k] = AyahTimings.fromJson(v as List<dynamic>));
  }

  final String urlTemplate;
  final String defaultFolder;
  final List<Reciter> reciters;

  Reciter byFolder(String? folder) {
    for (final r in reciters) {
      if (r.folder == folder) return r;
    }
    for (final r in reciters) {
      if (r.folder == defaultFolder) return r;
    }
    return reciters.first;
  }

  /// The surah file of a timed reciter, e.g. …/002.mp3.
  String surahFileUrl(Reciter r, int surah) => r.surahUrl!.replaceAll('{sss}', surah.toString().padLeft(3, '0'));

  /// e.g. https://everyayah.com/data/Alafasy_128kbps/002255.mp3
  String url(String folder, AyahRef r) => urlTemplate
      .replaceAll('{folder}', folder)
      .replaceAll('{sss}', r.surah.toString().padLeft(3, '0'))
      .replaceAll('{aaa}', r.ayah.toString().padLeft(3, '0'));
}

/// One file to play. [ref] is the ayah to highlight; for the basmala that is
/// played before ayah 1 it is that ayah 1 (the basmala itself is 1:1's file).
class QueueItem {
  const QueueItem(this.ref, {this.isBasmala = false});
  final AyahRef ref;
  final bool isBasmala;

  /// The ayah whose audio file is played.
  AyahRef get audioRef => isBasmala ? const AyahRef(1, 1) : ref;

  @override
  bool operator ==(Object other) => other is QueueItem && other.ref == ref && other.isBasmala == isBasmala;

  @override
  int get hashCode => Object.hash(ref, isBasmala);

  @override
  String toString() => isBasmala ? 'basmala→$ref' : '$ref';
}

/// Whether the basmala (file 001001) is recited before ayah 1 of [surah]:
/// every surah except al-Fatihah (where 1:1 IS the basmala) and at-Tawbah.
bool basmalaBeforeSurah(int surah) => surah != 1 && surah != 9;

/// [ranges]: the verse ranges of a Quranic story, played in order.
enum PlayScope { ayah, page, surah, toEnd, ranges, radio }

/// Builds the play list from [from] to [to] inclusive (reading order), adding
/// the basmala before ayah 1 of each surah where [basmalaBeforeSurah] holds.
/// Each ayah is repeated [repeat] times (the basmala is not repeated).
List<QueueItem> buildQueue(QuranContent q, AyahRef from, AyahRef to, {int repeat = 1}) {
  if (!q.isValid(from) || !q.isValid(to)) throw ArgumentError('invalid range $from..$to');
  if (to.compareTo(from) < 0) throw ArgumentError('range end $to before start $from');
  final reps = repeat < 1 ? 1 : repeat;
  final out = <QueueItem>[];
  var r = from;
  while (true) {
    if (r.ayah == 1 && basmalaBeforeSurah(r.surah)) out.add(QueueItem(r, isBasmala: true));
    for (var i = 0; i < reps; i++) {
      out.add(QueueItem(r));
    }
    if (r == to) break;
    r = nextAyah(q, r)!;
  }
  return out;
}

/// The ayah after [r] in reading order, or null after 114:6.
AyahRef? nextAyah(QuranContent q, AyahRef r) {
  if (r.ayah < q.surah(r.surah).ayahCount) return AyahRef(r.surah, r.ayah + 1);
  if (r.surah < q.surahs.length) return AyahRef(r.surah + 1, 1);
  return null;
}

/// Quran radio: every ayah of the Mushaf, starting at surah [fromSurah] and
/// wrapping after an-Nas back to al-Fatihah (each surah once).
List<QueueItem> radioQueue(QuranContent q, int fromSurah, {int repeat = 1}) {
  final n = q.surahs.length;
  final start = fromSurah >= 1 && fromSurah <= n ? fromSurah : 1;
  return [
    ...buildQueue(q, AyahRef(start, 1), AyahRef(n, q.surahs.last.ayahCount), repeat: repeat),
    if (start > 1)
      ...buildQueue(q, const AyahRef(1, 1), AyahRef(start - 1, q.surah(start - 1).ayahCount), repeat: repeat),
  ];
}

/// End of the range for a play [scope] starting at [from].
AyahRef scopeEnd(QuranContent q, AyahRef from, PlayScope scope) => switch (scope) {
  PlayScope.ayah || PlayScope.ranges => from,
  PlayScope.page => q.page(q.pageOf(from)).end,
  PlayScope.surah => AyahRef(from.surah, q.surah(from.surah).ayahCount),
  PlayScope.toEnd || PlayScope.radio => AyahRef(q.surahs.length, q.surahs.last.ayahCount),
};

/// The Mushaf page to show while [item] plays (the page where its ayah starts),
/// used to turn pages automatically during continuous playback.
int pageForItem(QuranContent q, QueueItem item) => q.pageOf(item.ref);
