/// Splits a Hajj / Umrah step's text so the duas and words to be said can be shaded (owner 2026-11-15).
/// The text itself is never changed: joining the parts gives the input back exactly.
/// A part is a dua when it is: a Quran passage in ﴿…﴾ (with its [surah: ayah] reference), a [bracketed]
/// dhikr such as the talbiya, or a (…) / «…» quote that follows a colon ("وقل: «…»") or another dua.
/// Same rule on the website: apps/web/src/lib/dua-segments.ts.
library;

class TextPart {
  const TextPart(this.text, {required this.dua});
  final String text;
  final bool dua;
}

final _quote = RegExp(r'﴿[^﴾]+﴾(?:\s*\[[^\]]+\])?|\[[^\]]+\]|\([^)]+\)|«[^»]+»');
final _reference = RegExp(r'^\[[^\]]*:\s*[\d٠-٩]+(?:\s*[-–]\s*[\d٠-٩]+)?\]$');
final _colonEnd = RegExp(r':\s*$');
final _joiner = RegExp(r'^[\s.،,]*$');

List<TextPart> duaParts(String text) {
  final parts = <TextPart>[];
  var at = 0;
  var lastDuaEnd = -1;
  for (final m in _quote.allMatches(text)) {
    final q = m.group(0)!;
    final before = text.substring(at, m.start);
    final bool dua;
    if (q.startsWith('﴿')) {
      dua = true;
    } else if (q.startsWith('[')) {
      dua = !_reference.hasMatch(q);
    } else {
      dua = _colonEnd.hasMatch(before) || (lastDuaEnd == at && _joiner.hasMatch(before));
    }
    if (!dua) continue;
    if (before.isNotEmpty) parts.add(TextPart(before, dua: false));
    parts.add(TextPart(q, dua: true));
    at = m.end;
    lastDuaEnd = at;
  }
  if (at < text.length) parts.add(TextPart(text.substring(at), dua: false));
  return parts;
}
