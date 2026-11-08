# Islamic reels

A vertical, swipeable feed of short Islamic videos (like Reels / Shorts) in the Android, iOS and web apps.

## Rules (owner decisions, 2026-11-08)
- **Source:** YouTube only for now. Instagram is not enabled (the code and the catalogue validator reject Instagram links).
- **Content:** only two kinds of reels:
  - `recitation` — humble, moving Quran recitation (تلاوة قرآنية خاشعة)
  - `lesson` — a short religious lesson in line with the Islamic Sharia and the Sunnah (درس ديني مختصر)
- **Religious review:** nothing is shown to users until a named reviewer approves it.
- **No hosting cost:** videos stay on YouTube and are played by YouTube's official privacy-enhanced embed (`youtube-nocookie.com`). Nothing is downloaded or re-hosted.

## Review states
| State | Who sees it | Required |
|---|---|---|
| `pending` | reviewers only (reviewer mode), with a red "not reviewed yet" banner | — |
| `approved` | everyone | reviewer name + review date |
| `rejected` | nobody (kept in the catalogue so it is not added again) | reviewer name + date + reason |

## Adding a reel
```
python tools/reels.py add "https://www.youtube.com/shorts/XXXXXXXXXXX" --title-ar "…" --category recitation --speaker-ar "…"
python tools/reels.py approve yt-XXXXXXXXXXX --reviewer "الاسم"
python tools/reels.py reject  yt-XXXXXXXXXXX --reviewer "الاسم" --notes "السبب"
apps/mobile/tool/sync_assets.sh            # copy the built list into the Flutter app
```
Accepted links: `youtube.com/shorts/ID`, `youtu.be/ID`, `youtube.com/watch?v=ID`, `youtube.com/embed/ID`.

The built list (`content/reels/dist/reels.v1.json`) is bundled with each app release and also served by `GET /v1/reels`, so once the API is hosted the list can change without an app update.

## How it plays
- Web: CSS scroll-snap feed; an IntersectionObserver marks the reel in view, which alone gets an `<iframe>`; arrow keys / buttons move between reels.
- Mobile: vertical `PageView`; the reel in view gets a `WebView` with the embed (autoplay muted, inline; YouTube's own controls unmute). Taps on YouTube links inside the player open the YouTube app/browser instead of navigating the feed.
- Autoplay starts muted because browsers and WebViews block autoplay with sound.

## Sample entries
The two entries shipped now are **pending samples** found by web search, only for testing the feed in reviewer mode. They have not been watched or reviewed, and normal users do not see them.
