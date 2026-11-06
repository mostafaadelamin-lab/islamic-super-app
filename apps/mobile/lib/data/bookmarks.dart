import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/bookmark.dart';
import '../domain/quran.dart';

typedef Clock = DateTime Function();

/// Local bookmark repository (shared_preferences). Deletions are kept as
/// tombstones so they can be synced; [dirty] holds ids not yet pushed.
class BookmarksController extends ChangeNotifier {
  BookmarksController(this._prefs, {Clock? clock}) : _clock = clock ?? DateTime.now {
    final raw = _prefs.getString(_kItems);
    if (raw != null) {
      for (final j in jsonDecode(raw) as List<dynamic>) {
        final b = Bookmark.fromJson(j as Map<String, dynamic>);
        _items[b.id] = b;
      }
    }
    _dirty.addAll(_prefs.getStringList(_kDirty) ?? const []);
  }

  static const _kItems = 'bookmarks.v1';
  static const _kDirty = 'bookmarks.dirty';
  static const _kSince = 'sync.since';

  final SharedPreferences _prefs;
  final Clock _clock;
  final Map<String, Bookmark> _items = {};
  final Set<String> _dirty = {};

  /// Every stored item, tombstones included.
  Map<String, Bookmark> get all => Map.unmodifiable(_items);

  /// Live bookmarks, most recently changed first.
  List<Bookmark> get active =>
      _items.values.where((b) => !b.deleted).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Set<String> get dirty => Set.unmodifiable(_dirty);
  int get since => _prefs.getInt(_kSince) ?? 0;

  bool isBookmarked(AyahRef r) {
    final b = _items[Bookmark.idFor(r.surah, r.ayah)];
    return b != null && !b.deleted;
  }

  int _stamp(String id) {
    final now = _clock().millisecondsSinceEpoch;
    final prev = _items[id]?.updatedAt ?? 0;
    return now > prev ? now : prev + 1;
  }

  Future<void> add(AyahRef r) async {
    final id = Bookmark.idFor(r.surah, r.ayah);
    _items[id] = Bookmark(id: id, surah: r.surah, ayah: r.ayah, updatedAt: _stamp(id));
    _dirty.add(id);
    await _save();
  }

  Future<void> remove(String id) async {
    final b = _items[id];
    if (b == null || b.deleted) return;
    _items[id] = b.copyWith(deleted: true, updatedAt: _stamp(id));
    _dirty.add(id);
    await _save();
  }

  /// Adds the bookmark if absent, otherwise removes it. Returns the new state.
  Future<bool> toggle(AyahRef r) async {
    if (isBookmarked(r)) {
      await remove(Bookmark.idFor(r.surah, r.ayah));
      return false;
    }
    await add(r);
    return true;
  }

  /// Applies server items with last-write-wins; returns the ids that changed.
  Future<Set<String>> applyRemote(Iterable<Bookmark> remote) async {
    final (merged, changed) = mergeBookmarks(_items, remote);
    if (changed.isEmpty) return changed;
    _items
      ..clear()
      ..addAll(merged);
    await _save();
    return changed;
  }

  /// Marks [id] as pushed, provided it was not edited again since [pushed].
  Future<void> markPushed(String id, Bookmark pushed) async {
    final cur = _items[id];
    if (cur != null && cur.updatedAt > pushed.updatedAt) return;
    _dirty.remove(id);
    await _prefs.setStringList(_kDirty, _dirty.toList()..sort());
  }

  Future<void> setSince(int serverTime) => _prefs.setInt(_kSince, serverTime);

  /// Forget sync state (on sign-out) so the next account starts clean.
  Future<void> resetSyncState() async {
    await _prefs.remove(_kSince);
    _dirty
      ..clear()
      ..addAll(_items.keys);
    await _prefs.setStringList(_kDirty, _dirty.toList()..sort());
  }

  Future<void> _save() async {
    await _prefs.setString(_kItems, jsonEncode([for (final b in _items.values) b.toJson()]));
    await _prefs.setStringList(_kDirty, _dirty.toList()..sort());
    notifyListeners();
  }
}
