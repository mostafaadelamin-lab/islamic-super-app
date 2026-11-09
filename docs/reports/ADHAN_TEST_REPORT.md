# Adhan alerts — test report (2026-11-09)

Branch `feature/adhan-alerts` on top of `feature/quran-stories` (not pushed: GitHub account suspended; code bundle in project files).

## What was tested
| Layer | Suite | Result |
|---|---|---|
| Web | vitest, 351 tests (new `components/adhan.test.tsx`: planning, per-prayer switches, settings + permission, alert at Dhuhr with notification + audio + stop, no ring when missed while asleep, autoplay-blocked play button) | PASS |
| Web | `tsc`, ESLint (0 warnings), Prettier, static export build (adhan.mp3 precached by the service worker) | PASS |
| Web | Playwright (Chromium, real build, fake clock): enabling the alert on /ar/prayer/ and the banner ringing at Makkah Dhuhr; mp3 served as audio/mpeg | PASS (screenshots) |
| Mobile | `flutter analyze` (no issues), `flutter test test/unit test/widget` 398 tests (new: sound choice re-plans, listen/stop, 10-second test alert, Prayer-screen banner and bells; Android plans 30 days) | PASS |
| Android | release APK built in the container (debug-signed), adhan.ogg kept in res/raw (keep.xml) | see builds/ |
| iOS | adhan_short.caf added to the Runner target; not built or run (no macOS) | NOT TESTED |

## Not verified here
- That the phone actually sounds the adhan at prayer time: no Android emulator in the container. Check on a phone with
  Settings → Adhan alerts → "Test the alert (in 10 seconds)", then wait for a real prayer.
- Some Android brands (Xiaomi, Oppo, Huawei…) delay or kill alarms under battery saving; the settings note tells the user
  to allow "Alarms & reminders" and disable battery optimisation.
- The browser alert only works while a page of the site is open; browsers cannot schedule a notification for a closed page.
- Religious review of the recording (wording/pronunciation): PENDING the owner's listen-through.
