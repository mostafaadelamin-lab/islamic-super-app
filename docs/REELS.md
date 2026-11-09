# Islamic reels

A vertical, swipeable feed of short Islamic videos (like Reels / Shorts) in the Android, iOS and web apps.

## Rules (owner decisions, updated 2026-11-09)
- **Source:** YouTube and Instagram. Instagram uses its official `/embed/` page, which needs no Meta app, token or account. Instagram embeds cannot autoplay, so the viewer taps play.
- **Content:** only three kinds of reels, from Quran recitation pages/channels and trusted teachers:
  - `recitation` — Quran recitation (تلاوة قرآنية)
  - `lesson` — a religious lesson in line with the Islamic Sharia and the Sunnah (درس ديني)
  - `admonition` — advice and admonitions (نصائح ومواعظ)
- **Automatic reels (owner decision 2026-11-09 21:31):** the apps pick the videos themselves from trusted Islamic channels. The owner approves a **channel once** (`content/reels/sources.json`); its newest Shorts are shown with **no per-video review**, marked "trusted channel". Viewers can hide a channel ("Hide this channel", with undo).
- **Hand-picked reels** (`content/reels/reels.json`) still use the review states below. Instagram reels can only be hand-picked: pulling them automatically needs a Meta Business account and app review (owner chose YouTube-automatic for now).
- **No hosting cost:** videos stay on YouTube/Instagram and are played by their official embeds (`youtube-nocookie.com`, `instagram.com/reel/<code>/embed/`). Nothing is downloaded or re-hosted.

## Trusted channels (automatic)
```
python tools/reels.py sources-add "https://www.youtube.com/channel/UC…" --name-ar "…" --name-en "…" --category recitation --approved-by "الاسم"
python tools/reels.py sources-remove yt-UC…
python tools/build_content.py && apps/mobile/tool/sync_assets.sh
```
Only `/channel/UC…` links or bare `UC…` ids are accepted (an `@handle` must be turned into its channel id first, e.g. from the channel page's "Share channel → Copy channel ID").

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
