# Changelog

## [1.2.21] — Simple home and sections in the owner's design — 2026-11-24
Owner 2026-11-24 (own description, then comments on real screenshots). Combined with the 1.2.20 Mushaf fix, «رجوع» = the page before, and nearby mosques from 1 km.
### Phone apps (Android + iPhone)
- Home: «الأذان» tile (was «مواقيت الصلاة»); 6 tiles: التسبيح / اتجاه القبلة، علّم طفلك / افهم دينك، مكتبة التلاوات / الأناشيد. Quran radio: the play duration is a button inside the player bar.
- «الأذان» tab: adhan alerts (all parts) first, then the prayer times.
- «الأقسام الرئيسية» (was «المزيد»): كتب التفسير بشرح مبسّط، أشهر كتب السنة بشرح مبسّط، مكتبة دروس الشيخ الشعراوي، المساجد القريبة، احسب زكاتك، شرح أسماء الله الحسنى، ختمة القرآن، متابعة العبادات، إذاعات متنوعة، الحج والعمرة، افهم دينك. Home items are not repeated; help and about moved into the settings.
- «افهم دينك» (was «سلاسل الدروس»): every topic visible, no scholars' groups row, stronger shading on the chosen topic; Sheikh Nabil al-Awadi's «قصص الأنبياء» (19 episodes) is a series under «الأنبياء والصحابة والقصص».
- Settings: language, appearance, then every permission with its explanation (location, notifications, full adhan, widget, battery, silent), then tour, share, rate, contact, «اطلب تطوير أو اقترح فكرة», FAQ, about (version), privacy policy, our apps.
- Tour: new «بياناتك ملكك» page after the welcome. «بلّغ عن خطأ» at the end of the tafsir, hadith and lessons pages (opens the contact form).
### Website (only the owner's website list)
- Renames: افهم دينك، مكتبة التلاوات، كتب التفسير بشرح مبسّط، أشهر كتب السنة بشرح مبسّط، احسب زكاتك، علّم طفلك.
- «افهم دينك»: no groups row, topics wrapped, stronger chosen-topic shading, al-Awadi series.
- Settings like the app: location + notification permissions, then the site links incl. «قيّمه على آب ستور» (App Store link now set).

## [1.2.20] — Mushaf page fits small phones with a big font size — 2026-11-24
Owner 2026-11-24 (realme C21-Y, Android 11): the Mushaf page was wider than the screen, the first and last words of every line were cut off.
### Fixed
- Phone apps (Android + iPhone): the Mushaf page followed the phone's own font size (Settings › font size / iOS Dynamic Type), so its words came out wider than the page had measured. The page now keeps its own size and fits the screen width; the Quran text and its lines are unchanged. Website checked at 360 px wide: it already fitted (no change).
- Same as 1.2.19 otherwise.

## Lessons: Eng. Ayman Abdelrahim's series — 2026-11-24
Owner 2026-11-24 (sent his YouTube playlist «تأسيس وعي المسلم المعاصر», asked for all his audio series under the fitting topics): 7 series, 46 lectures (~85 h), app and website. Two new topics: «الفكر والوعي الإسلامي» (تأسيس وعي المسلم المعاصر) and «التاريخ الإسلامي» (مدخل لدراسة التاريخ الإسلامي، تاريخ الدولة الأموية والعباسية); the others under the Prophet's life (العهد المكي), prophets & Companions (الخلفاء الراشدون), with the Quran (الثلاثون جذرًا) and family (البيت المسلم). Owner: religious lessons only, so his general courses (psychology, humanities, linguistics, «التأسيس المعرفي», «من هنا نبدأ», a TV programme, «ما بعد السلفية») were left out. lessons_build: per-series hand-written "names" for lesson titles. Now 71 series, ~3100 lessons.

## Website: «the site is being updated» bar — 2026-11-24
Owner 2026-11-24: while the website is being uploaded or changed, every page shows an orange bar at the top (owner picked this look with a × to hide it): «نحدّث الموقع الآن ونضيف خدمات جديدة. إن تقطّعت خدمة أو توقفت فستعود للعمل خلال دقائق.» (English on /en/). The upload tool (builds/ftp_deploy.py `deploy`, plus `notice on|off` for hand changes) writes /site-status.json {"updating": true} before the first file and false when it ends without errors; optional message_ar / message_en replace the text. MaintenanceBanner reads it on load, every minute and when the tab comes back; the service worker and .htaccess never cache it, and the file is not part of the build. Website only: the phone apps carry their content inside and are not affected by uploads.

## [1.2.19] — «سلاسل الدروس» audio lesson series — 2026-11-23
Owner 2026-11-23: a new section of complete religious lesson series, all audio, downloadable, with the player under each lesson; famous Egyptian and Arab sheikhs, all of Sheikh Omar Abdelkafy's series, Saudi sheikhs and Al-Azhar scholars. Phone apps (Android + iPhone) and website.
### Added
- «سلاسل الدروس» (More on the app, Library menu on the website): 50 complete series, about 1850 lessons, in 13 topics (creed, the Prophet's life, fiqh, hadith, purifying the soul, prophets/Companions/stories, with the Quran, raising children and family, good character, manners and daily life, dealings with people, purity and personal hygiene, end times and the hereafter). Filters: Al-Azhar scholars / Egyptian sheikhs / Saudi sheikhs, topic, and search by series or sheikh.
- Sha'rawi section now has three parts: Quran tafsir, the Prophet's life (220 lessons) and prophets' stories (44 lessons), with the same download-all / resume / ✓ as the lesson series (owner 2026-11-23); his series are not repeated in «سلاسل الدروس».
- Owner 2026-11-23 (second round): four series of the Grand Imam Ahmed al-Tayeb's Ramadan talks (Names of Allah, Islam the middle way, issues from our lives, women & the family) from his official podcast; «الطهارة ببساطة», 7 simple purity lessons (incl. hygiene / sunan al-fitra) shown first under purity.
- Each series: «أكمل الدرس N» (resumes where the listener stopped), «تحميل السلسلة» (whole series for offline listening, with stop), download per lesson, ✓ on every lesson heard to the end (long-press on the app / ✓ button on the website to set or clear it), progress on every card, and a «أكمل» card for the last series. The lock-screen-style player opens right under the lesson playing and goes on to the next lesson.
### Fixed (owner 2026-11-23, after the first upload)
- Grand Imam al-Tayeb's lessons: the music at the start, between the parts and at the end of each episode is skipped by the player (app + website). The places were found per episode by a speech / music classifier (tools/lessons_music.py → content/lessons/music.json); the recordings themselves are unchanged.
- Website: the Sha'rawi section's «السيرة النبوية» / «قصص الأنبياء» showed the whole lesson catalogue (and its cards did nothing) when the browser still had the older lesson list; the list is now /data/lessons-2.json (new name) and is never cached long; a Sha'rawi part never falls back to the catalogue.
- A ✕ on the «أكمل» card of the lesson series (app + website), like the one on every player.
- Website home: the dark prayer-times box (the phone widget's look) is removed; it repeated the two prayer cards above it.
- iPhone build: the prayer widget's countdown used an iOS 15 API in an iOS 14 widget (Codemagic archive failed).
- Owner 2026-11-24 («بعض الدروس صوتها ضعيف جدا وقديم»): every series was measured (loudness and how much of the voice band is left); 34 are evened out while playing: quiet ones raised (up to +12 dB), very loud ones lowered, old muffled tapes get the hum cut and the voice lifted (website through Web Audio, Android through the system loudness enhancer + equalizer; iPhone plays them as recorded, its player has no such effects). Seven clearer series added beside the old / quiet ones: «تيسير الوصول: شرح ثلاثة الأصول» (Sheikh Abdulmohsen al-Qasim), «شرح كتاب التوحيد» (Sheikh Abdulrazzaq al-Badr), «الشمائل النبوية» (Sheikh Abdulkarim al-Khudair), «المعاملات المالية المعاصرة» (Sheikh Yusuf al-Shubaily), «فتاوى الحج والعمرة» (Sheikh Atiyya Saqr), «مع القرآن ٣» and «مع القرآن ٦» (Sheikh Saleh al-Maghamsi). Now 57 series, about 2120 lessons.
- Owner 2026-11-24: Ibn Uthaymeen's old muffled «شرح ثلاثة الأصول» tape is removed; the same book is now Sheikh Abdulmohsen al-Qasim's clear «تيسير الوصول» series (56 own series).
- Owner 2026-11-24: Sheikh Mustafa al-Adawi added (Egyptian sheikhs), 8 series in their topics: «رسائل إيمانية» (purifying the soul), «قرآن تفسره السنة» and «تفسير القرآن العظيم» (with the Quran; tafsir titled by surah), «سلسلة العقيدة» and «شرح كتاب التوحيد لابن خزيمة» (creed), «السيرة النبوية», «شرح متن أبي شجاع» and «البحث الفقهي» (fiqh). Now 64 series, about 3050 lessons. Short fatwas left out (owner).
- Owner 2026-11-24: the section is now «دروس الشيخ الشعراوي»: its front page shows three series cards in the series-page look (تفسير القرآن الكريم · السيرة النبوية · قصص الأنبياء, each with topic · lessons · hours); the tafsir card's button «اختر السورة» opens the surah list, the others open the full series (app: start / download right on the card too). The three are also listed in «سلاسل الدروس» under their topics (Quran, seerah, stories); app + website.
### Changed
- Unchanged: Quran text and all other religious content.

## [1.2.18] — CarPlay sections + adhan first — 2026-11-23

### Added
- CarPlay / Android Auto: the whole dhikr on the car screen (part by part with the recording) and a «نص الذكر» button; radio, recitation library, al-Sha'rawi, prophets' stories and nasheeds beside the morning / evening adhkar.
- Reminder 10 minutes before the adhan and the iqama alert on by default; iqama countdown on home, prayer tab, widgets, lock screen and the website; no other app reminders from 10 minutes before the adhan until the iqama.
- Wide prayer widget in the owner's look; «تنبيهات الأذكار» card on the Adhkar tab; every audio player in the lock-screen look.

## [1.2.17] — full adhan on iPhone — 2026-11-21
Owner 2026-11-21: iPhone adhan alerts played only 30 seconds; the whole adhan must ring on every iPhone. Phone apps only (Android already rings the full adhan; the website plays it in full while a page is open). Also the first-run setup asks for everything at once and offers the prayer widget, and Android gets the next prayer on the lock screen.
### Added
- iPhone: the whole adhan rings at prayer time with the chosen muezzin. iOS plays at most 30 s of a notification sound, so the app cuts the recording (on the phone, at the pauses between the phrases) into parts of up to 29 s, and each part rings as its own notification the moment the one before ends. The next 48 hours ring in full; later days ring the first 30 s until the app is opened again (iOS keeps at most 64 pending notifications).
- iPhone: opening the app from an adhan notification plays the rest of the adhan in the app from where it reached, removes the remaining parts, and shows a «إيقاف الأذان» bar.
- iPhone with iOS 26 or newer: «الأذان كامل كمنبّه» (asked at the first run right after the adhan notifications, and in the adhan settings): the adhan rings as a system alarm (AlarmKit) with the whole recording, even on silent, with «إيقاف» and «أكمل في التطبيق» buttons.
- iPhone: if the app is not opened for about two days, a notification half an hour before the first 30-second adhan asks the user to open it once (which plans the full adhan for the next two days again).
- Prayer widget offered at the first run and in the settings («ودجيت الصلاة على الشاشة الرئيسية», owner 2026-11-21): Android adds it with one system message (most launchers; otherwise the steps); iPhone shows the steps for the home screen and the lock screen (Apple lets no app add a widget itself).
- Android: «الصلاة القادمة على شاشة القفل» (on by default, switch in the widget card): a quiet lasting notification with the next prayer, its time, a live countdown and the day's five times, updated at every prayer (phones have no lock-screen widgets).
### Changed
- Unchanged: Quran text and all other religious content; Android and website behaviour.

## [1.2.16] — one combined store update + website — 2026-11-21
Owner 2026-11-21: one release with every change asked for (1.2.14 and 1.2.15 were never uploaded to the stores; 1.2.15 went to the website only).
Owner 2026-11-20: everything ships together (1.2.14 was never uploaded). Phone apps (Android + iPhone) and website.
### Added
- «الرقية الشرعية» and «الرقية الشرعية للأطفال» (read and listen), in adhkar and in the kids section.
- Kids section («الأطفال», on the home screen instead of the short videos tile; its own menu on the website): prophets' stories (watch, listen, save offline), the teaching Mushaf (Minshawi / Husary with children), stories.
- Dhikr reminders («تنبيهات الأذكار»): chosen adhkar every N minutes in a daily window, said by Sheikh Mishary Alafasy when the phone is not silent (iPhone: at most 24 a day). Website: while the site is open.
- Prayer widgets: Android medium widget (day, Hijri + Gregorian dates, six times, countdown). iPhone: small, medium and lock-screen widgets (first time in the iPhone app; needs the Apple App Group setup).
- Videos tab age question (app + website, owner's wording): «اختر فئتك العمرية» → «أقل من 13» / «13 أو أكثر», saved on the device only. 13+: videos open, never asked again. Under 13: only the kids section videos; «قفل ولي الأمر» (4-digit PIN chosen by the parent, «نسيت الرقم؟» via a question for adults) opens all videos. Google Play Families policy (the app has a kids section; target audience includes children).
- Privacy: location leaves the device rounded to about 100 m (mosques, place name); privacy policy has a full children section; contact form asks under-13s to let a parent write.
- Tafsir books: Muyassar (default) + Sa'di, Ibn Kathir, Tabari, Baghawi, Qurtubi; gharib, i'rab, sarf, balagha and fawa'id tabs; «التفسير» page (read, compare, search, offline download). The app reads the books from rattilwasalli.com, so the website goes up with or before the app.
- Mushaf player: 41 reciters (27 new), 4 of them one file per surah with ayah highlighting.
- Every audio player has a ✕ that stops it and hides it (owner 2026-11-20): website player bar, Mushaf mini player (app + website), adhkar, recitation library, Sha'rawi, nasheeds, stories, kids listening.
- Kids: two modern prophets' stories series (published videos, no prophet's face shown) above the full series; kids corner with a 43-book shelf, «احفظ حديث», adhkar cards and wudu/salah steps (app + website).
- Kids: the teaching Mushaf covers the whole Quran; prophets' stories picked from a list; fuller kids ruqyah (from trusted sources).
- Mushaf: «الجزء كاملاً», whole-surah tafsir split, bigger page; kids interactive teaching Mushaf.
### Changed
- The printed Mushaf look (King Fahd Complex page fonts) is the default; the old look is an option in settings.
- 12-hour clock by default (24 hours in settings).
- Driving mode: Ayat al-Kursi and al-Ikhlas no longer cut before their end.
- Nearby mosques: roads and squares are no longer listed; big «افتح على خرائط جوجل» button on top.
- About: no source credits shown (on request only); version fixed.
- Unchanged: Quran text and all other religious content.

## [1.2.13] — next store update: CarPlay + the big Mushaf with tafsir — 2026-11-19
Phone apps (Android + iPhone) for the stores, to send after Apple approves 1.2.8. It brings together 1.2.9 (CarPlay) and 1.2.10 (Mushaf beside the tafsir, full screen with the tafsir) below; 1.2.11 and 1.2.12 were website-only and are already live. Nothing else changed.

## [1.2.12] - 2026-11-18 (website)

- Settings: the account / bookmark-sync card (developer server address, email, password) is hidden on the live site; it needs our own sync server, which is not online (NEXT_PUBLIC_ACCOUNT_SYNC=1 shows it). The app never showed it.
- Settings → «العمل دون اتصال»: the whole-site download still starts only when the visitor taps «احفظ الموقع كاملًا…», and now has «إيقاف الحفظ للعمل بدون إنترنت» to stop it (also stops the re-download after each new upload).

## [1.2.11] - 2026-11-18 (website)

- Mushaf on laptops/desktops: the page starts at 200% of the old fitted size and scrolls; − / + buttons (bottom corner), Ctrl + mouse wheel and touchpad pinch change it (100%–300%, saved).
- Full screen: a big page that scrolls instead of the whole page squeezed into the screen height.
- Tafsir beside the page: the page takes its full half (normal view and full screen).
- Player: the reciter list is now our own pop-up list (the hidden native drop-down did not open for the owner on a laptop).

## [1.2.10] — big Mushaf beside the tafsir, full screen with the tafsir — 2026-11-18
Owner 2026-11-18 (website on a computer): the Mushaf page became very small when the tafsir was open, full screen did not fill the screen, and full screen could not be used with the tafsir. App + website. (1.2.9 is kept for the CarPlay build.)
### Changed (app + website)
- Wide screens (computer, tablet): «تفسير الآية» opens beside the page instead of under it in the bottom strip, so the page keeps its size.
- Page beside the tafsir («استماع مع التفسير» and the new button): the page is much bigger (up to 2.2x the column height, scrolling with the recitation; was 1.4x).
- Full screen works with the tafsir, listening or only reading: the whole page on the screen's height beside the tafsir; above it «إظهار الأدوات», «التفسير» on/off and play/pause with the ayah being recited. A tap on an ayah shows its tafsir and stays full screen.
- Phones with page + tafsir halves: the player folds to one row by itself (opens from its handle; the saved choice is unchanged) and the A− / A+ row is hidden, so the page and the tafsir get more room.
### Added (app + website)
- «التفسير» button by full screen: the page's tafsir beside the page, without listening.
### Changed (website)
- Full screen also asks the browser for the whole screen (no tabs, address bar or taskbar); Esc brings the tools back.
- Unchanged: Quran text, page layout and all other religious content.
## [1.2.9] — CarPlay for driving mode — 2026-11-18
Apple approved the CarPlay audio entitlement (2026-11-17).
### Added (iPhone)
- CarPlay: «رتّل وصلِّ» on the car screen with a list «أذكار الصباح» / «أذكار المساء» (driving mode, counted for you). Picking one starts it and opens the car's Now Playing screen with the dhikr and its live count («سبحان الله وبحمده · ٣٧ من ١٠٠») and play / pause / next / previous, the same as Android Auto. It works with the phone locked and the app closed (CarPlay starts the app).
- iOS project: CarPlay scene (CarPlaySceneDelegate.swift), Runner.entitlements with com.apple.developer.carplay-audio, and one Flutter engine shared by the phone screen and CarPlay.
- Codemagic ios-testflight stops with a clear message if the App Store profile has no CarPlay Audio entitlement.
### Unchanged
- Android (Android Auto already has the list since 1.2.7), the website (CarPlay is for the phone app), and all religious content.

## [1.2.8] — website matches the app — 2026-11-17
Owner rule: every feature on Android, iPhone and the website. A code comparison of 1.2.2 (report in E:\Quaran-App-Project\reports) found six app features missing on the website; all six are now there. The app is unchanged (its recitation library already has the sleep timer, in the player under the surah playing).
### Added (website)
- Audio stories: a download button beside every episode, to listen offline (as in the app).
- Recitation library: a download button beside every surah of every reciter, to listen offline (as in the app).
- Tasbih: the app's five bead looks (glossy, marble, wood, pearl, crystal) in every colour; picking one shows the beads.
- Qibla: «استدر يمينًا / يسارًا N°» while the compass is live, the compass accuracy where the phone reports it (iPhone), and the app's «البوصلة تحتاج معايرة» card when it is poor.
- Prayer times: «مشاركة التقويم» sends the month as a picture (as in the app), or downloads it where the browser cannot share files.
- Mushaf: «عن السورة» in the bar under the page opens «عن السورة وأسباب نزولها» for the surah of the selected ayah (else the page's first), as in the app: place and order of revelation, introduction and reasons for revelation, the app's text verbatim (before, the website showed it only on the surah list page).
### Changed (app + website)
- «ليل المدينة» is now the default colour style (owner 2026-11-17). A style saved before 1.2.8 gives way once, so everyone starts on «ليل المدينة»; a style picked after updating is kept. The browser bar colour and the installed website's colours follow it.
### Changed (website)
- Zakat: every kind on one page (money, gold, silver, livestock, crops) with its due beside its name and «إجمالي الزكاة المطلوبة» at the bottom, the same as the app (the five tabs are gone).
- Unchanged: Quran text and all other religious content.

## [1.2.7] — driving mode for the morning / evening adhkar — 2026-11-17
### Added
- Driving mode (Android + iPhone): «استمع أثناء القيادة» in the Adhkar tab (morning / evening) and a car button on the morning / evening adhkar page. The app plays every dhikr in Sheikh Alafasy's voice as many times as Hisn al-Muslim says (e.g. 100) and counts for the driver; a soft sound between repetitions and a different one when a dhikr is complete (can be turned off); optionally the count said out loud every 10 or 33 (phone text-to-speech). One reading of each dhikr is cut from the same recording the «listen» card plays (clip times in content/adhkar/drive-clips.json, checked one by one); the counts come only from Hisn al-Muslim. Items the recording does not read (al-Hamdu lillah wahdah, last two ayat of al-Baqarah) are skipped; the evening «أستغفر الله وأتوب إليه» is taken from the morning recording.
- Lock screen, notification, headset / steering-wheel buttons and the car screen show the dhikr and its live count («سبحان الله وبحمده · ٣٧ من ١٠٠»): next = next dhikr, previous = this dhikr again (twice = the one before), pause resumes at the same count.
- Android Auto: the app shows on the car screen with «أذكار الصباح» and «أذكار المساء» (driving mode) and Now Playing. CarPlay: Now Playing works through the phone; the app's own CarPlay list needs Apple's CarPlay audio entitlement (requested by the owner, see the CarPlay steps file).
- Website: not changed (driving mode is for the phone apps).

## [1.2.6] — Hajj & Umrah round counter in the app — 2026-11-17
### Added
- Hajj & Umrah (app, Android + iPhone): the round counter the website already had: seven rounds of tawaf, seven of sa'i and seven pebbles at the jamarat, under the tawaf (Umrah, arrival, ifadah, farewell), sa'i and stoning steps. «أتممت شوطًا», «تراجع», «تصفير», seven dots that light up, and «اكتمل العدد — تقبّل الله» at seven. The count is kept when the app is closed. The website is unchanged (it has had the counter since the first version).
### Fixed
- App strings: the Mushaf player handle and word-meanings labels now live in tool/i18n/mobile.*.json, so regenerating the ARB files keeps them.

## [1.2.5] — Word meanings in the Mushaf — 2026-11-17
### Added
- Mushaf (app + website): «معاني الكلمات». A small icon in the bar under the Mushaf opens the difficult words of the page with their meanings, ayah by ayah (tap an ayah's name to select it on the page); the ayah menu has a new «المعاني» button for that ayah's words. Text from «السراج في بيان غريب القرآن» (Muhammad al-Khudairi), copied verbatim from the Quranpedia.net data dump (free for use in apps); built by tools/word_meanings.py into content/word-meanings/dist/siraj.v1.json. The Quran text is unchanged.

## [1.2.2] — Mushaf player slides down — 2026-11-17
### Added
- Mushaf (app + website, phones and tablets): a handle with an arrow on top of the player. Tap it or drag it down and the player and the page slider slide down to one thin row (play / pause and what is playing), so the Mushaf page gets the room back; tap or drag up to bring them back. The choice is remembered.

## [1.2.1] — smaller app, owner's screen changes — 2026-11-17
### Added
- Mushaf (app + website): «السورة كاملة», the whole surah on one scrolling screen on the Mushaf paper with A+ / A− (the same KFGQPC text, no change to letters or tashkeel); next/previous page buttons and a sideways swipe at the end of the verses and tafsir views.
- Tasbih (app): five drawn bead styles (glossy, marble, wood, pearl, crystal) in every colour, the dhikr and its virtue from Hisn al-Muslim on top, big beads in the middle, the count on the side, change dhikr / history / reset.
### Changed
- Mushaf (app + website): the page turns like a paper Mushaf: the leaf, hinged on the spine, follows the finger (left to right = next page). The selected ayah is a clear warm honey tint, the recited one soft green (never red).
- Mushaf (app): a phone held sideways keeps the page large with the tools in a side column, also while listening with tafsir; full screen opens sideways and while listening with tafsir.
- Home (app): «فيديوهات إسلامية مختصرة», new «مكتبة التلاوات» and «الأناشيد» tiles, Hajj and Umrah beside prayer times; the radio's pause, sleep timer and ✕ sit in the station row.
- Adhkar (app): listening keeps the page; a player bar with ✕ shows under that dhikr.
- Zakat (app): every kind on one screen with its due beside it and a grand total at the bottom.
- Adhan recordings' credits (app): moved from Settings to About (folded).
- Hisn al-Muslim (app + website): the typo «صلى الله عيه وسلم» corrected to «عليه» (13 places) and a missing space in «حسنة فسأله» (owner-approved; no other wording changed).

- App size (Android + iPhone): about 90 MB smaller. Nothing is removed for the user, and the texts are unchanged.
  - Hadith books are stored compressed (gzip) inside the app (77 MB to 12 MB); the text is byte-for-byte the same (checked by sha-256 per book).
  - Sheikh Mishary Alafasy's morning and evening adhkar recordings download the first time they are played (about 4 MB each, from rattilwasalli.com) and then play offline. If the download fails, the sheet offers retry or the same recording online.
  - Only the default adhan voices are bundled: Sheikh Ali Mulla (Makkah Haram) and Sheikh Al-Daghriri's Fajr adhan (Haram). Every other muezzin downloads once when chosen or played (from rattilwasalli.com, then the original source), and then works offline. A muezzin chosen before the update downloads by itself on the first start; the default adhan sounds until it is there.
- Website: no size change (it already loads each recording only when played).

## [1.2.0] — App Store release — 2026-11-16
Everything since the 1.1.0 build of 2026-11-14 (that build was never uploaded to a store).
### Added
- Colour styles (app + website): emerald and gold, and Madinah night, each in light and dark, picked in Settings; the app icon follows the style.
- Mushaf (app + website): pinch to zoom the page (up to 3x); page and tafsir halves on every screen; one bottom strip with the ayah actions; a tap on an ayah opens its options; first-open guide.
- Hajj and Umrah guide from its sources (Ibn Baz's Tahqiq with page numbers, the official guide, hadith, Hisn al-Muslim, the Quran text as printed), with pictures and every dua in full at each step; each Hajj kind on its own page.
- Hadith: the simplified explanation under each hadith, and a list of explained hadiths.
- Players: the lock screen shows elapsed time, length and a seek bar; the bottom player takes you back to what is playing; in the library and radios the player sits under the item playing.
- Adhkar: finishing the last dhikr goes back to the adhkar list by itself.
- "Report a mistake" opens the contact form with the title and message filled in.
- Website: the website look on phones too (☰ menu), the area name of the viewer's position, and a simpler home page.
- Recitation library (app + website): Sheikh «محمد أحمد شبيب» is a reciter inside the library's reciters list (in name order, like every other reciter; not a separate section or More entry). Tapping him opens his recitations inside the library. No complete 114-surah recording of the sheikh exists, so he has what is available: 16 murattal recordings (Hafs; 11 are a passage of the surah, marked «ما تيسّر من») and 70 mujawwad recordings (Quran al-Fajr, radio, evening gatherings; ordered by surah), about 44 hours. Search by surah, the next recording plays by itself, and each one can be downloaded for offline listening. Sources are not shown.
- Website: the player's buttons sit right under the recitation playing (Sheikh Shabib's list and al-Sha'rawi's lessons), as in the reciters' surah lists and the nasheeds, not at the top of the page. The app already did this.
- Unchanged: Quran text and all other religious content.

## [1.1.0] — First store release (App Store, then Google Play) — 2026-11-14
### Added
- First run (app): a short tour, then a setup that asks for location and adhan notifications straight away, plus exact alarms, battery and adhan on silent (Android only; iPhone cannot play sound on silent).
- Radios (app + website): live sound from Masjid al-Haram and the Prophet's Mosque.
- Contact us (app + website): a form with request title, name, phone, WhatsApp and message. No email address is shown.
- Website: everything the app had that the website lacked (adhkar hub, five-tab zakat calculator, hadith explanations, surah "about" cards, story videos, "your channels" in videos, qibla distance and tips, automatic location and shared monthly timetable).
- Website on a computer: top bar, drop-down menus, website home, breadcrumbs and a site-map footer. Phones keep the app look.
- Adhkar (app + website): finishing the last dhikr of a list closes it by itself. The "done" tick shows for about a second, then the app goes back to the adhkar list (morning, evening and every Hisn al-Muslim chapter in the one-card view); the website scrolls back up to the adhkar list, and a Hisn chapter returns to the chapter list. A list already finished today opens normally. The website's Hisn chapters now have the same tap counter as the app in the one-card view.
- Reader (app + website): page-turn arrows and a hint in full screen; on tablets held sideways and wide screens, the player and tools sit beside the page; the ayah sheet no longer covers the page; one sound at a time (adhkar pause the Quran, which resumes from its ayah); the nasheed player sits under the playing nasheed.
### Changed
- Colours: the app and website follow the Mushaf's cream, brown and gold palette instead of green, in light and dark mode.
- "Rate the app" opens only this device's store (App Store on iPhone, hidden until the App Store link exists; Google Play on Android). Account sync is hidden in store builds.
- Hajj and Umrah guide (app + website): a new tawaf drawing that starts at the Black Stone and goes anti-clockwise with numbered rounds, and numbered step-by-step graphics. Hajj steps in order for each type (tamattu', qiran, ifrad), each opening its paragraph of the official Saudi Ministry of Hajj guide, with the full guide at the end of the Hajj tab.
- Hajj and Umrah section (app + website): its own entry on the home screen, in More and in the website menu, with the guide, buttons to the official crowd-level pages (General Authority page and Nusuk) and live audio from Makkah and Madinah. Religious-review labels removed on the website, as in the app.
- Website hosted on rattilwasalli.com (Bluehost), with the privacy policy at /privacy-policy.html and support at /ar/help/.
- Unchanged: Quran text, tashkeel and all religious content.

## [1.0.16] — Video search, nasheeds on the website, khatma planner and worship tracker in More, installable website — 2026-11-13
### Added
- Videos (app + website): a search box at the top of the videos page. Results are Islamic videos only (Quran recitation, religious lessons, advice/admonitions): the trusted channels first, other channels only when the title is clearly Islamic, never titles with music, songs or entertainment words. Tap a result to play it in the official YouTube player. The viewer's past searches are saved on the device (up to 20, newest first): tap one to search again, × removes it, "مسح السجل" clears them.
- Website: the Nasheeds section (same voice-only list as the app: 34 munshids, 516 nasheeds), with search, a player that goes on to the next nasheed, and saving for offline listening.
- Website: installable as a Windows app (Edge/Chrome: desktop + Start menu shortcut, own window). "ثبّت الموقع كتطبيق" card in More and Help with an install button when the browser offers it.
- App (Android + iPhone): More now opens the full khatma planner (khatma by days or pages per day, daily portion, reminder, history) and the worship tracker (prayers, fasting, notes). The Mushaf's khatma sheet links to the planner, and reading the last page of today's portion in the Mushaf marks the portion done.
### Changed
- The two placeholder reels "pending review" are removed, and so is the reviewer switch. The videos page opens straight on the trusted channels' newest videos.
- YouTube's channel feeds were failing on 2026-11-13 (404/500): the feed now falls back to each trusted channel's Videos page, so videos keep coming.
- Website videos feed and search run through a small Netlify Function (netlify/functions/videos.mjs, deployed with the site); before this the website had no automatic videos.
- Unchanged: Quran text and all religious content.

## [1.0.15] — New name: «رتّل وصلِّ» (Rattil wa Salli) — 2026-11-13
### Changed
- The app is now called «رتّل وصلِّ» in Arabic and "Rattil wa Salli" in English (owner's choice). It is the name under the icon on Android and iPhone, the iPhone widget name, the media notification, the help/share texts, the website title, header and installable web app.
- Share buttons now link to the app's own domain https://rattilwasalli.com (owner registered it 2026-11-13).
- Store files: listing titles "رتّل وصلِّ: مصحف وأذان وأذكار" / "Rattil wa Salli: Quran, Adhan", subtitle "بلا إعلانات. لوجه الله تعالى"; privacy policy renamed and now also published at /privacy-policy.html on the website.
- Unchanged: the icon, the package/bundle id org.rattil.app, and all Quran and religious content.

## [1.0.14] — Mushaf full screen, new colours, landscape — 2026-11-13
### Changed
- The Mushaf opens full screen: only the page, with the status and navigation bars hidden. One tap on the page brings back the tabs, player, page slider and bottom bar; a tap beside the text hides them again. An ayah number still opens that ayah directly.
- Reader colours follow the owner's reference: cream paper, brown frame, surah bands and ayah markers, black text; the reader's buttons, player and bars are brown and cream instead of green (a warm dark variant in dark mode).
- A phone held sideways: the lines take the whole width in a bigger font and the page scrolls down (tablets and desktops still show the whole page).
- The page layout, Quran text (KFGQPC Hafs v18), font, lines and page turning (swipe right for the next page) are unchanged.

## [1.0.13] — Names of Allah explained by Sheikh al-Nabulsi; story titles — 2026-11-12
### Changed
- Names of Allah: the phone's text-to-speech voice is gone. Each name now has Sheikh Muhammad Ratib al-Nabulsi's recorded lessons on it (91 of the 99 names; two lessons per name from his 2008 series, one from his 1996 series where 2008 has none), streamed with a play/pause bar. The flutter_tts dependency was removed.
- Website: a new Names of Allah page with the same explanations and lessons.
- Stories: "قصة زكريا ويحيى" and "قصة إدريس ونوح" spelled correctly.

## [1.0.12] — Audio keeps playing in the background — 2026-11-12
### Fixed
- Radio stations, the recitation library, al-Sha'rawi lessons, stories, nasheeds and the adhkar recordings stopped a few seconds after leaving the app. Every player now runs through the system media service (Android) and the iOS background audio session, with a notification and lock-screen controls (play/pause, next/previous where there is a list, stop). Paused audio keeps its notification so it can be resumed from there.
### Changed
- The reader's play button goes on past the end of the page through the following pages and surahs (the page turns by itself), instead of stopping at the page end.
- In the recitation library a surah goes straight on to the next surah of the same reciter; al-Sha'rawi lessons go on to the next lesson of the surah; a munshid's nasheeds play one after another.
- Website: the same continuation, and the lock-screen / notification controls for the library, radio, lessons and stories players.

## [1.0.11] — Al-Sha'rawi audio tafsir — 2026-11-12
### Added
- "تفسير الشعراوي" under More (app on Android and iOS, and the website): Sheikh Muhammad Mutawalli al-Sha'rawi's reflections on the Quran in his own voice, 1116 lessons (about 667 hours) ordered by surah, each labelled with the ayahs it explains. Search by surah name or number; listen online, or download any lesson for offline listening (about 7 MB each). The audio is not bundled in the app. The recordings cover the surahs the sheikh recorded (1–60, 78–89, 96, 100–114).

## [1.0.10] — Adhkar audio, hadith icon, home-screen widget, tashkeel — 2026-11-12
### Changed
- Dhikr listening: a player bar (play/pause, position, stop) appears while a dhikr plays; the recording stops at its end, when moving to another dhikr, and when leaving the screen.
- A "الحديث" icon under each dhikr (all 34 morning/evening adhkar, 106 Hisn al-Muslim items) shows the hadith it comes from, its virtue and where it is reported.
- Home-screen widget (Android): Hijri date, clock, next prayer and a countdown ring. iOS widget code is in ios/PrayerWidget and needs a one-time Xcode target (see its README).
- Tashkeel of all adhkar and Hisn al-Muslim texts completed and corrected from the fully vowelled Hisn al-Muslim text (tools/hisn_tashkeel.py; every changed word is listed in content/adhkar/tashkeel-changes-2026-11-12.tsv). Tanween al-fath is written on the letter before the alif (رَبًّا، دِينًا), as the owner asked.

## [1.0.9] — Final feedback round before release (owner's list) — 2026-11-11
### Changed
- Settings rebuilt: language, prayer times auto/manual, location auto/manual, rate, share, FAQ, contact us (a form, no phone or email shown), our apps, about. The account & sync section and the theme/font/translation entries were removed.
- Adhan alerts and the muezzin choice are on the prayer page. New voices: Abdul Basit adhan and Abdul Basit Fajr adhan.
- Cairo Quran radio is the home radio's default; any station from the radios list can be chosen.
- Adhkar: one dhikr per page with a big counter, an overall progress bar, and an automatic move to the next dhikr. Every dhikr (adhkar and Hisn al-Muslim) can be listened to online. The listening section keeps only the morning and evening recordings.
- The review notices are gone from the adhkar, Hisn al-Muslim and Hajj/Umrah screens.
- Quran reader: A+ / A− (the Mushaf zooms 1x to 2x, and the lists change font size), and a card per surah with where it was revealed and the reasons for revelation. On short phones these sit in a menu so the whole page still fits.
- Zakat: simplified to five tabs (silver, gold, money, livestock, crops).
- Tasbih: a realistic misbaha is the default.
- Reels: search YouTube channels and add them; the app suggests similar Islamic channels from what you watch most; the labels under each video are gone.
- Prophets' stories: a video option per episode (Sheikh Nabil al-Awadi), plus listening and the offline download. The story player bar stays visible with stop on the main screens.
- Names of Allah: the 99 names with a simplified explanation each; a listen button reads the name and its explanation (the phone's Arabic text-to-speech).
- Nasheeds: the old YouTube list was replaced by 516 nasheeds from 34 munshidin, streamed or downloaded for offline listening. Battle and war anthems were left out (store policy).
- Hadith books: a "simplified explanation" button on 5,731 hadiths (2,543 explanations from a published hadith encyclopedia, linked by matching the Prophet's words).
- "مكتبة التلاوات والإذاعات" is renamed "مكتبة التلاوات لجميع قراء القرآن الكريم".
- Juz 4 and 11 start at 3:93 and 9:93, as in the printed Mushaf margin.

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
- Juz 4 and 11 start at their ۞ marks (3:93, 9:93) as the printed margin shows; page headers follow the Complex's data (page 201 = juz 10, page 202 = juz 11). Checked against the owner's printed copy.
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
