# Changelog

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
