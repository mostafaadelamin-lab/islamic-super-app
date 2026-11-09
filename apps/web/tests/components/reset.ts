import { bookmarksStore } from "@/lib/bookmarks";
import { lastReadStore, prayerStore, prefsStore } from "@/lib/settings";
import { accountStore } from "@/lib/sync";
import { adhanStore } from "@/lib/adhan-alerts";
import { khatmaStore } from "@/lib/khatma";

export function resetStores(): void {
  localStorage.clear();
  for (const s of [
    bookmarksStore,
    lastReadStore,
    prayerStore,
    prefsStore,
    accountStore,
    adhanStore,
    khatmaStore,
  ])
    s.reload();
}
