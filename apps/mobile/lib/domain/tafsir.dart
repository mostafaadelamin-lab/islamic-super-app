import 'dart:convert';

/// A tafsir with one entry per ayah (content/tafsir/dist/*.v1.json, schema
/// tafsir.v1). The text is kept exactly as stored.
class TafsirContent {
  TafsirContent({required this.id, required this.nameAr, required this.nameEn, required this.surahs});

  factory TafsirContent.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 'tafsir.v1') throw FormatException('not a tafsir.v1 file: ${j['schema']}');
    final surahs = [
      for (final s in j['surahs'] as List<dynamic>) List<String>.unmodifiable((s as List<dynamic>).cast<String>()),
    ];
    if (surahs.length != 114) throw FormatException('tafsir has ${surahs.length} surahs, expected 114');
    return TafsirContent(
      id: j['id'] as String,
      nameAr: j['nameAr'] as String,
      nameEn: j['nameEn'] as String,
      surahs: List.unmodifiable(surahs),
    );
  }

  /// Decodes the raw JSON file (top-level so it can run in a background isolate).
  static TafsirContent parse(String json) => TafsirContent.fromJson(jsonDecode(json) as Map<String, dynamic>);

  final String id;
  final String nameAr;
  final String nameEn;

  /// surahs[s - 1][a - 1] is the entry for ayah s:a.
  final List<List<String>> surahs;

  int get entryCount => surahs.fold(0, (n, s) => n + s.length);

  /// The stored entry for [surah]:[ayah], or null when there is no such ayah.
  String? text(int surah, int ayah) {
    if (surah < 1 || surah > surahs.length) return null;
    final s = surahs[surah - 1];
    if (ayah < 1 || ayah > s.length) return null;
    return s[ayah - 1];
  }
}
