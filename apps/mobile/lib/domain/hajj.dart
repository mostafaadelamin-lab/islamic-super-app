// Hajj & Umrah guide, extracted verbatim from content/pilgrimage/source-hajj.js
// into assets/content/hajj.v1.json by tool/extract_hajj.mjs.
// Religious review is pending: the UI shows a visible notice.

class HajjDef {
  const HajjDef(this.term, this.detail);
  final String term;
  final String detail;
}

class HajjBlock {
  const HajjBlock({
    required this.kind,
    this.label,
    this.title,
    this.text,
    this.items = const [],
    this.paragraphs = const [],
    this.dua,
    this.defs = const [],
  });

  factory HajjBlock.fromJson(Map<String, dynamic> j) => HajjBlock(
    kind: j['kind'] as String,
    label: j['label'] as String?,
    title: j['title'] as String?,
    text: j['text'] as String?,
    items: List.unmodifiable(((j['items'] as List<dynamic>?) ?? const []).cast<String>()),
    paragraphs: List.unmodifiable(((j['paragraphs'] as List<dynamic>?) ?? const []).cast<String>()),
    dua: j['dua'] as String?,
    defs: List.unmodifiable([
      for (final d in (j['defs'] as List<dynamic>?) ?? const [])
        HajjDef((d as Map<String, dynamic>)['term'] as String, d['detail'] as String),
    ]),
  );

  /// "intro" (a single paragraph) or "card".
  final String kind;
  final String? label;
  final String? title;
  final String? text;
  final List<String> items;
  final List<String> paragraphs;
  final String? dua;
  final List<HajjDef> defs;

  /// Every string in the block (used by the source-fidelity test).
  Iterable<String> get strings sync* {
    for (final s in [label, title, text, dua]) {
      if (s != null) yield s;
    }
    yield* items;
    yield* paragraphs;
    for (final d in defs) {
      yield d.term;
      yield d.detail;
    }
  }
}

class HajjGuide {
  const HajjGuide({required this.talbiya, required this.sections, required this.reviewStatus});

  factory HajjGuide.fromJson(Map<String, dynamic> j) => HajjGuide(
    talbiya: j['talbiya'] as String,
    reviewStatus: j['reviewStatus'] as String? ?? '',
    sections: Map.unmodifiable({
      for (final e in (j['sections'] as Map<String, dynamic>).entries)
        e.key: List<HajjBlock>.unmodifiable([
          for (final b in e.value as List<dynamic>) HajjBlock.fromJson(b as Map<String, dynamic>),
        ]),
    }),
  );

  final String talbiya;
  final String reviewStatus;

  /// "umrah", "hajj", "ihram".
  final Map<String, List<HajjBlock>> sections;
}
