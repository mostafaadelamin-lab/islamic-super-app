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
| `content/quran/dist/mushaf-lines.v1.json`                                             | `public/data/mushaf-lines.json` (15-line layout, fetched once by the Mushaf reader)       |
| `packages/shared-schemas/audio/reciters.json`                                         | `src/generated/reciters.json`                                                             |
| `content/adhkar/dist/adhkar.v1.json`, `content/adhkar/hisn.json`                      | `src/generated/` (rendered at build time)                                                 |
| `content/pilgrimage/source-hajj.js`                                                   | `src/generated/hajj.json` (data constants evaluated in an empty VM context)               |

These generated paths are git-ignored. Surah and Mushaf-page routes read `quran.v1.json` **at build time**
and inline only that route's ayahs; the 2.2 MB file is never shipped to the browser as a whole (the search
page lazily loads the 1.3 MB Arabic-only index).

## Routes

`/` redirects to the saved language (default `/ar/`). Every page exists as `/ar/…` (RTL) and `/en/…` (LTR):
home, `quran/` (114-surah index with filter + go-to-page), `surah/1…114/` (list view with translation),
`page/1…604/` (the 15-line Madinah Mushaf), `search/`, `bookmarks/`, `prayer/`, `settings/`, `about/`, and
since Milestone 2 `more/`, `adhkar/`, `hisn/` + `hisn/1…134/`, `tasbih/`, `qibla/`, `hajj/`.

Navigation: five tabs — Home / Quran / Prayer / Adhkar / More — in the top bar on wide screens and as a
bottom tab bar on phone widths (≤ 720 px).

## Features

- ar/en UI from `packages/shared-schemas/i18n` plus web-only strings in `src/i18n/web.{ar,en}.json`;
  language switch keeps the current page and is persisted.
- Theme light / dark / system (design tokens), Quran font size 18–40 (tokens) — persisted in `localStorage`
  (every access wrapped in try/catch; the app works with storage blocked).
- Surah reader: Arabic-Indic ayah numbers in Arabic (U+06DD + digits), optional English translation
  (fetched per surah), bookmarks, last-read position (IntersectionObserver), previous/next surah.
- Mushaf (`page/N/`): each page is drawn from `mushaf-lines.v1.json` with Amiri Quran — surah title bands,
  basmala lines, 15 lines justified edge to edge (8 centred lines on pages 1–2), ayah-end markers with
  Arabic-Indic digits, paper background and gold frame. The font size is measured so the widest line exactly
  fills the frame (and the page fits the screen height on wide screens). The route's page is rendered at
  build time; the reader then fetches the line layout and the Arabic text once (cached by the service worker)
  and turns pages on the device: swipe/drag like a book (Arabic: drag right = next), arrow keys, buttons, page
  slider, go-to-page. Last page is remembered. Tapping an ayah selects it: play from here, bookmark, copy
  (canonical text). Surah list and search results open the Mushaf at the right page (`#a-S-A` selects).
- Recitation (online only): player bar with play/pause, stop, next/previous ayah, reciter (8, saved in
  Settings) and repeat count. Plays the page, the surah or from an ayah to the end of the surah; the basmala
  (001001) is played before ayah 1 of every surah except 1 and 9; the reader highlights the recited ayah and
  turns the page as the recitation crosses it. Per-ayah MP3s stream from everyayah.com (`reciters.json`);
  offline and network failures are shown in the player.
- Home: next prayer with a live countdown, today's five prayers + sunrise, Hijri (Umm al-Qura via `Intl`) and
  Gregorian dates, city, continue reading, section tiles.
- Adhkar: morning/evening lists with a counter per item (counts as annotated in Hisn al-Muslim; mapping in
  `src/data/adhkar-sessions.json`), daily progress kept on the device. Hisn al-Muslim: 134 chapters with a
  filter. Tasbih: counter with targets 33/99/100/1000, rounds, undo, reset (persisted). Qibla: live compass
  from `DeviceOrientation` (`deviceorientationabsolute`, iOS `webkitCompassHeading` after
  `requestPermission()`), falling back to the static bearing compass. Hajj & Umrah guide from the prototype
  text with a visible "pending religious review" notice and Tawaf/Sa'i/Jamarat round counters.
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
  shell (all routes except surah, Mushaf-page and Hisn-chapter pages, of both languages, JS/CSS, fonts, JSON
  data including `mushaf-lines.json`); after activation the worker precaches every surah, Mushaf page and
  Hisn chapter of the language being used and reports progress (Settings → Offline availability). Audio is
  cross-origin and never cached.

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
  coordinates). The live Qibla compass needs a magnetometer and a browser that exposes an absolute heading.
- Recitation needs an internet connection (streamed from everyayah.com). The container used for development
  blocks that host, so real-audio playback is only exercised in CI/on devices; e2e tests answer audio
  requests with a local silent MP3 and say "mocked network" in their names.
- Fonts are shipped as TTF (no WOFF2 subsetting); UI fonts use `font-display: optional` to avoid layout
  shift, so a first visit on a slow connection may show the system font.
- The Mushaf follows the printed Madinah line breaks, but is drawn with the Amiri Quran font (not the KFGQPC
  page fonts), so letter shapes and spacing differ from the print; Chrome justifies by widening spaces
  (no kashida).
- Only Chromium is available in this environment; Firefox/WebKit were not tested.
- Only bookmarks sync; `/v1/me/settings` sync is not wired yet.
