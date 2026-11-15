/// The sourced Hajj & Umrah guide (owner 2026-11-16) and its 3D pictures.
///
/// assets/content/hajj-guide.v2.json is made by content/pilgrimage/build-guide.mjs, which cuts every text
/// out of its published source (Ibn Baz «التحقيق والإيضاح» with page numbers, the official «دليل الحاج
/// والمعتمر», the hadith books, Hisn al-Muslim) and puts the KFGQPC words in for every ayah. Nothing here
/// writes religious text; the website reads the same files.
library;

/// A run of a text: plain words, or ayahs of the Quran (the KFGQPC text).
sealed class GuideSeg {
  const GuideSeg();
  static GuideSeg fromJson(Map<String, dynamic> j) =>
      j['t'] == 'quran' ? QuranSeg.fromJson(j) : TextSeg(j['v'] as String);
  static List<GuideSeg> list(dynamic l) => [
    for (final x in (l as List<dynamic>? ?? const [])) GuideSeg.fromJson(x as Map<String, dynamic>),
  ];
}

class TextSeg extends GuideSeg {
  const TextSeg(this.text);
  final String text;
}

class QuranSeg extends GuideSeg {
  const QuranSeg({required this.surah, required this.from, required this.to, required this.texts, this.part});
  factory QuranSeg.fromJson(Map<String, dynamic> j) => QuranSeg(
    surah: j['s'] as int,
    from: j['from'] as int,
    to: j['to'] as int,
    texts: [for (final x in j['texts'] as List<dynamic>) x as String],
    part: j['part'] as String?,
  );
  final int surah;
  final int from;
  final int to;

  /// The whole ayahs [from]..[to].
  final List<String> texts;

  /// When the source quotes only some words of the ayah: those words (then only they are shown).
  final String? part;
}

enum GuideItemKind { text, hadith, say, quran, table }

class GuideItem {
  const GuideItem({
    required this.kind,
    this.segs = const [],
    this.src = '',
    this.times,
    this.notes = const [],
    this.quran,
    this.say = false,
    this.citeText,
    this.citeSrc,
    this.head = const [],
    this.rows = const [],
  });

  factory GuideItem.fromJson(Map<String, dynamic> j) {
    final kind = GuideItemKind.values.byName(j['k'] as String);
    final cite = j['cite'] as Map<String, dynamic>?;
    return GuideItem(
      kind: kind,
      segs: GuideSeg.list(j['segs']),
      src: j['src'] as String? ?? '',
      times: j['times'] as int?,
      notes: [for (final x in j['notes'] as List<dynamic>? ?? const []) x as String],
      quran: kind == GuideItemKind.quran ? QuranSeg.fromJson(j) : null,
      say: j['say'] == true,
      citeText: cite?['text'] as String?,
      citeSrc: cite?['src'] as String?,
      head: [for (final x in j['head'] as List<dynamic>? ?? const []) x as String],
      rows: [
        for (final r in j['rows'] as List<dynamic>? ?? const []) [for (final c in r as List<dynamic>) c as String],
      ],
    );
  }

  final GuideItemKind kind;
  final List<GuideSeg> segs;
  final String src;

  /// How many times it is said (the Safa and Marwah dhikr: three).
  final int? times;
  final List<String> notes;
  final QuranSeg? quran;

  /// An ayah said by the pilgrim (shaded like a dua).
  final bool say;

  /// The hadith that tells where the ayah is said, quoted up to it.
  final String? citeText;
  final String? citeSrc;
  final List<String> head;
  final List<List<String>> rows;
}

class GuideSub {
  const GuideSub({required this.title, required this.items, this.tags = const [], this.scene});
  factory GuideSub.fromJson(Map<String, dynamic> j) => GuideSub(
    title: j['title'] as String,
    tags: [for (final x in j['tags'] as List<dynamic>? ?? const []) x as String],
    scene: j['scene'] as String?,
    items: [for (final x in j['items'] as List<dynamic>) GuideItem.fromJson(x as Map<String, dynamic>)],
  );
  final String title;

  /// men, women, first (the first tawaf only).
  final List<String> tags;
  final String? scene;
  final List<GuideItem> items;
}

class GuideStep {
  const GuideStep({required this.title, required this.subs, this.scene});
  final String title;
  final String? scene;
  final List<String> subs;
}

class GuideFlowStep {
  const GuideFlowStep({required this.title, required this.step, this.dalil});
  final String title;
  final String step;

  /// The official guide's paragraph: "u1".."u4", "h1".."h9", or "types" (the kind itself).
  final String? dalil;
}

class GuideSource {
  const GuideSource({required this.id, required this.title, this.author, this.publisher, this.edition});
  final String id;
  final String title;
  final String? author;
  final String? publisher;
  final String? edition;
}

class SourcedHajjGuide {
  const SourcedHajjGuide({
    required this.sources,
    required this.corrections,
    required this.subs,
    required this.steps,
    required this.flows,
    required this.umrahIntro,
    required this.days,
    required this.ihram,
    required this.madinah,
    this.pillars = '',
    required this.officialTitle,
    required this.officialTypes,
    required this.officialTypesNote,
    required this.officialUmrah,
    required this.officialHajj,
  });

  factory SourcedHajjGuide.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 'hajj-guide.v2') throw const FormatException('hajj-guide.v2.json: unexpected schema');
    final hub = j['hub'] as Map<String, dynamic>;
    final off = j['official'] as Map<String, dynamic>;
    List<String> strings(dynamic l) => [for (final x in l as List<dynamic>) x as String];
    return SourcedHajjGuide(
      sources: [
        for (final s in j['sources'] as List<dynamic>)
          GuideSource(
            id: (s as Map<String, dynamic>)['id'] as String,
            title: s['title'] as String,
            author: s['author'] as String?,
            publisher: s['publisher'] as String?,
            edition: s['edition'] as String?,
          ),
      ],
      corrections: strings(j['corrections']),
      subs: {
        for (final e in (j['subs'] as Map<String, dynamic>).entries)
          e.key: GuideSub.fromJson(e.value as Map<String, dynamic>),
      },
      steps: {
        for (final e in (j['steps'] as Map<String, dynamic>).entries)
          e.key: GuideStep(
            title: (e.value as Map<String, dynamic>)['title'] as String,
            scene: e.value['scene'] as String?,
            subs: strings(e.value['subs']),
          ),
      },
      flows: {
        for (final e in (j['flows'] as Map<String, dynamic>).entries)
          e.key: [
            for (final s in e.value as List<dynamic>)
              GuideFlowStep(
                title: (s as Map<String, dynamic>)['title'] as String,
                step: s['step'] as String,
                dalil: s['dalil'] as String?,
              ),
          ],
      },
      umrahIntro: hub['umrahIntro'] as String,
      days: strings(hub['days']),
      ihram: strings(hub['ihram']),
      madinah: hub['madinah'] as String,
      pillars: hub['pillars'] as String? ?? '',
      officialTitle: off['title'] as String,
      officialTypes: [
        for (final t in off['types'] as List<dynamic>)
          (name: (t as Map<String, dynamic>)['name'] as String, segs: GuideSeg.list(t['segs'])),
      ],
      officialTypesNote: GuideSeg.list(off['typesNote']),
      officialUmrah: [for (final p in off['umrah'] as List<dynamic>) GuideSeg.list(p)],
      officialHajj: [for (final p in off['hajj'] as List<dynamic>) GuideSeg.list(p)],
    );
  }

  static const empty = SourcedHajjGuide(
    sources: [],
    corrections: [],
    subs: {},
    steps: {},
    flows: {},
    umrahIntro: '',
    days: [],
    ihram: [],
    madinah: '',
    officialTitle: '',
    officialTypes: [],
    officialTypesNote: [],
    officialUmrah: [],
    officialHajj: [],
  );

  final List<GuideSource> sources;
  final List<String> corrections;
  final Map<String, GuideSub> subs;
  final Map<String, GuideStep> steps;

  /// umrah, tamattu, qiran, ifrad.
  final Map<String, List<GuideFlowStep>> flows;
  final String umrahIntro;
  final List<String> days;
  final List<String> ihram;
  final String madinah;

  /// The pillars of Hajj (Ibn Baz's fatwa, owner 2026-11-16).
  final String pillars;
  final String officialTitle;
  final List<({String name, List<GuideSeg> segs})> officialTypes;
  final List<GuideSeg> officialTypesNote;
  final List<List<GuideSeg>> officialUmrah;
  final List<List<GuideSeg>> officialHajj;

  static const _kindInOfficial = {'tamattu': 'التمتع', 'qiran': 'القِرَان', 'ifrad': 'الإفراد'};

  /// The official guide's own paragraph for a step of [kind], or null.
  List<GuideSeg>? official(String? dalil, String kind) {
    if (dalil == null) return null;
    if (dalil == 'types') {
      for (final t in officialTypes) {
        if (t.name == _kindInOfficial[kind]) return t.segs;
      }
      return null;
    }
    final n = int.tryParse(dalil.substring(1));
    final list = dalil.startsWith('u') ? officialUmrah : officialHajj;
    return n != null && n >= 1 && n <= list.length ? list[n - 1] : null;
  }

  /// Every picture a step shows: its own, then those of its parts.
  List<String> scenesOf(String stepId) {
    final step = steps[stepId];
    if (step == null) return const [];
    return {?step.scene, for (final k in step.subs) ?subs[k]?.scene}.toList();
  }
}

/// One shape of a picture, in the picture's own box. Colours are roles (scene-roles.v1.json).
class SceneShape {
  const SceneShape(this.j);
  final Map<String, dynamic> j;
  String get type => j['t'] as String;
  double n(String k) => (j[k] as num).toDouble();
  List<double> get points => [for (final x in j['p'] as List<dynamic>) (x as num).toDouble()];
  String? get fill => j['f'] as String?;
  String? get stroke => j['s'] as String?;
  double get strokeWidth => (j['sw'] as num?)?.toDouble() ?? 1;
  List<double>? get dash => (j['dash'] as List<dynamic>?)?.map((x) => (x as num).toDouble()).toList();
  bool get arrow => j['arrow'] == true;
  String get text => j['v'] as String;
}

class HajjScene {
  const HajjScene({
    required this.id,
    required this.w,
    required this.h,
    required this.title,
    required this.places,
    required this.shapes,
  });
  final String id;
  final double w;
  final double h;
  final String title;

  /// The places it shows (Umrah steps never show mina, arafah, muzdalifah or jamarat).
  final List<String> places;
  final List<SceneShape> shapes;
}

/// A role's colour: 't:name' token of the style, 'b:name' brand colour, '#rrggbb[aa]', or a mix.
sealed class RoleColour {
  const RoleColour();
  static RoleColour parse(dynamic x) {
    if (x is List) return MixColour(parse(x[1]), parse(x[2]), (x[3] as num).toDouble());
    final s = x as String;
    if (s.startsWith('t:')) return TokenColour(s.substring(2));
    if (s.startsWith('b:')) return BrandColour(s.substring(2));
    return FixedColour(int.parse(s.length == 7 ? '${s.substring(1)}ff' : s.substring(1), radix: 16));
  }
}

class TokenColour extends RoleColour {
  const TokenColour(this.name);
  final String name;
}

class BrandColour extends RoleColour {
  const BrandColour(this.name);
  final String name;
}

/// RGBA as 0xRRGGBBAA.
class FixedColour extends RoleColour {
  const FixedColour(this.rgba);
  final int rgba;
}

/// [p] of [a] mixed with [b].
class MixColour extends RoleColour {
  const MixColour(this.a, this.b, this.p);
  final RoleColour a;
  final RoleColour b;
  final double p;
}

class HajjScenes {
  const HajjScenes({required this.scenes, required this.roles});
  factory HajjScenes.fromJson(Map<String, dynamic> scenes, Map<String, dynamic> roles) {
    if (scenes['schema'] != 'hajj-scenes.v1') throw const FormatException('hajj-scenes.v1.json: unexpected schema');
    return HajjScenes(
      scenes: {
        for (final e in (scenes['scenes'] as Map<String, dynamic>).entries)
          e.key: HajjScene(
            id: e.key,
            w: ((e.value as Map<String, dynamic>)['w'] as num).toDouble(),
            h: (e.value['h'] as num).toDouble(),
            title: e.value['title'] as String,
            places: [for (final p in e.value['places'] as List<dynamic>) p as String],
            shapes: [for (final s in e.value['shapes'] as List<dynamic>) SceneShape(s as Map<String, dynamic>)],
          ),
      },
      roles: {for (final e in (roles['roles'] as Map<String, dynamic>).entries) e.key: RoleColour.parse(e.value)},
    );
  }
  static const empty = HajjScenes(scenes: {}, roles: {});
  final Map<String, HajjScene> scenes;
  final Map<String, RoleColour> roles;
}
