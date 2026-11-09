import { bookmarksStore } from "@/lib/bookmarks";
import { lastReadStore, prayerStore, prefsStore } from "@/lib/settings";
import { accountStore } from "@/lib/sync";
import { adhanStore } from "@/lib/adhan-alerts";
import { reelsFeedStore, reelsPrefsStore } from "@/lib/reels";

export function resetStores(): void {
  localStorage.clear();
  for (const s of [bookmarksStore, lastReadStore, prayerStore, prefsStore, accountStore, adhanStore, reelsPrefsStore, reelsFeedStore])
    s.reload();
}
