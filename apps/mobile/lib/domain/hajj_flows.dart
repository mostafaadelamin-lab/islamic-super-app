// Hajj steps in order for each type (owner, 2026-11-14: show the type, Muzdalifah, and what
// comes before the day of Tarwiyah), and the official guide whose own words explain each step.
// Same lists as apps/web/src/lib/hajj-flows.ts.

enum HajjType { tamattu, qiran, ifrad }

/// A step name and the paragraph of the official guide that explains it:
/// 'types', 'u1'..'u4' (Umrah), 'h1'..'h9' (Hajj) or 'farewell' (the app's own Hajj guide).
class FlowStep {
  const FlowStep(this.title, this.ref);
  final String title;
  final String ref;
}

const _daysAfterIhram = [
  FlowStep('منى يوم التروية', 'h2'),
  FlowStep('الوقوف بعرفة', 'h3'),
  FlowStep('المبيت بمزدلفة', 'h4'),
  FlowStep('رمي جمرة العقبة', 'h6'),
];
const _end = [
  FlowStep('المبيت بمنى أيام التشريق', 'h8'),
  FlowStep('رمي الجمرات الثلاث', 'h9'),
  FlowStep('طواف الوداع', 'farewell'),
];
const _qiranIfradStart = [
  FlowStep('طواف القدوم', 'u2'),
  FlowStep('السعي بعد طواف القدوم', 'h7'),
  FlowStep('البقاء على الإحرام', 'types'),
];

const hajjFlows = <HajjType, List<FlowStep>>{
  HajjType.tamattu: [
    FlowStep('الإحرام بالعمرة من الميقات', 'u1'),
    FlowStep('طواف العمرة', 'u2'),
    FlowStep('سعي العمرة', 'u3'),
    FlowStep('الحلق أو التقصير والتحلل', 'u4'),
    FlowStep('الإحرام بالحج يوم التروية', 'h1'),
    ..._daysAfterIhram,
    FlowStep('ذبح الهدي', 'h6'),
    FlowStep('الحلق أو التقصير', 'h6'),
    FlowStep('طواف الإفاضة ثم السعي', 'h7'),
    ..._end,
  ],
  HajjType.qiran: [
    FlowStep('الإحرام بالعمرة والحج من الميقات', 'h1'),
    ..._qiranIfradStart,
    ..._daysAfterIhram,
    FlowStep('ذبح الهدي', 'h6'),
    FlowStep('الحلق أو التقصير', 'h6'),
    FlowStep('طواف الإفاضة', 'h7'),
    ..._end,
  ],
  HajjType.ifrad: [
    FlowStep('الإحرام بالحج من الميقات', 'h1'),
    ..._qiranIfradStart,
    ..._daysAfterIhram,
    FlowStep('الحلق أو التقصير', 'h6'),
    FlowStep('طواف الإفاضة', 'h7'),
    ..._end,
  ],
};

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
