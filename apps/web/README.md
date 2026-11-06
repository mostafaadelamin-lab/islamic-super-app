# Rattil — Web / PWA (`apps/web`)

Next.js 15 (App Router, TypeScript strict) exported as a fully static site (`output: "export"`) with a
hand-written service worker, so the whole app works offline after the first visit. Free forever: no ads,
subscriptions, purchases or tracking.

## Run

```bash
npm ci
npm run dev        # http://localhost:3000 (no service worker in dev)
npm run build      # prepares content, `next build` -> out/, then writes out/sw.js
npm run serve      # serves out/ on http://127.0.0.1:4173 (gzip, trailing-slash dirs, 404.html)
```

`npm run content` (run automatically by dev/build/test/typecheck) copies the shared sources into the app:

| Source (read-only)                                                                    | Copied to                                                                                 |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `packages/shared-schemas/*` (methods, cities, i18n, render map, search normalisation) | `src/generated/`                                                                          |
| `packages/design-tokens/dist/tokens.{css,ts}`                                         | `src/generated/` (all colours/sizes come from these)                                      |
| `content/fonts/*.ttf` + OFL licences                                                  | `public/fonts/` (self-hosted, no CDN)                                                     |
| `content/quran/dist/quran.v1.json`                                                    | `public/data/en/<n>.json` (translation per surah), `public/data/quran-text.json` (search) |

These generated paths are git-ignored. Surah and Mushaf-page routes read `quran.v1.json` **at build time**
and inline only that route's ayahs; the 2.2 MB file is never shipped to the browser as a whole (the search
page lazily loads the 1.3 MB Arabic-only index).

## Routes

`/` redirects to the saved language (default `/ar/`). Every page exists as `/ar/…` (RTL) and `/en/…` (LTR):
home, `quran/` (114-surah index with filter + go-to-page), `surah/1…114/`, `page/1…604/` (Madinah 1405H
boundaries from `pages.v1.json`), `search/`, `bookmarks/`, `prayer/`, `settings/`, `about/`.

## Features

- ar/en UI from `packages/shared-schemas/i18n` plus web-only strings in `src/i18n/web.{ar,en}.json`;
  language switch keeps the current page and is persisted.
- Theme light / dark / system (design tokens), Quran font size 18–40 (tokens) — persisted in `localStorage`
  (every access wrapped in try/catch; the app works with storage blocked).
- Surah reader: Arabic-Indic ayah numbers in Arabic (U+06DD + digits), optional English translation
  (fetched per surah), bookmarks, last-read position (IntersectionObserver), previous/next surah.
- Mushaf page reader: page/juz header, previous/next, arrow keys (RTL: ← = next), go-to-page with
  validation (accepts Arabic-Indic digits).
- Search: diacritic-insensitive per `search-normalization.json`; results show the original text.
- `quran-render.json` is applied **only** to strings handed to the renderer (`renderQuranText`); stored,
  searched, synced and hashed text is never altered.
- Prayer: TypeScript port of `services/api/app/domain/prayer.py` (`src/lib/prayer.ts`), city picker,
  "use my location" (denial/timeout handled; the device time zone is used), method & Asr school,
  per-prayer adjustment −30..+30, today's six times in the location's IANA zone (Intl), next-prayer
  countdown, high-latitude note, Qibla bearing + static compass.
- Account & sync (optional, Settings): configurable API base URL (default `http://127.0.0.1:8000`),
  register / sign in / sign out, "Sync now" for bookmarks — pull `since`, last-write-wins on `updatedAt`
  (server wins ties), tombstones (`deleted: true`), then push dirty items. Offline, network and CORS
  failures and HTTP errors are shown in the page.
- PWA: `manifest.webmanifest`, `out/sw.js` generated from `scripts/sw-template.js`. Install precaches the
  shell (all non-surah/page routes of both languages, JS/CSS, fonts, JSON data); after activation the worker
  precaches every surah and Mushaf page of the language being used and reports progress (Settings →
  Offline availability).

## Test

```bash
npm run lint && npm run format:check && npm run typecheck
npm test                # Vitest unit + React Testing Library component tests
npm run test:coverage   # coverage for src/lib (report in tests/evidence/web/coverage)
npm run build && API_PYTHON=/path/to/venv/bin/python npm run test:e2e
npm run serve & npm run lighthouse
```

- `test:e2e` serves `out/` itself. With `API_PYTHON` set (a Python with `services/api/requirements.txt`
  installed) it also starts the FastAPI backend on :8000 with a throw-away SQLite DB (`API_DB`, default
  `/tmp/rattil-e2e.db`) and relaxed rate limits; without it the real-backend sync test is skipped.
- `E2E_BROWSERS=chromium,firefox,webkit` selects browsers (only Chromium is installed in CI here).
- Reports (JUnit/JSON, axe, Lighthouse, coverage, screenshots, functionality inventory) are written to
  `tests/evidence/web/`.
- `scripts/make-icons.mjs` re-renders `public/icon-{192,512}.png` from `public/icon.svg`.

## Limitations

- Offline precache of the reader routes is per language (~26 MB uncompressed, ~1440 files); switching
  language starts a second background download. The first offline-ready moment is therefore some time
  after the first visit, not instant.
- "Use my location" uses the device time zone for the computed times (no offline tz lookup by
  coordinates); the Qibla compass is static (no device-orientation sensor).
- Fonts are shipped as TTF (no WOFF2 subsetting); UI fonts use `font-display: optional` to avoid layout
  shift, so a first visit on a slow connection may show the system font.
- The Mushaf view uses the Madinah page boundaries but flows text with Amiri Quran; it is not a
  line-by-line facsimile of the printed page.
- Only Chromium is available in this environment; Firefox/WebKit were not tested.
- Only bookmarks sync; `/v1/me/settings` sync is not wired yet.
