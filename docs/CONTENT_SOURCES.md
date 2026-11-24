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
| Hajj/Umrah guide | Ibn Baz, «التحقيق والإيضاح لكثير من مسائل الحج والعمرة والزيارة» (Shamela book 31235, print page cited under every point); pillars and obligations = Ibn Baz fatwa binbaz.org.sa/fatwas/14833; parts of «دليل الحاج والمعتمر وزائر مسجد الرسول ﷺ» (Saudi Ministry of Islamic Affairs); hadith from the bundled Open-Hadith-Data books; duas from Hisn al-Muslim chapters 15, 117, 118, 121–123, 129; ayahs from KFGQPC v18. Built by `content/pilgrimage/build-guide.mjs` (references only, text cut verbatim) | quoted text with its reference | owner approved the source 2026-11-16; one sentence (women visiting graves, p. 91) left out at the owner's request | owner approved |
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
| Lesson series «سلاسل الدروس» (71 series, ~3100 lessons, ~2020 h; Al-Azhar, Egyptian and Saudi scholars) | archive.org items listed per series in `content/lessons/sources.json` (`Kitab_Tawhid_Saleh_Bin_Abdul_Aziz_Al-Cheikh_uP_bY_mUSLEm`, `doroos-mohimmah`, `Hoi-ALLAH_Mghamsi-mp3`, `hassantahiri28_gmail_41`, `jnnatalfirdos_gmail_29`, `Essirra_Al_Mohamadia`, `almolakhas-alfeqhy`, `ahmed_alkttawy_yahoo_6_201808`, `002_20210929`, `06Shar7KetabReyadhAlSal7een`, `Dr_Omar-Abdulkafy_Ahadith_9odosia_uP_bY_mUSLEm`, `Islamic_Tape-223_uP_bY_mUSLEm`, `Hearts_Deeds_uP_bY_mUSLEm`, `Hearts_Deeds-2_uP_bY_mUSLEm`, `aa_127_201608`, `Dr_Omar-Abdulkafy_Ajeib_Al_Koloub_uP_bY_mUSLEm`, `Al9alb_Essalim`, `Dr_Omar-Abdulkafy_Tarik_E-nour_uP_bY_mUSLEm`, `Islamic_Tape-600_uP_bY_mUSLEm`, `kono-rabbaneen`, `aa_123_20160715`, `Deen-qaeem_Omar-abdlkafee`, `Fawz-mobeen_Omar-abdlkafee`, `Islamic_Tape-222_uP_bY_mUSLEm`, `gzaly`, `Sahaba_uP_bY_mUSLEm`, `qesas-sahaba_munjid`, `Islamic_Tape-682_uP_bY_mUSLEm`, `Islamic_Tape-683_uP_bY_mUSLEm`, `Islamic_Tape-684_uP_bY_mUSLEm`, `qasass-quran_up-by-ayoub-islam`, `way2sona_20160322_2134`, `Ma3a-quran_Mghamsi-mp3`, `Islamic_Tape-895_uP_bY_mUSLEm`, `Al_Waad_Al_Haq-Up-By-MusleM`, `Awled_uP_bY_mUSLEm`, `al7oqoq_Omar-abdlkafee`, `Mohammad_Hassen_Azmt_Akhla9_up-by-muslem`, `Abdel-Kefi_uP_bY_mUSLEm`, `Afat-lissan_Omar-abdlkafee`, `baqli-adab`, `hayatona_munjid`, `31.-3-31`, `Selselat_ketab_a-ttahara__majmo3at_bologh_al-maram__ibn-othaimeen`, `2929MohamedHassan`, `Islamic_Tape-758_uP_bY_mUSLEm`, `Dr.omar-abdulkafy_Dar_Akhira_uP_bY_mUSLEm`, `feqh-moyasser-alaa-001-001` … `feqh-moyasser-alaa-007-007` (Sheikh Alaa Hamed, simple purity lessons from «الفقه الميسر»); added 2026-11-24 as clearer recordings beside old / quiet ones (owner): `Taysir_Wosool` (Sheikh Abdulmohsen al-Qasim, Three Principles; replaced Ibn Uthaymeen's old muffled tape of the same book, owner 2026-11-24), `06_20190906_201909` (Sheikh Abdulrazzaq al-Badr, Kitab al-Tawhid), `Shamael-Khudair` (Sheikh Abdulkarim al-Khudair, al-Shama'il), `boyo3_shbaili` (Sheikh Yusuf al-Shubaily, contemporary financial dealings), `01_20210717_20210717_0856` (Sheikh Atiyya Saqr, Hajj & Umrah fatwas), `M3a-Quran-3_Saleh-Mghamsi-mp3`, `Ma3a-Quran-6_Saleh-Mghamsi-mp3` (Sheikh Saleh al-Maghamsi, «مع القرآن» 3 and 6); Sheikh Mustafa al-Adawi, 8 series added 2026-11-24 (owner chose all but the short-fatwa set): `aa_211_20160824` (رسائل إيمانية), `Quran-tafssiroh-sunna_Mustafa-Adawi-mp3` (قرآن تفسره السنة), `tafseer_mostafa` (full tafsir, 571 lessons; 4 broken 1 KB uploads left out), `alaqida_mustafa_aladawy` (العقيدة), `ibn-khozaima_taweed` (Ibn Khuzaymah's Tawhid), `zizovolex_yahoo_007_201611` (السيرة النبوية), `mtn-abe-shojaa` (Matn Abi Shuja'), `islami-1474` (البحث الفقهي, 65 lessons: duplicates, cut-off copies and one other speaker's file left out via `keep`); Eng. Ayman Abdelrahim, 7 series added 2026-11-24 (owner: religious lessons only; his general courses — psychology, humanities, linguistics, «التأسيس المعرفي», «من هنا نبدأ», «بره الصندوق», «ما بعد السلفية» — and a mixed talks item were left out, new topics «الفكر والوعي الإسلامي» and «التاريخ الإسلامي»): `islami-2429` (تأسيس وعي المسلم المعاصر), `islami-2425` (السيرة النبوية: العهد المكي), `islami-2431` (الخلفاء الراشدون), `islami-2422` (الثلاثون جذرًا في القرآن; lesson titles written from the file names), `islami-2421` (البيت المسلم), `1_20220208_20220208_1628` (مدخل لدراسة التاريخ الإسلامي, ordered by the lecture ordinal), `Dawlatain_Ayman` (الدولة الأموية والعباسية; the 6-file `Amoy-Abbasy` item is unplayable text, not audio); quiet / muffled series are evened out while playing (gain + voice lift, `tools/lessons_loudness.py` → `content/lessons/audio-fx.json`; website and Android) and the Grand Imam's podcast music is skipped (`tools/lessons_music.py`), the recordings themselves unchanged); Grand Imam Ahmed al-Tayeb's official podcast feeds on Spreaker (artist «Ahmed Al Tayeb - أحمد الطيب»): shows 5523185 (Ramadan 2022, Names of Allah), 4998819 (2021, wasatiyya), 5055825 (2020), 5055842 (2019, women & family); Sha'rawi's seerah (`Prophetic_biography_by_Al_Shaarawy`) and prophets' stories (`Islamic_Tape-250_uP_bY_mUSLEm`) are shown inside his own section as its 2nd and 3rd parts (owner 2026-11-23), not in the lesson list; file lists cached 2026-11-23 in content/lessons/raw; `tools/lessons_build.py` | streamed / downloaded per lesson or whole series, not bundled; owner approved the list 2026-11-23 (freely downloadable audio, owner rule 2026-11-12); source never shown in-app |
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
| Kids ruqyah | islamqa.info fatwa 104454 (Bukhari 3371, 5748, Tirmidhi 2058); dua = Hisn al-Muslim «ما يعوذ به الأولاد» (`content/adhkar/hisn.json` 49:0) with its existing recording. Fuller list (owner 2026-11-21): islamweb.net fatwa 48991 «علاج ورقية المصاب بالعين» (for a child: al-Fatiha, Ayat al-Kursi, al-Ikhlas, al-Baqarah 285–286, al-Mu'awwidhatan) + Jibril's ruqyah «بِاسْمِ اللَّهِ أَرْقِيكَ…» Sahih Muslim 2186 (text copied by the tool from `content/hadith/dist/muslim` no. 4056) | Quran text = KFGQPC v18 |
| Prophets' stories (25 cartoon episodes) | archive.org item `5-2_20210816` | ~250 MB each; streamed, listened or downloaded; owner should watch them |
| Stories of the Prophet ﷺ for kids (Sheikh Mahmoud al-Masri, 17 episodes) | archive.org items `qsas-elrasoul-ramdan2019-ep*` | streamed / downloaded |
| Episode titles of «قصص الرسول ﷺ للأطفال» (2026-11-20) | 7, 8, 12–17: Al-Rahma TV programme page alrahma.tv/programs/64 (the broadcaster); 10, 11: archive.org item titles; 1–6, 9: the story the sheikh names at the start of each episode | titles only, no text of ours |
| Kids: modern prophets' stories videos (2026-11-20) | Published YouTube channels «Broccole - بروكلي» (8 episodes) and «Kids Zone» (5 episodes), played in the official youtube-nocookie embed | each episode checked frame by frame (storyboards): kept only where the prophet appears as light or from behind with no face; dropped Broccole Noah, Hud, Salih, Yunus, Ayyub, Dawud, 3× Yusuf, Isa; Kids Zone Yusuf, Ibrahim, Musa (owner picked both series 2026-11-20) |
| Short educational comics (13) | archive.org item `ramadan-stories-videos-ar` | hadith content in the comics not checked |
| Teaching Mushaf | everyayah.com `Minshawy_Teacher_128kbps` (children repeat) and `Husary_Muallim_128kbps` | per-ayah, surahs 1 and 78–114 |
| Interactive teaching Mushaf (2026-11-20) | Quran.com API `api/qdc/audio/reciters/{12,168}/audio_files?chapter=S&segments=true` (ayah + word timings), surah files on download.quranicaudio.com/qdc (Husary Muallim, Minshawi kids_repeat); tap-a-word audio audio.qurancdn.com/wbw/SSS_AAA_WWW.mp3; built by `tools/kids_teacher_timings.py` into `content/kids/dist/teacher-timings.v1.json` | streamed; word positions match KFGQPC v18 words except the «۞» token (mapped); one missing ayah bound (Minshawi 101:3) filled from its neighbours |
| Printed Mushaf look | King Fahd Complex QCF v2 page fonts (static.qurancdn.com `fonts/quran/hafs/v2/{ttf,woff2}/p{page}`) with the per-word `code_v2` / `line_number` of api.quran.com v4 (`content/quran/printed/pages.json.gz`); `tools/mushaf_printed_build.py` | fonts downloaded per page on first view (or all at once in settings); every one of the 604 pages starts at the same ayah as the 1441H layout |

## Kids learning corner: book shelf, «احفظ حديث», adhkar cards, wudu / salah steps (2026-11-20)

All from saaid.org «مكتبة الطفل» (`https://saaid.org/book/list.php?cat=106`, PDF of each book via `open.php?book=ID`). The site shows no terms of use; each book belongs to its author / publisher (owner's rule: openly published books may be used; no source names in the app, except the wudu/salah book whose own terms ask to be named). Data: `content/kids/learn/`, built by `tools/kids_learn_build.py`; PDF helpers in `tools/kids_hadith600/`.

| What | Source | Notes |
|---|---|---|
| «احفظ حديث» (600 hadith, 4 levels) | saaid book 19945 «600 حديث للحفظ للأطفال متدرجة حسب الطول ومقسمة إلى أربعة مستويات بالألوان», د. هاني الشيخ جمعة سهل | text taken from the PDF text layer (ToUnicode fixed, visual order fixed, NFC), never typed; levels 1–200 / 201–350 / 351–500 / 501–600 as in the book. The author's introduction asks to be contacted before use in apps: owner told 2026-11-20 |
| Adhkar cards | saaid book 19621 «بطاقات الأذكار للناشئة (بنين)», محب الدين علي بن تقي المصري (19622 بنات has the same text) | since 2026-11-21 shown as TEXT with a counter: copied from the book's PDF text layer (tools/kids_cards/extract_cards.py); card 14's three surahs come from the app's Hisn al-Muslim adhkar |
| Wudu and salah steps | saaid book 10436 «هيا نتعلم الوضوء والصلاة», سلسلة العلامتين | since 2026-11-21: each step's title and text copied from book pages 6–16 (wudu) and 18–31 (salah) (content/kids/learn/steps.json), with OUR OWN 3D pictures (tools/kids_steps_3d/, three.js; faceless child) instead of the book's drawings; Ayat al-Kursi on page 31 from the app's adhkar (KFGQPC wording). The book allows free use when named, so the app/site shows «النص من كتاب «هيا نتعلم الوضوء والصلاة» – سلسلة العلامتين» |
| Book shelf (43 books) | saaid books listed below | each page rendered to webp from the PDF (1000 px), hosted at `rattilwasalli.com/kids-books/<id>/<page>.webp`; covers bundled in the app and site; the app saves a book for offline reading on request |

Shelf books (saaid id, title, author):

- 17385 «الأذكار لأطفالنا الصغار», أبو حازم الأثري (adhkar)
- 14439 «حصن الطفل المسلم», روض الذهور الصيفي (adhkar)
- 15340 «العطر الفواح في أذكارالصباح», طالب علم (adhkar)
- 19866 «الأدعية والأذكار للطفل المسلم سؤال وجواب (حصن طفلك)», يزن الغانم (adhkar)
- 16856 «حصن الطفل المسلم سؤال وجواب», يزن الغانم (adhkar)
- 17307 «عقيدة الطفل المسلم للأطفال من عمر 3-6 سنوات», أبو حازم الأثري (aqeedah)
- 17346 «عقيدة الطفل المسلم», خالد بن سعود البليهد (aqeedah)
- 10734 «عقيدة الطفل المسلم», راجية الرحمن أم عمر (aqeedah)
- 10435 «مختصر العقيدة الإسلامية من الكتاب والسنة», محمد بن جميل زينو (aqeedah)
- 18054 «تعليم الصغار توحيد الغفار (نظام مختصر في اثنين وثلاثين بيتا)», محمد بن عبدالسلام بن علي (aqeedah)
- 16849 «ما لا يسع أطفال المسلمين جهله», يزن الغانم (aqeedah)
- 19779 «تربية أطفال المسلمين بمعاني أسماء الله الحميد», يزن الغانم (aqeedah)
- 16857 «أخلاق الطفل المسلم سؤال وجواب», يزن الغانم (akhlaq)
- 4943 «الآداب الإسلامية للناشئة», محمد خير فاطمة (akhlaq)
- 14822 «علمني رسول الله صلى الله عليه وسلم», موقع بطاقات (akhlaq)
- 19504 «زاد المسلم الصغير», عبدالشكور معلم (akhlaq)
- 10436 «هيا نتعلم الوضوء والصلاة», موقع سلسلة العلامتين (fiqh)
- 13437 «مختصر البيان في طهارة وصلاة الفتيان», محمد رفيق مؤمن الشوبكي (fiqh)
- 19654 «تفسير سورة القدر للأطفال», د.فاطمة عمر نصيف (quran)
- 19945 «600 حديث للحفظ للأطفال متدرجة حسب الطول ومقسمة إلى أربعة مستويات بالألوان», د.هاني الشيخ جمعة سهل (quran)
- 10601 «نور البيان في معلم القراءة بالقرآن (كتاب منهجي لأطفال الحضانة ، ودور نحفيظ القرآن )», راجي رحمة الغفور (quran)
- 13839 «الطريقة المثالية لتعليم القراءة العربية», بكر موسى هارون (quran)
- 17821 «الحروف الهجائية المنقطة بالتشكيل المستوى الثاني», بكار فيصل المنفي (quran)
- 10123 «قصص الصحابة1 : الغلام الذي اختار الجنة», سلوى العناني (stories)
- 10124 «قصص الصحابة2 : صوت من السماء», سلوى العناني (stories)
- 12884 «رجال ونساء حول الرسول صلى الله عليه وسلم للأطفال», سيد مبارك (stories)
- 10986 «سلسلة السيرة النبوية للأطفال», سيد مبارك (stories)
- 11033 «معجزات الرسول للأطفال», سيد مبارك (stories)
- 13041 «قصة فتي من قريش (قصص إسلامية للأطفال)», سيد مبارك (stories)
- 20387 «صور مشرقة من حياة الأطفال», السيد مراد سلامة (stories)
- 19603 «تربية أطفال المسلمين بسير الأئمة الصالحين المصلحين (رضي الله عنهم أجمعين)», يزن الغانم (stories)
- 19604 «تربية بنات المسلمين بسير خير نساء العالمين», يزن الغانم (stories)
- 19605 «تربية أطفال المسلمين بسيرة أصحاب سيد الأنبياء والمرسلين (رضي الله عنهم أجمعين)», يزن الغانم (stories)
- 19606 «تربية أطفال المسلمين بقصص الأنبياء والمرسلين (عليه السلام)», يزن الغانم (stories)
- 19607 «تربية أطفال المسلمين بسيرة سيد الأنبياء والمرسلين (صلى الله عليه وسلم)», يزن الغانم (stories)
- 15108 «للأطفال - مفكرتي (شهر رمضان)», آيات (ramadan)
- 14700 «رفقا بعقيدتي يا أمي (دليل إرشادي لغرس الإيمان في قلوب الأبناء بدءًا من الحمل إلى البلوغ)», أم عبد الرحمن سوزان بنت مصطفى بخيت (parents)
- 12897 «من قصص القرآن للأطفال», سيد مبارك (stories); the book says «حقوق الطبع محفوظة»: added on the owner's decision 2026-11-20
- 12937 «سلسلة قصص الأنبياء للفتيان والفتيات», سيد مبارك (stories); the book says «حقوق الطبع محفوظة»: added on the owner's decision 2026-11-20
- 13047 «سلسلة العشرة المبشرون بالجنة للفتيان والفتيات», سيد مبارك (stories); the book says «حقوق الطبع محفوظة»: added on the owner's decision 2026-11-20
- 13048 «سلسلة زوجات الرسول صلى الله عليه وسلم», سيد مبارك (stories); the book says «حقوق الطبع محفوظة»: added on the owner's decision 2026-11-20
- 14698 «منهاج الطفل المسلم في المسجد والمدرسة والبيت», د. إبراهيم عبدالرحمن العاني (akhlaq); the book says «حقوق الطبع محفوظة»: added on the owner's decision 2026-11-20
- 16872 «حصن المسلم للأطفال», بدر الفيلكاوي (adhkar); the book says «حقوق الطبع محفوظة»: added on the owner's decision 2026-11-20

## Tafsir books, i'rab and word meanings (listed here 2026-11-20)

| What | Source | Notes |
|---|---|---|
| Tafsir al-Sa'di, Ibn Kathir, al-Tabari, al-Baghawi | Quranpedia.net open-data dumps (book ids 3, 136, 4, 2), built by `tools/tafsir_books.py` into `content/tafsir/dist/*.v1.json.gz` | words kept exactly as published; only HTML removed and editor footnotes moved to `notes`; licence `content/tafsir/upstream/QURANPEDIA-LICENSE.md` (use inside apps/sites allowed) |
| Tafsir al-Qurtubi | public GitHub repository spa5k/tafsir_api (MIT, `content/tafsir/upstream/qurtubi/LICENSE-spa5k-tafsir_api.txt`) | plain text per ayah, verbatim |
| I'rab, sarf, balagha and fawa'id per ayah | «الجدول في إعراب القرآن وصرفه وبيانه», Mahmud Safi, from spa5k/tafsir_api folder `tafsir/al-jadwal-fi-i-rab-al-quran` (MIT); `tools/irab_build.py` → `content/irab/dist/jadwal.v1.json.gz` | verbatim, only blank lines collapsed |
| Word meanings (gharib, 6104 words) | «السراج في بيان غريب القرآن», Dr Muhammad ibn Abd al-Aziz al-Khudairi (1st ed. 1429H), Quranpedia dump `meanings.json.gz` (book 491); `tools/word_meanings.py` → `content/word-meanings/dist/siraj.v1.json` | Quranpedia licence allows in-app use; the contemporary book stays its author's property |
| Dhikr reminder sounds | clips of the bundled Alafasy morning adhkar recording (audio.islamweb.net 146980), cut by `tools/dhikr_reminder_clips.py` | nothing added |

A full Arabic list for the owner is kept in `E:\Quaran-App-Project\reports\قائمة-مصادر-رتل-وصل-<date>.md/.docx`; update it with every new source.
