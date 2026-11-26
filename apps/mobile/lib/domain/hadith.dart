/// The nine hadith books, bundled in assets/hadith (copied from content/hadith/dist). Sahih al-Bukhari and
/// Sahih Muslim are the sunnah.com copy with sunnah.com numbers (tools/build_hadith_sunnah.py, owner
/// 2026-11-26); the other seven are Open-Hadith-Data (ODbL 1.0, tools/build_hadith.py). The texts are shown
/// exactly as in the source; this file only describes the books and the saved list.
library;

class HadithBook {
  const HadithBook({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.count,
    required this.chunks,
    required this.textSha256,
    this.refs = false,
  });

  factory HadithBook.fromJson(Map<String, dynamic> j) => HadithBook(
    id: j['id'] as String,
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    count: j['count'] as int,
    chunks: j['chunks'] as int,
    textSha256: j['textSha256'] as String,
    refs: j['refs'] == true,
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final int count;
  final int chunks;

  /// SHA-256 of all the texts joined with "\n" (checked by the tests).
  final String textSha256;

  /// true: every entry has its sunnah.com number in BOOK/refs.json; the entry index n is only the
  /// app's own position (links, bookmarks).
  final bool refs;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class HadithCatalog {
  const HadithCatalog({
    required this.reviewStatus,
    required this.chunkSize,
    required this.sourceName,
    required this.sourceUrl,
    required this.licence,
    required this.books,
  });

  factory HadithCatalog.fromJson(Map<String, dynamic> j) {
    final source = j['source'] as Map<String, dynamic>;
    return HadithCatalog(
      reviewStatus: j['reviewStatus'] as String,
      chunkSize: j['chunkSize'] as int,
      sourceName: source['name'] as String,
      sourceUrl: source['url'] as String,
      licence: source['licence'] as String,
      books: [for (final b in j['books'] as List<dynamic>) HadithBook.fromJson(b as Map<String, dynamic>)],
    );
  }

  static const empty = HadithCatalog(
    reviewStatus: 'pending',
    chunkSize: 500,
    sourceName: '',
    sourceUrl: '',
    licence: '',
    books: [],
  );

  final String reviewStatus;

  /// Hadiths per part file (assets/hadith/BOOK/K.json).
  final int chunkSize;
  final String sourceName;
  final String sourceUrl;
  final String licence;
  final List<HadithBook> books;

  HadithBook? book(String id) => books.where((b) => b.id == id).firstOrNull;

  /// Which part file holds hadith [n] (1-based).
  int chunkOf(int n) => (n - 1) ~/ chunkSize;

  /// A saved key ("bukhari:1") if it names a book and a number inside it.
  (HadithBook, int)? parseKey(String key) {
    final i = key.indexOf(':');
    if (i <= 0) return null;
    final b = book(key.substring(0, i));
    final n = int.tryParse(key.substring(i + 1));
    if (b == null || n == null || n < 1 || n > b.count) return null;
    return (b, n);
  }
}

class HadithItem {
  const HadithItem(this.n, this.text, [this.ref]);

  /// Position of the entry in the book (1-based).
  final int n;
  final String text;

  /// sunnah.com number(s), raw: "2186", "1218a", "5709,5710", "intro3", "~597b" (null for other books).
  final String? ref;
}

/// sunnah.com letters after a number (a, b, c…) as Arabic abjad letters.
const _abjad = 'أبجدهوزحطيكلمنسعفصقرشتثخذضظغ';
final _refRe = RegExp(r'^(\d+)([a-z]?)$');

String _oneRef(String r, bool arabic, String Function(Object) digits) {
  final intro = RegExp(r'^intro(\d+)$').firstMatch(r);
  if (intro != null) return arabic ? 'المقدمة ${digits(intro.group(1)!)}' : 'Introduction ${intro.group(1)}';
  final m = _refRe.firstMatch(r);
  if (m == null) return r;
  final l = m.group(2)!;
  final letter = l.isEmpty
      ? ''
      : arabic
      ? ' ${_abjad[l.codeUnitAt(0) - 97]}'
      : l;
  return '${digits(m.group(1)!)}$letter';
}

/// A raw sunnah.com number for display: "1218a" → "١٢١٨ أ", "5709,5710" → "٥٧٠٩، ٥٧١٠", "~597b" → "بعد ٥٩٧ ب".
String hadithRefLabel(String raw, bool arabic, String Function(Object) digits) {
  if (raw.isEmpty) return '';
  if (raw.startsWith('~')) {
    final inner = _oneRef(raw.substring(1), arabic, digits);
    return arabic ? 'بعد $inner' : 'after $inner';
  }
  return raw.split(',').map((r) => _oneRef(r, arabic, digits)).join(arabic ? '، ' : ', ');
}

/// The entry (1-based) holding sunnah.com number [query] ("2186", "2186a", "١٢١٨"); null when none.
/// A number without a letter opens its first part.
int? findHadithRef(List<String> refs, String query) {
  final q = String.fromCharCodes(
    query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '').runes.map(
      (r) => r >= 0x0660 && r <= 0x0669 ? r - 0x0660 + 0x30 : r,
    ),
  );
  final m = _refRe.firstMatch(q);
  if (m == null) return null;
  final base = int.parse(m.group(1)!).toString();
  final letter = m.group(2)!;
  for (var i = 0; i < refs.length; i++) {
    if (refs[i].startsWith('~')) continue;
    for (final r in refs[i].split(',')) {
      final x = _refRe.firstMatch(r);
      if (x != null && x.group(1) == base && (letter.isEmpty || x.group(2) == letter)) return i + 1;
    }
  }
  return null;
}

/// Text for display: the source's own words without the spaces around them. The sunnah.com copy keeps the
/// line breaks of the site's page source, which the site itself shows as spaces: shown the same way here.
String hadithDisplayText(String text) => text.replaceAll(RegExp(r'[ \t]*\n\s*'), ' ').trim();

/// Hadiths shown per screen.
const hadithPageSize = 20;

/// Most results a search returns.
const hadithSearchLimit = 200;

/// First number on the screen that holds hadith [n].
int hadithPageStart(int n) => (n - 1) ~/ hadithPageSize * hadithPageSize + 1;
