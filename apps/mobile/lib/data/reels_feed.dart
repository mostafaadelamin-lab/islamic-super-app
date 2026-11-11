import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reels.dart';

/// Pulls the newest Shorts of the trusted channels from YouTube's public
/// feeds (no API key, no account), caches them on the device and mixes them.
/// The viewer can hide a channel they do not want to see.
class ReelsFeedController extends ChangeNotifier {
  ReelsFeedController({
    required List<ReelSource> sources,
    this.suggestionPool = const [],
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
  final http.Client _http;

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
  Future<void> addUserSource(String channelId, String name, {String category = 'lesson'}) async {
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
    return parseChannelSearch(page);
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
      final list = [for (final r in j['items'] as List<dynamic>) s.fromCache(r)].whereType<Reel>().toList();
      return (at, list);
    } on Object {
      return null;
    }
  }

  /// Fetches every visible channel whose cache is older than [maxAge] (or all
  /// of them with [force]). Never throws; a channel that fails keeps its cache.
  Future<void> refresh({bool force = false}) => _inFlight ??= _refresh(force).whenComplete(() => _inFlight = null);

  Future<void> _refresh(bool force) async {
    final now = _clock();
    bool stale(ReelSource s) {
      final at = _cached(s)?.$1;
      return force || at == null || now.difference(at) >= maxAge;
    }

    final due = visibleSources.where(stale).toList();
    if (due.isEmpty) {
      _failed = false;
      return;
    }
    _loading = true;
    notifyListeners();
    var anyOk = false;
    await Future.wait(
      due.map((s) async {
        final list = await _fetch(s);
        if (list == null) return;
        anyOk = true;
        await _prefs.setString(
          cacheKey(s.id),
          jsonEncode({
            'at': now.toUtc().toIso8601String(),
            'items': [
              for (final r in list.take(perSource))
                {'ref': r.ref, 'title': r.titleAr, 'published': r.published?.toUtc().toIso8601String()},
            ],
          }),
        );
      }),
    );
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
    if (all == null) return shorts == null ? null : const [];
    final onlyShorts = s.parseFeed(all, shortsOnly: true);
    return onlyShorts.isNotEmpty ? onlyShorts : s.parseFeed(all);
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
