/// The kids' learning corner (owner, 2026-11-20): a book shelf, «احفظ حديث» (600 hadith
/// for children in four levels), adhkar cards, and wudu / salah steps. Built by
/// tools/kids_learn_build.py into assets/content/kids-learn.v1.json. The hadith text is
/// copied unchanged from the published book; cards, steps and book pages are the
/// published pages themselves (pictures). Sources: docs/CONTENT_SOURCES.md.
library;

import 'dart:convert';

/// One book on the shelf: its pages are pictures at `booksBase/<id>/<page>.webp`.
class KidsBook {
  const KidsBook({
    required this.id,
    required this.shelf,
    required this.title,
    required this.author,
    required this.pages,
  });
  final int id;
  final String shelf;
  final String title;
  final String author;
  final int pages;

  String pageUrl(String base, int page) => '$base$id/$page.webp';
  String get cover => 'assets/kids/covers/$id.webp';
}

/// A memorising level of the hadith book: hadith numbers [from]..[to] (1-based).
class HadithLevel {
  const HadithLevel({required this.level, required this.from, required this.to, required this.color});
  final int level;
  final int from;
  final int to;
  final int color;

  int get count => to - from + 1;
  bool contains(int n) => n >= from && n <= to;
}

class KidsLearnContent {
  const KidsLearnContent({
    required this.booksBase,
    required this.shelves,
    required this.books,
    required this.levels,
    required this.hadith,
    required this.wudu,
    required this.salah,
    required this.stepsCredit,
    required this.cards,
  });

  final String booksBase;
  final List<String> shelves;
  final List<KidsBook> books;
  final List<HadithLevel> levels;

  /// Hadith text by number - 1.
  final List<String> hadith;

  /// Page numbers of the wudu / salah book (pictures in assets/kids/wudu/).
  final List<int> wudu;
  final List<int> salah;

  /// The wudu / salah book asks to be named when shared (its own terms).
  final String stepsCredit;

  /// Page numbers of the adhkar cards (`assets/kids/cards/b<n>.webp` and `g<n>.webp`).
  final List<int> cards;

  List<KidsBook> onShelf(String shelf) => [
    for (final b in books)
      if (b.shelf == shelf) b,
  ];

  String hadithText(int n) => hadith[n - 1];

  static KidsLearnContent parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    List<int> ints(Object? v) => [for (final x in v! as List) x as int];
    return KidsLearnContent(
      booksBase: j['booksBase'] as String,
      shelves: [for (final s in j['shelves'] as List) s as String],
      books: [
        for (final b in (j['books'] as List).cast<Map<String, dynamic>>())
          KidsBook(
            id: b['id'] as int,
            shelf: b['shelf'] as String,
            title: b['title'] as String,
            author: b['author'] as String,
            pages: b['pages'] as int,
          ),
      ],
      levels: [
        for (final l in (j['hadithLevels'] as List).cast<Map<String, dynamic>>())
          HadithLevel(
            level: l['level'] as int,
            from: l['from'] as int,
            to: l['to'] as int,
            color: 0xFF000000 | int.parse((l['color'] as String).substring(1), radix: 16),
          ),
      ],
      hadith: [for (final h in j['hadith'] as List) h as String],
      wudu: ints(j['wudu']),
      salah: ints(j['salah']),
      stepsCredit: j['stepsCredit'] as String,
      cards: ints(j['cards']),
    );
  }
}
