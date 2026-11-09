# Changelog

## [Unreleased] — Adhkar, help and sharing (owner's feature list, phases 5–6) — 2026-11-10
### Added
- Hisn al-Muslim sections (remembrance, morning and evening, sleep, prayer, home, food, travel, hardship, illness, nature, people, hajj): a grouping of the existing chapters, no text added or changed.
- Adhkar and Hisn al-Muslim as a list or one card at a time; in cards the morning / evening adhkar move on by themselves when a dhikr's count is complete.
- Share any dhikr (text unchanged, with its source) and "Report a mistake" (opens email / the share sheet with the chapter, number and the first words).
- Morning and evening adhkar reminders at a chosen time (mobile notifications ids 2002 / 2003; web while a page is open).
- Help & contact: frequently asked questions, contact (address pending from the owner), share the app, rate (once the store links are set in packages/shared-schemas/app-links.json).
- A one-time "Share Rattil?" suggestion after the app has been used on five different days.
- Home-screen shortcuts: Quran, prayer times, adhkar and tasbih (Android / iOS long-press; installed web app).
### Not yet
- Zakat calculator: waits for the owner to choose the published reference, then a shar'i review.
- Fadl notes and dhikr audio: need a licensed published source.

## [Unreleased] — Reader and player: speed, lock screen, offline, share as image (owner's feature list, phase 4) — 2026-11-09
### Added
- Playback speed 0.75× to 2× (mobile mini player; web player bar, Mushaf player and Settings), kept between sessions.
- Lock-screen / notification controls (play, pause, next and previous ayah, stop) showing the surah, ayah and reciter. Mobile (audio_service) also keeps reciting with the screen off on Android; web uses the browser's Media Session.
- Listen offline: save whole surahs of the chosen reciter (basmala included) and delete them again; saved surahs play without a connection. Mobile: More → Downloads. Web: Settings → Listen offline (Cache Storage, served by the service worker).
- Share an ayah as an image: a card in the Rattil colours with the ayah text unchanged, its reference and the app name. Mobile opens a preview then the share sheet; web uses the share sheet where the browser can share files and downloads the PNG otherwise.
### Fixed
- Web worship calendar: removed partial grid roles that screen readers could not use (axe).

## [Unreleased] — Prayer alarms, Quran khatma and tasbih (owner's feature list, phases 1–3) — 2026-11-09
### Added
- Prayer times: move between days (previous / next / today) with the Hijri date; 12 or 24 hour clock; "use my location" (GPS, coarse) with the nearest city's time zone and method; monthly prayer calendar with a Gregorian / Hijri month toggle that follows the Hijri adjustment, shared as an image (mobile) or printed / saved as PDF (web).
- Prayer alerts (mobile notifications; web while a page is open): a reminder 5–30 minutes before the adhan, an iqama alert with minutes per prayer, alerts at sunrise and at the start of the last third of the night, a Friday reminder (Surat al-Kahf) at a chosen time, and a sound per prayer (adhan, short tone or silent). Reminders never use the adhan recording.
- Home: "N min since the X adhan" during the first half hour after each adhan.
- Quran khatma (mobile + web): plan by number of days or pages per day, today's portion with its pages and opening words, mark as read, ahead / behind the plan, reschedule the rest over the remaining days, rename, daily reminder, and a history of finished khatmas.
- Tasbih on the web: a separate counter, target and rounds for each dhikr, a beads mode, nine colours, optional click sound and vibration, the user's own adhkar (up to 20), and a 60-day history that can be cleared.
### Notes
- Mobile reminders (khatma, Friday, later adhkar) share the iOS 64-notification budget with the adhan plan.

## [Unreleased] — Owner's reference guidelines: audit and fixes — 2026-11-09
See docs/reports/GUIDELINES_AUDIT.md.
### Added
- Hijri date: manual adjustment of the Umm al-Qura date (−2..+2 days) in Settings on mobile and web, with a live preview, so the date can follow the moon sighting announced locally. Used everywhere a Hijri date is shown.
- Qibla compass (mobile): reads the phone's own compass heading (iOS CLLocationManager, Android rotation-vector sensor) and falls back to the raw accelerometer + magnetometer. Mobile and web now correct magnetic north to true north with the World Magnetic Model 2025 (Cairo ≈ +4.8°, New York ≈ −12.5°); before this the needle could be off by the local declination.
- Android: the adhan plays in full at prayer time through an exact AlarmManager alarm and a media-playback foreground service (Stop button, stops on a phone call, notification only on silent/vibrate, alarms restored after reboot / update / clock change). Tone and silent alerts are unchanged.
- Nearby mosques (owner chose OpenStreetMap, 2026-11-09): mobile (More → Nearby mosques) and web (/mosques, also on the More page). Mosques tagged in OpenStreetMap within 2 / 5 / 10 km of the prayer-times location, nearest first, with distance; the last list is kept for offline use. Mobile opens directions in the phone's maps app; web links to openstreetmap.org and can use the browser's current location. Free Overpass API servers (overpass-api.de, then overpass.kumi.systems); "© OpenStreetMap contributors" shown as the ODbL requires.
### Fixed (re-applied from the religious content review of 2026-11-07, which was lost with the GitHub suspension)
- Umm al-Qura method: Isha is 120 min after Maghrib during Ramadan (90 min otherwise), on server, web and mobile. Ramadan dates come from the Umm al-Qura calendar table in methods.json (1440–1499 AH).
- Web adhkar: the last two verses of al-Baqarah are in the evening list only (as on mobile).
## [Unreleased] — Reels pick themselves from trusted channels — 2026-11-09
### Added
- The app now fills the reels by itself (owner decision 2026-11-09): it pulls the newest Shorts of trusted Islamic YouTube channels the owner approved once (`content/reels/sources.json`, first channel: Sheikh Yasser Al-Dosari), mixes the channels and shows them before the hand-picked reels. No per-video review; each such reel shows a "Trusted channel" chip.
- "Hide this channel" on every automatic reel (with undo, and "Show hidden channels" in the empty state).
- Mobile reads YouTube's public feeds directly (no key or account), caches 3 hours and works offline from the cache. Website: through the new API endpoint `GET /v1/reels/feed` (needs the API hosted).
- `tools/reels.py sources-add / sources-remove` to manage the trusted channels.
### Unchanged
- Instagram stays hand-picked (owner's choice: automatic YouTube now). Hand-picked reels keep the pending / approved / rejected review.

## [Unreleased] — Reels: Instagram + admonitions — 2026-11-09
### Added
- Reels now accept Instagram as well as YouTube (owner decision 2026-11-09). Instagram reels play through Instagram's official embed page (no Meta app, token or account); they need a tap to play.
- Third reels category "advice and admonitions" (نصائح ومواعظ). Categories are now: Quran recitation, religious lesson, advice and admonitions.
- Reels show a platform chip (YouTube / Instagram) and an "Open on YouTube / Instagram" button; Instagram reels show a placeholder instead of a poster off-screen.
- Mobile: only the official embed pages may load inside the feed; any other link opens the YouTube/Instagram app or the browser.
### Unchanged
- Religious review gate (pending / approved / rejected): users still see approved reels only.

## [Unreleased] — Mushaf reader redesign + listen with tafsir — 2026-11-09
### Changed
- Mushaf page reader redesigned on the website and the mobile app after the owner's mockup (layout only; our own icons and ornaments): tabs Mushaf / Ayat / Tafsir at the top, an ornate surah band, a floating recitation card (reciter drop-down, previous / play-pause / next, repeat count, "Listen with tafsir"), a page slider and a bottom bar (Index, Bookmarks, Khatma, Search). On phones the reader is full-screen.
### Added
- Tap any ayah: "Play this ayah", "Play from here", "Listen with tafsir", play the surah, bookmark, copy, and its Tafsir al-Muyassar entry.
- "Listen with tafsir": the screen splits in two — the ayah being recited (highlighted) and its Tafsir al-Muyassar entry (KFGQPC, verbatim) — following the recitation ayah by ayah and across page turns; side by side on wide screens. "Show page" turns it off.
- Ayat tab (the page's ayahs one by one, large) and Tafsir tab (each ayah followed by its tafsir, with a font-size button); tapping an ayah in either plays it.
- Khatma tracker: start a khatma, pages read are marked after 4 s on a page, progress and "continue".
- Integration build: this release merges the new home page, the Quran index and the Mushaf reader (branch integration/reader-home-index).

## [Unreleased] — New home page (owner's mockup) — 2026-11-09
### Changed
- Home page redesigned on the website and the mobile app after the owner's mockup: place ("Egypt - Cairo") with a settings button; mosque drawing; next prayer name, its time in large digits and a live countdown; a day card with the weekday, Gregorian and Hijri dates, a "Prayer calendar" button, the five prayers with icons (next one highlighted) and sunrise / sunset; big tiles for the Quran, Adhkar & Dua and Prayer times; wide tiles for Tasbih, Qibla, Islamic reels and Prophets' stories; "Main sections" opens the full list.
- Sunset is shown without the user's Maghrib adjustment. After Isha the card shows tomorrow's day and times.
- "Continue reading" moved off the home page: it stays on the Quran page (web) and the Bookmarks screen (mobile). Hajj, Hisn al-Muslim, search and bookmarks are under "Main sections".
### Added
- Quran radio on the home page: continuous recitation of the whole Mushaf by the chosen reciter, starting from a random surah and wrapping round, with a play duration (unlimited, 15, 30, 45 or 60 minutes) that stops it through the sleep timer. Streams per ayah from everyayah.com, like the rest of the recitation.

## [Unreleased] — Quran index: surahs and quarters — 2026-11-09
### Added
- New Quran index ("فهرس السور") on the Quran tab (mobile) and /quran (web): a Surahs / Quarters toggle, a search box with a clear button, and lists grouped under juz headers (الجزء الأول، الثاني …).
- Surahs: star badge with the number, "سورة …", and "الصفحة X - آياتها N - مكية/مدنية". Tapping opens the Mushaf at that page; a small list icon still opens the text (list) view.
- Quarters: the 240 hizb quarters with badge 1, 1/4, 2/4, 3/4, 2 …, the opening words of the quarter in Uthmani script (taken unchanged from the canonical text), and "سورة X: ayah - الصفحة N".
- The surah and quarter of the current position are highlighted, and the list opens scrolled to them. Mobile also has `showQuranIndexSheet()` (bottom sheet returning the chosen page) for the Mushaf reader.
- Data: `pages.v1.json` now carries `quarters` (start ayah, page, juz, hizb). Starts come from npm quran-meta@7.0.0 (MIT, Tanzil metadata) and are checked against the rub' al-hizb sign ۞ in the KFGQPC text; where they differ the Mushaf wins (15:49 instead of Tanzil's 15:50).

## [Unreleased] — New home page (owner's mockup) — 2026-11-09
### Changed
- Home page redesigned on the website and the mobile app after the owner's mockup: place ("Egypt - Cairo") with a settings button; mosque drawing; next prayer name, its time in large digits and a live countdown; a day card with the weekday, Gregorian and Hijri dates, a "Prayer calendar" button, the five prayers with icons (next one highlighted) and sunrise / sunset; big tiles for the Quran, Adhkar & Dua and Prayer times; wide tiles for Tasbih, Qibla, Islamic reels and Prophets' stories; "Main sections" opens the full list.
- Sunset is shown without the user's Maghrib adjustment. After Isha the card shows tomorrow's day and times.
- "Continue reading" moved off the home page: it stays on the Quran page (web) and the Bookmarks screen (mobile). Hajj, Hisn al-Muslim, search and bookmarks are under "Main sections".
### Added
- Quran radio on the home page: continuous recitation of the whole Mushaf by the chosen reciter, starting from a random surah and wrapping round, with a play duration (unlimited, 15, 30, 45 or 60 minutes) that stops it through the sleep timer. Streams per ayah from everyayah.com, like the rest of the recitation.

## [Unreleased] — More Quran reciters — 2026-11-09
### Changed
- Reciters list (packages/shared-schemas/audio/reciters.json, mirrored to the mobile app) now has the 13 the owner picked, all per-ayah from everyayah.com: Alafasy (default), Yasser Al-Dosari, As-Sudais, Maher Al-Muaiqly (now 128 kbps), Al-Minshawy murattal and mujawwad, Al-Husary murattal, mujawwad and teaching, Abdul Basit murattal and mujawwad, Al-Tablawi, Mahmoud Ali Al-Banna (32 kbps, the only rate available).
- Removed "Al-Minshawy (teaching)": its folder is not listed on everyayah.com/recitations_ayat.html. A saved choice that is no longer listed falls back to the default reciter.

## [Unreleased] — Adhan alerts with the adhan voice — 2026-11-09
### Added
- Mobile: prayer-time notifications now play the adhan recording (Android: the full adhan through its own notification channel, with a "Stop adhan" action; iOS: the opening takbir, as iOS allows at most 30 s). Sound choice: adhan / phone tone / silent.
- Mobile: "Listen to the adhan" and "Test the alert (in 10 seconds)" buttons in Settings; a banner on the Prayer screen to turn alerts on, and a bell next to each of the five prayers to switch it on or off.
- Mobile: Android schedules 30 days ahead (iOS stays at 7 days / 60 notifications), so alerts keep coming even if the app is not opened for a while.
- Web: "Adhan alert" card on the prayer page (on/off, per prayer, sound). While any page of the site is open it shows a notification, plays the adhan and shows a banner with "Stop adhan"; if the browser blocks autoplay the banner offers a play button. A prayer missed while the computer slept (over 5 min late) does not ring.
- Audio: "Beautiful adhan" (Wikimedia Commons, CC0) — see apps/mobile/assets/audio/ADHAN_AUDIO.md. Pending religious review (listen-through) before a store release.

## [Unreleased] — Quranic stories (audio) — 2026-11-08
### Added
- Quranic stories on Android, iOS and the web (`/stories`), from Home and More: listen or read. See docs/STORIES.md.
- Sheikh Nabil al-Awadi's "Stories of the Prophets" (19 audio episodes, streamed from archive.org; non-commercial licence notice). Users hear only episodes a named reviewer approved; reviewer mode lists pending ones with a banner. Resume per episode, ±30 s (mobile).
- 25 verse stories: each story's Quranic verse ranges (Mushaf text) recited in order with the chosen reciter and highlighted as they play, Tafsir al-Muyassar per ayah. No text written by us (validator rejects summaries).
- Sleep timer (15/30/45/60 min) that stops the recitation and the episode.
- `tools/stories.py` (list / approve / reject / build, per episode or `--episode all`), build step in `tools/build_content.py`, API `GET /v1/stories`.

## [Unreleased] — Islamic reels — 2026-11-08
### Added
- Islamic reels: a vertical, swipeable short-video feed on Android, iOS and the web (`/reels`), reachable from Home and More.
- Source: curated YouTube links only (Instagram not enabled yet), played with YouTube's official privacy-enhanced embed; no video is downloaded, re-hosted or stored, so there is no hosting cost.
- Content policy: two categories only, "humble Quran recitation" and "short religious lesson per the Quran and Sunnah".
- Religious review gate: each reel is `pending`, `approved` (reviewer + date required) or `rejected` (reason required). Users see approved reels only; "reviewer mode" shows pending ones with a red "not reviewed" banner.
- `tools/reels.py` (add / approve / reject / list / build), build step in `tools/build_content.py`, API `GET /v1/reels`.
- Only the reel in view has a live player; the others show the poster image.

## [0.1.0] — Milestone 1 — 2026-11-06
### Added
- Monorepo layout (apps, services, packages, content, tests, docs, infrastructure).
- Shared content pipeline: pristine Quran text from `quran-json@3.1.2` (QuranEnc/KFGQPC Uthmani), Madinah 1405H page map (604 pages), SHA-256 integrity manifest.
- Shared rules: prayer methods, cities, Arabic search normalisation, display-only glyph map, AR/EN strings, design tokens (CSS + Dart generated).
- Independent prayer reference vectors (38 cases, adhan-js 4.4.6) and Quran reference counts.
- FastAPI backend: Quran, pages, search, prayer times, qibla, auth (Argon2id + JWT), bookmarks and settings sync (LWW + tombstones), rate limiting, security headers, Alembic migration 0001, OpenAPI contract with drift check.
- Flutter app (Android + iOS): Quran surah list/reader, Madinah page reader, search, bookmarks, continue reading, prayer times with adjustments and qibla, AR/EN, themes, optional account sync, About.
- Next.js static PWA with the same features plus browser geolocation and full offline precache.
- CI: content, backend, web (3 browsers + axe), Android (APK + emulator), iOS (simulator build + integration test), Semgrep, gitleaks, dependency audits, Dependabot.
### Fixed during milestone (see reports/BUG_REPORT.md)
- DEF-001 basmala line missing in mobile readers.
- DEF-002 API contract ambiguity for bookmark PUT body.
- DEF-003 `timezone` package link zones (Asia/Kuwait) missing.
- DEF-004 outdated backend dependencies with known CVEs.
- DEF-005 Android emulator integration test tapped before the keyboard settled.
- DEF-006 WebKit offline e2e: Playwright setOffline + service worker.
- DEF-007 Semgrep: mutable action tags, Dependabot without cooldown.
- DEF-008 leftover snackbar covered the Mushaf page reader's Go button on small Android screens.
- DEF-009 web inputs lost if used before hydration (tests now wait; marker added).
- DEF-010 postcss advisories via Next 15 (npm override).
- DEF-011 CI device-test hangs (portable time limit).
### Changed vs the Rattil prototype
- The stored Quran text no longer contains the font-workaround code points; the substitution is display-only.
