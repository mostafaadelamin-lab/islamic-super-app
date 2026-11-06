// Arabic text utilities: search normalisation (search-normalization.json),
// display-only glyph mapping (quran-render.json) and digit formatting.

/// Search normaliser driven by packages/shared-schemas/search-normalization.json.
/// Applied to the query and to an in-memory index copy; never to stored text.
class SearchNormalizer {
  SearchNormalizer({required List<(int, int)> removeRanges, required Map<int, String> map})
    : _ranges = List.unmodifiable(removeRanges),
      _map = Map.unmodifiable(map);

  factory SearchNormalizer.fromJson(Map<String, dynamic> j) {
    final ranges = <(int, int)>[
      for (final r in j['removeRanges'] as List<dynamic>)
        (int.parse((r as List<dynamic>)[0] as String, radix: 16), int.parse(r[1] as String, radix: 16)),
    ];
    final map = <int, String>{};
    for (final e in (j['map'] as Map<String, dynamic>).entries) {
      final runes = e.key.runes.toList();
      if (runes.length != 1) {
        throw FormatException('normalisation map key must be one code point: ${e.key}');
      }
      map[runes.single] = e.value as String;
    }
    return SearchNormalizer(removeRanges: ranges, map: map);
  }

  final List<(int, int)> _ranges;
  final Map<int, String> _map;
  static final _ws = RegExp(r'\s+');

  bool _removed(int cp) {
    for (final (a, b) in _ranges) {
      if (cp >= a && cp <= b) return true;
    }
    return false;
  }

  String normalize(String input) {
    // Step 1: remove code points in removeRanges.
    final step1 = StringBuffer();
    for (final cp in input.runes) {
      if (!_removed(cp)) step1.writeCharCode(cp);
    }
    // Step 2: character map.
    final step2 = StringBuffer();
    for (final cp in step1.toString().runes) {
      final m = _map[cp];
      if (m != null) {
        step2.write(m);
      } else {
        step2.writeCharCode(cp);
      }
    }
    // Step 3: collapse whitespace and trim.
    return step2.toString().replaceAll(_ws, ' ').trim();
  }

  /// Number of letters (non-space code points) left after normalisation.
  int letterCount(String input) => normalize(input).runes.where((c) => c != 0x20).length;
}

/// Display-only glyph map from quran-render.json. Apply ONLY to the string
/// handed to a Text widget; stored/searched/synced/hashed text is untouched.
class QuranRenderMap {
  QuranRenderMap(Map<String, String> map) : _map = Map.unmodifiable(map);

  factory QuranRenderMap.fromJson(Map<String, dynamic> j) =>
      QuranRenderMap({for (final e in (j['map'] as Map<String, dynamic>).entries) e.key: e.value as String});

  final Map<String, String> _map;
  Map<String, String> get map => _map;

  String forDisplay(String text) {
    if (_map.isEmpty) return text;
    final sb = StringBuffer();
    for (final cp in text.runes) {
      final ch = String.fromCharCode(cp);
      sb.write(_map[ch] ?? ch);
    }
    return sb.toString();
  }
}

const _arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Replaces ASCII digits with Arabic-Indic digits (U+0660..U+0669).
String toArabicIndic(Object value) {
  final s = value.toString();
  final sb = StringBuffer();
  for (final cp in s.runes) {
    if (cp >= 0x30 && cp <= 0x39) {
      sb.write(_arabicIndic[cp - 0x30]);
    } else {
      sb.writeCharCode(cp);
    }
  }
  return sb.toString();
}

/// Converts Arabic-Indic / Eastern Arabic-Indic digits to ASCII so that user
/// input such as "٦٠٤" or "۶۰۴" can be parsed.
String toAsciiDigits(String s) {
  final sb = StringBuffer();
  for (final cp in s.runes) {
    if (cp >= 0x0660 && cp <= 0x0669) {
      sb.writeCharCode(0x30 + cp - 0x0660);
    } else if (cp >= 0x06F0 && cp <= 0x06F9) {
      sb.writeCharCode(0x30 + cp - 0x06F0);
    } else {
      sb.writeCharCode(cp);
    }
  }
  return sb.toString();
}

/// Ayah end marker with Arabic-Indic number, e.g. "﴿١٢﴾".
String ayahMarker(int n) => '﴿${toArabicIndic(n)}﴾';

/// Parses a Mushaf page number typed by the user; null when invalid.
int? parsePageNumber(String raw, {int max = 604}) {
  final s = toAsciiDigits(raw.trim());
  if (!RegExp(r'^\d{1,4}$').hasMatch(s)) return null;
  final n = int.parse(s);
  return n >= 1 && n <= max ? n : null;
}
