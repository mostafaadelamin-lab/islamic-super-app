# Bug report — Milestone 1

| ID | Severity | Feature | Platform | Found by | Root cause | Fix | Verification | Status |
|---|---|---|---|---|---|---|---|---|
| DEF-001 | Major | F-QURAN-02/03 basmala | Android, iOS | Lead review of screenshots vs web | Mobile readers rendered only numbered ayahs; no unnumbered basmala before surahs | `BasmalaLine` widget in both readers (all surahs except 1 and 9) | 9 new widget tests; full suite 273/273 | CLOSED |
| DEF-002 | Minor | F-SYNC-01 | API contract | Web + mobile engineers | API.md showed `id` in the PUT body; backend forbids extra fields (422) | Contract clarified: id is in the path only; both clients send it there | Web e2e sync vs real API; mobile live-API run (9 tests) | CLOSED |
| DEF-003 | Major | F-PRAYER-01 | Android, iOS | Mobile tests | `timezone` `latest.dart` lacks link zones (e.g. Asia/Kuwait) | Use `latest_all.dart`; test loads every city's zone | flutter_test | CLOSED |
| DEF-004 | High (security) | F-API-01 | Backend | pip-audit | Pinned FastAPI/Starlette/PyJWT versions had published advisories | Upgraded to fastapi 0.162.0, starlette 1.10.0, PyJWT 2.15.1 etc. | pip-audit: no known vulnerabilities; 128/128 tests | CLOSED |
| DEF-005 | Major | F-QURAN-03 go-to-page | Android emulator | CI run 42215319714 | Integration test tapped "Go" while the soft keyboard was still animating; the page re-laid out under the tap | Wait for the keyboard to settle and ensure the button is visible before tapping (test synchronisation) | CI run 42242255777 (see REGRESSION_REPORT) | see regression report |
| DEF-006 | Minor | NFR-OFF | Web (WebKit) | CI run 42215319714 | Playwright's WebKit fails navigation when `setOffline()` is combined with a service worker | Offline test now stops its own static server (real unreachability) for all browsers; Chromium/Firefox additionally use setOffline | local Chromium pass; CI run 42242255777 | see regression report |
| DEF-007 | Medium (supply chain) | CI | CI | Semgrep in CI | Third-party actions referenced by mutable tags; Dependabot without cooldown | Pinned every action to a commit SHA; 7-day cooldown | CI run 42242255777 | see regression report |

## Open limitations (not defects in shipped behaviour)
| ID | Area | Description | Status |
|---|---|---|---|
| LIM-01 | Mushaf layout | Page reader shows the correct ayahs per Madinah page but not the printed line layout | OPEN (M2) |
| LIM-02 | Mobile security | Access token stored in shared_preferences (not Keychain/Keystore); release APK signed with debug key | OPEN (before store release) |
| LIM-03 | Sync | Only bookmarks sync; settings sync endpoint exists but clients don't use it; tombstones never purged | OPEN |
| LIM-04 | Translation | English translation licence review pending | OPEN — owner/legal |
| LIM-05 | Religious review | Human verification of text, page map and prayer parameters by a qualified reviewer | PENDING |
| LIM-06 | Rate limiting | In-process limiter; needs shared store for multi-instance deploy | OPEN |
