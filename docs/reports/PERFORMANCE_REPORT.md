# Performance report — Milestone 1

## Backend API (measured)
Environment: development container, 4 vCPU, Python 3.13.18, uvicorn single worker, SQLite; 200 sequential requests per endpoint over loopback after one warm-up. Raw data: `tests/evidence/backend/perf.json`.

| Endpoint | p50 ms | p95 ms | max ms | response bytes |
|---|---|---|---|---|
| /health | 1.14 | 1.64 | 5.46 | 33 |
| /v1/quran/surahs | 2.15 | 2.56 | 3.16 | 13,301 |
| /v1/quran/surahs/2 | 2.88 | 4.60 | 28.72 | 111,515 |
| /v1/quran/pages/300 | 1.28 | 1.56 | 2.90 | 2,524 |
| /v1/quran/search?q=الرحمن | 2.24 | 3.11 | 4.52 | 4,542 |
| /v1/prayer/times | 1.39 | 1.64 | 1.91 | 383 |

Target NFR-PERF (content endpoints p95 < 100 ms): **PASS** under these conditions. No concurrency/load test yet (NOT TESTED).

## Web (Lighthouse, measured locally on the static export, Chromium headless)
| Page | Form factor | Perf | A11y | Best practices | SEO | FCP | LCP | TBT | CLS |
|---|---|---|---|---|---|---|---|---|---|
| /ar/ | mobile | 97 | 100 | 100 | 100 | 0.8 s | 0.8 s | 190 ms | 0.034 |
| /ar/surah/18/ | mobile | 98 | 100 | 100 | 100 | 0.9 s | 0.9 s | 170 ms | 0 |
| /ar/ | desktop | 99 | 100 | 100 | 100 | | | | 0.08 |
| /ar/surah/18/ | desktop | 100 | 100 | 100 | 100 | | | | |
Raw: `tests/evidence/web/lighthouse/`. Surah route JS 2.76 kB, first-load JS 128 kB; surah 18 HTML 21.8 kB gzipped. Lighthouse runs against localhost, so network latency is simulated, not real.

## Mobile
Debug APK built in CI (artifact `android-debug-apk`). Startup time, memory and frame timing on a real device: **NOT TESTED** (no physical device; emulator timings in CI are not representative). Planned: `flutter drive --profile` with timeline summary in CI.
