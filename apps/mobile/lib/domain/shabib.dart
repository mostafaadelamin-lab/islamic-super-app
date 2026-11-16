/// Sheikh Mohamed Ahmed Shabib's recitations (owner 2026-11-16). No complete
/// 114-surah recording of the sheikh exists, so he has his own section in the
/// recitation library: the murattal surahs that exist (Hafs, several partial)
/// and his mujawwad recitations. Streamed, or saved per track for offline
/// listening. List: assets/content/shabib.v1.json, built by
/// tools/shabib_build.py (sources in docs/CONTENT_SOURCES.md, never shown in the app).
library;

import 'dart:convert';

enum ShabibKind { murattal, mujawwad }

class ShabibTrack {
  const ShabibTrack({
    required this.id,
    required this.kind,
    required this.surahs,
    required this.url,
    required this.seconds,
    this.part = false,
    this.tag,
    this.year,
  });

  /// Stable across builds (saved offline copies are keyed by it).
  final String id;
  final ShabibKind kind;

  /// Empty = short surahs ("قصار السور").
  final List<int> surahs;
  final String url;
  final int seconds;

  /// Murattal only: a passage of the surah ("ما تيسر من").
  final bool part;

  /// fajr = Quran al-Fajr, radio = radio recording, oct73 = dawn of 6 October 1973, short = short surahs.
  final String? tag;
  final int? year;
}

class ShabibRecitations {
  const ShabibRecitations(this.murattal, this.mujawwad);
  final List<ShabibTrack> murattal;
  final List<ShabibTrack> mujawwad;

  List<ShabibTrack> of(ShabibKind k) => k == ShabibKind.murattal ? murattal : mujawwad;

  static ShabibRecitations parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    List<ShabibTrack> list(String key, ShabibKind kind) => [
      for (final x in j[key] as List)
        ShabibTrack(
          id: x['id'] as String,
          kind: kind,
          surahs: [for (final n in x['surahs'] as List) n as int],
          url: x['url'] as String,
          seconds: x['s'] as int,
          part: x['part'] == true,
          tag: x['tag'] as String?,
          year: x['year'] as int?,
        ),
    ];
    return ShabibRecitations(list('murattal', ShabibKind.murattal), list('mujawwad', ShabibKind.mujawwad));
  }
}
