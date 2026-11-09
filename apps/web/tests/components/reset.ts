import { bookmarksStore } from "@/lib/bookmarks";
import { lastReadStore, prayerStore, prefsStore } from "@/lib/settings";
import { accountStore } from "@/lib/sync";
import { adhanStore } from "@/lib/adhan-alerts";
import { khatmaStore } from "@/lib/khatma";
import { worshipStore } from "@/lib/worship";
import { reelsFeedStore, reelsPrefsStore } from "@/lib/reels";
import { audioStore } from "@/lib/audio";
import { downloadsStore } from "@/lib/audio-offline";
import { adhkarStore } from "@/lib/adhkar";
import { adhkarViewStore } from "@/lib/dhikr-share";
import { sharePromptStore } from "@/lib/app-links";

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
    worshipStore,
    reelsPrefsStore,
    reelsFeedStore,
    audioStore,
    downloadsStore,
    adhkarStore,
    adhkarViewStore,
    sharePromptStore,
  ])
    s.reload();
}
