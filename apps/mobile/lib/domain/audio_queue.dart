// Recitation queue logic (pure Dart, no plugins): reciters from
// packages/shared-schemas/audio/reciters.json, per-ayah URL building and the
// order of files to play, including the basmala rule.
import 'quran.dart';

class Reciter {
  const Reciter({required this.folder, required this.nameAr, required this.nameEn});
  final String folder;
  final String nameAr;
  final String nameEn;

  String name(bool arabic) => arabic ? nameAr : nameEn;
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
        ),
    ]),
  );

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

enum PlayScope { ayah, page, surah, toEnd }

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

/// End of the range for a play [scope] starting at [from].
AyahRef scopeEnd(QuranContent q, AyahRef from, PlayScope scope) => switch (scope) {
  PlayScope.ayah => from,
  PlayScope.page => q.page(q.pageOf(from)).end,
  PlayScope.surah => AyahRef(from.surah, q.surah(from.surah).ayahCount),
  PlayScope.toEnd => AyahRef(q.surahs.length, q.surahs.last.ayahCount),
};

/// The Mushaf page to show while [item] plays (the page where its ayah starts),
/// used to turn pages automatically during continuous playback.
int pageForItem(QuranContent q, QueueItem item) => q.pageOf(item.ref);
