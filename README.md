# Islamic Super App — Rattil (رتّل)

A completely free Islamic ecosystem — **Android, iOS and Web built together** — with no ads, subscriptions or purchases.

Milestone 1: Holy Quran (Madinah Mushaf text, 604-page reader, search, bookmarks) and prayer times/qibla, in Arabic and English, offline-first, with optional account sync.

| Part | Path | Run tests |
|---|---|---|
| Flutter app (Android + iOS) | `apps/mobile` | `flutter test` (Flutter 3.41.6) |
| Web app / PWA (Next.js) | `apps/web` | `npm ci && npm test && npm run build && npm run test:e2e` |
| API (FastAPI) | `services/api` | `pip install -r requirements-dev.txt && pytest` |
| Content build + integrity | `tools/build_content.py` | `python tools/build_content.py` |

Status: Milestone 1 — all CI gates green (Android emulator, iOS simulator, 3 browsers, backend, security). See [release readiness](docs/reports/RELEASE_READINESS_REPORT.md).

Docs: [SRS](docs/SRS.md) · [Architecture](docs/ARCHITECTURE.md) · [Content sources](docs/CONTENT_SOURCES.md) · [Reports](docs/reports/).

The Quran text is taken unchanged from the approved source and is verified with SHA-256 hashes on every platform.
