# Adhan recordings (muezzin voices): sources and licences

The user picks the muezzin in Settings (mobile) or the adhan settings (website). Catalogue:
`apps/mobile/lib/domain/adhan_voices.dart` and `apps/web/src/lib/adhan-voices.ts`.

## Voice 1 (`v1`)

| | |
|---|---|
| Title | Beautiful adhan |
| Source | https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg |
| Author | Adam-synagda (own work, uploaded 2022-05-01) |
| Licence | CC0 1.0 (public-domain dedication): https://creativecommons.org/publicdomain/zero/1.0/ |
| Original | Ogg Vorbis, 154.0 s, 44.1 kHz stereo, 1 229 032 bytes |
| SHA-256 (original) | 35fe06b08fe80505c550c33fed8a783fa9901ddc81ac884958b4be048f5b2a79 |
| Fetched | 2026-11-09 from upload.wikimedia.org |

Files made from it (all derived from the original above, no other audio):

- `android/app/src/main/res/raw/adhan.ogg`: the original, byte for byte (Android notification sound).
- `apps/mobile/assets/audio/adhan.m4a`: AAC 64 kbit/s mono, full length (in-app "listen" button).
- `ios/Runner/adhan_short.caf`: first 16.6 s (opening takbir, up to the first pause) with a 0.5 s fade,
  IMA ADPCM 22.05 kHz mono. iOS refuses notification sounds longer than 30 s.
- `apps/web/public/audio/adhan.mp3`: MP3 64 kbit/s mono, full length (website alert).

CC0 requires no attribution; the app credits the recording anyway (settings card / website prayer page).

## Voice 2 (`v2`)

| | |
|---|---|
| Title | The Adhan - Muslim Call to Prayer - Aaqib Azeez |
| Source | https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3 |
| Author | Atcovi (own work, 2020-12-23); the title names the muezzin, Aaqib Azeez |
| Licence | CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/ (credit the author; the derived files below are shared under the same licence) |
| Original | MP3 44.1 kHz stereo, 86.5 s, 1 448 294 bytes |
| SHA-256 (original) | 0faa59e2028bbb2f60a670b53ec89ffcf628f3c195b43fb41d9bdbc99000c1b3 |
| Fetched | 2026-11-10 from upload.wikimedia.org |

Derived (mono transcodes of the whole recording, nothing cut or added):
`android/app/src/main/res/raw/adhan_v2.ogg` (Vorbis q4), `assets/audio/adhan_v2.m4a` (AAC 64 kbit/s),
`apps/web/public/audio/adhan_v2.mp3` (MP3 64 kbit/s). The iPhone notification keeps voice 1's opening
takbir (adhan_short.caf); the full chosen voice plays inside the app.

## Bundled muezzins from Wikimedia Commons (2026-11-10, replaces the islamweb recordings)

The owner was told that islamweb's terms forbid reuse without written permission and asked for another
source. The islamweb default/Fajr recordings and the ~290-voice downloadable collection were removed; every
muezzin is now an openly licensed Wikimedia Commons recording, bundled in the app (offline). Originals are
kept outside the repo; SHA-256 below.

| id | Recording (Wikimedia Commons file) | Author | Licence | SHA-256 of original |
|---|---|---|---|---|
| `haram` (default) | Adhan, Great Mosque of Mecca - Jan 21, 2013 (`a/a7/Adhan,_Great_Mosque_of_Mecca_-_Jan_21,_2013.webm`) | Seyfula Islam | CC BY 3.0 | f4acc1bcc6e7919fce60b21162a3c794952c562a6df7b6aa7971f80d191eb5f0 |
| `haram_fajr` (default Fajr) | Eid al-Fitr Fajr azan at Malmö Mosque - 19 August 2012 (`b/b1/…Malmö_Mosque_-_19_August_2012.webm`) | Islamic Center Malmö | CC BY 3.0 | 899a3325aafb03e09381b3e40149e88d06b00b40ce2b1eeb09d63e594c9c1742 |
| `madinah` | Call to prayer from the prophet's mosque (`7/7c/33937_ejaz215_call-to-prayer-from-the-prophet-s-mo.ogg`) | ejaz215 | CC BY 3.0 | 4d0fabe0e0ef52186646a256220f74a972ba698ac269165fed5d52de3202d656 |
| `fakhry` | Call to prayer by Sabah Fakhry (`2/27/Call_to_prayer_by_Sabah_Fakhry.mp3`) | Sabah Fakhri | public domain | 94a2fe12f2e9998b64d5c77469f530a4e75a9e3514837ce71f6937fc6c1ae9a5 |
| `v1`, `v2` | as above | | | |

Derived files (ffmpeg, mono): `android/app/src/main/res/raw/adhan_<id>.ogg` (Vorbis q4), `assets/audio/adhan_<id>.m4a`
(AAC 64 kbit/s), `apps/web/public/audio/adhan_<id>.mp3` (MP3 64 kbit/s). The Makkah recording starts at 11 s and
the Malmö Fajr recording at 5 s (ambient lead-in removed); nothing else cut. `ios/Runner/adhan_short.caf` is now
the first 28 s of the Makkah recording (iOS notification limit 30 s).

**Open checks:** the owner should listen to the Fajr recording to confirm "الصلاة خير من النوم"; religious
listen-through by a named reviewer still pending for every voice.

## The owner's picks (2026-11-11)

On 2026-11-11 the owner chose these eight recordings from the audio.islamweb.net adhan collection and told us to bundle them offline (owner's decision: the site offers free download; see feedback-round notes). The source is recorded here only and never shown in the app. Transcodes: Android `res/raw/adhan_<id>.ogg` (Vorbis q2 mono) and `assets/audio/adhan_<id>.m4a` (AAC 48 kbit/s mono), full length, nothing cut or added.

| App id | Title on the site | audioid | Download URL | Original SHA-256 |
|---|---|---|---|---|
| `mulla` | أذان الحرم المكي 3 - علي بن أحمد ملا | 3 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=3 | d2aad7b357c0b83c968ceb450c02624febb6c1a7272ce681aa22d88de497d3f4 |
| `makkah` | أذان - مكة المكرمة | 122647 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=122647 | 4ab22d15fcea1a70f636b50f21e3f82597fa583ec2a21065373b3bde87482647 |
| `bukhari` | الحرم المدني 1 - عصام البخارى | 5 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=5 | d4085827cd4cd0d51b4b598af9ac4905191b0e90429d689265293b47420a79ad |
| `mismail` | أذان - مصطفى إسماعيل | 176760 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=176760 | 06e6376fb4243d8553892d33492ac70239489e5bbf797e43250d2c96176178fa |
| `banna` | أذان القاهرة - محمود علي البنا | 122666 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=122666 | 66f89f1852b33974fb33ae9640c9aa4768d409d1dec57f8ecd82edc320fa8d23 |
| `rifaat` | أذان القاهرة - محمد رفعت | 122665 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=122665 | 39964e1b6df88cfc30e66ca18cbc8efe5829fbf82d24210ebddc3d435eebd96c |
| `daghriri_fajr` | آذان الفجر الأول من المسجد الحرام للشيخ حمد الدغريري (Fajr) | 489488 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=489488 | c2a824f3b0e8a2b77104c9e4a24f2b4229bb361ae202ebd853ee8362e044ae22 |
| `afasy_fajr` | أذان الفجر1 الشيخ مشاري بن راشد العفاسي (Fajr) | 206932 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=206932 | e025f8cf040e6490edc3aef1dc13b5883339b6b9481092b4bed00b7b54087d5a |
| `abdulbasit` | أذان الشيخ عبد الباسط 1 (list no. 134) | 88633 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=88633 | 1c44f4a44265e975a6fe85bea0d4282c00cfe17e736a6df146fee8dbd7f070b6 |
| `abdulbasit_fajr` | أذان الفجر1-بصوت الشيخ عبدالباسط عبد الصمد (list no. 139, Fajr) | 404627 | https://audio.islamweb.net/audio/downloadmp3.php?audioid=404627 | 6acb1d78cb53fba6151ce621308ae213007ae087bede0fcf9f96c3c9b299d565 |

The two Abdul Basit recordings were added in 1.0.9 (owner's request, 2026-11-11), same transcodes (web: MP3 64 kbit/s mono).

Defaults since 1.0.8: `mulla` for the five prayers and `daghriri_fajr` for Fajr. The Commons recordings above stay available.
