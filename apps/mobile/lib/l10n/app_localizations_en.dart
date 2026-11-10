// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutFonts =>
      'Fonts: Quran — KFGQPC HAFS Uthmanic Script v18 (King Fahd Complex, unmodified, under its licence); interface — IBM Plex Sans Arabic, SIL Open Font License 1.1.';

  @override
  String get aboutOpenSource => 'Open source and free forever. No tracking, no ads, no in-app purchases.';

  @override
  String get aboutPages =>
      'Mushaf pages and lines: Madinah Mushaf, KFGQPC new edition (1441H), line breaks via quran-madina-html (Waqf General Public License 2.0), checked against the Complex\'s page and line data.';

  @override
  String get aboutPrayerAlgo =>
      'Prayer times are calculated on the device with standard astronomical formulas (Meeus / USNO) and checked against the independent adhan-js library.';

  @override
  String get aboutQuranText =>
      'Quran text: King Fahd Glorious Quran Printing Complex, Hafs Uthmanic Data v18 (hafsData_v18.json), Hafs an Asim. Bundled exactly as published (only the trailing ayah number is removed); verified by SHA-256.';

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
  String get adhanCredit => 'Adhan recordings:';

  @override
  String get adhanDenied => 'Notifications are not allowed. Turn them on in the system settings.';

  @override
  String get adhanEnable => 'Notify me at prayer times';

  @override
  String get adhanExtras => 'Reminder before the adhan and iqama';

  @override
  String get adhanExtrasNote =>
      'The reminder and the iqama alert use the phone\'s short tone, not the adhan recording.';

  @override
  String get adhanFajrVoice => 'Fajr adhan';

  @override
  String get adhanFajrVoiceNote =>
      'The Fajr adhan says «prayer is better than sleep», so it has its own choice and plays only at Fajr.';

  @override
  String get adhanIosNote =>
      'On iPhone the notification plays the opening takbir only (the system allows at most 30 seconds); the full adhan in the chosen voice plays inside the app.';

  @override
  String get adhanIqama => 'Iqama alert after the adhan';

  @override
  String adhanIqamaBody(String name, String minutes) {
    return '$name iqama, $minutes minutes after the adhan';
  }

  @override
  String adhanIqamaDecrease(String name) {
    return 'One minute less before $name iqama';
  }

  @override
  String adhanIqamaIncrease(String name) {
    return 'One minute more before $name iqama';
  }

  @override
  String adhanIqamaMinutes(String n) {
    return '$n min after the adhan';
  }

  @override
  String adhanIqamaTitle(String name) {
    return 'Iqama time for $name';
  }

  @override
  String get adhanNote =>
      'Scheduled ahead on this device and works even when the app is closed; opening the app renews them. If an alert is late, allow \"Alarms & reminders\" and turn off battery optimisation for the app.';

  @override
  String get adhanPre => 'Reminder before the adhan';

  @override
  String adhanPreBody(String name) {
    return 'Get ready for $name prayer';
  }

  @override
  String adhanPreMinutes(String n) {
    return '$n minutes before';
  }

  @override
  String get adhanPreOff => 'Off';

  @override
  String adhanPreTitle(String minutes, String name) {
    return '$minutes minutes until the $name adhan';
  }

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
  String get adhanSoundGeneral => 'Same as the general setting';

  @override
  String get adhanSoundPerPrayer => 'Alert sound per prayer';

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
  String get adhanVoice => 'Muezzin';

  @override
  String get adhanVoiceBundled => 'In the app';

  @override
  String get adhanVoiceDownloadFailed => 'Could not download the adhan. Check the internet and try again.';

  @override
  String get adhanVoiceDownloaded => 'On the phone';

  @override
  String adhanVoiceListen(String name) {
    return 'Listen to $name';
  }

  @override
  String get adhanVoiceNote =>
      'Dhuhr, Asr, Maghrib and Isha. Pick a muezzin and press play to listen; every voice is inside the app and works offline.';

  @override
  String get adhanVoiceSearch => 'Search by muezzin or country';

  @override
  String get adhanVoiceTapToDownload => 'Tap to download';

  @override
  String get adhkarArabicOnly => 'This content is available in Arabic only.';

  @override
  String get adhkarCards => 'One card at a time';

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
  String get adhkarList => 'Show as a list';

  @override
  String get adhkarMorning => 'Morning';

  @override
  String get adhkarMorningTitle => 'Morning adhkar';

  @override
  String get adhkarNextCard => 'Next';

  @override
  String get adhkarPrevCard => 'Previous';

  @override
  String adhkarProgress(String done, String total) {
    return '$done of $total completed';
  }

  @override
  String adhkarRemaining(String n) {
    return '$n left';
  }

  @override
  String get adhkarReminderEvening => 'Evening adhkar reminder';

  @override
  String get adhkarReminderMorning => 'Morning adhkar reminder';

  @override
  String get adhkarReminders => 'Adhkar reminders';

  @override
  String adhkarRepeat(String n) {
    return 'Repeat $n';
  }

  @override
  String get adhkarReport => 'Report a mistake';

  @override
  String get adhkarReportIntro => 'I think there is a mistake in this dhikr (please describe it below):';

  @override
  String get adhkarReset => 'Start again';

  @override
  String get adhkarReviewNotice =>
      'Pending religious review. Texts: Kazi Shariar adhkar dataset (CC BY 4.0) and Hisn al-Muslim; repetition counts follow Hisn al-Muslim.';

  @override
  String get adhkarShare => 'Share';

  @override
  String adhkarShareSourceChapter(String title, String n) {
    return 'Hisn al-Muslim — $title (chapter $n)';
  }

  @override
  String adhkarShareSourceSession(String session) {
    return 'Hisn al-Muslim — $session adhkar';
  }

  @override
  String get adhkarTapToCount => 'Tap a card to count it';

  @override
  String get alertAdhkarEveningBody => 'Time for the evening adhkar';

  @override
  String get alertAdhkarEveningTitle => 'Evening adhkar';

  @override
  String get alertAdhkarMorningBody => 'Time for the morning adhkar';

  @override
  String get alertAdhkarMorningTitle => 'Morning adhkar';

  @override
  String get alertFriday => 'Friday reminder (Surat al-Kahf)';

  @override
  String get alertFridayBody => 'A reminder to read Surat al-Kahf and send many blessings upon the Prophet ﷺ';

  @override
  String get alertFridayTitle => 'Friday';

  @override
  String get alertLastThird => 'Alert at the last third of the night';

  @override
  String get alertLastThirdBody => 'The last third of the night has begun';

  @override
  String get alertLastThirdTitle => 'Last third of the night';

  @override
  String get alertOthers => 'Other alerts';

  @override
  String get alertSunrise => 'Alert at sunrise';

  @override
  String alertSunriseBody(String city) {
    return 'The sun has risen in $city; the Fajr time has ended';
  }

  @override
  String get alertSunriseTitle => 'Sunrise';

  @override
  String get appName => 'Rattil';

  @override
  String get asmaLess => 'Less';

  @override
  String get asmaMore => 'More';

  @override
  String get asmaSearch => 'Find a name';

  @override
  String asmaSeeAlso(String name) {
    return 'Explained together with: $name';
  }

  @override
  String get asmaSource =>
      'Explanations quoted word for word from «تفسير أسماء الله الحسنى» by Sheikh Abd al-Rahman al-Sa\'di (compiled and edited by Ubaid al-Ubaid).';

  @override
  String get asmaTitle => 'Names of Allah';

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
  String audioSpeed(String speed) {
    return 'Playback speed: $speed×';
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
  String get downloadsCancel => 'Stop download';

  @override
  String get downloadsDelete => 'Delete download';

  @override
  String get downloadsDeleteAll => 'Delete all';

  @override
  String get downloadsDownload => 'Download surah';

  @override
  String get downloadsFailed =>
      'The download failed. Check the connection and try again; files already saved are kept.';

  @override
  String get downloadsNote => 'Downloaded surahs play without internet. Downloads are for the reciter chosen now.';

  @override
  String downloadsReciter(String name) {
    return 'Reciter: $name';
  }

  @override
  String get downloadsTitle => 'Downloaded recitations';

  @override
  String downloadsUsed(String mb) {
    return 'Space used: $mb MB';
  }

  @override
  String hadithAttribution(String name, String licence) {
    return 'Hadiths numbered as in al-Alamiyya, from the $name project ($licence).';
  }

  @override
  String get hadithBackToBook => 'Back to the book';

  @override
  String hadithCount(String n) {
    return '$n hadiths';
  }

  @override
  String get hadithFavourites => 'Saved hadiths';

  @override
  String hadithGoTo(String max) {
    return 'Go to hadith number (1–$max)';
  }

  @override
  String get hadithLoadError => 'Couldn\'t open this part of the book.';

  @override
  String get hadithNext => 'Next';

  @override
  String get hadithNoFavourites => 'No saved hadiths yet. Tap the star next to any hadith.';

  @override
  String hadithNumber(String n) {
    return 'Hadith $n';
  }

  @override
  String get hadithPrev => 'Previous';

  @override
  String hadithRange(String from, String to, String count) {
    return 'Hadiths $from–$to of $count';
  }

  @override
  String hadithResults(String n) {
    return '$n results';
  }

  @override
  String hadithResultsMany(String n) {
    return 'First $n results (add more words to narrow it)';
  }

  @override
  String get hadithReview =>
      'Under shar\'i review: the hadith texts are copied unchanged from the open Open-Hadith-Data database and have not yet been checked against a printed edition. If you find a mistake, please report it.';

  @override
  String get hadithSave => 'Save hadith';

  @override
  String hadithSearch(String book) {
    return 'Search $book';
  }

  @override
  String hadithSearching(String done, String total) {
    return 'Searching… part $done of $total';
  }

  @override
  String hadithSource(String book, String n) {
    return '$book, hadith $n (al-Alamiyya numbering)';
  }

  @override
  String get hadithTitle => 'Hadith books';

  @override
  String get hadithUnsave => 'Remove from saved';

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
  String get helpA1 => 'Yes. Rattil has no ads, no subscriptions and no purchases, and it will stay that way.';

  @override
  String get helpA2 =>
      'The Quran text, tafsir, prayer times, qibla, adhkar, tasbih and your bookmarks all work offline. Recitations stream from the internet unless you save the surahs first (More → Downloads).';

  @override
  String get helpA3 =>
      'Mosques use different calculation methods and add a few minutes for caution. Choose your country\'s method and Asr school in the prayer settings, and adjust each prayer by minutes if needed.';

  @override
  String get helpA4 => 'In Settings → Recitation, or from the player itself while a recitation is playing.';

  @override
  String get helpA5 =>
      'On this phone only: bookmarks, khatma, worship tracker and settings never leave it unless you turn on account sync yourself.';

  @override
  String get helpA6 =>
      'Allow notifications for Rattil and, on Android, \"alarms and reminders\". Some phones stop apps in the background to save battery: exclude Rattil from battery optimisation.';

  @override
  String get helpA7 =>
      'Use \"Report a mistake\" under the dhikr, or write to us below. Religious texts come from published sources and go through a review.';

  @override
  String get helpContact => 'Contact us';

  @override
  String get helpContactPending => 'The contact address will be added soon.';

  @override
  String get helpEmail => 'Send us an email';

  @override
  String get helpFaq => 'Frequently asked questions';

  @override
  String get helpNotNow => 'Not now';

  @override
  String get helpPromptBody =>
      'You have been using Rattil for a few days. If it helps you, share it with someone; it is free for everyone.';

  @override
  String get helpPromptTitle => 'Share Rattil?';

  @override
  String get helpQ1 => 'Is Rattil really free?';

  @override
  String get helpQ2 => 'What works without the internet?';

  @override
  String get helpQ3 => 'Why do the prayer times differ from my mosque?';

  @override
  String get helpQ4 => 'How do I change the reciter or the speed?';

  @override
  String get helpQ5 => 'Where is my data kept?';

  @override
  String get helpQ6 => 'Why did the adhan not sound?';

  @override
  String get helpQ7 => 'I found a mistake in a text. What should I do?';

  @override
  String get helpRate => 'Rate Rattil';

  @override
  String get helpRatePending => 'Rating opens once the app is in the stores.';

  @override
  String get helpShareApp => 'Share Rattil';

  @override
  String get helpShareText => 'Rattil: Quran, prayer times and adhkar, free with no ads.';

  @override
  String get helpSpread => 'Share and rate';

  @override
  String get helpSpreadBody => 'If Rattil helps you, share it with family and friends.';

  @override
  String get helpTitle => 'Help & contact';

  @override
  String get hisnSectionFood => 'Food and fasting';

  @override
  String get hisnSectionHajj => 'Hajj and umrah';

  @override
  String get hisnSectionHardship => 'Worry and hardship';

  @override
  String get hisnSectionHome => 'Home and clothing';

  @override
  String get hisnSectionIllness => 'Illness and death';

  @override
  String get hisnSectionMorningEvening => 'Morning and evening';

  @override
  String get hisnSectionNature => 'Rain, wind and the new moon';

  @override
  String get hisnSectionPeople => 'Family and people';

  @override
  String get hisnSectionPrayer => 'Purification, mosque and prayer';

  @override
  String get hisnSectionRemembrance => 'Remembrance and its virtue';

  @override
  String get hisnSectionSleep => 'Sleep and waking';

  @override
  String get hisnSectionTravel => 'Travel';

  @override
  String get hisnSectionAll => 'All';

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
  String homeElapsed(String time) {
    return '$time ago';
  }

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
  String khatmaAhead(String n) {
    return '$n portions ahead of the plan, may Allah bless you.';
  }

  @override
  String khatmaBehind(String n) {
    return '$n days behind the plan.';
  }

  @override
  String get khatmaByDays => 'Number of days';

  @override
  String get khatmaByPages => 'Pages per day';

  @override
  String khatmaCurrentWird(String n, String total) {
    return 'Current portion ($n of $total)';
  }

  @override
  String get khatmaDays => 'Finish in (days)';

  @override
  String khatmaDaysN(String n) {
    return '$n days';
  }

  @override
  String get khatmaDefaultName => 'My khatma';

  @override
  String get khatmaDelete => 'Delete khatma';

  @override
  String get khatmaDeleteConfirm => 'Delete this khatma? This cannot be undone.';

  @override
  String khatmaEndsOn(String date) {
    return 'Finishes on: $date';
  }

  @override
  String khatmaFinishedOn(String date, String days) {
    return 'completed on $date in $days days';
  }

  @override
  String get khatmaHistory => 'Completed khatmas';

  @override
  String get khatmaHistoryEmpty => 'You have not completed a khatma yet.';

  @override
  String khatmaJuz(String n) {
    return 'Juz $n';
  }

  @override
  String get khatmaMarkDone => 'I have read it';

  @override
  String get khatmaName => 'Khatma name';

  @override
  String get khatmaNew => 'New khatma';

  @override
  String get khatmaOpening => 'من قوله تعالى:';

  @override
  String get khatmaPagesPerDay => 'Pages each day';

  @override
  String khatmaPreview(String wirds, String pages, String end) {
    return '$wirds portions, about $pages pages a day, finishing on $end.';
  }

  @override
  String khatmaRange(String fromSurah, String fromAyah, String fromPage, String toSurah, String toAyah, String toPage) {
    return 'From surah $fromSurah ayah $fromAyah, page $fromPage to surah $toSurah ayah $toAyah, page $toPage';
  }

  @override
  String get khatmaRead => 'Read the portion';

  @override
  String get khatmaRemainingDays => 'Days left';

  @override
  String get khatmaRemainingWirds => 'Portions left';

  @override
  String get khatmaReminder => 'Daily reminder';

  @override
  String khatmaReminderBody(String name) {
    return 'Time for today\'s portion of “$name”';
  }

  @override
  String get khatmaReminderTitle => 'Khatma portion';

  @override
  String get khatmaRename => 'Edit';

  @override
  String get khatmaReschedule => 'Spread the rest again';

  @override
  String get khatmaShowAll => 'Show all';

  @override
  String get khatmaStart => 'Start the khatma';

  @override
  String get khatmaTileSub => 'A daily plan to complete the Mushaf';

  @override
  String get khatmaTitle => 'Quran khatma';

  @override
  String get libraryAllRiwayat => 'All riwayat';

  @override
  String get libraryEmpty => 'No results.';

  @override
  String get libraryLive => 'Live';

  @override
  String get libraryLoadError => 'Couldn\'t load the list. Check your connection and try again.';

  @override
  String get libraryRadios => 'Radios';

  @override
  String get libraryReciters => 'Reciters';

  @override
  String get libraryRetry => 'Try again';

  @override
  String get libraryRewaya => 'Riwaya';

  @override
  String get librarySearch => 'Search by name';

  @override
  String get librarySource => 'Recitations and radios are streamed over the internet.';

  @override
  String librarySurahCount(String n) {
    return '$n surahs';
  }

  @override
  String librarySurahTitle(String reciter, String surah) {
    return '$reciter — Surah $surah';
  }

  @override
  String get libraryTitle => 'Recitations and radios';

  @override
  String get moreTitle => 'More';

  @override
  String mosquesAround(String place) {
    return 'Mosques around $place';
  }

  @override
  String mosquesCount(String n) {
    return '$n mosques, nearest first. Tap one for directions.';
  }

  @override
  String get mosquesError => 'Could not reach OpenStreetMap. Check your internet connection.';

  @override
  String get mosquesGeoFallback =>
      'Your location is not available (turn on GPS and allow location). Showing mosques around your prayer-times city.';

  @override
  String mosquesKm(String n) {
    return '$n km';
  }

  @override
  String get mosquesLoading => 'Searching for mosques…';

  @override
  String get mosquesLocate => 'Update my location';

  @override
  String get mosquesLocating => 'Finding your location…';

  @override
  String mosquesMeters(String n) {
    return '$n m';
  }

  @override
  String get mosquesMyLocation => 'your current location';

  @override
  String get mosquesNone => 'No mosques are mapped within this distance. Try a larger one.';

  @override
  String get mosquesNote =>
      'Straight-line distance. Data from the open OpenStreetMap map; it can be incomplete in some places.';

  @override
  String get mosquesOffline => '(last saved result, you are offline)';

  @override
  String get mosquesOnGoogleMaps => 'Open nearby mosques in Google Maps';

  @override
  String get mosquesRetry => 'Try again';

  @override
  String get mosquesTitle => 'Nearby mosques';

  @override
  String get mosquesUnnamed => 'Mosque (no name on the map)';

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
  String get mushafShareImage => 'Share as image';

  @override
  String get mushafShareImageTitle => 'Ayah image';

  @override
  String get mushafShareNow => 'Share';

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
  String get offlineDone => 'Saved: you can listen without internet';

  @override
  String get offlineDownload => 'Download for offline listening';

  @override
  String get offlineFailed => 'Download failed. Check the internet and try again';

  @override
  String get offlineSavedDelete => 'Saved on the phone — tap to delete';

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
  String get prayerBackToToday => 'Back to today';

  @override
  String get prayerCalendarTitle => 'Monthly prayer calendar';

  @override
  String get prayerCity => 'City';

  @override
  String get prayerClock => 'Time format';

  @override
  String get prayerClock12 => '12-hour (1:05 PM)';

  @override
  String get prayerClock24 => '24-hour (13:05)';

  @override
  String prayerCompassLabel(String deg) {
    return 'Compass: qibla is $deg° clockwise from north';
  }

  @override
  String prayerDate(String date) {
    return 'Date: $date';
  }

  @override
  String get prayerDayCol => 'Day';

  @override
  String prayerDecrease(String name) {
    return 'Subtract a minute from $name';
  }

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerGeoDenied => 'Location permission was denied. Choose a city from the list instead.';

  @override
  String get prayerGeoUnavailable => 'Could not get your location. Turn on location services or choose a city.';

  @override
  String get prayerGregorian => 'Gregorian';

  @override
  String prayerHighLat(String list) {
    return 'High-latitude rule applied to: $list';
  }

  @override
  String get prayerHijri => 'Hijri';

  @override
  String get prayerHijriCol => 'Hijri';

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
  String get prayerLocating => 'Locating…';

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
  String get prayerNextDay => 'Next day';

  @override
  String get prayerNextMonth => 'Next month';

  @override
  String get prayerNoPrayerToday => 'Prayer times cannot be calculated here today (polar day or night)';

  @override
  String get prayerNorth => 'N';

  @override
  String get prayerOpenCalendar => 'Monthly calendar';

  @override
  String get prayerPrevDay => 'Previous day';

  @override
  String get prayerPrevMonth => 'Previous month';

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
  String get prayerShareCalendar => 'Share the calendar';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String prayerTimezone(String tz) {
    return 'Time zone: $tz';
  }

  @override
  String get prayerTitle => 'Prayer times';

  @override
  String get prayerUseLocation => 'Use my location';

  @override
  String qiblaDeclination(String deg) {
    return 'Corrected from magnetic to true north: $deg°';
  }

  @override
  String get qiblaDirection => 'Qibla direction';

  @override
  String get qiblaDistance => 'Distance to the Kaaba';

  @override
  String get qiblaEast => 'E';

  @override
  String get qiblaFacing => 'You are facing the qibla';

  @override
  String qiblaHeading(String deg) {
    return 'Phone heading: $deg°';
  }

  @override
  String get qiblaLiveNote =>
      'Hold the phone flat, away from metal and magnets; if the reading jumps, move it in a figure 8. The phone\'s compass points to magnetic north; the app corrects it to true north for your city.';

  @override
  String get qiblaSouth => 'S';

  @override
  String get qiblaStatic => 'No compass reading on this device: the diagram shows the qibla from true north.';

  @override
  String get qiblaTipsTitle => 'For an accurate reading';

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
  String get qiblaWest => 'W';

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
  String get quranClearSearch => 'Clear search';

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
  String quranHizbN(String n) {
    return 'Hizb $n';
  }

  @override
  String get quranIndex => 'Quran index';

  @override
  String get quranIndexSearch => 'Search';

  @override
  String quranJuz(String juz) {
    return 'Juz $juz';
  }

  @override
  String get quranJuzOrdinals => '1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30';

  @override
  String quranJuzTitle(String ordinal) {
    return 'Juz $ordinal';
  }

  @override
  String get quranListView => 'List view';

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
  String quranQuarterLine(String surah, String ayah, String page) {
    return '$surah $ayah · Page $page';
  }

  @override
  String quranQuarterOfHizb(String q, String n) {
    return 'Quarter $q of hizb $n';
  }

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
  String quranSurahLine(String page, String count, String kind) {
    return 'Page $page · $count ayahs · $kind';
  }

  @override
  String quranSurahN(String n) {
    return 'Surah $n';
  }

  @override
  String quranSurahTitle(String name) {
    return '$name';
  }

  @override
  String get quranSurahs => 'Surahs';

  @override
  String get quranTabQuarters => 'Quarters';

  @override
  String get quranTabSurahs => 'Surahs';

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
  String get radiosFeatured => 'Live';

  @override
  String get radiosMore => 'More radios';

  @override
  String get radiosTitle => 'Quran radios';

  @override
  String get readerBack => 'Back to the index';

  @override
  String get readerBasmalaNow => 'Reciting the basmala';

  @override
  String get readerBookmarks => 'Bookmarks';

  @override
  String get readerFont => 'Text size';

  @override
  String readerFontSize(String size) {
    return 'Text size: $size — press to enlarge';
  }

  @override
  String get readerHelp => 'Help';

  @override
  String get readerHelp1 => 'Swipe the page to turn it, or use the page slider.';

  @override
  String get readerHelp2 => 'Tap any ayah to listen to it and read its tafsir.';

  @override
  String get readerHelp3 =>
      '“Listen with tafsir” splits the screen in two: the ayah being recited, and its short tafsir below it.';

  @override
  String get readerHelpTitle => 'How to use';

  @override
  String get readerIndex => 'Index';

  @override
  String get readerKhatma => 'Khatma';

  @override
  String readerKhatmaContinue(String page) {
    return 'Continue from page $page';
  }

  @override
  String get readerKhatmaDone => 'Khatma complete. May Allah accept it from you.';

  @override
  String readerKhatmaLeft(String left) {
    return '$left pages left';
  }

  @override
  String get readerKhatmaNone => 'No khatma yet. Start one and your progress is counted from the last page you read.';

  @override
  String readerKhatmaProgress(String done, String pct) {
    return 'Read $done of 604 pages ($pct%)';
  }

  @override
  String get readerKhatmaReset => 'Cancel the khatma';

  @override
  String readerKhatmaSince(String date) {
    return 'Started on $date';
  }

  @override
  String get readerKhatmaStart => 'Start a new khatma from al-Fatihah';

  @override
  String get readerKhatmaTitle => 'Khatma (complete reading)';

  @override
  String get readerListenWithTafsir => 'Listen with tafsir';

  @override
  String get readerPlayAyah => 'Listen to this ayah';

  @override
  String get readerPlayWithTafsir => 'Listen with tafsir';

  @override
  String readerRepeatN(String n) {
    return 'Repeat: $n';
  }

  @override
  String get readerSearch => 'Search';

  @override
  String get readerShowPage => 'Show the page';

  @override
  String get readerSplitTafsir => 'Short tafsir';

  @override
  String get readerSplitTitle => 'Now reciting';

  @override
  String get readerTabAyat => 'Verses';

  @override
  String get readerTabMushaf => 'Mushaf';

  @override
  String get readerTabTafsir => 'Tafsir';

  @override
  String get reelsCatAdmonition => 'Advice & admonition';

  @override
  String get reelsCatLesson => 'Religious lesson';

  @override
  String get reelsCatRecitation => 'Quran recitation';

  @override
  String get reelsEmpty => 'No reels to show right now.';

  @override
  String get reelsFeed => 'reels';

  @override
  String reelsHidden(String name) {
    return '$name hidden';
  }

  @override
  String get reelsHide => 'Hide this channel';

  @override
  String get reelsLoading => 'Fetching the newest reels…';

  @override
  String get reelsNext => 'Next reel';

  @override
  String get reelsNote =>
      'Reels play from YouTube and Instagram in their official players, and come automatically from trusted Islamic channels the app approved (Quran recitations, religious lessons, advice and admonitions).';

  @override
  String get reelsOffline => 'Could not reach YouTube. Check your internet connection and try again.';

  @override
  String get reelsOpenInstagram => 'Open on Instagram';

  @override
  String get reelsOpenYoutube => 'Open on YouTube';

  @override
  String get reelsPending => 'This reel has not been religiously reviewed yet — you see it because reviewer mode is on';

  @override
  String get reelsPlatformInstagram => 'Instagram';

  @override
  String get reelsPlatformYoutube => 'YouTube';

  @override
  String reelsPosition(String n, String total) {
    return 'Reel $n of $total';
  }

  @override
  String get reelsPrev => 'Previous reel';

  @override
  String get reelsRetry => 'Try again';

  @override
  String reelsReviewedBy(String name) {
    return 'Reviewed by $name';
  }

  @override
  String get reelsReviewerHint => 'show reels that are not reviewed yet';

  @override
  String get reelsReviewerMode => 'Reviewer mode';

  @override
  String get reelsShowHidden => 'Show hidden channels';

  @override
  String get reelsSub => 'Recitations, lessons and admonitions from trusted channels';

  @override
  String get reelsTapToPlay => 'Tap to play';

  @override
  String get reelsTitle => 'Islamic reels';

  @override
  String get reelsTrusted => 'Trusted channel';

  @override
  String get reelsUndo => 'Undo';

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
  String get settingsFree => 'A free app made for the sake of Allah: no charge and no ads.';

  @override
  String get settingsHijriOffset => 'Hijri date adjustment';

  @override
  String get settingsHijriOffsetHint =>
      'Umm al-Qura. Shift by a day or two to match the moon sighting announced in your country.';

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
  String get shortcutAdhkar => 'Adhkar';

  @override
  String get shortcutPrayer => 'Prayer times';

  @override
  String get shortcutQuran => 'Quran';

  @override
  String get shortcutTasbih => 'Tasbih';

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
  String get tasbihAdd => 'Add';

  @override
  String get tasbihCancel => 'Cancel';

  @override
  String get tasbihClear => 'Clear';

  @override
  String get tasbihClearConfirm => 'Clear the whole tasbih history?';

  @override
  String get tasbihClearHistory => 'Clear history';

  @override
  String get tasbihColor => 'Colour';

  @override
  String tasbihCounter(String count, String target) {
    return 'Count $count of $target';
  }

  @override
  String get tasbihHistory => 'History';

  @override
  String get tasbihHistoryEmpty => 'Nothing counted yet.';

  @override
  String get tasbihMine => 'My adhkar';

  @override
  String get tasbihMode => 'Counter style';

  @override
  String get tasbihModeBeads => 'Beads';

  @override
  String get tasbihModeButton => 'Big button';

  @override
  String get tasbihNewDhikr => 'Type a dhikr to count';

  @override
  String get tasbihPhrase => 'Dhikr';

  @override
  String tasbihRemove(String name) {
    return 'Delete “$name”';
  }

  @override
  String get tasbihReset => 'Reset';

  @override
  String tasbihRounds(String n) {
    return 'Rounds: $n';
  }

  @override
  String get tasbihSound => 'Sound on each count';

  @override
  String get tasbihTap => 'Tap to count';

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String tasbihToday(String n) {
    return 'Today for this dhikr: $n';
  }

  @override
  String tasbihTotal(String n) {
    return 'Total: $n';
  }

  @override
  String get tasbihUndo => 'Undo';

  @override
  String get tasbihVibrate => 'Vibration';

  @override
  String worshipFasted(String n) {
    return 'Fasting days: $n';
  }

  @override
  String get worshipFasting => 'Fasting';

  @override
  String worshipFullDays(String n) {
    return 'Full days: $n';
  }

  @override
  String get worshipMonth => 'Month';

  @override
  String get worshipNote => 'Note';

  @override
  String worshipPrayedOf(String n, String total) {
    return '$n of $total prayers';
  }

  @override
  String get worshipPrayers => 'Prayers';

  @override
  String get worshipPrivate => 'Kept on this device only.';

  @override
  String worshipStreak(String n) {
    return 'Days in a row with all five prayers: $n';
  }

  @override
  String get worshipTitle => 'Worship tracker';

  @override
  String get worshipToday => 'Today';

  @override
  String get worshipWeek => 'Last 7 days';

  @override
  String get zakatAdornment => 'Gold worn for adornment';

  @override
  String zakatBelowNisab(String net, String nisab) {
    return 'Your wealth after debts ($net) is below the nisab ($nisab), so no zakat is due on it now.';
  }

  @override
  String zakatDue(String zakat) {
    return 'Zakat due: $zakat';
  }

  @override
  String zakatDueDetail(String net, String nisab) {
    return 'One fortieth (2.5%) of $net; the nisab is $nisab.';
  }

  @override
  String zakatFatwa(String n) {
    return 'Fatwa no. $n on Dar al-Ifta\'s website';
  }

  @override
  String get zakatFieldCash => 'Cash and bank balances';

  @override
  String get zakatFieldCertificateReturns => 'Certificate returns you add to the capital at year end';

  @override
  String get zakatFieldCertificates => 'Bank certificates and deposits (principal)';

  @override
  String get zakatFieldDebts => 'Debts now due from you (subtracted)';

  @override
  String get zakatFieldGold18 => 'Gold kept as savings or investment, 18 karat (grams)';

  @override
  String get zakatFieldGold21 => 'Gold kept as savings or investment, 21 karat (grams)';

  @override
  String get zakatFieldGold24 => 'Gold kept as savings or investment, 24 karat (grams)';

  @override
  String get zakatFieldShares => 'Shares kept as savings (today\'s value with profits)';

  @override
  String get zakatFieldTrade => 'Trade goods (market price)';

  @override
  String get zakatNeedPrice => 'Enter the price of a gram of 21-karat gold to work out the nisab.';

  @override
  String zakatNisabRule(String grams, String karat) {
    return 'The nisab is the value of $grams grams of $karat-karat gold, so enter today\'s market price per gram.';
  }

  @override
  String get zakatPrice => 'Price of one gram of 21-karat gold today (your currency)';

  @override
  String get zakatPriceTitle => 'Today\'s gold price';

  @override
  String get zakatResult => 'Result';

  @override
  String get zakatReview =>
      'Pending a shar\'i review: the calculator follows the published fatwas of Egypt\'s Dar al-Ifta (linked below) and has not been reviewed by a scholar yet. If your case is unclear, ask Dar al-Ifta.';

  @override
  String zakatSources(String ref) {
    return 'Sources: fatwas of $ref';
  }

  @override
  String get zakatTileSub => 'Zakat on money, after Egypt\'s Dar al-Ifta';

  @override
  String get zakatTitle => 'Zakat calculator';

  @override
  String get zakatWealth => 'Your wealth (in your currency; gold in grams)';

  @override
  String zakatYearNotPassed(String net, String nisab) {
    return 'Your wealth ($net) has reached the nisab ($nisab); zakat is due once a full Hijri year passes over it.';
  }

  @override
  String get zakatYearPassed => 'A full Hijri year has passed since my wealth reached the nisab';
}
