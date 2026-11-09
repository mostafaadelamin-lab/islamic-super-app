# Islamic reels

A vertical, swipeable feed of short Islamic videos (like Reels / Shorts) in the Android, iOS and web apps.

## Rules (owner decisions, updated 2026-11-09)
- **Source:** YouTube and Instagram. Instagram uses its official `/embed/` page, which needs no Meta app, token or account. Instagram embeds cannot autoplay, so the viewer taps play.
- **Content:** only three kinds of reels, from Quran recitation pages/channels and trusted teachers:
  - `recitation` — Quran recitation (تلاوة قرآنية)
  - `lesson` — a religious lesson in line with the Islamic Sharia and the Sunnah (درس ديني)
  - `admonition` — advice and admonitions (نصائح ومواعظ)
- **Religious review:** nothing is shown to users until a named reviewer approves it.
- **No hosting cost:** videos stay on YouTube/Instagram and are played by their official embeds (`youtube-nocookie.com`, `instagram.com/reel/<code>/embed/`). Nothing is downloaded or re-hosted.

## Review states
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
