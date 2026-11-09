import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reels.dart';

/// Pulls the newest Shorts of the trusted channels from YouTube's public
/// feeds (no API key, no account), caches them on the device and mixes them.
/// The viewer can hide a channel they do not want to see.
class ReelsFeedController extends ChangeNotifier {
  ReelsFeedController({
    required this.sources,
    required http.Client httpClient,
    required SharedPreferences prefs,
    DateTime Function()? clock,
    this.maxAge = const Duration(hours: 3),
    this.perSource = 15,
    this.timeout = const Duration(seconds: 12),
  }) : _http = httpClient,
       _prefs = prefs,
       _clock = clock ?? DateTime.now;

  final List<ReelSource> sources;
  final http.Client _http;
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

  /// Cached reels of the visible channels, mixed.
  List<Reel> get items => mixReels([for (final s in visibleSources) _cached(s)?.$2 ?? const <Reel>[]]);

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
