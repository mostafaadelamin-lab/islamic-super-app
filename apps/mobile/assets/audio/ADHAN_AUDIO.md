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
