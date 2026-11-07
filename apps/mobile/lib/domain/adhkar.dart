// Morning/evening adhkar (content/adhkar/dist/adhkar.v1.json) and
// Hisn al-Muslim (content/adhkar/hisn.json). The texts are shown exactly as
// stored; this file only adds, per item, WHEN it is said and HOW MANY times.
//
// Those two facts are not in adhkar.v1.json. They are taken from the
// "أذكار الصباح والمساء" chapter of hisn.json, whose own text carries the
// counts, e.g. "( ثلاث مرات )" or "(مائة مرة إذا أصبح )".
// test/unit/adhkar_test.dart re-derives every count and session from that
// chapter's text, so this table cannot drift from the source.
// Religious review of the selection and counts is still pending.

enum AdhkarSession { morning, evening }

class AdhkarMeta {
  const AdhkarMeta(this.sessions, this.count, this.hisnIndex);

  /// When the item is said.
  final Set<AdhkarSession> sessions;

  /// Repetitions.
  final int count;

  /// Index in hisn.json's "أذكار الصباح والمساء" chapter the count/session
  /// come from, or null when the item is not in that chapter.
  final int? hisnIndex;
}

const _m = {AdhkarSession.morning};
const _e = {AdhkarSession.evening};
const _b = {AdhkarSession.morning, AdhkarSession.evening};

/// Indexed like adhkar.v1.json `items` (34 entries).
const adhkarMeta = <AdhkarMeta>[
  AdhkarMeta(_b, 1, 0), // 0  الحمد لله وحده
  AdhkarMeta(_b, 1, 1), // 1  آية الكرسي
  AdhkarMeta(_e, 1, null), // 2  آخر آيتين من البقرة (not in the chapter; read at night)
  AdhkarMeta(_b, 3, 2), // 3  الإخلاص
  AdhkarMeta(_b, 3, 2), // 4  الفلق
  AdhkarMeta(_b, 3, 2), // 5  الناس
  AdhkarMeta(_m, 1, 3), // 6  أصبحنا وأصبح الملك لله
  AdhkarMeta(_e, 1, 3), // 7  أمسينا وأمسى الملك لله
  AdhkarMeta(_m, 1, 4), // 8  اللهم بك أصبحنا
  AdhkarMeta(_e, 1, 4), // 9  اللهم بك أمسينا
  AdhkarMeta(_b, 1, 5), // 10 سيد الاستغفار
  AdhkarMeta(_m, 4, 6), // 11 اللهم إني أصبحت أشهدك
  AdhkarMeta(_e, 4, 6), // 12 اللهم إني أمسيت أشهدك
  AdhkarMeta(_m, 1, 7), // 13 اللهم ما أصبح بي من نعمة
  AdhkarMeta(_e, 1, 7), // 14 اللهم ما أمسى بي من نعمة
  AdhkarMeta(_b, 3, 8), // 15 اللهم عافني في بدني
  AdhkarMeta(_b, 7, 9), // 16 حسبي الله
  AdhkarMeta(_b, 1, 10), // 17 اللهم إني أسألك العفو والعافية
  AdhkarMeta(_b, 1, 11), // 18 اللهم عالم الغيب والشهادة
  AdhkarMeta(_b, 3, 12), // 19 بسم الله الذي لا يضر مع اسمه شيء
  AdhkarMeta(_b, 3, 13), // 20 رضيت بالله رباً
  AdhkarMeta(_b, 1, 14), // 21 يا حي يا قيوم
  AdhkarMeta(_m, 1, 15), // 22 أصبحنا وأصبح الملك لله رب العالمين
  AdhkarMeta(_e, 1, 15), // 23 أمسينا وأمسى الملك لله رب العالمين
  AdhkarMeta(_m, 1, 16), // 24 أصبحنا على فطرة الإسلام
  AdhkarMeta(_e, 1, 16), // 25 أمسينا على فطرة الإسلام
  AdhkarMeta(_m, 1, 21), // 26 اللهم إني أسألك علماً نافعاً
  AdhkarMeta(_b, 10, 18), // 27 لا إله إلا الله وحده (عشر مرات)
  AdhkarMeta(_b, 10, 24), // 28 اللهم صل وسلم على نبينا محمد
  AdhkarMeta(_e, 3, 23), // 29 أعوذ بكلمات الله التامات
  AdhkarMeta(_m, 3, 20), // 30 سبحان الله وبحمده عدد خلقه
  AdhkarMeta(_m, 100, 19), // 31 لا إله إلا الله وحده (مائة مرة إذا أصبح)
  AdhkarMeta(_b, 100, 22), // 32 أستغفر الله وأتوب إليه
  AdhkarMeta(_b, 100, 17), // 33 سبحان الله وبحمده
];

class Dhikr {
  const Dhikr({required this.index, required this.text, required this.meta});
  final int index;
  final String text;
  final AdhkarMeta meta;
}

class HisnChapter {
  const HisnChapter(this.index, this.title, this.items);
  final int index;
  final String title;
  final List<String> items;
}

/// Name of the Hisn chapter the counts come from.
const hisnMorningEveningTitle = 'أذكار الصباح والمساء';

class AdhkarContent {
  AdhkarContent({required this.items, required this.hisn});

  factory AdhkarContent.fromJson(Map<String, dynamic> adhkar, List<dynamic> hisn) {
    final texts = (adhkar['items'] as List<dynamic>).cast<String>();
    if (texts.length != adhkarMeta.length) {
      throw FormatException('adhkar.v1.json has ${texts.length} items, metadata covers ${adhkarMeta.length}');
    }
    return AdhkarContent(
      items: List.unmodifiable([
        for (var i = 0; i < texts.length; i++) Dhikr(index: i, text: texts[i], meta: adhkarMeta[i]),
      ]),
      hisn: List.unmodifiable([
        for (var i = 0; i < hisn.length; i++)
          HisnChapter(
            i,
            (hisn[i] as List<dynamic>)[0] as String,
            List.unmodifiable(((hisn[i] as List<dynamic>)[1] as List<dynamic>).cast<String>()),
          ),
      ]),
    );
  }

  final List<Dhikr> items;
  final List<HisnChapter> hisn;

  List<Dhikr> forSession(AdhkarSession s) => [
    for (final d in items)
      if (d.meta.sessions.contains(s)) d,
  ];
}

/// Arabic count phrases used in hisn.json, and the number each one means.
const hisnCountPhrases = <String, int>{'ثلاث مرات': 3, 'أربع مرات': 4, 'سبع مرات': 7, 'عشر مرات': 10, 'مائة مرة': 100};

/// The repetition count stated in a Hisn text, or 1 when none is stated.
int countStatedIn(String hisnText) {
  for (final e in hisnCountPhrases.entries) {
    if (hisnText.contains(e.key)) return e.value;
  }
  return 1;
}

/// Per-item counters for one session on one day. Tapping counts down from the
/// item's count; an item is done at zero.
class AdhkarProgress {
  AdhkarProgress(this.items, [Map<int, int>? done]) : _done = {...?done};

  final List<Dhikr> items;
  final Map<int, int> _done;

  Map<int, int> get done => Map.unmodifiable(_done);

  int countOf(Dhikr d) => _done[d.index] ?? 0;
  int remaining(Dhikr d) => (d.meta.count - countOf(d)).clamp(0, d.meta.count);
  bool isDone(Dhikr d) => remaining(d) == 0;

  /// Counts one repetition; returns false when the item was already complete.
  bool tap(Dhikr d) {
    if (isDone(d)) return false;
    _done[d.index] = countOf(d) + 1;
    return true;
  }

  void reset(Dhikr d) => _done.remove(d.index);
  void resetAll() => _done.clear();

  int get completedItems => items.where(isDone).length;
  double get fraction => items.isEmpty ? 0 : completedItems / items.length;
}
