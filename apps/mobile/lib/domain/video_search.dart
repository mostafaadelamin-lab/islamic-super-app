/// Islamic videos search: the same rules as the website's function
/// (apps/web/netlify/lib/videos-core.mjs and apps/web/bluehost/api/videos.php).
/// Owner 2026-11-27: videos are Quran recitation only. Lessons, sermons, nasheeds and
/// anything naming an excluded sheikh are never shown; music/entertainment never.
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

/// Words that show a title is Quran recitation (keep equal to videos-core.mjs RECITATION_WORDS).
const recitationWords = [
  'قران', 'سوره', 'سور', 'تلاوه', 'تلاوات', 'ترتيل', 'تجويد', 'مصحف', 'ايات', 'قارئ', 'القارئ', 'مقرئ', //
  'تراويح', 'تهجد', 'قيام الليل', 'فجريه', 'عشائيه', 'عشائيات', 'صلاه الفجر', 'صلاه العشاء', 'صلاه المغرب',
  'صلاه الظهر',
  'صلاه العصر',
  'ختمه',
  'رقيه',
  'سورتي',
  'سورتين',
  'سورتا',
  'صلاه الجمعه',
  'صلاه التراويح',
  'tahajjud',
  'quran',
  'koran',
  'recitation',
  'surah',
  'surat',
  'sura',
  'tilawat',
  'tilawah', 'tajweed', 'taraweeh', 'tarawih', 'qiyam', 'fajr', 'isha', 'maghrib',
];

/// Not recitation even on a reciter's channel. No surah names (القصص, الشرح must pass).
const nonRecitationWords = [
  'خطبه', 'خطبتي', 'خطبتا', 'درس', 'دروس', 'محاضره', 'محاضرات', 'موعظه', 'مواعظ', 'نصيحه', 'نصائح', 'فتوي', //
  'فتاوي', 'لقاء', 'حوار', 'برنامج', 'بودكاست', 'نشيد', 'انشوده', 'اناشيد', 'قصيده', 'دعاء', 'ادعيه', 'تكبيرات',
  'اذان',
  'تفسير',
  'سؤال',
  'اسئله',
  'مقابله',
  'معلقه',
  'معلقات',
  'شعر',
  'كورس',
  'لهجه',
  'عيديه',
  'استقبال',
  'اذكار',
  'رضي الله عنه',
  'رضي الله عنها',
  'فوائد',
  'سلسله',
  'فضل يوم',
  'فضل صيام',
  'فضل شهر',
  'لا اله الا الله وحده',
  'ادع الله',
  'lecture', 'lesson', 'khutbah', 'khutba', 'sermon', 'nasheed', 'anasheed', 'dua', 'podcast', 'interview',
];

/// Never shown (owner 2026-11-26/27: jailed, or ever in a political current).
const excludedPeople = [
  'نبيل العوضي', 'محمد العريفي', 'صالح المنجد', 'محمد حسين يعقوب', 'ايمن عبد الرحيم', 'بدر المشاري', //
  'عبدالله بصفر', 'عبد الله بصفر', 'صالح ال طالب', 'بندر بليله', 'عمرو خالد', 'محمد حسان', 'عائض القرني',
  'راتب النابلسي', 'حازم شومان', 'طارق السويدان', 'احمد عبد المنعم', 'ياسر الحزيمي',
];

final _tashkeelMark = RegExp('[\u064B-\u0652\u0670]');
final _quotedArabic = RegExp(r'[(«"“{﴿][^)»"”}﴾]*\p{Script=Arabic}[^)»"”}﴾]*[)»"”}﴾]', unicode: true);

/// Quran text in a title: 4+ tashkeel marks, or Arabic between brackets/quotes (same as videos-core.mjs).
bool looksLikeVerse(String text) => _tashkeelMark.allMatches(text).length >= 4 || _quotedArabic.hasMatch(text);

bool looksRecitation(String text) => _hasWord(text, recitationWords) || text.contains('﴿') || looksLikeVerse(text);
bool namesExcluded(String text) => _hasWord(text, excludedPeople);

/// Blocked, not recitation, or naming an excluded sheikh.
bool notRecitation(String text) =>
    isBlockedVideoText(text) || _hasWord(text, nonRecitationWords) || namesExcluded(text);

/// A video from a reciter's channel may join the feed.
/// The golden generation's channels hold only their recitations (often titled with the name alone): blocklist only.
bool allowedFeedTitle(String title, [String? group]) =>
    !notRecitation(title) && (group == 'golden' || looksRecitation(title));

/// A channel from the channel search may be added: its name must say recitation/Quran.
bool allowedChannel(String title) => !notRecitation(title) && looksRecitation(title);

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

/// May the result be shown? Recitation only; trusted reciters' channels pass without a recitation word.
bool allowedVideo(VideoHit h, Set<String> trustedChannelIds) {
  final channel = h.channel ?? '';
  if (notRecitation(h.title) || isBlockedVideoText(channel) || namesExcluded(channel)) return false;
  if (h.channelId != null && trustedChannelIds.contains(h.channelId)) return true;
  return looksRecitation(h.title);
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
