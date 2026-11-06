# Software Requirements Specification — Islamic Super App (Rattil)

Version 0.1.0 · Milestone 1 · 2026-11-06 · Owner: mostafa amin

## 1. Purpose and scope
A completely free Islamic ecosystem (Android, iOS, Web/PWA, backend) for reading the Holy Quran from the Madinah Mushaf, prayer times and qibla, with later milestones for adhkar, Hajj/Umrah, learning, recitation feedback and an Islamic AI assistant.

### 1.1 Non-negotiable policies
- **POL-1 Free**: no subscriptions, ads, in-app purchases, premium tiers, paid AI credits or payment gateways. Any unavoidable cost needs explicit owner approval before activation.
- **POL-2 Quran integrity**: Quran text comes only from the approved source (Madinah Mushaf / KFGQPC Uthmani text via QuranEnc, Hafs, 6236 ayahs) and is never altered, generated or "corrected" by AI.
- **POL-3 Parity**: every milestone ships Android, iOS and Web together; a feature is complete only when it passes on all three (or a documented limitation exists).
- **POL-4 Evidence**: no feature is reported done without executed tests and saved evidence.
- **POL-5 Religious review**: religious rulings and guidance require review by qualified humans; approval is tracked as pending until done.

## 2. Platforms
| ID | Platform | Tech | Min version |
|---|---|---|---|
| PL-AND | Android | Flutter 3.41.6 | Android 7.0 (API 24) |
| PL-IOS | iOS | Flutter 3.41.6 | iOS 13 |
| PL-WEB | Web/PWA | Next.js static export + service worker | last 2 versions of Chrome, Safari, Firefox, Edge |
| PL-API | Backend | FastAPI, Python 3.13 | — |

## 3. Milestone 1 functional requirements
Each requirement has acceptance criteria (AC). Test IDs are listed in `docs/reports/TEST_MATRIX.csv`.

### F-QURAN-01 Surah index
AC: lists 114 surahs in order with Arabic name, English name, ayah count, Meccan/Medinan; a filter box narrows the list by Arabic or Latin name/number; selecting one opens the reader.

### F-QURAN-02 Surah reader
AC: shows every ayah of the surah exactly as stored, with ayah numbers (Arabic-Indic in Arabic UI); optional English translation toggle that persists; font size 18–40 applies immediately and persists.

### F-QURAN-03 Madinah Mushaf page reader
AC: pages 1–604 follow KFGQPC 1405H boundaries (e.g. p1 = 1:1–7, p2 = 2:1–5, p50 starts 3:1, p604 = 112:1–114:6); previous/next controls and swipe/keyboard; go-to-page accepts only 1–604 and rejects other input with a message; header shows page and juz.

### F-QURAN-04 Search
AC: diacritic-insensitive Arabic search per `search-normalization.json`; results show the original text and open the ayah; fewer than 2 letters shows guidance, no results shows "No results".

### F-QURAN-05 Bookmarks & continue reading
AC: add/remove a bookmark from the reader; bookmarks list opens the ayah; data persists across restarts; last read position is offered as "continue reading".

### F-QURAN-06 Integrity
AC: 114 surahs, 6236 ayahs, per-surah counts equal the independent reference, SHA-256 of all ayahs and of each surah equal `integrity.v1.json`, upstream file hash pinned; verified by tests on API, Android/iOS (Dart) and Web.

### F-PRAYER-01 Prayer times
AC: for the selected city (or browser location on Web), method and Asr school, shows Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha in the city's time zone; results agree with the independent reference vectors within 2 minutes in all 38 cases (10 methods, 19 cities, DST transitions in 5 zones, high latitudes, southern hemisphere); polar day/night handled with a message.

### F-PRAYER-02 Manual adjustments
AC: per-prayer offset −30…+30 minutes, persisted, applied to display.

### F-PRAYER-03 Next prayer
AC: shows the next prayer name and a live countdown; after Isha the next is tomorrow's Fajr.

### F-PRAYER-04 Qibla bearing
AC: bearing in degrees from true north within 0.5° of reference for 6 cities; shown as text and on a static compass. (Live compass with sensors: Milestone 2.)

### F-I18N-01 Localization
AC: Arabic (RTL, default) and English (LTR) for every screen; switch persists; layout direction flips correctly.

### F-UI-01 Design system & theming
AC: colours/typography from `design-tokens`; light, dark, system themes; minimum touch target 48 px; text contrast passes WCAG AA checks used in tests.

### F-SYNC-01 Account & sync (optional)
AC: register/login; "sync now" pushes local bookmark changes and pulls server changes; last-write-wins by `updatedAt`; deletions propagate as tombstones; one user cannot read or change another user's data; offline sync shows an error and keeps local data.

### F-ABOUT-01 About & free policy
AC: states the app is free with no ads/subscriptions/purchases and lists content sources and licences.

### F-API-01 Backend API
AC: endpoints in `packages/api-contracts/API.md`; input validation (422), auth (401), not found (404), rate limiting (429), security headers, CORS allow-list; OpenAPI contract has no drift; migrations upgrade/downgrade cleanly.

## 4. Non-functional requirements
- **NFR-OFF** Offline: after first install/load, F-QURAN-01…05 and F-PRAYER-01…04 work without network.
- **NFR-A11Y** Accessibility: semantic labels on all controls; Web: zero serious/critical axe violations on main pages; Flutter: tap-target, labelled-tap-target and text-contrast guidelines pass.
- **NFR-SEC** Security: Argon2id passwords, signed expiring tokens, no secrets in repo, dependency audit with no known vulnerabilities at release, Semgrep and secret scanning in CI.
- **NFR-PERF** Performance: surah page interactive < 2.5 s on a mid-range phone profile (Lighthouse mobile); API p95 < 100 ms for content endpoints on the reference container.
- **NFR-PRIV** Privacy: no analytics or trackers; location stays on device; the account stores only email, password hash, settings and bookmarks.

## 5. Out of scope for Milestone 1 (tracked for later milestones)
Audio recitation, adhan notifications, live compass, adhkar & Hisn al-Muslim, Hajj/Umrah guide, tafsir, Hadith, memorisation & speech recognition, Islamic AI assistant, admin dashboard. None of these are shown in the M1 apps as working features.
