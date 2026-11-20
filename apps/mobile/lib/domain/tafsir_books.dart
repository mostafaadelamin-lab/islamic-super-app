import 'dart:convert';

/// The tafsir books and the ayah studies (owner 2026-11-20). In the Mushaf al-Muyassar stays the default; the
/// reader can switch to al-Sa'di, Ibn Kathir, al-Tabari, al-Baghawi or al-Qurtubi, and open the gharib, i'rab,
/// sarf, balagha and fawa'id of the ayah. Every text is kept exactly as the books publish it
/// (tools/tafsir_books.py, tools/irab_build.py); nothing here edits it.
enum TafsirBookId {
  muyassar('muyassar', 'التفسير الميسر', 'الميسر', 'Al-Muyassar', 'نخبة من العلماء', BookLength.short),
  saadi('saadi', 'تفسير السعدي', 'السعدي', "Al-Sa'di", 'عبد الرحمن بن ناصر السعدي', BookLength.medium),
  ibnKathir('ibn-kathir', 'تفسير ابن كثير', 'ابن كثير', 'Ibn Kathir', 'ابن كثير', BookLength.long),
  tabari('tabari', 'تفسير الطبري', 'الطبري', 'Al-Tabari', 'محمد بن جرير الطبري', BookLength.long),
  baghawi('baghawi', 'تفسير البغوي', 'البغوي', 'Al-Baghawi', 'الحسين بن مسعود البغوي', BookLength.long),
  qurtubi('qurtubi', 'تفسير القرطبي', 'القرطبي', 'Al-Qurtubi', 'محمد بن أحمد القرطبي', BookLength.long);

  const TafsirBookId(this.id, this.nameAr, this.shortAr, this.nameEn, this.authorAr, this.length);

  /// The folder name on the website (/data/tafsir/`<id>`/).
  final String id;
  final String nameAr;
  final String shortAr;
  final String nameEn;
  final String authorAr;
  final BookLength length;

  static TafsirBookId? byId(String id) {
    for (final b in values) {
      if (b.id == id) return b;
    }
    return null;
  }
}

enum BookLength { short, medium, long }

/// What the ayah card shows: the tafsir, or one study of the ayah.
enum StudyTab { tafsir, gharib, irab, sarf, balagha, fawaid }

/// The i'rab parts of «الجدول في إعراب القرآن وصرفه وبيانه», in the book's order.
const irabTabs = [StudyTab.irab, StudyTab.sarf, StudyTab.balagha, StudyTab.fawaid];

/// A passage of a book that explains ayahs [from]..[to] of a surah together.
class BookSection {
  const BookSection(this.from, this.to, this.text, [this.notes = '']);
  final int from;
  final int to;
  final String text;

  /// The editor's footnotes ('' when none).
  final String notes;

  bool get isRange => from != to;
}

/// One section of «الجدول»: the four parts ('' when the book has none for these ayahs).
class IrabSection {
  const IrabSection(this.from, this.to, this.parts);
  final int from;
  final int to;
  final List<String> parts;

  String part(StudyTab tab) => parts[irabTabs.indexOf(tab)];
}

/// Parses one surah file of a book (/data/tafsir/`<book>`/`<n>`.json: [[from, to, text, notes?], ...]) and checks
/// that every ayah of the surah belongs to exactly one section.
List<BookSection> parseBookSurah(String json, int ayahCount) {
  final raw = jsonDecode(json) as List<dynamic>;
  final secs = [
    for (final s in raw)
      BookSection((s as List<dynamic>)[0] as int, s[1] as int, s[2] as String, s.length > 3 ? s[3] as String : ''),
  ];
  checkCoverage([for (final s in secs) (s.from, s.to)], ayahCount);
  return secs;
}

/// Parses one surah file of «الجدول» (/data/irab/jadwal/`<n>`.json: [[from, to, irab, sarf, balagha, fawaid], ...]).
List<IrabSection> parseIrabSurah(String json, int ayahCount) {
  final raw = jsonDecode(json) as List<dynamic>;
  final secs = [
    for (final s in raw)
      IrabSection((s as List<dynamic>)[0] as int, s[1] as int, [for (final p in s.sublist(2, 6)) p as String]),
  ];
  checkCoverage([for (final s in secs) (s.from, s.to)], ayahCount);
  return secs;
}

void checkCoverage(List<(int, int)> ranges, int ayahCount) {
  var next = 1;
  for (final (from, to) in ranges) {
    if (from != next || to < from) throw const FormatException('tafsir sections out of order');
    next = to + 1;
  }
  if (next != ayahCount + 1) throw FormatException('tafsir sections cover ${next - 1} of $ayahCount ayahs');
}

/// The section that explains [ayah].
T sectionFor<T>(List<T> secs, int ayah, (int, int) Function(T) range) {
  for (final s in secs) {
    final (from, to) = range(s);
    if (from <= ayah && ayah <= to) return s;
  }
  throw RangeError('no section for ayah $ayah');
}

/// A Quran quote inside a book's text («﴿…﴾»), shown in the Quran colour.
final quoteRe = RegExp('﴿[^﴾]*﴾');

// ---- Search ---------------------------------------------------------------------------------------------

final _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
const _forms = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ة': 'ه', 'ؤ': 'و', 'ئ': 'ي'};

/// Letters only, for matching: no tashkeel or tatweel, alef/ya/ta-marbuta forms unified.
String normalizeArabic(String s) {
  final b = StringBuffer();
  for (final r in s.replaceAll(_marks, '').runes) {
    final c = String.fromCharCode(r);
    b.write(_forms[c] ?? c);
  }
  return b.toString();
}

class SearchHit {
  const SearchHit(this.surah, this.from, this.to, this.before, this.match, this.after);
  final int surah;
  final int from;
  final int to;
  final String before;
  final String match;
  final String after;
}

const searchLimit = 200;
const minQueryLetters = 2;

/// The first match of [q] (already normalized) in [text], with the words around it, verbatim.
SearchHit? hitIn(String text, int surah, int from, int to, String q) {
  final norm = StringBuffer();
  final map = <int>[];
  final white = RegExp(r'\s');
  var lastSpace = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    final n = white.hasMatch(ch) ? ' ' : normalizeArabic(ch);
    if (n.isEmpty) continue;
    if (n == ' ' && lastSpace) continue;
    lastSpace = n == ' ';
    norm.write(n);
    map.add(i);
  }
  final s = norm.toString();
  final at = s.indexOf(q);
  if (at < 0) return null;
  final start = map[at];
  final end = map[at + q.length - 1] + 1;
  final b = text.lastIndexOf(' ', (start - 60).clamp(0, text.length));
  final cut = b < 0 ? 0 : b;
  final stop = text.indexOf(' ', (end + 80).clamp(0, text.length));
  return SearchHit(
    surah,
    from,
    to,
    (cut > 0 ? '… ' : '') + text.substring(cut, start).trimLeft(),
    text.substring(start, end),
    stop < 0 ? text.substring(end) : '${text.substring(end, stop)} …',
  );
}

/// Searches every section of a book (one list of sections per surah), in Mushaf order.
List<SearchHit> searchSections(List<List<BookSection>> surahs, String query) {
  final q = normalizeArabic(query.trim()).replaceAll(RegExp(r'\s+'), ' ');
  if (q.length < minQueryLetters) return const [];
  final hits = <SearchHit>[];
  for (var i = 0; i < surahs.length; i++) {
    for (final sec in surahs[i]) {
      final h = hitIn(sec.text, i + 1, sec.from, sec.to, q);
      if (h != null) hits.add(h);
      if (hits.length >= searchLimit) return hits;
    }
  }
  return hits;
}
