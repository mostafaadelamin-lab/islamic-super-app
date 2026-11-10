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

## Candidates not added yet

Commons blocked downloads (HTTP 429) on 2026-11-10. Licence checked, files still to fetch:
`Azan.ogg` (Andrewler, CC BY-SA 4.0), `Adhan.ogg` (Aishatu98, CC0), `Adhan_in_Istanbul.webm` (CC0),
`Maghrib_Adhan_at_the_Masjid_al_Haram,_Mecca_-_25_Feb,_2012.webm` and
`Adhan,_Great_Mosque_of_Mecca_-_Jan_21,_2013.webm` (YouTube CC BY, licence-reviewed on Commons).
Rejected: Sabah Fakhri recording (doubtful public-domain claim), Shia-form adhan files, spoken
readings (`Adhan_wiki.oga`, `Islamic_call_to_worship.oga`), the 30 s fragment `Oración_Al-Azzan.ogg`.

**Religious review:** every recording must be listened to and approved by a named reviewer before a
store release (wording and pronunciation of the adhan). Status: PENDING owner review.
