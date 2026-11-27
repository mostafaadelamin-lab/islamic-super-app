# Islamic reels

A vertical, swipeable feed of short Islamic videos (like Reels / Shorts) in the Android, iOS and web apps.

## Rules (owner decisions, updated 2026-11-27)
- **Source:** YouTube and Instagram. Instagram uses its official `/embed/` page, which needs no Meta app, token or account. Instagram embeds cannot autoplay, so the viewer taps play.
- **Content (owner 2026-11-27, supersedes 2026-11-09): Quran recitation only** (`recitation`). Lessons and admonitions were removed. Every channel has a **group**: `golden` (Egypt's golden generation), `makkah` (imams of the Makkah Haram), `madinah` (imams of the Prophet's Mosque), `famous` (other well-known reciters). List and per-name checks: project files `_sync/videos-ideas/قائمة-القراء-الجديدة-2026-11-27.md`.
- **Excluded people:** anyone jailed or ever in a political current (owner 2026-11-27). Their names are in `EXCLUDED_PEOPLE` (Dart `video_search.dart`, JS `videos-core.mjs`, PHP `videos.php`; keep the three equal). Any new reciter needs a per-name security check with a link first.
- **Filter:** a video joins the feed only if its title looks like recitation (`RECITATION_WORDS`, or contains «﴿») and has no lesson/sermon/nasheed word (`NON_RECITATION_WORDS`). Surah names such as «القصص» and «الشرح» are not blocked on purpose.
- **Live:** `live` in `sources.json` = the official KSA Qur'an TV (Makkah) and Sunnah TV (Madinah) channels, played through `youtube-nocookie.com/embed/live_stream?channel=UC…`.
- **Layout (owner 2026-11-27):** page 1 = live cards, chips (الكل · أئمة الحرمين · الجيل الذهبي المصري · أشهر القرّاء · المحفوظة) and a row per group; page 2 = full-screen player with tabs «الكل · أئمة الحرمين · الجيل الذهبي المصري · بث مباشر من الحرمين», save and share, one video at a time; page 3 = reciters list with show/hide.
- **Automatic reels (owner decision 2026-11-09 21:31):** the apps pick the videos themselves from trusted Islamic channels. The owner approves a **channel once** (`content/reels/sources.json`); its newest Shorts are shown with **no per-video review**, marked "trusted channel". Viewers can hide a channel ("Hide this channel", with undo).
- **Hand-picked reels** (`content/reels/reels.json`) still use the review states below. Instagram reels can only be hand-picked: pulling them automatically needs a Meta Business account and app review (owner chose YouTube-automatic for now).
- **No hosting cost:** videos stay on YouTube/Instagram and are played by their official embeds (`youtube-nocookie.com`, `instagram.com/reel/<code>/embed/`). Nothing is downloaded or re-hosted.

## Trusted channels (automatic)
```
python tools/reels.py sources-add "https://www.youtube.com/channel/UC…" --name-ar "…" --name-en "…" --group golden|makkah|madinah|famous --approved-by "الاسم"
python tools/reels.py sources-remove yt-UC…
python tools/build_content.py && apps/mobile/tool/sync_assets.sh
```
Accepted: `youtube.com/@handle` links, `youtube.com/channel/UC…` links or bare `UC…` ids. An `@handle` is turned into the channel id at run time (from the channel page, once, then remembered) by the mobile app and the API.

Instagram pages the owner sent are kept in `sources.json` → `instagramPages` (not shipped): they can only be pulled automatically once a Meta Business account and an approved Meta app exist. Single reels from them can be added by hand (`tools/reels.py add`).

How the newest reels are found (no API key, no account):
1. YouTube's public Atom feed of the channel's Shorts: `https://www.youtube.com/feeds/videos.xml?playlist_id=UUSH<id without "UC">`.
2. If that fails or is empty, the channel feed `?channel_id=UC…`, keeping `/shorts/` entries (or every upload if none).
3. Up to 15 per channel, cached 3 hours; when offline the cached ones are shown. Channels are mixed (newest of each in turn), followed by the hand-picked approved reels.

- Mobile reads the feeds directly (`lib/data/reels_feed.dart`).
- Web: browsers cannot read YouTube's feeds (no CORS), so the site asks the API `GET /v1/reels/feed` (`services/api/app/domain/reel_feed.py`, same steps, cached 3 hours). **The website shows automatic reels only once the API is hosted** and its address is set (Settings → account server); until then it says it could not reach YouTube and shows the hand-picked list.

## Review states (hand-picked reels)
| State | Who sees it | Required |
|---|---|---|
| `pending` | reviewers only (reviewer mode), with a red "not reviewed yet" banner | — |
| `approved` | everyone | reviewer name + review date |
| `rejected` | nobody (kept in the catalogue so it is not added again) | reviewer name + date + reason |

## Adding a reel
```
python tools/reels.py add "https://www.youtube.com/shorts/XXXXXXXXXXX" --title-ar "…" --category recitation --speaker-ar "…"
python tools/reels.py add "https://www.instagram.com/reel/CODE/" --title-ar "…" --category admonition
python tools/reels.py approve yt-XXXXXXXXXXX --reviewer "الاسم"
python tools/reels.py reject  yt-XXXXXXXXXXX --reviewer "الاسم" --notes "السبب"
apps/mobile/tool/sync_assets.sh            # copy the built list into the Flutter app
```
Accepted links: `youtube.com/shorts/ID`, `youtu.be/ID`, `youtube.com/watch?v=ID`, `youtube.com/embed/ID`, `instagram.com/reel/CODE`, `instagram.com/reels/CODE`, `instagram.com/p/CODE`, `instagram.com/<user>/reel/CODE`.

The built list (`content/reels/dist/reels.v1.json`) is bundled with each app release and also served by `GET /v1/reels`, so once the API is hosted the list can change without an app update.

## How it plays
- Web: CSS scroll-snap feed; an IntersectionObserver marks the reel in view, which alone gets an `<iframe>`; arrow keys / buttons move between reels.
- Mobile: vertical `PageView`; the reel in view gets a `WebView` with the embed (YouTube: autoplay muted, inline; Instagram: tap play). Only the official embed pages may load in the feed (`reelNavigationAllowedInFeed`); other links open the YouTube/Instagram app or the browser.
- Autoplay starts muted because browsers and WebViews block autoplay with sound.

## Sample entries
The two entries shipped now are **pending samples** found by web search, only for testing the feed in reviewer mode. They have not been watched or reviewed, and normal users do not see them.
