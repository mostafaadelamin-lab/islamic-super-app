/// Curated Islamic reels. Videos stay on YouTube / Instagram and play through
/// the platforms' official embed players; nothing is downloaded or re-hosted.
/// Instagram's plain /embed/ page needs no Meta app, token or account, but it
/// cannot autoplay (the viewer taps play).
///
/// Owner policy (2026-11-09): only Quran recitations ("recitation"), religious
/// lessons ("lesson") and advice/admonitions ("admonition") in line with the
/// Quran and Sunnah, and only reels that passed a religious review
/// ("approved") are shown to users.
/// Pending (unreviewed) reels are never shown; the two samples were removed (owner, 2026-11-13).
///
/// Owner decision (2026-11-09 21:31): besides the curated list, the app pulls
/// the newest Shorts from trusted channels the owner approved once
/// (content/reels/sources.json). Those reels ("auto") need no per-video review.
library;

import 'dart:convert';

import 'package:xml/xml.dart';

enum ReelStatus { approved, pending, auto }

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
    this.sourceId,
    this.published,
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

  /// The trusted channel an automatic reel came from (null for curated reels).
  final String? sourceId;
  final DateTime? published;

  bool get isAuto => status == ReelStatus.auto;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String? speaker(bool arabic) => arabic ? speakerAr : speakerEn;
  bool get isPending => status == ReelStatus.pending;

  bool get isInstagram => platform == ReelPlatform.instagram;

  /// YouTube's thumbnail; Instagram has no public poster URL.
  String? get posterUrl => isInstagram ? null : 'https://i.ytimg.com/vi/$ref/hqdefault.jpg';

  /// Instagram's official embed page, loaded directly in the WebView.
  Uri get instagramEmbedUri => Uri.https('www.instagram.com', '/reel/$ref/embed/');

  /// The YouTube privacy-enhanced embed, autoplaying with sound (the WebView
  /// allows playback without a tap), inline and looping.
  Uri embedUri({String origin = ReelCatalog.embedOrigin}) => Uri.https('www.youtube-nocookie.com', '/embed/$ref', {
    'autoplay': '1',
    'mute': '0',
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

/// A trusted channel the owner approved once; its newest Shorts are shown
/// automatically (content/reels/dist/reel-sources.v1.json).
class ReelSource {
  const ReelSource({
    required this.id,
    this.channelId,
    this.handle,
    required this.nameAr,
    required this.nameEn,
    required this.category,
  });

  static final channelPattern = RegExp(r'^UC[A-Za-z0-9_-]{22}$');
  static final _handle = RegExp(r'^[\p{L}\p{N}\p{M}_.-]{3,30}$', unicode: true);

  static ReelSource? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final cid = raw['channelId'];
    final handle = raw['handle'];
    final name = raw['name'];
    if (raw['platform'] != 'youtube') return null;
    final okId = cid is String && channelPattern.hasMatch(cid);
    final okHandle = handle is String && _handle.hasMatch(handle);
    if (okId == okHandle) return null; // exactly one of them
    if (!Reel.categories.contains(raw['category']) || name is! Map<String, dynamic>) return null;
    final ar = name['ar'];
    if (ar is! String || ar.trim().isEmpty) return null;
    final en = name['en'] is String && (name['en'] as String).isNotEmpty ? name['en'] as String : ar;
    return ReelSource(
      id: okId ? 'yt-$cid' : 'yt-@$handle',
      channelId: okId ? cid : null,
      handle: okHandle ? handle : null,
      nameAr: ar,
      nameEn: en,
      category: raw['category'] as String,
    );
  }

  final String id;

  /// The channel id (UC…), or null when the owner gave an @handle; the
  /// handle is turned into the id at run time from the channel page.
  final String? channelId;
  final String? handle;
  final String nameAr;
  final String nameEn;
  final String category;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  /// YouTube's public feed of a channel's Shorts only (the "UUSH" playlist).
  static Uri shortsFeed(String channelId) =>
      Uri.https('www.youtube.com', '/feeds/videos.xml', {'playlist_id': 'UUSH${channelId.substring(2)}'});

  /// A channel's whole upload feed (fallback when the Shorts feed fails).
  /// The channel's Videos tab (used when YouTube's feeds fail, as seen 2026-11-13).
  static Uri channelVideosPage(String channelId) =>
      Uri.https('www.youtube.com', '/channel/$channelId/videos', {'hl': 'ar'});

  static Uri channelFeed(String channelId) =>
      Uri.https('www.youtube.com', '/feeds/videos.xml', {'channel_id': channelId});

  /// The channel's page (by @handle when that is what the owner gave).
  Uri get channelPage =>
      handle != null ? Uri.https('www.youtube.com', '/@$handle') : Uri.https('www.youtube.com', '/channel/$channelId');

  static final _idOnPage = [
    RegExp(r'<link rel="canonical" href="https://www\.youtube\.com/channel/(UC[A-Za-z0-9_-]{22})"'),
    RegExp(r'<meta itemprop="identifier" content="(UC[A-Za-z0-9_-]{22})"'),
    RegExp(r'"externalId":"(UC[A-Za-z0-9_-]{22})"'),
    RegExp(r'"browseId":"(UC[A-Za-z0-9_-]{22})"'),
  ];

  /// Finds the channel's own id on its YouTube page (null if not found).
  static String? channelIdFromPage(String html) {
    for (final re in _idOnPage) {
      final m = re.firstMatch(html);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// Turns a YouTube Atom feed into reels. With [shortsOnly], only entries
  /// linking to /shorts/ are kept. Malformed XML gives an empty list.
  List<Reel> parseFeed(String xml, {bool shortsOnly = false}) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } on Object {
      return const [];
    }
    final out = <Reel>[];
    for (final e in doc.findAllElements('entry')) {
      final id = e.getElement('yt:videoId')?.innerText.trim() ?? '';
      final title = e.getElement('title')?.innerText.trim() ?? '';
      if (!Reel._ytId.hasMatch(id) || title.isEmpty) continue;
      final link = e.getElement('link')?.getAttribute('href') ?? '';
      if (shortsOnly && !link.contains('/shorts/')) continue;
      out.add(fromCache({'ref': id, 'title': title, 'published': e.getElement('published')?.innerText.trim()})!);
    }
    return out;
  }

  /// Rebuilds a reel of this channel from its cached form ({ref, title, published}).
  /// Newest videos from the channel page ("lockupViewModel" layout), newest first.
  List<Reel> parseChannelPage(String page, {int max = 30}) {
    final out = <Reel>[];
    final seen = <String>{};
    for (final m in _lockup.allMatches(page)) {
      if (out.length >= max) break;
      final id = m.group(1)!;
      if (seen.contains(id)) continue;
      final end = m.start + 12000 < page.length ? m.start + 12000 : page.length;
      final t = _lockupTitle.firstMatch(page.substring(m.start, end));
      if (t == null) continue;
      String title;
      try {
        title = jsonDecode('"${t.group(1)}"') as String;
      } on Object {
        title = t.group(1)!;
      }
      final r = fromCache({'ref': id, 'title': title});
      if (r == null) continue;
      seen.add(id);
      out.add(r);
    }
    return out;
  }

  static final _lockup = RegExp(
    r'"lockupViewModel":\{"contentImage":\{"thumbnailViewModel":\{"image":\{"sources":\[\{"url":"https://i\.ytimg\.com/vi/([A-Za-z0-9_-]{11})/',
  );
  static final _lockupTitle = RegExp(r'"title":\{"content":"((?:[^"\\]|\\.)*)"');

  Reel? fromCache(Object? raw) {
    if (raw is! Map) return null;
    final ref = raw['ref'];
    final title = raw['title'];
    if (ref is! String || !Reel._ytId.hasMatch(ref) || title is! String || title.trim().isEmpty) return null;
    final published = raw['published'] is String ? DateTime.tryParse(raw['published'] as String) : null;
    return Reel(
      id: 'yt-$ref',
      platform: ReelPlatform.youtube,
      ref: ref,
      url: 'https://www.youtube.com/watch?v=$ref',
      titleAr: title,
      titleEn: title,
      category: category,
      status: ReelStatus.auto,
      speakerAr: nameAr,
      speakerEn: nameEn,
      sourceId: id,
      published: published,
    );
  }

  static List<ReelSource> listFromJson(Map<String, dynamic> j) {
    if (j['schema'] != 'reel-sources.v1') return const [];
    final items = j['sources'];
    return List.unmodifiable([if (items is List) ...items.map(tryParse).whereType<ReelSource>()]);
  }
}

/// Mixes reels from several channels so no single channel fills the feed:
/// each channel's reels newest first, then taken one per channel in turn.
/// Duplicates (same id) are dropped.
List<Reel> mixReels(Iterable<List<Reel>> perSource) {
  final queues = [
    for (final l in perSource)
      if (l.isNotEmpty) ([...l]..sort((a, b) => (b.published ?? DateTime(0)).compareTo(a.published ?? DateTime(0)))),
  ];
  final seen = <String>{};
  final out = <Reel>[];
  for (var i = 0; queues.any((q) => i < q.length); i++) {
    for (final q in queues) {
      if (i < q.length && seen.add(q[i].id)) out.add(q[i]);
    }
  }
  return out;
}
