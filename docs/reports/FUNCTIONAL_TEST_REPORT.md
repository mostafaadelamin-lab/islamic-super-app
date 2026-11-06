# Functional test report — Milestone 1

Version 0.1.0 · final CI run [42305310075](https://github.com/mostafaadelamin-lab/islamic-super-app/actions/runs/42305310075) on commit e986194 · 2026-11-06

## Summary
| Item | Value |
|---|---|
| Implemented functions (M1) | 29 (rows of `TEST_MATRIX.csv` excluding the 7 not-implemented rows) |
| Functions with test cases | 29 / 29 |
| Functions with an executed, passing acceptance test on Web | 28 / 28 applicable |
| Functions with executed, passing tests in the shared Flutter suite (run on Linux and on macOS) | 27 / 27 applicable |
| Functions exercised end-to-end on a real **Android emulator** and **iOS simulator** | 5 (open surah, bookmark, bookmarks list, go to page, change city) |
| Failed tests in the final run | 0 |
| Blocked tests | 0 in CI. Locally blocked: Android emulator (no KVM), iOS (no macOS) — both run in CI instead |
| Untested implemented functions | 0. Not implemented (NOT TESTED): live compass, settings sync in clients, audio, adhkar, Hajj guide, notifications, AI |
| Open defects | 0 critical, 0 major; limitations LIM-01…08 in BUG_REPORT.md |

## Executed tests (final run unless noted)
| Suite | Platform / environment | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|---|
| pytest (unit, API, DB, auth, security, migrations) | Ubuntu, Python 3.13 | 128 | 128 | 0 | 0 |
| Flutter unit + widget + golden-screenshot | Ubuntu (Android job) | 274 | 274 | 0 | 0 |
| Flutter unit + widget + golden-screenshot | macOS 15 arm64 (iOS job) | 274 | 274 | 0 | 0 |
| Flutter integration_test (device flow) | Android emulator API 34 x86_64 | 1 flow (11 assertions) | 1 | 0 | 0 |
| Flutter integration_test (device flow) | iOS simulator (iPhone, macOS 15 runner) | 1 flow | 1 | 0 | 0 |
| Vitest unit + React Testing Library | Ubuntu, Node 22 | 250 | 250 | 0 | 0 |
| Playwright e2e (inventory, features, responsive, offline, a11y, sync vs real API) | Chromium, Firefox, WebKit | 294 (98 × 3) | 294 | 0 | 0 |
| Content integrity build | Ubuntu | 1 build, all checks | pass | 0 | 0 |
| Semgrep | repo | 553 rules | 0 findings | | |
| gitleaks | full history | | 0 leaks | | |
| pip-audit / npm audit | deps | | 0 vulnerabilities | | |

Total executed automated tests in the final run: 128 + 274 + 274 + 2 + 250 + 294 = **1,222**, all passing.

## Functionality inventory (every control)
- **Web**: 846 interactive controls inventoried automatically across 22 pages × 2 languages (`tests/evidence/web/functionality-inventory.json`); every one has an accessible name. Behaviour of each control type is asserted in `features.spec.ts` (state after the action), links are crawled in `pages.spec.ts`.
- **Mobile**: every screen and control is covered by the 12 widget-test files (tap → assert resulting state), both directions, text scale 1.5/2.0 and accessibility guidelines; see `apps/mobile/test/widget/`.
- No placeholder controls are shown in either app; not-yet-built features are absent from the UI.

## Coverage
| Module | Line coverage |
|---|---|
| Backend `services/api/app` | 98 % |
| Web `src/lib` (business logic) | 99.27 % lines, 95.94 % branches |
| Mobile `lib/domain` | 96.94 % |
| Mobile `lib` (excluding generated l10n) | 98.77 % |

## Platform coverage and honesty notes
- iOS results come **only** from GitHub-hosted macOS runners (simulator). Not tested on a physical iPhone.
- Android results come from the CI emulator; not tested on a physical phone. The debug APK is built in CI.
- Web: three engines via Playwright (Chromium, Firefox, WebKit). Real Safari/Edge on devices: not tested.
- Religious content verification by a qualified human reviewer: **PENDING**.

## Evidence locations
- `tests/evidence/backend/` (junit, coverage, perf), `tests/evidence/web/` (junit/json, axe, Lighthouse, screenshots, inventory), `tests/evidence/mobile/` (machine output, lcov, analyze, screenshots), `tests/evidence/security/`, `tests/evidence/ci/` (logs of every job in run 42305310075 and the first iOS run).
- CI artifacts (90 days): `android-debug-apk`, `web-reports`, `backend-reports`.
