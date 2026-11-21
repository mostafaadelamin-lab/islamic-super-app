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

/// One dhikr of the kids' adhkar cards, as text (owner 2026-11-21): copied from the cards book's
/// PDF text layer by tools/kids_cards/extract_cards.py. [morning] / [evening] are the repeat counts
/// the card gives (0 = not said then); [note] is the card's own wording of them.
class CardDhikr {
  const CardDhikr({
    required this.n,
    required this.text,
    required this.note,
    required this.morning,
    required this.evening,
    this.surahs = const [],
  });
  final int n;
  final String text;
  final String note;
  final int morning;
  final int evening;

  /// «قل هو الله أحد والمعوذتين»: the three surahs written out.
  final List<String> surahs;

  int countFor({required bool evening}) => evening ? this.evening : morning;
}

/// One wudu / salah step: the book's own title and text, with our own 3D picture (none on text pages).
class KidsStep {
  const KidsStep({required this.title, required this.text, this.pic, this.ayah});
  final String title;
  final String text;

  /// Picture name in `assets/kids/steps/<pic>.webp`.
  final String? pic;

  /// Ayat al-Kursi on the "dhikr after salah" page (KFGQPC wording from the app's adhkar).
  final String? ayah;

  static KidsStep fromJson(Map<String, dynamic> j) => KidsStep(
    title: j['title'] as String,
    text: j['text'] as String,
    pic: j['pic'] as String?,
    ayah: j['ayah'] as String?,
  );
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
    this.cardAdhkar = const [],
  });

  final String booksBase;
  final List<String> shelves;
  final List<KidsBook> books;
  final List<HadithLevel> levels;

  /// Hadith text by number - 1.
  final List<String> hadith;

  /// Wudu / salah steps in the book's order.
  final List<KidsStep> wudu;
  final List<KidsStep> salah;

  /// The wudu / salah book asks to be named when shared (its own terms).
  final String stepsCredit;


  /// The adhkar cards as text, in the cards' order.
  final List<CardDhikr> cardAdhkar;

  List<CardDhikr> cardAdhkarFor({required bool evening}) => [
    for (final c in cardAdhkar)
      if (c.countFor(evening: evening) > 0) c,
  ];

  List<KidsBook> onShelf(String shelf) => [
    for (final b in books)
      if (b.shelf == shelf) b,
  ];

  String hadithText(int n) => hadith[n - 1];

  static KidsLearnContent parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    List<KidsStep> steps(Object? v) => [for (final x in (v! as List).cast<Map<String, dynamic>>()) KidsStep.fromJson(x)];
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
      wudu: steps(j['wudu']),
      salah: steps(j['salah']),
      stepsCredit: j['stepsCredit'] as String,
      cardAdhkar: [
        for (final c in (j['cardAdhkar'] as List? ?? const []).cast<Map<String, dynamic>>())
          CardDhikr(
            n: c['n'] as int,
            text: c['text'] as String,
            note: c['note'] as String,
            morning: c['m'] as int,
            evening: c['e'] as int,
            surahs: [for (final t in (c['surahs'] as List? ?? const [])) t as String],
          ),
      ],
    );
  }
}
