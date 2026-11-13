/// Islamic videos search: the same rules as the website's function
/// (apps/web/netlify/lib/videos-core.mjs). Only Quran recitation, religious
/// lessons and advice/admonitions: trusted channels always, other channels
/// only when the title is clearly Islamic, and never music/entertainment titles.
library;

import 'dart:convert';

final _tashkeel = RegExp('[ً-ٰٟـ]');
final _alef = RegExp('[أإآٱ]');
final _spaces = RegExp(r'\s+');

/// Lower-case, no tashkeel/tatweel, one form of alef/yaa/taa marbuta.
String normalizeSearch(String s) => s
    .toLowerCase()
    .replaceAll(_tashkeel, '')
    .replaceAll(_alef, 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(_spaces, ' ')
    .trim();

const islamicWords = [
  'قران', 'سوره', 'تلاوه', 'تلاوات', 'ترتيل', 'تجويد', 'مصحف', 'ايات', 'قارئ', 'القارئ', 'مقرئ', //
  'الشيخ', 'شيخ', 'مشايخ', 'درس', 'دروس', 'محاضره', 'خطبه', 'موعظه', 'مواعظ', 'نصيحه', 'نصائح', 'تذكير', 'رقائق',
  'تفسير', 'حديث', 'احاديث', 'السنه', 'النبي', 'الرسول', 'صلي الله عليه وسلم', 'سيره', 'الصحابه', 'فقه', 'فتوي',
  'الله', 'اسلام', 'اسلامي', 'اسلاميه', 'الايمان', 'التوبه', 'الجنه', 'الاخره', 'الصلاه', 'الدعاء', 'دعاء', 'اذكار',
  'رمضان', 'الحج', 'العمره', 'الزكاه', 'التوحيد', 'العقيده', 'القيامه', 'استغفار', 'الصبر',
  'quran', 'koran', 'recitation', 'surah', 'surat', 'tilawat', 'tajweed', 'islam', 'islamic', 'muslim', 'sheikh',
  'shaykh', 'tafsir', 'hadith', 'prophet', 'sunnah', 'allah', 'dua', 'lecture', 'khutbah', 'reminder', 'imam',
];

const blockedWords = [
  'اغنيه', 'اغاني', 'موسيقي', 'مهرجان', 'كليب', 'رقص', 'فيلم', 'افلام', 'مسلسل', 'مقلب', 'مقالب', 'ضحك', //
  'كوميدي', 'نكت', 'العاب', 'لعبه', 'ريمكس', 'شيله', 'غناء', 'طرب', 'ديسكو',
  'song', 'songs', 'music', 'remix', 'dance', 'dancing', 'movie', 'film', 'trailer', 'prank', 'funny', 'comedy',
  'gaming', 'gameplay', 'lyrics', 'karaoke', 'beat', 'rap', 'concert',
];

final _arPrefix = RegExp(r'^(?:و|ف|ب|ل|ك)?(?:ال|ل)?');
final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

bool _hasWord(String text, List<String> words) {
  final t = normalizeSearch(text);
  final tokens = <String>{
    for (final w in t.split(_nonWord))
      if (w.isNotEmpty) ...[w, w.replaceFirst(_arPrefix, '')],
  };
  for (final raw in words) {
    final n = normalizeSearch(raw);
    if (n.contains(' ')) {
      if (t.contains(n)) return true;
    } else if (tokens.contains(n) || tokens.contains(n.replaceFirst(_arPrefix, ''))) {
      return true;
    }
  }
  return false;
}

bool isBlockedVideoText(String text) => _hasWord(text, blockedWords);
bool looksIslamic(String text) => _hasWord(text, islamicWords);

class VideoHit {
  const VideoHit({
    required this.ref,
    required this.title,
    this.channel,
    this.channelId,
    this.duration,
    this.trusted = false,
  });
  final String ref;
  final String title;
  final String? channel;
  final String? channelId;
  final String? duration;
  final bool trusted;

  String get thumbUrl => 'https://i.ytimg.com/vi/$ref/mqdefault.jpg';
  String get watchUrl => 'https://www.youtube.com/watch?v=$ref';

  VideoHit withTrusted(bool t) =>
      VideoHit(ref: ref, title: title, channel: channel, channelId: channelId, duration: duration, trusted: t);
}

/// May the result be shown? Never a blocked title; trusted channels always; others only clearly Islamic.
bool allowedVideo(VideoHit h, Set<String> trustedChannelIds) {
  if (isBlockedVideoText(h.title) || isBlockedVideoText(h.channel ?? '')) return false;
  if (h.channelId != null && trustedChannelIds.contains(h.channelId)) return true;
  return looksIslamic(h.title) || looksIslamic(h.channel ?? '');
}

/// YouTube's results page for videos only (no API key).
Uri videoSearchUri(String q) =>
    Uri.https('www.youtube.com', '/results', {'search_query': q, 'sp': 'EgIQAQ==', 'hl': 'ar'});

String _str(String raw) {
  try {
    return jsonDecode('"$raw"') as String;
  } on Object {
    return raw;
  }
}

final _renderer = RegExp(r'"videoRenderer":\{"videoId":"([A-Za-z0-9_-]{11})"');
final _titleRuns = RegExp(r'"title":\{"runs":\[\{"text":"((?:[^"\\]|\\.)*)"');
final _titleSimple = RegExp(r'"title":\{"simpleText":"((?:[^"\\]|\\.)*)"');
final _owner = RegExp(
  r'"(?:ownerText|longBylineText)":\{"runs":\[\{"text":"((?:[^"\\]|\\.)*)"[\s\S]{0,600}?"browseId":"(UC[A-Za-z0-9_-]{22})"',
);
final _length = RegExp(r'"lengthText":\{[\s\S]{0,400}?"simpleText":"([0-9:]+)"');

/// Videos on YouTube's results page (the page embeds its data as JSON).
List<VideoHit> parseVideoSearch(String page, {int max = 30}) {
  final out = <VideoHit>[];
  final seen = <String>{};
  for (final m in _renderer.allMatches(page)) {
    if (out.length >= max) break;
    final id = m.group(1)!;
    if (seen.contains(id)) continue;
    final end = m.start + 8000 < page.length ? m.start + 8000 : page.length;
    final chunk = page.substring(m.start, end);
    final title = _titleRuns.firstMatch(chunk) ?? _titleSimple.firstMatch(chunk);
    if (title == null) continue;
    final owner = _owner.firstMatch(chunk);
    seen.add(id);
    out.add(
      VideoHit(
        ref: id,
        title: _str(title.group(1)!),
        channel: owner == null ? null : _str(owner.group(1)!),
        channelId: owner?.group(2),
        duration: _length.firstMatch(chunk)?.group(1),
      ),
    );
  }
  return out;
}
