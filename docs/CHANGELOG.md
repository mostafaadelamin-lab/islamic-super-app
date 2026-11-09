# Changelog

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

## [Unreleased] — Quran index: surahs and quarters — 2026-11-09
### Added
- New Quran index ("فهرس السور") on the Quran tab (mobile) and /quran (web): a Surahs / Quarters toggle, a search box with a clear button, and lists grouped under juz headers (الجزء الأول، الثاني …).
- Surahs: star badge with the number, "سورة …", and "الصفحة X - آياتها N - مكية/مدنية". Tapping opens the Mushaf at that page; a small list icon still opens the text (list) view.
- Quarters: the 240 hizb quarters with badge 1, 1/4, 2/4, 3/4, 2 …, the opening words of the quarter in Uthmani script (taken unchanged from the canonical text), and "سورة X: ayah - الصفحة N".
- The surah and quarter of the current position are highlighted, and the list opens scrolled to them. Mobile also has `showQuranIndexSheet()` (bottom sheet returning the chosen page) for the Mushaf reader.
- Data: `pages.v1.json` now carries `quarters` (start ayah, page, juz, hizb). Starts come from npm quran-meta@7.0.0 (MIT, Tanzil metadata) and are checked against the rub' al-hizb sign ۞ in the KFGQPC text; where they differ the Mushaf wins (15:49 instead of Tanzil's 15:50).

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
