# Release readiness — Milestone 1

## Verdict: **NOT production-ready** (ready for internal testing)
Milestone 1 meets its engineering acceptance criteria on Android (emulator), iOS (simulator) and Web, with all automated gates green in CI run 42305310075. It must not be published to stores or production until the blockers below are closed. No deployment has been made, and none will be made without the owner's explicit approval.

## Gate checklist
| Rule (owner's absolute release rule) | Status |
|---|---|
| Any critical function untested | OK — all implemented functions tested |
| Any mandatory critical test failing | OK — 0 failures in the final run |
| Quran text integrity verification | OK (automated) — **human religious review PENDING** |
| Critical security vulnerability unresolved | OK for automated scans — **specialist review NOT DONE**, ZAP NOT RUN |
| Core features failing on a supported platform | OK |
| Sync data loss | No loss observed in tests (LWW + tombstones); settings sync not wired |
| Religious AI fabricated references | N/A (no AI in M1) |
| Required platform tests not executed | Physical-device testing NOT DONE (Android phone, iPhone) |

## Blockers before a public release
1. Qualified religious review of Quran text display, Madinah page map and prayer-method parameters.
2. Licence confirmation for the English translation (or remove it).
3. Move mobile token storage to Keychain/Keystore; release signing keys.
4. Store accounts: Google Play — the owner already has a paid developer account (confirmed 2026-11-07), no new cost. Apple Developer Program (USD 99/year) — **paid, requires owner approval**. Web hosting can be free (e.g. GitHub Pages / Cloudflare Pages); the API needs a host — free tiers exist but must be chosen and approved.
5. Physical-device smoke test on at least one Android phone and one iPhone.
6. Specialist security review and a DAST (OWASP ZAP) scan against a staging deployment.

## Recommended next milestone (M2)
Quran audio with verse sync, adhan notifications, live qibla compass, adhkar & Hisn al-Muslim, Hajj/Umrah guide port, settings sync in clients, KFGQPC page fonts for a printed-identical Mushaf layout.
