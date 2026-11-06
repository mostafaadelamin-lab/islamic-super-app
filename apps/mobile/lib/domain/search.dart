import 'quran.dart';
import 'text.dart';

class SearchHit {
  const SearchHit(this.ref, this.text);
  final AyahRef ref;

  /// Original, unmodified ayah text.
  final String text;
}

class SearchResult {
  const SearchResult(this.query, this.total, this.hits);
  final String query;
  final int total;
  final List<SearchHit> hits;
}

/// Diacritic-insensitive in-memory Quran search. The index holds normalised
/// copies; results always carry the original ayah text.
class QuranSearch {
  QuranSearch(this.content, this.normalizer);
  final QuranContent content;
  final SearchNormalizer normalizer;
  late final List<(AyahRef, String)> _index = [
    for (final s in content.surahs)
      for (var i = 0; i < s.ayahs.length; i++) (AyahRef(s.n, i + 1), normalizer.normalize(s.ayahs[i])),
  ];

  static const minLetters = 2;

  /// Returns null when the query has fewer than [minLetters] letters.
  SearchResult? search(String query, {int limit = 200}) {
    final q = normalizer.normalize(query);
    if (q.runes.where((c) => c != 0x20).length < minLetters) return null;
    final hits = <SearchHit>[];
    var total = 0;
    for (final (ref, norm) in _index) {
      if (norm.contains(q)) {
        total++;
        if (hits.length < limit) hits.add(SearchHit(ref, content.text(ref)));
      }
    }
    return SearchResult(q, total, hits);
  }
}
