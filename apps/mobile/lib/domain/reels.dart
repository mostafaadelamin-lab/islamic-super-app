/// Curated Islamic reels. Videos stay on YouTube / Instagram and play through
/// the platforms' official embed players; nothing is downloaded or re-hosted.
/// Instagram's plain /embed/ page needs no Meta app, token or account, but it
/// cannot autoplay (the viewer taps play).
///
/// Owner policy (2026-11-09): only Quran recitations ("recitation"), religious
/// lessons ("lesson") and advice/admonitions ("admonition") in line with the
/// Quran and Sunnah, and only reels that passed a religious review
/// ("approved") are shown to users.
/// Pending reels are visible in reviewer mode only, with a warning banner.
library;

enum ReelStatus { approved, pending }

enum ReelPlatform { youtube, instagram }

class Reel {
  const Reel({
    required this.id,
    required this.platform,
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

  static const categories = ['recitation', 'lesson', 'admonition'];
  static final _ytId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _igCode = RegExp(r'^[A-Za-z0-9_-]{5,40}$');

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
    final platform = switch (raw['platform']) {
      'youtube' => ReelPlatform.youtube,
      'instagram' => ReelPlatform.instagram,
      _ => null,
    };
    if (platform == null || ref is! String) return null;
    if (!(platform == ReelPlatform.youtube ? _ytId : _igCode).hasMatch(ref)) return null;
    if (status == null || !categories.contains(raw['category']) || title is! Map<String, dynamic>) return null;
    final ar = title['ar'];
    if (ar is! String || ar.trim().isEmpty) return null;
    final en = title['en'] is String && (title['en'] as String).isNotEmpty ? title['en'] as String : ar;
    final speaker = raw['speaker'] is Map<String, dynamic> ? raw['speaker'] as Map<String, dynamic> : null;
    return Reel(
      id: platform == ReelPlatform.youtube ? 'yt-$ref' : 'ig-$ref',
      platform: platform,
      ref: ref,
      url: platform == ReelPlatform.youtube
          ? 'https://www.youtube.com/watch?v=$ref'
          : 'https://www.instagram.com/reel/$ref/',
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
  final ReelPlatform platform;
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

  bool get isInstagram => platform == ReelPlatform.instagram;

  /// YouTube's thumbnail; Instagram has no public poster URL.
  String? get posterUrl => isInstagram ? null : 'https://i.ytimg.com/vi/$ref/hqdefault.jpg';

  /// Instagram's official embed page, loaded directly in the WebView.
  Uri get instagramEmbedUri => Uri.https('www.instagram.com', '/reel/$ref/embed/');

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
