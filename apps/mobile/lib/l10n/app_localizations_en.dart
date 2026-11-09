// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutFonts => 'Fonts: Amiri Quran and IBM Plex Sans Arabic — SIL Open Font License 1.1.';

  @override
  String get aboutOpenSource => 'Open source and free forever. No tracking, no ads, no in-app purchases.';

  @override
  String get aboutPages =>
      'Mushaf page boundaries: Madinah Mushaf 1405H (KFGQPC) via QuranMeHelp manifest — Waqf General Public License 2.0.';

  @override
  String get aboutPrayerAlgo =>
      'Prayer times are calculated on the device with standard astronomical formulas (Meeus / USNO) and checked against the independent adhan-js library.';

  @override
  String get aboutQuranText =>
      'Quran text: The Noble Qur\'an Encyclopedia (quranenc.com) Uthmani text, Hafs an Asim, via quran-json 3.1.2 — CC BY 4.0. Bundled unchanged; verified by SHA-256.';

  @override
  String get aboutTranslation =>
      'English translation: Saheeh International, via quran-json 3.1.2 (licence review pending).';

  @override
  String get aboutTzdb => 'Time zones: IANA tz database (public domain) via the timezone package.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get accountEmail => 'Email';

  @override
  String get accountErrAuth => 'Incorrect email or password';

  @override
  String get accountErrEmail => 'Enter a valid email address';

  @override
  String get accountErrOffline => 'Cannot reach the server. Check your internet connection and the server address.';

  @override
  String get accountErrPassword => 'Password must be at least 10 characters';

  @override
  String get accountErrRateLimit => 'Too many attempts. Wait a minute and try again.';

  @override
  String accountErrServer(String code) {
    return 'Server error ($code)';
  }

  @override
  String get accountErrSession => 'Your session has expired. Please sign in again.';

  @override
  String get accountErrTaken => 'This email is already registered';

  @override
  String accountLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get accountLogin => 'Sign in';

  @override
  String get accountLogout => 'Sign out';

  @override
  String get accountOptional => 'An account is optional. Everything works offline without one.';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountRegister => 'Create account';

  @override
  String get accountRegistered => 'Account created. You can sign in now.';

  @override
  String get accountSaveServer => 'Save address';

  @override
  String get accountServerInvalid => 'Enter an http:// or https:// address';

  @override
  String get accountServerSaved => 'Server address saved';

  @override
  String get accountServerUrl => 'Server address';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String accountSyncDone(String count) {
    return 'Sync complete: $count bookmarks';
  }

  @override
  String get accountSyncNow => 'Sync now';

  @override
  String get adhanBanner => 'Adhan alerts are off. Turn them on to hear the adhan at every prayer time.';

  @override
  String get adhanBannerAction => 'Turn on';

  @override
  String adhanBellOff(String name) {
    return '$name alert off';
  }

  @override
  String adhanBellOn(String name) {
    return '$name alert on';
  }

  @override
  String adhanBody(String name, String city) {
    return '$name prayer time in $city';
  }

  @override
  String get adhanCredit =>
      'Adhan recording: \"Beautiful adhan\" from Wikimedia Commons (Adam-synagda), public domain CC0.';

  @override
  String get adhanDenied => 'Notifications are not allowed. Turn them on in the system settings.';

  @override
  String get adhanEnable => 'Notify me at prayer times';

  @override
  String get adhanIosNote =>
      'On iPhone the notification plays the opening takbir only (the system allows at most 30 seconds).';

  @override
  String get adhanNote =>
      'Scheduled ahead on this device and works even when the app is closed; opening the app renews them. If an alert is late, allow \"Alarms & reminders\" and turn off battery optimisation for the app.';

  @override
  String get adhanPreview => 'Listen to the adhan';

  @override
  String get adhanPreviewStop => 'Stop';

  @override
  String get adhanSettings => 'Adhan notifications';

  @override
  String get adhanSound => 'Alert sound';

  @override
  String get adhanSoundAdhan => 'Adhan';

  @override
  String get adhanSoundSilent => 'Silent';

  @override
  String get adhanSoundTone => 'Notification tone';

  @override
  String get adhanStop => 'Stop adhan';

  @override
  String get adhanTest => 'Test the alert (in 10 seconds)';

  @override
  String get adhanTestBody => 'If you heard the sound, alerts work on this phone.';

  @override
  String get adhanTestScheduled => 'A test alert will arrive in 10 seconds; you can close the app.';

  @override
  String get adhanTestTitle => 'Adhan alert test';

  @override
  String adhanTitle(String name) {
    return 'Time for $name';
  }

  @override
  String get adhkarArabicOnly => 'This content is available in Arabic only.';

  @override
  String get adhkarCopied => 'Copied';

  @override
  String get adhkarCopy => 'Copy';

  @override
  String get adhkarDone => 'Done';

  @override
  String get adhkarEvening => 'Evening';

  @override
  String get adhkarEveningTitle => 'Evening adhkar';

  @override
  String get adhkarHisn => 'Hisn al-Muslim';

  @override
  String adhkarHisnCount(String n) {
    return '$n entries';
  }

  @override
  String get adhkarHisnSearch => 'Search chapters';

  @override
  String get adhkarMorning => 'Morning';

  @override
  String get adhkarMorningTitle => 'Morning adhkar';

  @override
  String adhkarProgress(String done, String total) {
    return '$done of $total completed';
  }

  @override
  String adhkarRemaining(String n) {
    return '$n left';
  }

  @override
  String adhkarRepeat(String n) {
    return 'Repeat $n';
  }

  @override
  String get adhkarReset => 'Start again';

  @override
  String get adhkarReviewNotice =>
      'Pending religious review. Texts: Kazi Shariar adhkar dataset (CC BY 4.0) and Hisn al-Muslim; repetition counts follow Hisn al-Muslim.';

  @override
  String get adhkarTapToCount => 'Tap a card to count it';

  @override
  String get appName => 'Rattil';

  @override
  String get audioBasmala => 'Basmala';

  @override
  String get audioLoading => 'Loading…';

  @override
  String get audioNext => 'Next ayah';

  @override
  String get audioOffline => 'Couldn\'t load the recitation. Check your internet connection and try again.';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioPlay => 'Play';

  @override
  String get audioPrevious => 'Previous ayah';

  @override
  String get audioReciter => 'Reciter';

  @override
  String get audioRepeat => 'Repeat each ayah';

  @override
  String audioRepeatN(String n) {
    return '$n×';
  }

  @override
  String get audioStop => 'Stop';

  @override
  String get audioStreamNote => 'Recitations are streamed from everyayah.com and need an internet connection.';

  @override
  String get audioTafsirToggle => 'Tafsir with recitation';

  @override
  String get audioTitle => 'Recitation';

  @override
  String bookmarksDelete(String label) {
    return 'Delete bookmark for $label';
  }

  @override
  String get bookmarksEmpty => 'No bookmarks yet';

  @override
  String get commonClose => 'Close';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonOffline => 'You are offline — showing saved content';

  @override
  String get commonRetry => 'Retry';

  @override
  String get hajjHajj => 'Hajj';

  @override
  String get hajjIhram => 'Ihram';

  @override
  String get hajjReviewNotice =>
      'Pending religious review: this guide has not yet been reviewed by a qualified scholar. Check with a trusted scholar before relying on it.';

  @override
  String get hajjTitle => 'Hajj & Umrah';

  @override
  String get hajjUmrah => 'Umrah';

  @override
  String get homeBigAdhkar => 'Adhkar & Dua';

  @override
  String get homeBigPrayer => 'Prayer times';

  @override
  String get homeBigQibla => 'Qibla direction';

  @override
  String get homeBigQuran => 'The Holy Quran';

  @override
  String get homeBigReels => 'Islamic reels';

  @override
  String get homeBigStories => 'Prophets\' stories';

  @override
  String get homeBigTasbih => 'Tasbih';

  @override
  String get homeCalendar => 'Prayer calendar';

  @override
  String homeHijriDate(String day, String month, String year) {
    return '$day $month $year AH';
  }

  @override
  String homeLastPage(String page) {
    return 'Last page: $page';
  }

  @override
  String homeLeft(String time) {
    return 'Time left $time';
  }

  @override
  String get homeMainSections => 'Main sections';

  @override
  String get homeNextPrayer => 'Next prayer';

  @override
  String get homeOpenMushaf => 'Open the Mushaf';

  @override
  String homePrayerOf(String name) {
    return '$name prayer';
  }

  @override
  String get homeQuickLinks => 'Quick links';

  @override
  String get homeSections => 'Sections';

  @override
  String get homeSunrise => 'Sunrise';

  @override
  String get homeSunset => 'Sunset';

  @override
  String get homeTimingFor => 'Times for';

  @override
  String get homeTodayTimes => 'Today\'s prayer times';

  @override
  String get homeTomorrowTimes => 'Tomorrow\'s times';

  @override
  String get homeWelcome => 'Peace be upon you';

  @override
  String get moreTitle => 'More';

  @override
  String get mushafCopied => 'Ayah copied';

  @override
  String get mushafCopy => 'Copy ayah';

  @override
  String get mushafPlayFromHere => 'Listen from here';

  @override
  String get mushafPlayPage => 'Listen to this page';

  @override
  String get mushafPlaySurah => 'Listen to the surah';

  @override
  String get mushafReadAsList => 'Read as a list';

  @override
  String mushafSlider(String page) {
    return 'Page $page of 604';
  }

  @override
  String get mushafTapHint => 'Tap an ayah for listening, bookmark and copy';

  @override
  String get mushafToggleControls => 'Show or hide controls';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navBookmarks => 'Bookmarks';

  @override
  String get navHome => 'Home';

  @override
  String get navMore => 'More';

  @override
  String get navPrayer => 'Prayer';

  @override
  String get navQuran => 'Quran';

  @override
  String get navSettings => 'Settings';

  @override
  String get prayerAdjust => 'Manual adjustment (minutes)';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerAsrHanafi => 'Hanafi';

  @override
  String get prayerAsrMethod => 'Asr method';

  @override
  String get prayerAsrStandard => 'Standard (Shafi\'i, Maliki, Hanbali)';

  @override
  String get prayerCity => 'City';

  @override
  String prayerCompassLabel(String deg) {
    return 'Compass: qibla is $deg° clockwise from north';
  }

  @override
  String prayerDate(String date) {
    return 'Date: $date';
  }

  @override
  String prayerDecrease(String name) {
    return 'Subtract a minute from $name';
  }

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String prayerHighLat(String list) {
    return 'High-latitude rule applied to: $list';
  }

  @override
  String prayerIn(String time) {
    return 'in $time';
  }

  @override
  String prayerIncrease(String name) {
    return 'Add a minute to $name';
  }

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerMethod => 'Calculation method';

  @override
  String prayerMinutesValue(String n) {
    return '$n min';
  }

  @override
  String prayerNext(String name) {
    return 'Next prayer: $name';
  }

  @override
  String get prayerNoPrayerToday => 'Prayer times cannot be calculated here today (polar day or night)';

  @override
  String get prayerNorth => 'N';

  @override
  String get prayerQibla => 'Qibla direction';

  @override
  String prayerQiblaDeg(String deg) {
    return '$deg° from true north';
  }

  @override
  String get prayerQiblaNote => 'Static diagram: hold the phone with the top pointing to true north.';

  @override
  String get prayerResetAdjust => 'Reset adjustments';

  @override
  String get prayerSearchCity => 'Search cities';

  @override
  String get prayerSelectCity => 'Choose city';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String prayerTimezone(String tz) {
    return 'Time zone: $tz';
  }

  @override
  String get prayerTitle => 'Prayer times';

  @override
  String get qiblaFacing => 'You are facing the qibla';

  @override
  String qiblaHeading(String deg) {
    return 'Phone heading: $deg°';
  }

  @override
  String get qiblaLiveNote =>
      'Hold the phone flat, away from metal and magnets; if the reading jumps, move it in a figure 8. The compass measures magnetic north, so it can differ from true north by a few degrees.';

  @override
  String get qiblaStatic => 'No compass reading on this device: the diagram shows the qibla from true north.';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String qiblaTurnLeft(String deg) {
    return 'Turn left $deg°';
  }

  @override
  String qiblaTurnRight(String deg) {
    return 'Turn right $deg°';
  }

  @override
  String get qiblaWaiting => 'Reading the compass…';

  @override
  String quranAyahCount(String count) {
    return '$count ayahs';
  }

  @override
  String quranAyahN(String n) {
    return 'Ayah $n';
  }

  @override
  String get quranBookmark => 'Bookmark ayah';

  @override
  String get quranBookmarkRemoved => 'Bookmark removed';

  @override
  String get quranBookmarked => 'Bookmarked';

  @override
  String get quranContinueReading => 'Continue reading';

  @override
  String get quranFilter => 'Filter surahs';

  @override
  String get quranFilterHint => 'Name or number';

  @override
  String get quranGo => 'Go';

  @override
  String get quranGoToPage => 'Go to page';

  @override
  String quranJuz(String juz) {
    return 'Juz $juz';
  }

  @override
  String get quranMeccan => 'Meccan';

  @override
  String get quranMedinan => 'Medinan';

  @override
  String get quranNextPage => 'Next page';

  @override
  String get quranNoResults => 'No results';

  @override
  String get quranOpenMushaf => 'Open Mushaf pages';

  @override
  String quranPage(String page) {
    return 'Page $page';
  }

  @override
  String get quranPageInvalid => 'Enter a whole number from 1 to 604';

  @override
  String get quranPageNumberHint => '1–604';

  @override
  String get quranPages => 'Mushaf pages';

  @override
  String get quranPrevPage => 'Previous page';

  @override
  String get quranRemoveBookmark => 'Remove bookmark';

  @override
  String quranResultsCount(String count) {
    return '$count results';
  }

  @override
  String get quranSearch => 'Search the Quran';

  @override
  String get quranSearchAction => 'Search';

  @override
  String get quranSearchHint => 'Type an Arabic word';

  @override
  String get quranSearchPrompt => 'Search ignores diacritics (tashkeel)';

  @override
  String get quranSearchTooShort => 'Type at least 2 Arabic letters';

  @override
  String get quranShowTranslation => 'Show English translation';

  @override
  String get quranStartReading => 'Start reading';

  @override
  String quranSurahAyah(String surah, String ayah) {
    return '$surah : $ayah';
  }

  @override
  String quranSurahN(String n) {
    return 'Surah $n';
  }

  @override
  String get quranSurahs => 'Surahs';

  @override
  String get radioDuration => 'Play for';

  @override
  String get radioListen => 'Listen';

  @override
  String get radioLonger => 'Longer';

  @override
  String radioMin(String n) {
    return '$n min';
  }

  @override
  String get radioNote => 'Continuous recitation of the whole Mushaf, starting from a random surah.';

  @override
  String radioNowPlaying(String surah) {
    return 'Surah $surah';
  }

  @override
  String get radioPause => 'Pause';

  @override
  String get radioShorter => 'Shorter';

  @override
  String get radioTitle => 'Quran radio';

  @override
  String get radioUnlimited => 'Unlimited';

  @override
  String get reelsCatLesson => 'Short lesson';

  @override
  String get reelsCatRecitation => 'Moving recitation';

  @override
  String get reelsEmpty => 'No reviewed reels yet. Reels are added after a religious review.';

  @override
  String get reelsFeed => 'reels';

  @override
  String get reelsNext => 'Next reel';

  @override
  String get reelsNote =>
      'Reels play from YouTube through its official player. They are limited to moving Quran recitations and short religious lessons in line with the Quran and Sunnah, and only reviewed reels are shown.';

  @override
  String get reelsOpen => 'Open on YouTube';

  @override
  String get reelsPending => 'This reel has not been religiously reviewed yet — you see it because reviewer mode is on';

  @override
  String reelsPosition(String n, String total) {
    return 'Reel $n of $total';
  }

  @override
  String get reelsPrev => 'Previous reel';

  @override
  String reelsReviewedBy(String name) {
    return 'Reviewed by $name';
  }

  @override
  String get reelsReviewerHint => 'show reels that are not reviewed yet';

  @override
  String get reelsReviewerMode => 'Reviewer mode';

  @override
  String get reelsSub => 'Reviewed short videos';

  @override
  String get reelsTitle => 'Islamic reels';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAccount => 'Account & sync';

  @override
  String get settingsAccountHint => 'Optional — sync bookmarks between devices';

  @override
  String get settingsFontPreview => 'Preview';

  @override
  String get settingsFontSize => 'Quran font size';

  @override
  String get settingsFree => 'This app is completely free: no ads, no subscriptions, no purchases.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageAr => 'العربية';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSources => 'Content sources';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String storiesAyahs(String count) {
    return '$count ayahs';
  }

  @override
  String get storiesBack => 'All stories';

  @override
  String get storiesCatOthers => 'Stories and lessons from the Quran';

  @override
  String get storiesCatProphets => 'Stories of the prophets in the Quran';

  @override
  String get storiesEpisodeError => 'The episode could not be played. Check your internet connection.';

  @override
  String get storiesEpisodePending =>
      'This episode has not been religiously reviewed yet — shown because reviewer mode is on';

  @override
  String storiesEpisodes(String count) {
    return '$count episodes';
  }

  @override
  String get storiesForward => 'Forward 30 seconds';

  @override
  String storiesFrom(String surah, String from, String to) {
    return 'Surah $surah, ayahs $from–$to';
  }

  @override
  String get storiesIntro =>
      'Listen to the stories of the prophets in a calm voice before sleep, or read each story\'s verses from the Mushaf with Tafsir al-Muyassar.';

  @override
  String get storiesListen => 'Listen to the story\'s verses';

  @override
  String storiesMinutes(String n) {
    return '$n min';
  }

  @override
  String get storiesNowPlaying => 'Now playing';

  @override
  String get storiesOnlineOnly => 'Episodes are streamed over the internet';

  @override
  String get storiesPause => 'Pause';

  @override
  String get storiesPlay => 'Listen';

  @override
  String get storiesReadVerses => 'Read the story\'s verses';

  @override
  String get storiesReciter => 'Reciter';

  @override
  String storiesReviewedBy(String name) {
    return 'Reviewed by: $name';
  }

  @override
  String get storiesReviewerMode => 'Reviewer mode (show unreviewed episodes)';

  @override
  String get storiesRewind => 'Back 30 seconds';

  @override
  String storiesSeriesHidden(String title, String narrator) {
    return 'The episodes of “$title” by $narrator appear here once they have been religiously reviewed.';
  }

  @override
  String storiesSeriesSource(String source, String licence) {
    return 'Source: $source. $licence';
  }

  @override
  String get storiesSleep => 'Sleep timer';

  @override
  String storiesSleepLeft(String time) {
    return 'Audio stops in $time min';
  }

  @override
  String storiesSleepMin(String n) {
    return 'After $n min';
  }

  @override
  String get storiesSleepOff => 'Off';

  @override
  String get storiesSource =>
      'Source: the Madinah Mushaf text and Tafsir al-Muyassar (King Fahd Glorious Quran Printing Complex).';

  @override
  String get storiesStop => 'Stop';

  @override
  String get storiesSub => 'Stories of the prophets, in audio and in their verses';

  @override
  String get storiesTafsirHint => 'Tap any ayah to see its Tafsir al-Muyassar.';

  @override
  String get storiesTitle => 'Quranic stories (audio)';

  @override
  String get storiesVersesIntro =>
      'Each story here is its own Quranic verses (Madinah Mushaf), recited by the reciter you choose, with Tafsir al-Muyassar for every ayah.';

  @override
  String get storiesVersesTitle => 'The stories\' verses from the Mushaf';

  @override
  String get tafsirArabicOnly => 'This tafsir is available in Arabic only.';

  @override
  String get tafsirError => 'The tafsir could not be loaded.';

  @override
  String get tafsirLoading => 'Loading the tafsir…';

  @override
  String get tafsirNext => 'Next ayah';

  @override
  String get tafsirPrev => 'Previous ayah';

  @override
  String get tafsirSource => 'King Fahd Glorious Quran Printing Complex';

  @override
  String get tafsirTitle => 'Al-Tafsir al-Muyassar';

  @override
  String get tagline => 'Quran, prayer and remembrance — free, no ads';

  @override
  String tasbihCounter(String count, String target) {
    return 'Count $count of $target';
  }

  @override
  String get tasbihReset => 'Reset';

  @override
  String tasbihRounds(String n) {
    return 'Rounds: $n';
  }

  @override
  String get tasbihTap => 'Tap to count';

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String tasbihTotal(String n) {
    return 'Total: $n';
  }
}
