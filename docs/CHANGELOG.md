# Changelog

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
