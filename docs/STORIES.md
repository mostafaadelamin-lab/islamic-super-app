# Quranic stories (قصص قرآنية مسموعة)

Stories of the prophets to **listen to** (a calm voice, e.g. before sleep) or to **read**, in the Android, iOS and web apps (`/stories`, reachable from Home and More).

## Owner rules (mostafa amin, 2026-11-08)
- **Trusted sources only. No story text is written by us** (an earlier draft had short summaries written by the assistant; the owner rejected them and they were removed — the validator now refuses any `summary` field).
- **Audio:** Sheikh Nabil al-Awadi's "Stories of the Prophets" (قصص الأنبياء — الشيخ نبيل العوضي), audio only.
- Also each story's own Quranic verses, recited by the app's reciters, with Tafsir al-Muyassar.

## Two parts
| Part | Content | Source | Shown to users |
|---|---|---|---|
| Narrated series | 19 audio episodes (Adam … Muhammad ﷺ), 23–99 min each | Internet Archive item `prophets_stories_Nabel-ElAwadde`, streamed from `archive.org/download/…` (never re-hosted) | **Only episodes a named reviewer approved.** Reviewer mode lists pending ones with a "not reviewed" banner. All 19 are pending now |
| Verse stories | 25 stories as Quranic verse ranges (e.g. Yusuf 12:4–101, Ayyub 21:83–84 + 38:41–44) | Madinah Mushaf text (canonical `quran.v1.json`), everyayah.com recitation, Tafsir al-Muyassar | Always (it is the Quran); the verse ranges themselves await a reviewer's check |

## Licence of the narrated series
The archive.org upload (from koonoz.blogspot.com) states: «الحقوق متاحة لكل مسلم بشرط عدم الإستخدام تجاريا» — free for every Muslim, **non-commercial use only**. The app is free with no ads or purchases, which fits. The notice comes from the uploader, not from the sheikh, so **written confirmation from Sheikh Nabil al-Awadi's office is advised before a store release**. If the app ever becomes commercial, the episodes must be removed or licensed.

## Listening features
- One voice at a time: starting an episode stops the recitation and vice versa.
- Episodes resume where the listener stopped (position saved every few seconds, per episode).
- **Sleep timer** (15 / 30 / 45 / 60 min): stops the recitation and pauses the episode. One timer for the whole app.
- ±30 s and a progress slider on mobile; the browser's native audio controls on the web.
- Each episode links to the matching verse story ("Read the story's verses") when there is one.

## Reviewing
```
python tools/stories.py list
python tools/stories.py approve awadi-prophets --episode yusuf --reviewer "الاسم"     # one episode
python tools/stories.py approve awadi-prophets --episode all   --reviewer "الاسم"     # every pending episode
python tools/stories.py reject  awadi-prophets --episode lut   --reviewer "الاسم" --notes "السبب"
python tools/stories.py approve yusuf --reviewer "الاسم"    # verse ranges of a verse story checked
apps/mobile/tool/sync_assets.sh                              # copy the built bundle into the Flutter app
```
The built bundle (`content/stories/dist/stories.v1.json`) ships with each app release and is served by `GET /v1/stories` (approved episodes only unless `include_pending=true`).

## Network
Episodes and recitation stream over the internet (archive.org, everyayah.com); nothing is cached offline. archive.org is blocked from the build container, so playback of the real files is verified on a device; tests answer those requests with a local silent MP3.
