/// The nine hadith books from Open-Hadith-Data (ODbL 1.0), bundled in assets/hadith
/// (copied from content/hadith/dist, built by tools/build_hadith.py). The texts are shown
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
  });

  factory HadithBook.fromJson(Map<String, dynamic> j) => HadithBook(
    id: j['id'] as String,
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    count: j['count'] as int,
    chunks: j['chunks'] as int,
    textSha256: j['textSha256'] as String,
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final int count;
  final int chunks;

  /// SHA-256 of all the texts joined with "\n" (checked by the tests).
  final String textSha256;

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
  const HadithItem(this.n, this.text);
  final int n;
  final String text;
}

/// Hadiths shown per screen.
const hadithPageSize = 20;

/// Most results a search returns.
const hadithSearchLimit = 200;

/// First number on the screen that holds hadith [n].
int hadithPageStart(int n) => (n - 1) ~/ hadithPageSize * hadithPageSize + 1;
