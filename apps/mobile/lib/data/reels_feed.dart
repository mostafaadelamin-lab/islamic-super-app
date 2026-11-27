import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reels.dart';
import '../domain/video_search.dart';

/// Pulls the newest recitations of the trusted reciters' channels from YouTube's
/// public feeds (no API key, no account), caches them on the device and mixes them.
/// Owner 2026-11-27: recitation only, grouped into tabs (all, Haramain imams,
/// Egypt's golden generation, famous reciters) plus the Haramain live streams.
/// The viewer can hide a reciter and save recitations.
class ReelsFeedController extends ChangeNotifier {
  ReelsFeedController({
    required List<ReelSource> sources,
    this.suggestionPool = const [],
    this.live = const [],
    required http.Client httpClient,
    required SharedPreferences prefs,
    DateTime Function()? clock,
    this.maxAge = const Duration(hours: 3),
    this.perSource = 15,
    this.timeout = const Duration(seconds: 12),
  }) : _base = sources,
       _http = httpClient,
       _prefs = prefs,
       _clock = clock ?? DateTime.now;

  final List<ReelSource> _base;

  /// Extra trusted Islamic channels the app adds by itself as the viewer's interest grows.
  final List<ReelSource> suggestionPool;

  /// Official live streams from the Haramain.
  final List<LiveChannel> live;
  final http.Client _http;

  /// Tabs (owner 2026-11-27). The reels player shows all, haramain, golden and live;
  /// the videos home also has famous and saved.
  static const tabAll = 'all';
  static const tabHaramain = 'haramain';
  static const tabGolden = 'golden';
  static const tabFamous = 'famous';
  static const tabLive = 'live';
  static const tabSaved = 'saved';

  /// Does [s] belong to [tab]? A channel the viewer added has no group and shows under «الكل» only.
  static bool inTab(ReelSource s, String tab) => switch (tab) {
    tabAll => true,
    tabHaramain => s.group == 'makkah' || s.group == 'madinah',
    tabGolden => s.group == 'golden',
    tabFamous => s.group == 'famous',
    _ => false,
  };

  /// Visible reciters of [tab], in the owner's order.
  List<ReelSource> sourcesIn(String tab) => [
    for (final s in visibleSources)
      if (inTab(s, tab)) s,
  ];

  /// Cached recitations of [tab] (saved ones for [tabSaved]), mixed across its reciters.
  List<Reel> itemsIn(String tab) {
    if (tab == tabSaved) return saved;
    if (tab == tabAll) return items;
    return mixReels([for (final s in sourcesIn(tab)) _cached(s)?.$2 ?? const <Reel>[]]);
  }

  /// Cached recitations of one reciter, newest first.
  List<Reel> itemsOf(String sourceId) {
    final s = source(sourceId);
    return s == null ? const [] : mixReels([_cached(s)?.$2 ?? const <Reel>[]]);
  }

  // --- Saved recitations -------------------------------------------------------

  static const savedKey = 'reels.saved';
  static const savedMax = 200;

  /// Saved recitations, newest saved first (kept on this device only).
  List<Reel> get saved => [
    for (final raw in _prefs.getStringList(savedKey) ?? const <String>[]) ?_savedReel(_decode(raw)),
  ];

  Reel? _savedReel(Object? raw) {
    if (raw is! Map) return null;
    final src = source(raw['sourceId'] as String?);
    if (src != null) return src.fromCache(raw);
    final name = raw['speaker'] is String ? raw['speaker'] as String : '';
    return ReelSource(
      id: (raw['sourceId'] as String?) ?? 'saved',
      channelId: null,
      handle: 'saved',
      nameAr: name,
      nameEn: name,
      category: 'recitation',
      group: Reel.groups.contains(raw['group']) ? raw['group'] as String : null,
    ).fromCache(raw);
  }

  bool isSaved(Reel r) => saved.any((x) => x.ref == r.ref);

  /// Saves [r], or removes it when it is already saved. Returns true when it is now saved.
  Future<bool> toggleSave(Reel r) async {
    final list = [...?_prefs.getStringList(savedKey)];
    final before = list.length;
    list.removeWhere((raw) {
      final j = _decode(raw);
      return j is Map && j['ref'] == r.ref;
    });
    final nowSaved = list.length == before;
    if (nowSaved) {
      list.insert(
        0,
        jsonEncode({
          'ref': r.ref,
          'title': r.titleAr,
          'sourceId': r.sourceId,
          'speaker': r.speakerAr,
          'group': r.group,
          'published': r.published?.toUtc().toIso8601String(),
        }),
      );
      if (list.length > savedMax) list.removeRange(savedMax, list.length);
    }
    await _prefs.setStringList(savedKey, list);
    notifyListeners();
    return nowSaved;
  }

  static const userKey = 'reels.userSources';
  static const suggestedKey = 'reels.suggested';
  static const interestKey = 'reels.interest';

  /// Channels the viewer added by searching.
  List<ReelSource> get userSources => [
    for (final raw in _prefs.getStringList(userKey) ?? const <String>[]) ?ReelSource.tryParse(_decode(raw)),
  ];

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on Object {
      return null;
    }
  }

  /// Suggested channels switched on automatically (ids from [suggestionPool]).
  List<ReelSource> get suggested {
    final on = {...?_prefs.getStringList(suggestedKey)};
    return [
      for (final s in suggestionPool)
        if (on.contains(s.id)) s,
    ];
  }

  /// Every channel in the feed: the owner's list, the viewer's own, then suggestions.
  List<ReelSource> get sources {
    final seen = <String>{};
    return [
      for (final s in [..._base, ...userSources, ...suggested])
        if (seen.add(s.id)) s,
    ];
  }

  /// Seconds watched per channel (the viewer's interest).
  Map<String, int> get interest {
    final raw = _prefs.getString(interestKey);
    if (raw == null) return const {};
    try {
      return {for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries) e.key: (e.value as num).toInt()};
    } on Object {
      return const {};
    }
  }

  /// Records [seconds] watched on a reel of [sourceId]; every 90 s watched in one category
  /// switches on one more suggested channel of that category (up to 8).
  Future<void> recordWatch(String? sourceId, int seconds) async {
    final src = source(sourceId);
    if (src == null || seconds < 3) return;
    final m = Map<String, int>.of(interest)..update(src.id, (v) => v + seconds, ifAbsent: () => seconds);
    await _prefs.setString(interestKey, jsonEncode(m));
    var catSeconds = 0;
    for (final s in sources) {
      if (s.category == src.category) catSeconds += m[s.id] ?? 0;
    }
    final on = [...?_prefs.getStringList(suggestedKey)];
    final wanted = (catSeconds ~/ 90).clamp(0, 8);
    final inCat = suggestionPool.where((s) => s.category == src.category && on.contains(s.id)).length;
    if (inCat < wanted && on.length < 8) {
      final have = {for (final s in sources) s.id};
      for (final s in suggestionPool) {
        if (s.category == src.category && !have.contains(s.id)) {
          on.add(s.id);
          await _prefs.setStringList(suggestedKey, on);
          notifyListeners();
          unawaited(refresh());
          break;
        }
      }
    }
  }

  /// Adds a channel the viewer found by searching.
  Future<void> addUserSource(String channelId, String name, {String category = 'recitation'}) async {
    if (!ReelSource.channelPattern.hasMatch(channelId)) return;
    final list = [...?_prefs.getStringList(userKey)];
    if (sources.any((s) => s.channelId == channelId)) {
      await unhide('yt-$channelId');
      return;
    }
    list.add(
      jsonEncode({
        'platform': 'youtube',
        'category': category,
        'channelId': channelId,
        'name': {'ar': name, 'en': name},
      }),
    );
    await _prefs.setStringList(userKey, list);
    notifyListeners();
    await refresh();
  }

  Future<void> removeUserSource(String id) async {
    final list = [
      for (final raw in _prefs.getStringList(userKey) ?? const <String>[])
        if (ReelSource.tryParse(_decode(raw))?.id != id) raw,
    ];
    await _prefs.setStringList(userKey, list);
    notifyListeners();
  }

  /// Channels matching [query] on YouTube (channel search page; no API key). Empty when offline.
  Future<List<({String id, String title, String? subs})>> searchChannels(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final page = await _get(
      Uri.https('www.youtube.com', '/results', {'search_query': q, 'sp': 'EgIQAg==', 'hl': 'ar'}),
    );
    if (page == null) return const [];
    return [
      for (final c in parseChannelSearch(page))
        if (allowedChannel(c.title)) c,
    ];
  }

  @visibleForTesting
  static List<({String id, String title, String? subs})> parseChannelSearch(String page) {
    final out = <({String id, String title, String? subs})>[];
    final seen = <String>{};
    final re = RegExp(
      r'"channelRenderer":\{"channelId":"(UC[A-Za-z0-9_-]{22})","title":\{"simpleText":"((?:[^"\\]|\\.)*)"',
    );
    for (final m in re.allMatches(page)) {
      if (!seen.add(m.group(1)!)) continue;
      String title;
      try {
        title = jsonDecode('"${m.group(2)}"') as String;
      } on Object {
        title = m.group(2)!;
      }
      final after = page.substring(m.end, math.min(page.length, m.end + 4000));
      final subs = RegExp(r'"subscriberCountText":\{[^}]*?"simpleText":"([^"]+)"').firstMatch(after)?.group(1);
      out.add((id: m.group(1)!, title: title, subs: subs));
      if (out.length >= 15) break;
    }
    return out;
  }

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final Duration maxAge;
  final int perSource;
  final Duration timeout;

  static const hiddenKey = 'reels.hiddenSources';
  static String cacheKey(String sourceId) => 'reels.cache.$sourceId';

  bool _loading = false;
  bool _failed = false;
  Future<void>? _inFlight;

  bool get loading => _loading;

  /// True when no channel could be reached and nothing was cached.
  bool get failed => _failed;

  Set<String> get hidden => {...?_prefs.getStringList(hiddenKey)};

  List<ReelSource> get visibleSources => [
    for (final s in sources)
      if (!hidden.contains(s.id)) s,
  ];

  ReelSource? source(String? id) {
    for (final s in sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Cached reels of the visible channels, mixed; the channels watched most come first.
  List<Reel> get items {
    final score = interest;
    final ordered = [...visibleSources]..sort((a, b) => (score[b.id] ?? 0).compareTo(score[a.id] ?? 0));
    return mixReels([for (final s in ordered) _cached(s)?.$2 ?? const <Reel>[]]);
  }

  (DateTime, List<Reel>)? _cached(ReelSource s) {
    final raw = _prefs.getString(cacheKey(s.id));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(j['at'] as String);
      final list = [
        for (final r in j['items'] as List<dynamic>) ?s.fromCache(r),
      ].where((r) => allowedFeedTitle(r.titleAr, s.group)).toList();
      return (at, list);
    } on Object {
      return null;
    }
  }

  /// Fetches every visible channel of [tab] whose cache is older than [maxAge] (or all
  /// of them with [force]), [batch] channels at a time so the list fills quickly without
  /// a burst of requests; channels with no cache yet go first. Never throws; a channel
  /// that fails keeps its cache.
  Future<void> refresh({bool force = false, String tab = tabAll}) =>
      _inFlight ??= _refresh(force, tab).whenComplete(() => _inFlight = null);

  static const batch = 8;

  Future<void> _refresh(bool force, String tab) async {
    final now = _clock();
    bool stale(ReelSource s) {
      final at = _cached(s)?.$1;
      return force || at == null || now.difference(at) >= maxAge;
    }

    final due = sourcesIn(tab == tabSaved || tab == tabLive ? tabAll : tab).where(stale).toList()
      ..sort((a, b) => (_cached(a) == null ? 0 : 1).compareTo(_cached(b) == null ? 0 : 1));
    if (due.isEmpty) {
      _failed = false;
      return;
    }
    _loading = true;
    notifyListeners();
    var anyOk = false;
    for (var i = 0; i < due.length; i += batch) {
      await Future.wait(
        due.skip(i).take(batch).map((s) async {
          final list = await _fetch(s);
          if (list == null) return;
          anyOk = true;
          await _prefs.setString(
            cacheKey(s.id),
            jsonEncode({
              'at': now.toUtc().toIso8601String(),
              'items': [
                for (final r in list.where((r) => allowedFeedTitle(r.titleAr, s.group)).take(perSource))
                  {'ref': r.ref, 'title': r.titleAr, 'published': r.published?.toUtc().toIso8601String()},
              ],
            }),
          );
        }),
      );
      if (i + batch < due.length) notifyListeners();
    }
    _loading = false;
    _failed = !anyOk && items.isEmpty;
    notifyListeners();
  }

  static String handleKey(String handle) => 'reels.handle.$handle';

  /// The channel id: given, remembered from an earlier lookup, or read from
  /// the channel's @handle page (then remembered).
  Future<String?> _channelId(ReelSource s) async {
    if (s.channelId != null) return s.channelId;
    final key = handleKey(s.handle!);
    final known = _prefs.getString(key);
    if (known != null && ReelSource.channelPattern.hasMatch(known)) return known;
    final page = await _get(s.channelPage);
    final id = page == null ? null : ReelSource.channelIdFromPage(page);
    if (id != null) await _prefs.setString(key, id);
    return id;
  }

  /// The Shorts feed first; if it fails or is empty, the channel feed
  /// (Shorts entries only, else every upload). Null when unreachable.
  Future<List<Reel>?> _fetch(ReelSource s) async {
    final cid = await _channelId(s);
    if (cid == null) return null;
    final shorts = await _get(ReelSource.shortsFeed(cid));
    final fromShorts = shorts == null ? const <Reel>[] : s.parseFeed(shorts);
    if (fromShorts.isNotEmpty) return fromShorts;
    final all = await _get(ReelSource.channelFeed(cid));
    if (all != null) {
      final onlyShorts = s.parseFeed(all, shortsOnly: true);
      final fromFeed = onlyShorts.isNotEmpty ? onlyShorts : s.parseFeed(all);
      if (fromFeed.isNotEmpty) return fromFeed;
    }
    // YouTube's feeds sometimes fail (404/500, seen 2026-11-13): read the channel's Videos tab instead.
    final page = await _get(ReelSource.channelVideosPage(cid));
    if (page == null) return shorts == null && all == null ? null : const [];
    return s.parseChannelPage(page);
  }

  Future<String?> _get(Uri u) async {
    try {
      final res = await _http.get(u).timeout(timeout);
      if (res.statusCode != 200) return null;
      return utf8.decode(res.bodyBytes, allowMalformed: true);
    } on Object {
      return null;
    }
  }

  // --- Video search ----------------------------------------------------------

  static const historyKey = 'videos.searchHistory';
  static const historyMax = 20;

  /// The viewer's past searches, newest first (kept on this device only).
  List<String> get searchHistory => [...?_prefs.getStringList(historyKey)];

  Future<void> rememberSearch(String query) async {
    final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (q.isEmpty) return;
    final list = [q, ...searchHistory.where((x) => x.toLowerCase() != q.toLowerCase())].take(historyMax).toList();
    await _prefs.setStringList(historyKey, list);
    notifyListeners();
  }

  Future<void> forgetSearch(String query) async {
    await _prefs.setStringList(historyKey, [...searchHistory.where((x) => x != query)]);
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(historyKey);
    notifyListeners();
  }

  /// Every channel the app trusts (owner's list, the viewer's own and the suggested ones).
  Set<String> get trustedChannelIds => {
    for (final s in [...sources, ...suggestionPool])
      if (s.channelId != null) s.channelId!,
  };

  /// Islamic videos for [query]: matches in the trusted channels' cached feed first, then
  /// YouTube's search filtered by [allowedVideo]. Null when YouTube cannot be reached and
  /// nothing matched locally.
  Future<List<VideoHit>?> searchVideos(String query) async {
    final q = query.trim();
    if (q.isEmpty || isBlockedVideoText(q)) return const [];
    final nq = normalizeSearch(q);
    final words = nq.split(' ').where((w) => w.isNotEmpty).toList();
    final local = <VideoHit>[
      for (final r in items)
        if (words.every((w) => normalizeSearch(r.titleAr).contains(w)))
          VideoHit(
            ref: r.ref,
            title: r.titleAr,
            channel: source(r.sourceId)?.name(true),
            channelId: source(r.sourceId)?.channelId,
            trusted: true,
          ),
    ];
    final page = await _get(videoSearchUri(q));
    if (page == null) return local.isEmpty ? null : local;
    final trusted = trustedChannelIds;
    final seen = {for (final h in local) h.ref};
    final web = [
      for (final h in parseVideoSearch(page))
        if (!seen.contains(h.ref) && allowedVideo(h, trusted)) h.withTrusted(trusted.contains(h.channelId)),
    ]..sort((a, b) => (a.trusted ? 0 : 1).compareTo(b.trusted ? 0 : 1));
    return [...local, ...web];
  }

  Future<void> hide(String sourceId) async {
    await _prefs.setStringList(hiddenKey, [...hidden, sourceId]..sort());
    notifyListeners();
  }

  Future<void> unhide(String sourceId) async {
    await _prefs.setStringList(hiddenKey, [...hidden.where((h) => h != sourceId)]);
    notifyListeners();
    await refresh();
  }
}
