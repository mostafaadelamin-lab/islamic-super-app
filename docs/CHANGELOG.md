# Changelog

## [1.0.7] — Nearby mosques: OpenStreetMap list, tap opens Google Maps (owner's decision) — 2026-11-11
### Changed
- Owner dropped Google Places (cost). The list comes from OpenStreetMap again (no key); tapping a mosque opens it in Google Maps. The Places code stays dormant (only used if a build passes GOOGLE_PLACES_KEY); the map-app chooser was removed.
- Faster search: the first two Overpass servers are asked at the same time (12 s limit), then the other three plus Nominatim together, instead of one by one with 25 s each (the screen could sit on "searching" for minutes).

## [1.0.6] — Nearby mosques: list inside the app, choose the maps app (owner's request) — 2026-11-11
### Changed
- Nearby mosques are a list again (name + distance, nearest first), from Google Places "Nearby Search (New)" when the build has a key (`--dart-define=GOOGLE_PLACES_KEY=…`, owner's Google Cloud project), else OpenStreetMap (credit line shown only then).
- Tapping a mosque opens a sheet: Google Maps directions, Waze, or another maps app (Android system chooser via MethodChannel `org.rattil.app/maps`; Apple Maps on iOS).

## [1.0.5] — Nearby mosques from Google Maps inside the app (owner's request) — 2026-11-11
### Changed
- Nearby mosques: Google Maps' mosque search around the phone's position is shown inside the app (WebView, no API key), zoomed to the 2/5/10 km choice; Google links stay in the view, anything else opens outside. The OpenStreetMap list and its attribution were removed from the screen.

## [1.0.4] — Area name and compass calibration (owner's feedback) — 2026-11-11
### Fixed
- Home place line: the area is now looked up at district level first (a compound or town such as Madinaty, then suburbs), with the street-level answer used to reject a nearby village; BigDataCloud's free client geocoder is a fallback when OpenStreetMap is unreachable. Names saved by the old rules are looked up again; a failed lookup is retried on the next start.
### Added
- Qibla: a "calibrate the compass" card (figure-8) when Android reports the magnetometer as unreliable/low or the heading error is over 25°; the current accuracy (± degrees); a link to Google's Qibla Finder to check the direction on a map. iOS sends its heading accuracy too.

## [1.0.3] — Bottom bar order, offline adhkar audio (owner's request) — 2026-11-11
### Changed
- Bottom bar: Home, Quran, Prayer, Adhkar, Videos, More (the reels tab is now called "Videos").
### Added
- Sheikh Mishary Alafasy's morning and evening adhkar ship inside the app (`assets/audio/adhkar_*_alafasy.mp3`) and play offline with pause and seek. After-prayer and sleep adhkar still play from his official channel.

## [1.0.2] — Nasheeds and adhkar audio (owner's request) — 2026-11-10
### Added
- More → Nasheeds: voice-only nasheeds by the munshidin the owner approved. Egypt: Mohamed Tarek, Mohamed Youssef, Sheikh Nasr el-Din Tobar, Sheikh Sayed al-Naqshbandi. Arab world: Mishary Alafasy, Ahmed Bukhatir, Abu Ali (Mosa Alomairah), Muhammad Al Muqit. They play from each artist's official YouTube channel (or the label's official/Topic channel) through YouTube's embedded player; nothing is copied or downloaded. The list is in `lib/domain/nasheeds.dart`.
- Adhkar audio in Sheikh Mishary Rashid Alafasy's voice (morning, evening, after prayer, sleep) from his official channel, from the Adhkar tab and the morning/evening list.
- Any Quran recitation or story that is playing pauses when a nasheed or adhkar recording opens.

## [Unreleased] — Owner's feedback round (mobile) — 2026-11-10
### Changed
- Bottom bar: Home, Quran, Reels, Prayer, Adhkar, More. Reels play with sound.
- Home shows "country - area" from the phone's location (detected automatically on start; can be turned off).
- Mushaf: tapping an ayah opens a list of 7 actions (listen to the ayah, with tafsir, to the end of the page, to the end of the surah, save a mark, copy, share as image). "Read ayah by ayah" removed; surah links open the Mushaf page.
- Adhkar: a list (morning, evening, sleep, prayer, and dua categories) with a round counter under each dhikr.
- Prayer times: compact screen; "Edit prayer times" holds the city, method, location services, adhan alerts and muezzin, adjustments and qibla.
- Tasbih: new design. Zakat: simpler layout with the result on top. Hadith books: read as a page-turning book, no review notice.
- Hajj/Umrah: a drawing for every step. Prophets' stories: every episode shown, story-verses section removed, episodes can be saved offline.
- More: Hadith, Names of Allah, Quran radios, Recitations library, Stories, Qibla, Mosques, Zakat, Hajj; bookmarks, Quran search, khatma, downloads, Hisn al-Muslim, duplicate tasbih and worship tracking removed from the menu.
- Qibla: steady heading when the phone is held upright; button to re-read the location the bearing uses.
- Nearby mosques: more servers plus an OpenStreetMap fallback, names shown, each opens in Google Maps.
- Muezzins: openly licensed Wikimedia Commons recordings (Makkah, Madinah, Sabah Fakhri, Fajr); islamweb recordings removed. Adhan settings always visible.
- About: free app made for the sake of Allah, no charge and no ads.
### Added
- Names of Allah with al-Sa'di's explanation; Quran radios screen (Mushaf radio, Egyptian and Saudi Quran radios, others); offline download in the recitations library.

## [Unreleased] — Store publishing setup: Codemagic, signing, listing, privacy (owner's request) — 2026-11-10
### Added
- `codemagic.yaml`: manual workflows only. iOS builds, signs (App Store Connect API key, certificate and profile created on the first run) and uploads to TestFlight without any beta review or App Store submission. Android builds a signed `.aab` for the first manual Play upload, and a second workflow uploads to the Play internal-testing track as a draft. No Mac needed.
- Android release builds sign with the Play upload key when Codemagic provides it (`CM_KEYSTORE_*`); local builds keep the debug key.
- `docs/store/`: owner's step-by-step guide (STORE_RELEASE.md), Arabic/English store listing drafts with category, age rating and privacy answers (LISTING.md), bilingual privacy policy page (privacy-policy.html).
- iOS: `ITSAppUsesNonExemptEncryption = false` (no export-compliance question per upload), motion and location purpose strings (qibla compass, nearby mosques).
### Changed
- Store builds (`--dart-define=RATTIL_STORE=true`) hide Settings → Account sync until the sync server is hosted.

## [Unreleased] — Quran text from the King Fahd Complex, release 18 (owner's request) — 2026-11-10
### Changed
- The Mushaf text is now the King Fahd Glorious Quran Printing Complex's latest published data, Hafs v18 (`hafsData_v18.json`), exactly as published. No letter, dot or haraka changed compared with the previous text (only the Unicode encoding).
- Pages and lines follow the Complex's new Madinah edition (1441H); checked ayah by ayah against the Complex's page and line columns.
- The Quran is drawn with the Complex's own font (KFGQPC HAFS Uthmanic Script v18) on web and mobile; ayah numbers use the Complex's ornament. Amiri Quran removed.
- Quran content version 2.0.0, pages 1441H-1.
### Checked
- Tafsir al-Muyassar: one entry per ayah, aligned (6236). Recitation audio: addressed by surah/ayah, page playlists follow the new pages.

## [Unreleased] — Recitations library and Quran radios from mp3quran.net (owner's feature list, phase 7) — 2026-11-10
### Added
- Recitations and radios (mobile: More → Recitations and radios; web: /library/): reciters from mp3quran.net in every riwaya (Hafs, Warsh, Qalun, ad-Duri, ...), filter by riwaya, search by name, choose a recording, then play any surah it has.
- Quran radios (live streams), with search.
- Streams through the narration player (mobile) or a native player (web) with the sleep timer; starting one stops the recitation player.
- The list is saved on the device for a week, so it opens without the internet (playing still needs it). The source site is not named in the app (owner's decision); it is recorded in CONTENT_SOURCES.md.

## [Unreleased] — Hadith books from Open-Hadith-Data (owner's feature list, phase 7) — 2026-11-10
### Added
- The nine hadith books (al-Bukhari, Muslim, Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah, Malik's Muwatta, Ahmad's Musnad, ad-Darimi) with their Arabic text unchanged, al-Alamiyya numbering (mobile: More → Hadith books; web: /hadith/).
- Read 20 hadiths at a time, jump to a number, search a whole book ignoring diacritics, save hadiths, copy, share and report a mistake.
- Mobile: the books are bundled and work offline. Web: each part is fetched when first opened and then kept for offline use.
- Source and licence (ODbL) shown on the hadith page; a "pending shar'i review" notice on every screen.
### Not yet
- Chapters (the source has none), the commentary column, and the other books (Riyad as-Salihin, Nawawi's 40, etc.) until an open source is found.

## [Unreleased] — Muezzin collection and a separate Fajr adhan — 2026-11-10
### Added
- Default adhan is now the Makkah Haram adhan (Mohamed Ramadan Saad); Fajr has its own adhan with "as-salatu khayrun min an-nawm" (Makkah Haram Fajr, Hamad Al-Daghriri). Both bundled, work offline. iPhone notification sound = first 28 s of the Haram adhan.
- Muezzin list (~290 recordings, 38 Fajr) with search, on mobile (Settings → Muezzin / Fajr muezzin) and the website (prayer page). On the phone a muezzin is downloaded when tapped and kept offline; the Android alarm plays the downloaded file. The website streams it.
- The Fajr alarm/alert uses the Fajr muezzin; the other prayers use the regular one.
### Note
- Recordings taken from a site whose terms forbid republishing without written permission; used by the owner's decision (see apps/mobile/assets/audio/ADHAN_AUDIO.md). The site's name is not shown in the app.

## [Unreleased] — App icon and one icon set in the app's design — 2026-11-10
### Changed
- New Rattil app icon (our own design): a gold mihrab arch with an eight-pointed star over an open Mushaf on a rehal, on the emerald background. Android (adaptive icon, round icon, Android 13 themed/monochrome icon), iPhone/iPad (all sizes, opaque as the App Store requires) and the website (favicon, PWA icons incl. maskable, Apple touch icon). Replaces the default Flutter logo in the app and the old blue moon icon of the website.
- One shared icon set for the app and the website (packages/design-tokens/icons.json, 80 line icons, 24×24, stroke 1.8, round ends): the mobile app now draws the same icons as the website (new RIcon widget) instead of mixed filled/outlined Material icons. Bottom bar, home tiles, More list (icons on a soft emerald square like the website's tiles), prayer times, reader, players, settings, khatma, adhkar, qibla, mosques, reels and stories.
- Same icon per section on both: Adhkar = raised hands, Prayer = mosque, Hisn al-Muslim = shield with a book (was the Quran book), Qibla = compass, Hajj = Kaaba, Zakat = coins, Tasbih = prayer beads.
- Android notifications (adhan, reminders) use a white Rattil mark in the status bar instead of the app icon square; launch screen on emerald with the gold mark (Android, Android 12+ splash, iPhone).
### How to change icons
- Edit packages/design-tokens/icons.json, run `python3 packages/design-tokens/scripts/build.py` and `apps/mobile/tool/sync_assets.sh`; app icon: edit packages/design-tokens/app-icon/*.svg, then `cd apps/web && node scripts/make-icons.mjs && python3 ../../tools/flatten_ios_icons.py`.

## [Unreleased] — Zakat calculator after Egypt's Dar al-Ifta (owner's feature list, phase 6) — 2026-11-10
### Added
- Zakat calculator (mobile: More → Zakat calculator; web: /zakat/): cash and bank balances, bank certificates and their returns, saved shares, trade goods, gold kept for saving (24, 21 or 18 karat) and debts due. Nisab = the value of 85 g of 21-karat gold at the price the user enters; 2.5% once a full Hijri year has passed.
- Every rule shows the fatwa's own words with a link to it on dar-alifta.org; gold worn for adornment shows fatwa 8848 instead of a field.
- A visible "pending shar'i review" notice. The numbers stay on the device.
### Not yet
- Apple Watch: parked (no Mac or Apple developer account).

## [Unreleased] — iPad and tablet layout (owner's feature list, phase 8) — 2026-11-10
### Added
- Mobile on iPad, Android tablets and wide landscape screens: a side navigation rail (on the right in Arabic, with labels from 840 pt wide) instead of the bottom bar, and the mini player under the content.
- Lists and reading screens keep a comfortable reading width (720 pt) centred on the screen; home and the tabs up to 960 pt.
- The Mushaf page keeps the printed page's proportions on a tablet instead of stretching to the full width.
- Tests on iPad sizes (834×1194, 1194×834, 1366×1024) in Arabic and English, plus iPad screenshots.
### Checked
- Website at iPad portrait and landscape: no sideways scrolling, two-column home, Mushaf page fits the height.
### Not yet
- Apple Watch: needs a Mac with Xcode and an Apple developer account to build and test.
## [Unreleased] — Nearest mosque fix, new qibla design, muezzin choice — 2026-11-10
### Fixed
- Nearby mosques searched around the centre of the prayer-times city, so the "nearest" mosque could be kilometres away. They now search around the phone's own position (GPS, with the last known position as a fallback), and only use the city when location is off (with a note). New "Update my location" button.
- Mosques drawn on OpenStreetMap only as a building ("building=mosque") are now included, without duplicates; a third free Overpass server and a 15 s limit per server.
### Changed
- Qibla compass redesigned (mobile and website): emerald and gold dial, Kaaba mark, eight-pointed star, the phone's pointer, gold glow and a light vibration (mobile) when facing the qibla, distance to the Kaaba.
### Added
- Choice of muezzin for the adhan (mobile Settings and website adhan settings), with a listen button per voice. Voice 2: CC BY-SA 4.0 recording from Wikimedia Commons (credited). On Android the full adhan alarm plays the chosen voice; the iPhone notification keeps the short opening takbir of voice 1.
### Not yet
- More voices (licences checked, see ADHAN_AUDIO.md): Wikimedia blocked the downloads for now.
- Religious listen-through of each voice: pending.

## [Unreleased] — Adhkar, help and sharing (owner's feature list, phases 5–6) — 2026-11-10
### Added
- Hisn al-Muslim sections (remembrance, morning and evening, sleep, prayer, home, food, travel, hardship, illness, nature, people, hajj): a grouping of the existing chapters, no text added or changed.
- Adhkar and Hisn al-Muslim as a list or one card at a time; in cards the morning / evening adhkar move on by themselves when a dhikr's count is complete.
- Share any dhikr (text unchanged, with its source) and "Report a mistake" (opens email / the share sheet with the chapter, number and the first words).
- Morning and evening adhkar reminders at a chosen time (mobile notifications ids 2002 / 2003; web while a page is open).
- Help & contact: frequently asked questions, contact (address pending from the owner), share the app, rate (once the store links are set in packages/shared-schemas/app-links.json).
- A one-time "Share Rattil?" suggestion after the app has been used on five different days.
- Home-screen shortcuts: Quran, prayer times, adhkar and tasbih (Android / iOS long-press; installed web app).
### Not yet
- Zakat calculator: waits for the owner to choose the published reference, then a shar'i review.
- Fadl notes and dhikr audio: need a licensed published source.

## [Unreleased] — Reader and player: speed, lock screen, offline, share as image (owner's feature list, phase 4) — 2026-11-09
### Added
- Playback speed 0.75× to 2× (mobile mini player; web player bar, Mushaf player and Settings), kept between sessions.
- Lock-screen / notification controls (play, pause, next and previous ayah, stop) showing the surah, ayah and reciter. Mobile (audio_service) also keeps reciting with the screen off on Android; web uses the browser's Media Session.
- Listen offline: save whole surahs of the chosen reciter (basmala included) and delete them again; saved surahs play without a connection. Mobile: More → Downloads. Web: Settings → Listen offline (Cache Storage, served by the service worker).
- Share an ayah as an image: a card in the Rattil colours with the ayah text unchanged, its reference and the app name. Mobile opens a preview then the share sheet; web uses the share sheet where the browser can share files and downloads the PNG otherwise.
### Fixed
- Web worship calendar: removed partial grid roles that screen readers could not use (axe).

## [Unreleased] — Prayer alarms, Quran khatma and tasbih (owner's feature list, phases 1–3) — 2026-11-09
### Added
- Prayer times: move between days (previous / next / today) with the Hijri date; 12 or 24 hour clock; "use my location" (GPS, coarse) with the nearest city's time zone and method; monthly prayer calendar with a Gregorian / Hijri month toggle that follows the Hijri adjustment, shared as an image (mobile) or printed / saved as PDF (web).
- Prayer alerts (mobile notifications; web while a page is open): a reminder 5–30 minutes before the adhan, an iqama alert with minutes per prayer, alerts at sunrise and at the start of the last third of the night, a Friday reminder (Surat al-Kahf) at a chosen time, and a sound per prayer (adhan, short tone or silent). Reminders never use the adhan recording.
- Home: "N min since the X adhan" during the first half hour after each adhan.
- Quran khatma (mobile + web): plan by number of days or pages per day, today's portion with its pages and opening words, mark as read, ahead / behind the plan, reschedule the rest over the remaining days, rename, daily reminder, and a history of finished khatmas.
- Tasbih on the web: a separate counter, target and rounds for each dhikr, a beads mode, nine colours, optional click sound and vibration, the user's own adhkar (up to 20), and a 60-day history that can be cleared.
### Notes
- Mobile reminders (khatma, Friday, later adhkar) share the iOS 64-notification budget with the adhan plan.

## [Unreleased] — Owner's reference guidelines: audit and fixes — 2026-11-09
See docs/reports/GUIDELINES_AUDIT.md.
### Added
- Hijri date: manual adjustment of the Umm al-Qura date (−2..+2 days) in Settings on mobile and web, with a live preview, so the date can follow the moon sighting announced locally. Used everywhere a Hijri date is shown.
- Qibla compass (mobile): reads the phone's own compass heading (iOS CLLocationManager, Android rotation-vector sensor) and falls back to the raw accelerometer + magnetometer. Mobile and web now correct magnetic north to true north with the World Magnetic Model 2025 (Cairo ≈ +4.8°, New York ≈ −12.5°); before this the needle could be off by the local declination.
- Android: the adhan plays in full at prayer time through an exact AlarmManager alarm and a media-playback foreground service (Stop button, stops on a phone call, notification only on silent/vibrate, alarms restored after reboot / update / clock change). Tone and silent alerts are unchanged.
- Nearby mosques (owner chose OpenStreetMap, 2026-11-09): mobile (More → Nearby mosques) and web (/mosques, also on the More page). Mosques tagged in OpenStreetMap within 2 / 5 / 10 km of the prayer-times location, nearest first, with distance; the last list is kept for offline use. Mobile opens directions in the phone's maps app; web links to openstreetmap.org and can use the browser's current location. Free Overpass API servers (overpass-api.de, then overpass.kumi.systems); "© OpenStreetMap contributors" shown as the ODbL requires.
### Fixed (re-applied from the religious content review of 2026-11-07, which was lost with the GitHub suspension)
- Umm al-Qura method: Isha is 120 min after Maghrib during Ramadan (90 min otherwise), on server, web and mobile. Ramadan dates come from the Umm al-Qura calendar table in methods.json (1440–1499 AH).
- Web adhkar: the last two verses of al-Baqarah are in the evening list only (as on mobile).
## [Unreleased] — Reels pick themselves from trusted channels — 2026-11-09
### Added
- The app now fills the reels by itself (owner decision 2026-11-09): it pulls the newest Shorts of trusted Islamic YouTube channels the owner approved once (`content/reels/sources.json`, first channel: Sheikh Yasser Al-Dosari), mixes the channels and shows them before the hand-picked reels. No per-video review; each such reel shows a "Trusted channel" chip.
- "Hide this channel" on every automatic reel (with undo, and "Show hidden channels" in the empty state).
- Mobile reads YouTube's public feeds directly (no key or account), caches 3 hours and works offline from the cache. Website: through the new API endpoint `GET /v1/reels/feed` (needs the API hosted).
- `tools/reels.py sources-add / sources-remove` to manage the trusted channels.
### Unchanged
- Instagram stays hand-picked (owner's choice: automatic YouTube now). Hand-picked reels keep the pending / approved / rejected review.

## [Unreleased] — Reels: Instagram + admonitions — 2026-11-09
### Added
- Reels now accept Instagram as well as YouTube (owner decision 2026-11-09). Instagram reels play through Instagram's official embed page (no Meta app, token or account); they need a tap to play.
- Third reels category "advice and admonitions" (نصائح ومواعظ). Categories are now: Quran recitation, religious lesson, advice and admonitions.
- Reels show a platform chip (YouTube / Instagram) and an "Open on YouTube / Instagram" button; Instagram reels show a placeholder instead of a poster off-screen.
- Mobile: only the official embed pages may load inside the feed; any other link opens the YouTube/Instagram app or the browser.
### Unchanged
- Religious review gate (pending / approved / rejected): users still see approved reels only.

## [Unreleased] — Mushaf reader redesign + listen with tafsir — 2026-11-09
### Changed
- Mushaf page reader redesigned on the website and the mobile app after the owner's mockup (layout only; our own icons and ornaments): tabs Mushaf / Ayat / Tafsir at the top, an ornate surah band, a floating recitation card (reciter drop-down, previous / play-pause / next, repeat count, "Listen with tafsir"), a page slider and a bottom bar (Index, Bookmarks, Khatma, Search). On phones the reader is full-screen.
### Added
- Tap any ayah: "Play this ayah", "Play from here", "Listen with tafsir", play the surah, bookmark, copy, and its Tafsir al-Muyassar entry.
- "Listen with tafsir": the screen splits in two — the ayah being recited (highlighted) and its Tafsir al-Muyassar entry (KFGQPC, verbatim) — following the recitation ayah by ayah and across page turns; side by side on wide screens. "Show page" turns it off.
- Ayat tab (the page's ayahs one by one, large) and Tafsir tab (each ayah followed by its tafsir, with a font-size button); tapping an ayah in either plays it.
- Khatma tracker: start a khatma, pages read are marked after 4 s on a page, progress and "continue".
- Integration build: this release merges the new home page, the Quran index and the Mushaf reader (branch integration/reader-home-index).

## [Unreleased] — New home page (owner's mockup) — 2026-11-09
### Changed
- Home page redesigned on the website and the mobile app after the owner's mockup: place ("Egypt - Cairo") with a settings button; mosque drawing; next prayer name, its time in large digits and a live countdown; a day card with the weekday, Gregorian and Hijri dates, a "Prayer calendar" button, the five prayers with icons (next one highlighted) and sunrise / sunset; big tiles for the Quran, Adhkar & Dua and Prayer times; wide tiles for Tasbih, Qibla, Islamic reels and Prophets' stories; "Main sections" opens the full list.
- Sunset is shown without the user's Maghrib adjustment. After Isha the card shows tomorrow's day and times.
- "Continue reading" moved off the home page: it stays on the Quran page (web) and the Bookmarks screen (mobile). Hajj, Hisn al-Muslim, search and bookmarks are under "Main sections".
### Added
- Quran radio on the home page: continuous recitation of the whole Mushaf by the chosen reciter, starting from a random surah and wrapping round, with a play duration (unlimited, 15, 30, 45 or 60 minutes) that stops it through the sleep timer. Streams per ayah from everyayah.com, like the rest of the recitation.

## [Unreleased] — Quran index: surahs and quarters — 2026-11-09
### Added
- New Quran index ("فهرس السور") on the Quran tab (mobile) and /quran (web): a Surahs / Quarters toggle, a search box with a clear button, and lists grouped under juz headers (الجزء الأول، الثاني …).
- Surahs: star badge with the number, "سورة …", and "الصفحة X - آياتها N - مكية/مدنية". Tapping opens the Mushaf at that page; a small list icon still opens the text (list) view.
- Quarters: the 240 hizb quarters with badge 1, 1/4, 2/4, 3/4, 2 …, the opening words of the quarter in Uthmani script (taken unchanged from the canonical text), and "سورة X: ayah - الصفحة N".
- The surah and quarter of the current position are highlighted, and the list opens scrolled to them. Mobile also has `showQuranIndexSheet()` (bottom sheet returning the chosen page) for the Mushaf reader.
- Data: `pages.v1.json` now carries `quarters` (start ayah, page, juz, hizb). Starts come from npm quran-meta@7.0.0 (MIT, Tanzil metadata) and are checked against the rub' al-hizb sign ۞ in the KFGQPC text; where they differ the Mushaf wins (15:49 instead of Tanzil's 15:50).

## [Unreleased] — New home page (owner's mockup) — 2026-11-09
### Changed
- Home page redesigned on the website and the mobile app after the owner's mockup: place ("Egypt - Cairo") with a settings button; mosque drawing; next prayer name, its time in large digits and a live countdown; a day card with the weekday, Gregorian and Hijri dates, a "Prayer calendar" button, the five prayers with icons (next one highlighted) and sunrise / sunset; big tiles for the Quran, Adhkar & Dua and Prayer times; wide tiles for Tasbih, Qibla, Islamic reels and Prophets' stories; "Main sections" opens the full list.
- Sunset is shown without the user's Maghrib adjustment. After Isha the card shows tomorrow's day and times.
- "Continue reading" moved off the home page: it stays on the Quran page (web) and the Bookmarks screen (mobile). Hajj, Hisn al-Muslim, search and bookmarks are under "Main sections".
### Added
- Quran radio on the home page: continuous recitation of the whole Mushaf by the chosen reciter, starting from a random surah and wrapping round, with a play duration (unlimited, 15, 30, 45 or 60 minutes) that stops it through the sleep timer. Streams per ayah from everyayah.com, like the rest of the recitation.

## [Unreleased] — More Quran reciters — 2026-11-09
### Changed
- Reciters list (packages/shared-schemas/audio/reciters.json, mirrored to the mobile app) now has the 13 the owner picked, all per-ayah from everyayah.com: Alafasy (default), Yasser Al-Dosari, As-Sudais, Maher Al-Muaiqly (now 128 kbps), Al-Minshawy murattal and mujawwad, Al-Husary murattal, mujawwad and teaching, Abdul Basit murattal and mujawwad, Al-Tablawi, Mahmoud Ali Al-Banna (32 kbps, the only rate available).
- Removed "Al-Minshawy (teaching)": its folder is not listed on everyayah.com/recitations_ayat.html. A saved choice that is no longer listed falls back to the default reciter.

## [Unreleased] — Adhan alerts with the adhan voice — 2026-11-09
### Added
- Mobile: prayer-time notifications now play the adhan recording (Android: the full adhan through its own notification channel, with a "Stop adhan" action; iOS: the opening takbir, as iOS allows at most 30 s). Sound choice: adhan / phone tone / silent.
- Mobile: "Listen to the adhan" and "Test the alert (in 10 seconds)" buttons in Settings; a banner on the Prayer screen to turn alerts on, and a bell next to each of the five prayers to switch it on or off.
- Mobile: Android schedules 30 days ahead (iOS stays at 7 days / 60 notifications), so alerts keep coming even if the app is not opened for a while.
- Web: "Adhan alert" card on the prayer page (on/off, per prayer, sound). While any page of the site is open it shows a notification, plays the adhan and shows a banner with "Stop adhan"; if the browser blocks autoplay the banner offers a play button. A prayer missed while the computer slept (over 5 min late) does not ring.
- Audio: "Beautiful adhan" (Wikimedia Commons, CC0) — see apps/mobile/assets/audio/ADHAN_AUDIO.md. Pending religious review (listen-through) before a store release.

## [Unreleased] — Quranic stories (audio) — 2026-11-08
### Added
- Quranic stories on Android, iOS and the web (`/stories`), from Home and More: listen or read. See docs/STORIES.md.
- Sheikh Nabil al-Awadi's "Stories of the Prophets" (19 audio episodes, streamed from archive.org; non-commercial licence notice). Users hear only episodes a named reviewer approved; reviewer mode lists pending ones with a banner. Resume per episode, ±30 s (mobile).
- 25 verse stories: each story's Quranic verse ranges (Mushaf text) recited in order with the chosen reciter and highlighted as they play, Tafsir al-Muyassar per ayah. No text written by us (validator rejects summaries).
- Sleep timer (15/30/45/60 min) that stops the recitation and the episode.
- `tools/stories.py` (list / approve / reject / build, per episode or `--episode all`), build step in `tools/build_content.py`, API `GET /v1/stories`.

## [Unreleased] — Islamic reels — 2026-11-08
### Added
- Islamic reels: a vertical, swipeable short-video feed on Android, iOS and the web (`/reels`), reachable from Home and More.
- Source: curated YouTube links only (Instagram not enabled yet), played with YouTube's official privacy-enhanced embed; no video is downloaded, re-hosted or stored, so there is no hosting cost.
- Content policy: two categories only, "humble Quran recitation" and "short religious lesson per the Quran and Sunnah".
- Religious review gate: each reel is `pending`, `approved` (reviewer + date required) or `rejected` (reason required). Users see approved reels only; "reviewer mode" shows pending ones with a red "not reviewed" banner.
- `tools/reels.py` (add / approve / reject / list / build), build step in `tools/build_content.py`, API `GET /v1/reels`.
- Only the reel in view has a live player; the others show the poster image.

## [0.1.0] — Milestone 1 — 2026-11-06
### Added
- Monorepo layout (apps, services, packages, content, tests, docs, infrastructure).
- Shared content pipeline: pristine Quran text from `quran-json@3.1.2` (QuranEnc/KFGQPC Uthmani), Madinah 1405H page map (604 pages), SHA-256 integrity manifest.
- Shared rules: prayer methods, cities, Arabic search normalisation, display-only glyph map, AR/EN strings, design tokens (CSS + Dart generated).
- Independent prayer reference vectors (38 cases, adhan-js 4.4.6) and Quran reference counts.
- FastAPI backend: Quran, pages, search, prayer times, qibla, auth (Argon2id + JWT), bookmarks and settings sync (LWW + tombstones), rate limiting, security headers, Alembic migration 0001, OpenAPI contract with drift check.
- Flutter app (Android + iOS): Quran surah list/reader, Madinah page reader, search, bookmarks, continue reading, prayer times with adjustments and qibla, AR/EN, themes, optional account sync, About.
- Next.js static PWA with the same features plus browser geolocation and full offline precache.
- CI: content, backend, web (3 browsers + axe), Android (APK + emulator), iOS (simulator build + integration test), Semgrep, gitleaks, dependency audits, Dependabot.
### Fixed during milestone (see reports/BUG_REPORT.md)
- DEF-001 basmala line missing in mobile readers.
- DEF-002 API contract ambiguity for bookmark PUT body.
- DEF-003 `timezone` package link zones (Asia/Kuwait) missing.
- DEF-004 outdated backend dependencies with known CVEs.
- DEF-005 Android emulator integration test tapped before the keyboard settled.
- DEF-006 WebKit offline e2e: Playwright setOffline + service worker.
- DEF-007 Semgrep: mutable action tags, Dependabot without cooldown.
- DEF-008 leftover snackbar covered the Mushaf page reader's Go button on small Android screens.
- DEF-009 web inputs lost if used before hydration (tests now wait; marker added).
- DEF-010 postcss advisories via Next 15 (npm override).
- DEF-011 CI device-test hangs (portable time limit).
### Changed vs the Rattil prototype
- The stored Quran text no longer contains the font-workaround code points; the substitution is display-only.
