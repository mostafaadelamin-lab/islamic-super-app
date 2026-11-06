# Architecture — Islamic Super App (Rattil)

Version 0.1.0 · Milestone 1 · 2026-11-06

## 1. Principles
1. **One product, three first-class clients**: Android and iOS (one Flutter codebase) and Web/PWA (Next.js) are built in the same milestone against the same contracts.
2. **Offline-first**: the Quran, Madinah page map, prayer methods and calculation ship *inside* every client. The backend adds accounts and sync; nothing religious depends on network access.
3. **Single sources of truth** in `packages/` and `content/`; every client consumes them, nothing is hand-copied.
4. **Quran text is immutable**: pinned upstream file → deterministic bundle → SHA-256 manifest → verified by tests on every platform.
5. **Free forever**: no ads, payments, subscriptions, paid APIs or trackers. Only open-source dependencies.

## 2. Repository layout
```
apps/mobile        Flutter 3.41.6 (Android + iOS), Dart
apps/web           Next.js static export + service worker (PWA), TypeScript
apps/admin         NOT STARTED
services/api       FastAPI + SQLAlchemy 2 + Alembic (SQLite dev, PostgreSQL-compatible schema)
services/islamic-ai, services/speech   NOT STARTED
packages/api-contracts   API.md + generated openapi.json (CI drift check)
packages/shared-schemas  prayer/methods.json, cities.json, i18n/{ar,en}.json, quran-render.json, search-normalization.json
packages/design-tokens   tokens.json → dist/tokens.css, tokens.ts, design_tokens.dart
content/                 quran (upstream + dist), translations, adhkar, fonts, pilgrimage (source only)
tests/vectors            cross-platform reference data (prayer times from adhan-js, Quran reference counts)
tests/evidence           raw test outputs, screenshots, coverage, security scans
tools/                   build_content.py, vectors/gen.mjs
docs/                    SRS, architecture, changelog, reports
```

## 3. Shared business rules
| Rule | Source of truth | Python (API) | Dart (mobile) | TypeScript (web) |
|---|---|---|---|---|
| Prayer methods, angles, dhuhr offset, high-latitude rule | `packages/shared-schemas/prayer/methods.json` | `app/domain/prayer.py` (reference) | ported | ported |
| Prayer-time correctness | `tests/vectors/prayer-times.json` (38 cases, independent adhan-js 4.4.6, ±2 min) | pytest | flutter_test | vitest |
| Quran text + hashes | `content/quran/dist/*.v1.json` | pytest | flutter_test | vitest |
| Arabic search normalisation | `search-normalization.json` (+ vectors) | `domain/quran.py` | ported | ported |
| Display glyph map (font workaround) | `quran-render.json` | n/a (API serves canonical text) | render only | render only |
| UI strings | `i18n/ar.json`, `i18n/en.json` | n/a | → ARB (gen-l10n) | JSON |
| Visual design | `design-tokens/tokens.json` | n/a | generated Dart | generated CSS |

### Prayer algorithm
Low-precision solar coordinates (Meeus / USNO), hour-angle for Fajr/Isha angles and sunrise/sunset at −0.833°, Asr shadow factor 1 or 2, two refinement iterations, Isha as fixed interval for Umm al-Qura/Qatar, "twilight angle" high-latitude rule (fraction angle/60 of the night), +1 min Dhuhr, rounding to the nearest minute. Times are computed in UTC and converted with the platform's IANA tz database, so DST is handled by tzdata, not by the algorithm. Polar day/night returns a clear error.

### Quran content pipeline
`content/quran/upstream/quran-json-3.1.2.quran.json` (npm tarball shasum verified against the registry) → `tools/build_content.py` → `quran.v1.json`, `pages.v1.json` (604 Madinah 1405H pages derived from the KFGQPC page manifest used by quran-madina-html), `integrity.v1.json` (overall and per-surah SHA-256). The build refuses to emit output if counts differ from the independent reference or pages have gaps/overlaps.

## 4. Backend
- FastAPI app factory `create_app(Settings)`; state holds DB, Quran store, rate limiter.
- Auth: email + password (Argon2id), JWT HS256 access tokens (30 days), `alg=none` and foreign-secret tokens rejected.
- Sync: per-record last-write-wins on client `updatedAt` (ms), tombstones for deletes, delta pull by server sequence time (`since`).
- Rate limiting: in-process sliding window (auth 10/min, general 120/min per IP). **Limitation**: multi-instance deployment needs a shared store (Redis) — not in M1.
- Security headers, strict CORS allow-list, request validation via Pydantic (extra fields forbidden).

### Database schema (Alembic `0001`)
| table | columns |
|---|---|
| users | id PK, email unique, password_hash, created_at |
| user_settings | user_id PK/FK→users (cascade), data JSON text ≤8 KB, updated_at_ms |
| bookmarks | id PK, user_id FK (cascade), client_id (unique per user), surah, ayah, note ≤500, deleted, updated_at_ms, server_seq_ms |

Quran content is not stored in the database in M1: it is versioned, read-only and identical on every node, so it is loaded from the content bundle.

## 5. Clients
Both clients: ar (RTL, default) / en (LTR), light/dark/system theme from tokens, Quran surah list → reader, Madinah page reader 1–604, search, bookmarks + continue reading, prayer times with city/method/Asr/adjustments, next-prayer countdown, qibla bearing, optional account + bookmark sync, About (free policy + sources). See each app's README for structure.

## 6. CI/CD (`.github/workflows/ci.yml`)
content → backend → web (Chromium/Firefox/WebKit e2e, axe) · mobile-android (analyze, test, APK, emulator integration tests) · mobile-ios (macOS: simulator build + integration tests) · Semgrep · gitleaks · pip-audit/npm audit · Dependabot. **No deploy job**: production requires explicit owner approval.

## 7. Known limitations (Milestone 1)
- iOS: no macOS in the development container; iOS is built and tested only by the CI macOS job.
- Android emulator tests run only in CI (no KVM in the container).
- Mushaf page reader shows the exact ayahs of each Madinah page, but not the printed line-by-line calligraphic layout (planned: KFGQPC page fonts).
- Amiri Quran font needs the display glyph map for open tanween; bundling the KFGQPC HAFS font removes it.
- Adhan notifications, audio recitation, adhkar, Hajj guide, AI and speech are not in M1.
