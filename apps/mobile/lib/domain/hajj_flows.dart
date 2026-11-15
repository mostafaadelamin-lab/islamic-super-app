// The official guide «دليل الحاج والمعتمر» as bundled (assets/content/dalil-hajj.v1.json). Since 2026-11-16 the
// screens show the sourced guide (hajj_guide.dart), which carries the same paragraphs with KFGQPC ayahs.

/// «دليل الحاج والمعتمر وزائر مسجد الرسول ﷺ» (Saudi Ministry of Islamic Affairs), copied
/// verbatim into assets/content/dalil-hajj.v1.json from content/pilgrimage/dalil-hajj.v1.json.
class OfficialHajjGuide {
  const OfficialHajjGuide({
    required this.title,
    required this.publisher,
    required this.types,
    required this.typesNote,
    required this.umrah,
    required this.hajj,
    required this.corrections,
  });

  factory OfficialHajjGuide.fromJson(Map<String, dynamic> j) {
    final src = j['source'] as Map<String, dynamic>;
    List<String> strings(Object? v) => List.unmodifiable((v as List<dynamic>).cast<String>());
    return OfficialHajjGuide(
      title: src['title'] as String,
      publisher: src['publisher'] as String,
      corrections: strings(src['corrections']),
      types: List.unmodifiable([
        for (final t in j['types'] as List<dynamic>)
          ((t as Map<String, dynamic>)['name'] as String, t['text'] as String),
      ]),
      typesNote: j['typesNote'] as String,
      umrah: strings(j['umrah']),
      hajj: strings(j['hajj']),
    );
  }

  static const empty = OfficialHajjGuide(
    title: '',
    publisher: '',
    types: [],
    typesNote: '',
    umrah: [],
    hajj: [],
    corrections: [],
  );

  final String title;
  final String publisher;
  final List<(String, String)> types;
  final String typesNote;
  final List<String> umrah;
  final List<String> hajj;
  final List<String> corrections;

  bool get isEmpty => hajj.isEmpty;

  /// The guide's paragraph for a step ref ('u2', 'h4'); null for 'types' and 'farewell'.
  String? paragraph(String ref) {
    final n = int.tryParse(ref.substring(1));
    if (n == null || n < 1) return null;
    final list = ref.startsWith('u') ? umrah : (ref.startsWith('h') ? hajj : const <String>[]);
    return n <= list.length ? list[n - 1] : null;
  }
}
