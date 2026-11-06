# Regression report — Milestone 1

Every push runs the full gate (`.github/workflows/ci.yml`). History of CI runs on `main` during the milestone (all results are from GitHub Actions; logs are kept by GitHub for 90 days, and the final run's logs are copied to `tests/evidence/ci/`).

| CI run | Commit | Content | Backend | Web (Chromium+Firefox+WebKit) | Android (tests, APK, emulator) | iOS (tests, build, simulator) | Semgrep | gitleaks | Notes |
|---|---|---|---|---|---|---|---|---|---|
| 42215319714 | 968839f | PASS | PASS 128 | FAIL 293/294 (WebKit offline) | tests 273 PASS, APK PASS, emulator **FAIL** | **PASS** (273 + simulator flow) | FAIL (23 supply-chain) | PASS | First run. DEF-005/006/007 opened |
| 42242255777 | e234e59 | PASS | PASS | FAIL 293/294 (WebKit select before hydration) | **PASS** incl. emulator | CANCELLED (runner, no steps logged) | PASS | PASS | DEF-009 opened |
| 42250018777 | e254de5 | PASS | PASS | e2e 294/294 PASS; `npm audit` FAIL | emulator hung 4 h (cancelled) | CANCELLED (runner) | PASS | PASS | DEF-010, DEF-011 opened |
| 42289185402 | 20e6920 | PASS | PASS | FAIL 293/294 (WebKit text field before hydration) | emulator flow FAIL (snackbar over Go) | PASS | PASS | PASS | DEF-008 found (root cause of DEF-005) |
| 42294829459 | 64c8c76 | PASS | PASS | **PASS 294/294**, audit 0 | emulator FAIL (same) | simulator hung (cancelled at 60 min) | PASS | PASS | |
| 42303764986 | 92b15f7 | PASS | PASS | PASS | **PASS** (274, emulator attempt 1) | FAIL: `timeout` missing on macOS | PASS | PASS | |
| **42305310075** | **e986194** | **PASS** | **PASS 128** | **PASS 250 unit + 294 e2e, audit 0** | **PASS 274 + APK + emulator flow (attempt 1)** | **PASS 274 + simulator build + simulator flow (attempt 1)** | **PASS 0 findings** | **PASS** | **All green** |

## Regression scope per fix
- DEF-001 (basmala): whole Flutter suite (273) re-run; screenshots regenerated.
- DEF-004/DEF-010 (dependency upgrades): full backend suite; full web unit + e2e in 3 browsers.
- DEF-008 (snackbar): full Flutter suite 274 locally (Docker, Flutter 3.41.6) and in CI on Linux + macOS; device flows on Android emulator and iOS simulator.
- DEF-009 (hydration): full e2e suite locally (Chromium 98/98) and in CI (3 browsers, 294/294).

## Notes
- Nothing was skipped or disabled to get green. One retry exists only for a *hung* device run (exit 124), never for a failing one; in the final run neither device job needed it.
- Historical results before M1 (Rattil prototype) were not automated and are not comparable.
