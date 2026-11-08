/// Curated Islamic reels. Videos stay on YouTube and play through YouTube's
/// official embed player; nothing is downloaded or re-hosted. Instagram is not
/// enabled yet.
///
/// Owner policy: only humble Quran recitations ("recitation") and short
/// religious lessons in line with the Quran and Sunnah ("lesson"), and only
/// reels that passed a religious review ("approved") are shown to users.
/// Pending reels are visible in reviewer mode only, with a warning banner.
library;

enum ReelStatus { approved, pending }

class Reel {
  const Reel({
    required this.id,
    required this.ref,
    required this.url,
    required this.titleAr,
    required this.titleEn,
    required this.category,
    required this.status,
    this.speakerAr,
    this.speakerEn,
    this.reviewer,
  });

  static const categories = ['recitation', 'lesson'];
  static final _ytId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Returns null for anything that is not a well-formed, allowed reel, so it
  /// is dropped rather than embedded.
  static Reel? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final ref = raw['ref'];
    final status = switch (raw['status']) {
      'approved' => ReelStatus.approved,
      'pending' => ReelStatus.pending,
      _ => null,
    };
    final title = raw['title'];
    if (raw['platform'] != 'youtube' || ref is! String || !_ytId.hasMatch(ref)) return null;
    if (status == null || !categories.contains(raw['category']) || title is! Map<String, dynamic>) return null;
    final ar = title['ar'];
    if (ar is! String || ar.trim().isEmpty) return null;
    final en = title['en'] is String && (title['en'] as String).isNotEmpty ? title['en'] as String : ar;
    final speaker = raw['speaker'] is Map<String, dynamic> ? raw['speaker'] as Map<String, dynamic> : null;
    return Reel(
      id: 'yt-$ref',
      ref: ref,
      url: 'https://www.youtube.com/watch?v=$ref',
      titleAr: ar,
      titleEn: en,
      category: raw['category'] as String,
      status: status,
      speakerAr: speaker?['ar'] as String?,
      speakerEn: (speaker?['en'] as String?) ?? speaker?['ar'] as String?,
      reviewer: status == ReelStatus.approved ? raw['reviewer'] as String? : null,
    );
  }

  final String id;
  final String ref;
  final String url;
  final String titleAr;
  final String titleEn;
  final String? speakerAr;
  final String? speakerEn;
  final String category;
  final ReelStatus status;
  final String? reviewer;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String? speaker(bool arabic) => arabic ? speakerAr : speakerEn;
  bool get isPending => status == ReelStatus.pending;

  String get posterUrl => 'https://i.ytimg.com/vi/$ref/hqdefault.jpg';

  /// The YouTube privacy-enhanced embed, autoplaying (muted, as mobile
  /// browsers require), inline and looping.
  Uri embedUri({String origin = ReelCatalog.embedOrigin}) => Uri.https('www.youtube-nocookie.com', '/embed/$ref', {
    'autoplay': '1',
    'mute': '1',
    'playsinline': '1',
    'loop': '1',
    'playlist': ref,
    'rel': '0',
    'modestbranding': '1',
    'origin': origin,
  });

  /// A minimal full-bleed page hosting the embed. YouTube refuses embeds that
  /// carry no HTTP referrer, so the WebView loads it with [ReelCatalog.embedOrigin]
  /// as its base URL.
  String embedHtml() =>
      '<!doctype html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}'
      'iframe{position:fixed;inset:0;width:100%;height:100%;border:0}</style></head><body>'
      '<iframe src="${embedUri()}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" '
      'allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe></body></html>';
}

class ReelCatalog {
  const ReelCatalog(this.items);

  factory ReelCatalog.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 'reels.v1') return const ReelCatalog([]);
    final items = j['items'];
    return ReelCatalog(List.unmodifiable([if (items is List) ...items.map(Reel.tryParse).whereType<Reel>()]));
  }

  static const empty = ReelCatalog([]);
  static const embedOrigin = 'https://www.youtube-nocookie.com';

  final List<Reel> items;

  /// Approved reels for everyone; reviewers also see pending ones.
  List<Reel> visible({required bool reviewer}) => [
    for (final r in items)
      if (r.status == ReelStatus.approved || (reviewer && r.isPending)) r,
  ];
}
