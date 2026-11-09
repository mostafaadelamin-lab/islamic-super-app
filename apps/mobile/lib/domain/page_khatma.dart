// PageKhatma (reading the whole Mushaf): which of the 604 pages were read since
// the khatma started. A page counts as read once it stayed open for
// [khatmaDwell] in the Mushaf reader.

/// How long a page must stay open to count as read.
const khatmaDwell = Duration(seconds: 4);

class PageKhatma {
  PageKhatma({required this.startedAt, Iterable<int> read = const [], this.pageCount = 604})
    : read = Set.unmodifiable({
        for (final p in read)
          if (p >= 1 && p <= pageCount) p,
      });

  final DateTime startedAt;
  final Set<int> read;
  final int pageCount;

  int get done => read.length;
  int get left => pageCount - done;

  /// Whole percent; 100 only when every page is read.
  int get percent => left == 0 ? 100 : (done * 100 ~/ pageCount).clamp(0, 99);

  /// First page not read yet, or null when the khatma is complete.
  int? get next {
    for (var p = 1; p <= pageCount; p++) {
      if (!read.contains(p)) return p;
    }
    return null;
  }

  PageKhatma markRead(int page) => read.contains(page) || page < 1 || page > pageCount
      ? this
      : PageKhatma(startedAt: startedAt, read: {...read, page}, pageCount: pageCount);

  /// Stored as the sorted page numbers.
  List<String> get encoded => [for (final p in (read.toList()..sort())) '$p'];

  static PageKhatma decode(int startedAtMs, List<String> pages) => PageKhatma(
    startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
    read: [for (final s in pages) ?int.tryParse(s)],
  );
}
