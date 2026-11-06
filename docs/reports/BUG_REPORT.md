# Bug report — Milestone 1

| ID | Severity | Feature | Platform | Found by | Root cause | Fix | Verification | Status |
|---|---|---|---|---|---|---|---|---|
| DEF-001 | Major | F-QURAN-02/03 basmala | Android, iOS | Lead review of screenshots vs web | Mobile readers rendered only numbered ayahs; no unnumbered basmala before surahs | `BasmalaLine` widget in both readers (all surahs except 1 and 9) | 9 new widget tests; full suite 273/273 | CLOSED |
| DEF-002 | Minor | F-SYNC-01 | API contract | Web + mobile engineers | API.md showed `id` in the PUT body; backend forbids extra fields (422) | Contract clarified: id is in the path only; both clients send it there | Web e2e sync vs real API; mobile live-API run (9 tests) | CLOSED |
| DEF-003 | Major | F-PRAYER-01 | Android, iOS | Mobile tests | `timezone` `latest.dart` lacks link zones (e.g. Asia/Kuwait) | Use `latest_all.dart`; test loads every city's zone | flutter_test | CLOSED |
| DEF-004 | High (security) | F-API-01 | Backend | pip-audit | Pinned FastAPI/Starlette/PyJWT versions had published advisories | Upgraded to fastapi 0.162.0, starlette 1.10.0, PyJWT 2.15.1 etc. | pip-audit: no known vulnerabilities; 128/128 tests | CLOSED |
| DEF-005 | Major | F-QURAN-03 go-to-page | Android emulator | CI run 42215319714 | Integration test tapped "Go" while the soft keyboard was still animating; the page re-laid out under the tap | Wait for the keyboard to settle and ensure the button is visible before tapping (test synchronisation) | Android emulator CI run 42305310075: pass on attempt 1 | CLOSED |
| DEF-006 | Minor | NFR-OFF | Web (WebKit) | CI run 42215319714 | Playwright's WebKit fails navigation when `setOffline()` is combined with a service worker | Offline test now stops its own static server (real unreachability) for all browsers; Chromium/Firefox additionally use setOffline | CI 42305310075: 294/294 e2e incl. WebKit offline | CLOSED |
| DEF-007 | Medium (supply chain) | CI | CI | Semgrep in CI | Third-party actions referenced by mutable tags; Dependabot without cooldown | Pinned every action to a commit SHA; 7-day cooldown | CI 42305310075 Semgrep: 0 findings | CLOSED |
| DEF-008 | Major | F-QURAN-03 go-to-page | Android (small screens) | Android emulator integration test (CI runs 42215319714, 42289185402) | The "Bookmarked" snackbar from the surah reader stayed on screen and floated over the page reader's Go button on the emulator's smaller screen (DEF-005's keyboard wait did not fix it; the hit-test trace showed the snackbar on top) | Page reader clears any leftover snackbar when it opens | New widget test fails without the fix, passes with it; 274/274; emulator + iOS simulator flows pass (CI 42305310075) | CLOSED |
| DEF-009 | Major | Web interactivity | Web (seen on WebKit) | CI runs 42242255777, 42289185402 | Tests (and a very fast user) could change a select or text field before React hydrated the static page; the change was lost (stale API URL → 401) | `<html data-hydrated>` marker; e2e fixture waits for hydration after every navigation | CI 42305310075: 294/294 in 3 browsers | CLOSED (test side). Residual: a user acting within the first moments of load can still lose an input — LIM-07 |
| DEF-010 | High (security) | Web build | Web | `npm audit` in CI | Next 15 pins postcss 8.4.31 (GHSA-qx2v-qp2m-jg93 and 3 related advisories) | npm `overrides` → postcss 8.5.32 | `npm audit --omit=dev`: 0 vulnerabilities | CLOSED |
| DEF-011 | Minor | CI | iOS/Android CI | CI | Device test step could hang for an hour; macOS has no GNU `timeout` | `tool/run_integration.sh`: portable 10-min limit, one retry for hangs only (not for failures) | CI 42305310075: both passed on attempt 1 | CLOSED |

## Open limitations (not defects in shipped behaviour)
| ID | Area | Description | Status |
|---|---|---|---|
| LIM-01 | Mushaf layout | Page reader shows the correct ayahs per Madinah page but not the printed line layout | OPEN (M2) |
| LIM-02 | Mobile security | Access token stored in shared_preferences (not Keychain/Keystore); release APK signed with debug key | OPEN (before store release) |
| LIM-03 | Sync | Only bookmarks sync; settings sync endpoint exists but clients don't use it; tombstones never purged | OPEN |
| LIM-04 | Translation | English translation licence review pending | OPEN — owner/legal |
| LIM-05 | Religious review | Human verification of text, page map and prayer parameters by a qualified reviewer | PENDING |
| LIM-06 | Rate limiting | In-process limiter; needs shared store for multi-instance deploy | OPEN |
| LIM-07 | Web | Inputs made before hydration (first ~0.5 s of a page load) are not kept | OPEN (low) |
| LIM-08 | CI | Android emulator / iOS simulator jobs occasionally hung in GitHub runners (infrastructure); now time-limited with one retry for hangs | MONITORED |
