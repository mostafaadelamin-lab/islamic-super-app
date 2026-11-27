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
import { userAdhkarStore } from "@/lib/custom-adhkar";
import { adhkarLookStore } from "@/lib/adhkar-look";
import { dhikrSavedStore } from "@/lib/audio-offline";
import { adhkarViewStore } from "@/lib/dhikr-share";
import { sharePromptStore } from "@/lib/app-links";
import { videoHistoryStore } from "@/lib/videos";
import { nasheedsSavedStore } from "@/lib/nasheeds";
import { firstRunStore } from "@/lib/first-run";
import { placeNameStore } from "@/lib/place-names";
import { dhikrReminderStore } from "@/lib/dhikr-reminders";

export function resetStores(): void {
  localStorage.clear();
  for (const s of [
    bookmarksStore,
    lastReadStore,
    prayerStore,
    placeNameStore,
    prefsStore,
    accountStore,
    adhanStore,
    dhikrReminderStore,
    khatmaStore,
    worshipStore,
    reelsPrefsStore,
    reelsFeedStore,
    videoHistoryStore,
    nasheedsSavedStore,
    audioStore,
    downloadsStore,
    adhkarStore,
    userAdhkarStore,
    adhkarLookStore,
    dhikrSavedStore,
    adhkarViewStore,
    sharePromptStore,
    firstRunStore,
  ])
    s.reload();
}
