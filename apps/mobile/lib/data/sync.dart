import '../domain/bookmark.dart';
import 'api.dart';
import 'bookmarks.dart';

class SyncReport {
  const SyncReport({required this.pulled, required this.pushed, required this.active});
  final int pulled;
  final int pushed;
  final int active;
}

/// Bookmark sync per API.md: pull changes since the last server time, merge
/// last-write-wins (tombstones included), then push every locally changed
/// item; the server's stored copy (its own LWW result) is merged back.
class SyncService {
  const SyncService(this.api, this.store);
  final ApiClient api;
  final BookmarksController store;

  Future<SyncReport> sync(String token) async {
    final page = await api.getBookmarks(token, since: store.since);
    final changed = await store.applyRemote(page.items);
    var pushed = 0;
    for (final id in store.dirty.toList()..sort()) {
      final Bookmark? local = store.all[id];
      if (local == null) {
        await store.markPushed(id, Bookmark(id: id, surah: 1, ayah: 1, updatedAt: 0));
        continue;
      }
      final stored = await api.putBookmark(token, local);
      await store.applyRemote([stored]);
      await store.markPushed(id, local);
      pushed++;
    }
    await store.setSince(page.serverTime);
    return SyncReport(pulled: changed.length, pushed: pushed, active: store.active.length);
  }
}
