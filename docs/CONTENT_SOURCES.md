# Content sources and licences

**Owner's rule (2026-11-10):** the owner considers the sites they sent (islamweb.net and audio.islamweb.net, alukah.net,
mp3quran.net and similar) free for anyone to download from, and asked that no permission is requested and that
their names are NOT shown in the app or on the website. Sources are recorded here only, for our reference. Credits
that an open licence itself requires (CC BY / CC BY-SA, ODbL: Quran text, Wikimedia voices, OpenStreetMap, hadith
data) stay visible, because showing them is the condition of that licence.

| Content | Source | Licence | Integrity control | Review status |
|---|---|---|---|---|
| Quran Arabic text (Uthmani, Hafs an Asim, 6236 ayahs) | King Fahd Glorious Quran Printing Complex (KFGQPC), "Hafs Uthmanic Data" **v18** `hafsData_v18.json` (2021-10-25, the Complex's latest published release), stored as `content/quran/upstream/kfgqpc-hafs-v18.json` | Published by the Complex for free use; distributed unmodified | file SHA-256 `5d8bb91726e482839d0057633cb1973031e4d706fa9604eea5e08892f20ba140` pinned in `tests/vectors/quran-reference.json`; build and tests on every platform assert every ayah equals `aya_text` byte-for-byte with only its trailing NBSP + ayah number removed; per-surah and overall hashes in `content/quran/dist/integrity.v1.json`. Surah names and translation come from `quran-json@3.1.2` (not the Arabic text) | Text verified mechanically against the Complex's file. **Human verification against a printed Madinah Mushaf by a qualified reviewer, and official approval (KFGQPC / al-Azhar), are still pending.** |
| Madinah Mushaf pages (KFGQPC new edition 1441H, 604 pages) | `page` column of `hafsData_v18.json` (the Complex) | as above | every ayah's page equals the Complex's page; contiguity + coverage tests; 5 printed-page spot checks | pending human spot check of more pages |
| English meaning translation | Saheeh International via `quran-json@3.1.2` | **Licence review pending** — the translation's own copyright terms must be confirmed before public release | shown only as an optional aid; never used as Quran text | pending |
| Tafsir al-Muyassar (Arabic, simplified) | King Fahd Glorious Quran Printing Complex; file from npm `@muslimjs/ar.muyassar@1.0.0` `Data/ar.muyassar.json` (alquran.cloud / Tanzil edition `ar.muyassar`), SHA-256 `0d0441ae…0da3` | Distributed for free non-commercial use with attribution and without modification (Tanzil terms); **formal licence confirmation pending** | copied unmodified; one entry per ayah (6236) checked in build and tests | pending comparison with the printed Complex edition |
| Prayer method parameters | Published parameters of each authority (MWL, Egyptian Survey, Umm al-Qura, Karachi, ISNA, Dubai, Kuwait, Qatar, UOIF) | facts | cross-checked against adhan-js 4.4.6 (MIT) | Official timetable comparison for Cairo/Makkah: pending |
| Morning/evening adhkar, Hisn al-Muslim, Nawawi 40 | Kazi Shariar datasets (digital text). Hisn al-Muslim is by Sa'id ibn Wahf al-Qahtani; the dataset licence covers the digitisation, not the book. **Written permission from the rights holder for in-app use is still needed before a store release.** Nawawi 40 is a classical text (public domain). | CC BY 4.0 (dataset) | shown from Milestone 2 (morning/evening split and repeat counts taken from Hisn al-Muslim chapter notes) | religious review pending |
| Hisn al-Muslim sections (content/adhkar/hisn-sections.json) | Grouping of the existing Hisn chapters by subject for browsing (chapter ids only; no text added or changed). Section names are UI labels. Fadl (virtue) notes and dhikr audio are **not** added: they need a licensed published source first (needs source). | — | 2026-11-09, phase 5 | grouping to be checked in the religious review |
| Hajj/Umrah guide | Rattil prototype text | project-owned | shown from Milestone 2 with a visible "pending religious review" notice | religious review required |
| Madinah Mushaf 15-line layout | npm `quran-madina-html@2.2.2` **Madina-1441H** database (per-file SHA-256 in `content/quran/upstream/quran-madina-html-2.2.2/SHA256SUMS`) | Waqf GPL 2.0 | used only to locate line breaks; `mushaf-lines.v1.json` stores word ranges of the canonical text; the build asserts every word appears once in order and that every ayah's page, first line and last line equal `page`/`line_start`/`line_end` of `hafsData_v18.json` | pending human comparison with printed pages |
| Hizb quarters (rub' al-hizb, 240) | npm `quran-meta@7.0.0` HafsLists.HizbQuarterList (Tanzil metadata), `content/quran/upstream/quran-meta-7.0.0-hizb-quarters.json` | MIT (`quran-meta-LICENSE.txt`) | build checks: 240 starts, every ۞ sign in the KFGQPC text is a start, every start without the sign is a surah start, every 8th start = juz start; the one Tanzil/Mushaf difference (15:50 vs 15:49) follows the Mushaf | pending human comparison with the printed index |
| Recitation audio | everyayah.com per-ayah MP3, streamed (not bundled) | free to stream; reciters' rights with their publishers | online only | — |
| Recitation audio, reciters recorded per surah (Idris Abkar, Mustafa Ismail mujawwad, Mahmoud Ali al-Banna mujawwad, Ahmad Eisa al-Masarawi; added 2026-11-20, 41 reciters in all) | mp3quran.net surah MP3s (`cdn.mp3quran.net/audio/...`) + its free ayah-timing API (`api/v3/ayat_timing`, reads 12/288/122/289), checked against the audio and stored in `packages/shared-schemas/audio/ayah-timings.json` by `tools/ayah_timings/build.py` | free to stream/download (owner rule 2026-11-12); source never shown in-app | online, or a surah saved for offline | Abkar's Ya-Sin (36) timings were re-placed in the recording's pauses (published ones did not match the file); Hassan Saleh left out (published timings do not match his files) |
| Islamic reels (short videos) | Curated YouTube and Instagram links in `content/reels/reels.json`, played through the official embeds (`youtube-nocookie.com`, `instagram.com/reel/<code>/embed/`); nothing downloaded or re-hosted | rights stay with each channel/account; embedding per YouTube's and Instagram's terms | `tools/reels.py` validates every link/id; only `approved` reels with a named reviewer and date are shown | Hand-picked reels need a religious review. **Automatic reels** come from trusted YouTube channels the owner approved once (`content/reels/sources.json`, owner decision 2026-11-09): no per-video review. Allowed: Quran recitation, religious lessons, advice and admonitions per the Quran and Sunnah |
| Stories of the Prophets (audio) — Sheikh Nabil al-Awadi | Internet Archive `prophets_stories_Nabel-ElAwadde` (uploaded from koonoz.blogspot.com), 19 MP3 episodes streamed from archive.org; not re-hosted | upload notice: free for every Muslim, non-commercial use only (the app is free, no ads) | `tools/stories.py` checks https audio URLs, source and licence; only `approved` episodes (named reviewer + date) are heard by users | **Every episode needs a religious review.** Written confirmation from the sheikh's office advised before a store release |
| Quranic stories (verse ranges) | `content/stories/stories.json`: 25 stories as verse ranges of the canonical Quran text; recitation from everyayah.com; Tafsir al-Muyassar | Quran text and tafsir as listed above | ranges validated against the ayah counts; no summary/text of ours allowed | ranges await a reviewer's check |
| Magnetic declination model (qibla compass) | World Magnetic Model 2025 (NOAA NCEI / British Geological Survey), coefficients from npm `geomagnetism@0.2.0` `data/wmm-2025.json`, stored as `packages/shared-schemas/geo/wmm2025.json` | US Government work, public domain | web implementation checked against npm `geomagnetism` (independent code) within 0.01° at 72 points/dates; mobile port checked against the same vectors (`tests/vectors/declination.json`) | — |
| Ramadan dates for the Umm al-Qura Isha rule | ICU `islamic-umalqura` calendar (official Umm al-Qura tables), generated by `tools/ramadan_table.mjs` into `methods.json` → `ramadanUmmAlQura` | facts | web test re-checks every row against ICU | — |
| Nearby mosques | OpenStreetMap via the public Overpass API (overpass-api.de, fallback overpass.kumi.systems), queried live from the user's device, not stored in the app | ODbL 1.0 — credit "© OpenStreetMap contributors" shown on the screen | parser tests with sample answers; the real servers are not reachable from the build environment | data quality varies by city |
| Fonts | Quran: **KFGQPC HAFS Uthmanic Script v18** (`content/fonts/KFGQPC-HAFS-Uthmanic-v18.ttf`), the Complex's font for this text. Interface: IBM Plex Sans Arabic (Google Fonts repository) | KFGQPC font EULA (`content/fonts/KFGQPC-HAFS-LICENSE.txt`): free use/copy/distribution, no modification (so it is not subset), no sale. IBM Plex: SIL OFL 1.1 | files committed with licence | — |
| Zakat calculator rules and quoted text (nisab 85 g of 21-karat gold, 2.5%, lunar year; adornment gold, trade goods, bank certificates, saved shares, debts) | Published fatwas of Dar al-Ifta al-Misriyya, nos. 7506, 8426, 6231, 6203, 8848, 8115, 8087, 6423, 3133, 6318 (dar-alifta.org; links in `content/zakat/dar-alifta.v1.json`). Chosen by the owner 2026-11-10. | Short verbatim quotes with a link to each fatwa (citation) | every quote re-checked word for word against the live page on 2026-11-10; arithmetic covered by unit tests on mobile and web | **pending a shar'i review**; four questions for the reviewer are listed in the JSON (`reviewQuestions`) |
| Hadith books: Sahih al-Bukhari, Sahih Muslim, Sunan Abi Dawud, Jami' at-Tirmidhi, Sunan an-Nasa'i, Sunan Ibn Majah, Muwatta Malik, Musnad Ahmad, Sunan ad-Darimi (Arabic text with diacritics, al-Alamiyya numbering) | [Open-Hadith-Data](https://github.com/mhashim6/Open-Hadith-Data) at commit `1515f6cba21efed20d8916bf55acef1dffa0d2d5`, files `*_ahadith_mushakkala_mufassala.utf8.csv` (text column only; the commentary column is not used). Built by `tools/build_hadith.py` into `content/hadith/dist/` (500 hadiths per file). Approved by the owner 2026-11-10. | ODbL 1.0 (database) / DbCL 1.0 (contents) — attribution shown on the hadith page (web) and screen (mobile). **Provenance caveat:** the dataset's README says the texts come from the hadith-islamware project ("Copyright (C) 2006-2014 Islam Ware"); told to the owner, who approved its use. | text copied unchanged; book counts and sequential ids checked at build time; SHA-256 of every book's texts recorded in `books.v1.json` and re-checked by web and mobile tests | **pending a shar'i review**; not yet compared with a printed edition (shown in-app) |
| Recitations library (reciters in every riwaya, full-surah MP3) and Quran radios | mp3quran.net public API v3 (`/reciters`, `/riwayat`, `/radios`), read live on the user's device and cached there for 7 days; audio streamed from the addresses the API gives (cdn.mp3quran.net, backup.qurango.net…), https only; nothing bundled | No licence file and no API terms found. The site's privacy page, section "Copyrights", says: "we allow any visitor or developer to copy any material or use any link on the websites". The owner decided on 2026-11-10 to use it without asking permission and not to name the site in the app (internal reference only) | online only; API answers validated (malformed or non-https entries dropped); not tested against the live API from the build machine (blocked there), tests use a recorded-shape fixture | recitations are published recordings of the Quran; no review gate added |

## Display glyph map
Since Quran content 2.0.0 the map in `packages/shared-schemas/quran-render.json` is **empty**: the KFGQPC v18 text is drawn with the Complex's own font, which draws every code point of that text (open tanween U+0657/U+065E/U+0656 included) as published. The end-of-ayah ornament is drawn by that font from Arabic-Indic digits, so no U+06DD is added.
Earlier versions (quranenc text + Amiri Quran font) substituted three tanween code points in the rendered string only; stored text was never changed.

## Adhan recordings (muezzin voices)
Voice 1: "Beautiful adhan" by Adam-synagda, Wikimedia Commons (https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg),
CC0 1.0 public-domain dedication, uploaded as own work. Original SHA-256
35fe06b08fe80505c550c33fed8a783fa9901ddc81ac884958b4be048f5b2a79. Derived files and their formats are listed in
apps/mobile/assets/audio/ADHAN_AUDIO.md.
Voice 2: "The Adhan - Muslim Call to Prayer - Aaqib Azeez" by Atcovi, Wikimedia Commons, CC BY-SA 4.0 (credited in the
app and on the website). Religious review (listen-through by a named reviewer) of every voice: PENDING.
Since 2026-11-10 every muezzin is an openly licensed Wikimedia Commons recording (Makkah Haram 2013, Madinah,
Sabah Fakhri, Malmö Fajr); the islamweb recordings and downloadable collection were removed at the owner's request
after being told the site's terms forbid reuse. Details in apps/mobile/assets/audio/ADHAN_AUDIO.md.

## Feedback round sources (2026-11-10)
| Content | Source | Licence / terms | Notes |
|---|---|---|---|
| Names of Allah (97 entries, explanation under each name) | al-Sa'di, «تفسير أسماء الله الحسنى», ed. Ubaid al-Ubaid, via Shamela (book 10090); `content/asma/` | classical text, public domain; Shamela edition used for the wording | first paragraph of al-Sa'di's own words per name, verbatim (footnote numbers removed); approved by the owner |
| Egyptian and Saudi Quran radios | live streams at stream.radiojar.com (`8s5u5tpdtwzuv` Cairo, `0tpy1h0kxtzuv` Saudi) | public live streams; station names shown, host not shown (owner) | cleartext allowed for radiojar.com (redirects to http edges) |
| Nearby mosques fallback, place names | OpenStreetMap Nominatim (search + reverse) | ODbL, attribution "© OpenStreetMap contributors" | used when the Overpass mirrors fail; area name for the home screen |
| Hajj/Umrah step drawings | drawn in code (`apps/mobile/lib/ui/hajj_art.dart`) | our own | no photos or third-party art |

## Nasheeds and adhkar audio (2026-11-10)

Played through YouTube's embedded player (www.youtube-nocookie.com) from the official channels below; YouTube's terms allow embedding, and every video was checked as embeddable (oEmbed 200) on 2026-11-10. Nothing is downloaded or re-hosted. Nasheeds were chosen as voice-only versions (the owner listen-checks them). "Mawlay" by al-Naqshbandi was left out because it has musical accompaniment.

| Artist | Channel | Kind |
|---|---|---|
| Mohamed Tarek | UCPp0_tTnE3DUJmUmcLMfOyg | Official Artist Channel (vocals-only versions) |
| Mohamed Youssef | UCeHKDFxsQXWxCYO-EXeBl_A | Official Artist Channel (vocals-only versions) |
| Nasr el-Din Tobar | UCM8T0Re5FfFnYEvQOfTQHOw | YouTube auto-generated Topic channel (licensed releases) |
| Sayed al-Naqshbandi | UCurG_RKCM6Cg1doqYa2mp4A | SayedNaqshbandiVEVO (label official) |
| Mishary Alafasy (nasheeds) | UCzuEc6pl59Z-lADI3ceQK1w | Anashid Alafasy, verified |
| Mishary Alafasy (adhkar) | UCmMcOjsVehVlEOteyrhjI2Q | Alafasy, verified |
| Ahmed Bukhatir | UC-2pqFUafqKCnACEfQasZGg | Official Artist Channel |
| Abu Ali (Mosa Alomairah) | UCQQCG2_xVTC6CYwobudUTLQ | Official Artist Channel |
| Muhammad Al Muqit | UCheBIbE_7Trrhatjt9LIteQ | Official Artist Channel |

### Offline adhkar audio (2026-11-11)

Morning and evening adhkar, Mishary Rashid Alafasy: audio.islamweb.net audioid 146980 (morning, 1121 s, 4 487 296 bytes) and 146981 (evening, 1162 s, 4 647 040 bytes), fetched 2026-11-11 via downloadmp3.php, bundled unchanged. Owner's decision (2026-11-11): the site offers free download; use it, no source name in the app.

2026-11-11 (owner's decision): eight muezzin recordings picked by the owner from audio.islamweb.net are bundled offline
(Ali Mulla, Makkah adhan, Essam Bukhari, Mustafa Ismail, Mahmoud Ali Al-Banna, Muhammad Rifaat; Fajr: Hamad Al-Daghriri,
Mishary Alafasy). The source site is not named in the app. audioids and checksums: apps/mobile/assets/audio/ADHAN_AUDIO.md.

## Final feedback round (v1.0.9, 2026-11-11)

None of these source names are shown in the app (owner's rule).

| Content | Source | Notes |
|---|---|---|
| Per-dhikr audio (adhkar + Hisn al-Muslim) | hisnmuslim.com API, `https://www.hisnmuslim.com/audio/ar/{id}.mp3`; mapping built by `tools/adhkar_audio.py` from `content/adhkar/hisnmuslim-audio-source.json` | streamed, not bundled; 272 Hisn items + the morning/evening list mapped |
| Surah information and asbab al-nuzul | Quranpedia dumps (`content/quran-info/quranpedia-surahs.json`, `quranpedia-asbab-wahidi.json`), built by `tools/surah_info.py` | licence allows in-app use without attribution |
| Names of Allah (99, simplified explanation) | surahquran.com, page 99-Names-of-Allah-with-Meaning, retrieved 2026-11-11 | replaces the al-Sa'di text; owner's request; audio is device text-to-speech |
| Nasheeds (516 by 34 munshidin) | anasheed.info singer pages (audio hosted on archive.org), scraped 2026-11-11; `tools/nasheeds_build.py` | only https archive.org links that answered 200; 47 dead links and 56 battle/war/militant titles and archive "jihad" collections left out; owner should listen-check for music |
| Al-Sha'rawi audio tafsir (1116 lessons, 667 h, surahs 1–60, 78–89, 96, 100–114 as recorded) | archive.org item `20240104_20240104_0645` ("خواطر الشيخ محمد متولي الشعراوي للقرأن الكريم", Public Domain Mark), metadata saved 2026-11-12 in content/sharawi/raw; `tools/sharawi_build.py` | streamed / downloaded per lesson, not bundled; ayah ranges from the file names (Saba (052_059) clamped to 54); owner confirmed the recordings are public (2026-11-12); source never shown in-app |
| Sheikh Mohamed Ahmed Shabib recitations (16 murattal, 70 mujawwad, ~44 h) | murattal: zekr.online author 6031, mushaf 5684 (`https://cdns1.zekr.online/quran/5684/{surah}/64.mp3`; partial ones per midad.com collection 457088); mujawwad: archive.org item `20240303` ("القارئ محمد احمد شبيب", Public Domain Mark); hand-checked list `content/shabib/shabib.src.json`, built by `tools/shabib_build.py` (2026-11-16) | streamed / downloaded per track, not bundled; no complete 114-surah recording exists anywhere (checked mp3quran, everyayah, archive.org, midad, zekr, alkabbah); Al-Ahzab murattal only behind expiring midad links, left out; files under 10 min, duplicates and files naming «أحمد شبيب» left out; owner rule 2026-11-12 (free audio is usable); source never shown in-app |
| Hadith simplified explanations | HadeethEnc (hadeethenc.com API, Arabic), 3,574 entries fetched 2026-11-11 into `content/hadith/hadeethenc-ar.json`; linked by `tools/hadith_explained.py` | quoted verbatim: title, explanation, benefits, grade, attribution |
| Prophets' stories videos | Sheikh Nabil Al-Awadi's lessons channel, playlist PLx0cDxpWtpY_65w9G0_SEA5TF3jhq_QaF | YouTube embed |
| Abdul Basit adhan / Fajr adhan | audio.islamweb.net audioid 88633 and 404627 | see apps/mobile/assets/audio/ADHAN_AUDIO.md |
| Reel channel suggestions | 21 verified YouTube channel ids, `assets/content/reel-suggestions.v1.json` | |

## Adhkar hadith links and tashkeel (v1.0.10, 2026-11-12)

| What | Source | Notes |
|---|---|---|
| Hadith, virtue and reference per morning/evening dhikr | Seen-Arabic/Morning-And-Evening-Adhkar-DB `ar.json`, commit 29d7623fede52eca835a789025dfda866e8cfe44 (`content/adhkar/seen-adhkar-ar.json`) | MIT; quoted verbatim; built by `tools/adhkar_hadith.py` |
| Hadith per Hisn al-Muslim item | HadeethEnc entries (`content/hadith/hadeethenc-ar.json`) matched to the dhikr text (4-gram overlap >= 0.6) | quoted verbatim: hadith text, attribution and grade |
| Tashkeel reference for adhkar and Hisn al-Muslim | the fully vowelled Hisn al-Muslim text (Sa'id ibn Wahf al-Qahtani) from the hisnmuslim.com API (`content/adhkar/hisnmuslim-audio-source.json`) | `tools/hisn_tashkeel.py` changes marks only, never letters; 266/298 Hisn items and 32/34 adhkar matched; intro and virtue prose with no counterpart keep their text. Change list: `content/adhkar/tashkeel-changes-2026-11-12.tsv` |

## Names of Allah lessons (v1.0.13, 2026-11-12)

| What | Source | Notes |
|---|---|---|
| Recorded lesson(s) on each name | Sheikh Muhammad Ratib al-Nabulsi's site nabulsi.com: series "أسماء الله الحسنى 2008" (`content/asma/nabulsi-2008.json`, 100 names x 2 parts) and, for names it lacks, "أسماء الله الحسنى 1996" (`content/asma/nabulsi-1996.json`) | streamed from the site's own audio host, not re-hosted; owner's choice 2026-11-12; `tools/asma_audio.py` maps 91 of the 99 names (the other 8 have no lesson in either series) |

## Ruqyah, kids section and the printed Mushaf look (1.2.14, 2026-11-20)

None of these source names are shown in the app or on the site (owner's rule). References in `content/kids/kids.json`, built by `tools/kids_build.py`.

| What | Source | Notes |
|---|---|---|
| Ruqyah: which Quran passages | Ibn Baz, Majmu' Fatawa wa Maqalat 6/368 (binbaz.org.sa fatwa 1694 «الدواء الشرعي للسحر»; same list in fatwa 2492) | Al-Fatiha, Ayat al-Kursi, al-A'raf 117–119, Yunus 79–82, Taha 65–69, al-Kafirun, al-Ikhlas, al-Falaq, an-Nas; text = KFGQPC v18 |
| Ruqyah: duas of the Sunnah | HadeethEnc ids 5542 and 5650 (`content/hadith/hadeethenc-ar.json`) | dua text copied by the tool (the quoted words of the hadith), never typed |
| Full ruqyah recording (Alafasy) | archive.org item `RuqyahAs-shariahBySheikhMisharyRashidAl-afasy` | streamed or saved for offline |
| Kids ruqyah | islamqa.info fatwa 104454 (Bukhari 3371, 5748, Tirmidhi 2058); dua = Hisn al-Muslim «ما يعوذ به الأولاد» (`content/adhkar/hisn.json` 49:0) with its existing recording | then al-Ikhlas, al-Falaq, an-Nas |
| Prophets' stories (25 cartoon episodes) | archive.org item `5-2_20210816` | ~250 MB each; streamed, listened or downloaded; owner should watch them |
| Stories of the Prophet ﷺ for kids (Sheikh Mahmoud al-Masri, 17 episodes) | archive.org items `qsas-elrasoul-ramdan2019-ep*` | streamed / downloaded |
| Short educational comics (13) | archive.org item `ramadan-stories-videos-ar` | hadith content in the comics not checked |
| Teaching Mushaf | everyayah.com `Minshawy_Teacher_128kbps` (children repeat) and `Husary_Muallim_128kbps` | per-ayah, surahs 1 and 78–114 |
| Printed Mushaf look | King Fahd Complex QCF v2 page fonts (static.qurancdn.com `fonts/quran/hafs/v2/{ttf,woff2}/p{page}`) with the per-word `code_v2` / `line_number` of api.quran.com v4 (`content/quran/printed/pages.json.gz`); `tools/mushaf_printed_build.py` | fonts downloaded per page on first view (or all at once in settings); every one of the 604 pages starts at the same ayah as the 1441H layout |
