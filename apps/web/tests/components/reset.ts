import { bookmarksStore } from "@/lib/bookmarks";
import { lastReadStore, prayerStore, prefsStore } from "@/lib/settings";
import { accountStore } from "@/lib/sync";

export function resetStores(): void {
  localStorage.clear();
  for (const s of [bookmarksStore, lastReadStore, prayerStore, prefsStore, accountStore]) s.reload();
}
