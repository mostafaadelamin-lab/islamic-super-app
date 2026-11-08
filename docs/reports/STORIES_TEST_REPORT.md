# Quranic stories — test report (2026-11-08)

Branch `feature/islamic-reels` + stories commit (not pushed: GitHub account suspended; code bundle in project files).

## What was tested
| Layer | Suite | Result |
|---|---|---|
| Content | `tools/build_content.py` (verse ranges vs ayah counts, episode URLs/licence/review rules) | PASS |
| API | pytest, 183 tests (21 new in `test_stories.py`: validator, bundle, CLI review per episode / `all`, `/v1/stories` hides unreviewed episodes) | PASS |
| Web | vitest, 344 tests (new: `unit/stories.test.ts`, `components/stories.test.tsx`) | PASS |
| Web | Playwright Chromium, 221 tests (new `stories.spec.ts`; `/stories/` and `/stories/yusuf/` added to the axe/route sweep; More page now 14 sections) | PASS |
| Web | `tsc`, ESLint (0 warnings), Prettier, static export build | PASS |
| Mobile | `flutter analyze` (no issues), `flutter test` 406 tests (new: `unit/stories_test.dart`, `widget/stories_test.dart`) | PASS |
| Android | release APK built in the container (debug-signed) | see builds/ |
| iOS | not built or run (no macOS; GitHub Actions unavailable while the account is suspended) | NOT TESTED |

## Behaviours covered
- Sheikh Nabil al-Awadi's 19 episodes are hidden from users until approved; reviewer mode lists them with a "not reviewed" banner.
- Playing an episode: correct archive.org URL, resume at the saved position, position saved on pause, one voice at a time (recitation stops), error message + retry when loading fails.
- Sleep timer: fires once after the chosen minutes, stops recitation and pauses the episode, can be cancelled; one timer shared by all pages (web).
- Verse stories: only the Mushaf verses are shown (no text of ours), recitation plays the ranges in order across surahs (e.g. Ayyub 21:83–84 then 38:41–44), the recited ayah is highlighted and kept in view; basmala only before an ayah 1.
- Malformed data is dropped on every platform: non-https or non-audio episode URLs (`javascript:`, `http:`, HTML pages), verse ranges outside the surah, rejected entries, series without a licence.

## Not verified here
- Real playback of the archive.org episodes and everyayah.com files: both hosts are blocked from the build container; tests answer them with a local silent MP3. Must be checked on a phone with internet.
- Religious review of the 19 episodes and of the 25 verse ranges: nothing is approved yet (needs a named reviewer).
- Licence: the non-commercial notice is the uploader's; written confirmation from the sheikh's office is advised before a store release.
