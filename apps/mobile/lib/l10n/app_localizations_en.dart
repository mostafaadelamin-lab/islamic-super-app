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
  String get adhanAlarmOfferBody =>
      'Allow it once and the whole adhan rings as one alarm, even when the iPhone is on silent, instead of several notifications one after another on the lock screen.';

  @override
  String get adhanAlarmOfferTitle => 'The whole adhan on iPhone';

  @override
  String get adhanAlertsHeader => 'Adhan alerts';

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
  String get adhanContinued => 'The adhan continues. Tap to hear all of it in the app.';

  @override
  String adhanContinuedTitle(String name, String k, String n) {
    return '$name adhan continues ($k of $n)';
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
  String get adhanIosAlarm => 'Full adhan as an alarm';

  @override
  String get adhanIosAlarmDenied => 'Allow alarms for Rattil wa Salli in the iPhone Settings, then turn this on again.';

  @override
  String get adhanIosAlarmHint =>
      'The whole adhan rings like an alarm clock, even when the iPhone is on silent, with a stop button on the lock screen. iOS 26 or newer.';

  @override
  String get adhanIosFullHint =>
      'On iPhone the whole adhan rings in parts, one after another. Open the app every day or two to keep it full; otherwise only the first 30 seconds ring.';

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
  String get adhanNowPlaying => 'Adhan';

  @override
  String get adhanOpenApp => 'Continue in app';

  @override
  String get adhanOpenAppBody => 'Just open the app once to renew the full adhan alerts for the next two days.';

  @override
  String get adhanOpenAppTitle => 'Open Rattil wa Salli to keep the full adhan';

  @override
  String get adhanPlayOnSilent => 'Play the adhan when the phone is silent';

  @override
  String get adhanPlayOnSilentHint =>
      'The adhan plays at alarm volume even on silent or vibrate, like an alarm clock. Applies to the full adhan only.';

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
  String get adhanTabTitle => 'Adhan';

  @override
  String get adhanTapForFull => 'Tap to hear the whole adhan in the app.';

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
  String get adhkarAfterPrayer => 'Adhkar after prayer';

  @override
  String get adhkarAlafasy => 'Recited by Sheikh Mishary Rashid Alafasy';

  @override
  String get adhkarArabicOnly => 'This content is available in Arabic only.';

  @override
  String get adhkarAudioDownloadFailed => 'Couldn\'t download the recording. Check your internet and try again.';

  @override
  String get adhkarAudioDownloading =>
      'Downloading the recording for the first time (about 4 MB); after that it plays without internet.';

  @override
  String get adhkarAudioWatchOnline => 'Listen online';

  @override
  String get adhkarBarAdd => 'Add';

  @override
  String get adhkarBarAlarm => 'Alarm';

  @override
  String get adhkarBarDrive => 'Drive';

  @override
  String get adhkarBarReset => 'Restart';

  @override
  String get adhkarBarView => 'View';

  @override
  String get adhkarCards => 'One card at a time';

  @override
  String get adhkarCopied => 'Copied';

  @override
  String get adhkarCopy => 'Copy';

  @override
  String get adhkarDaily => 'Daily adhkar';

  @override
  String get adhkarDone => 'Done';

  @override
  String get adhkarDuas => 'Duas';

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
  String adhkarItemOf(String n, String total) {
    return 'Dhikr $n of $total';
  }

  @override
  String get adhkarList => 'Show as a list';

  @override
  String get adhkarListen => 'Listen (Mishary Alafasy)';

  @override
  String get adhkarListenHeader => 'Listen to the adhkar';

  @override
  String get adhkarMine => 'My adhkar';

  @override
  String get adhkarMineAdd => 'Add a dhikr';

  @override
  String get adhkarMineAddLong => 'Add your own dhikr';

  @override
  String get adhkarMineBoth => 'Both';

  @override
  String get adhkarMineCancel => 'Cancel';

  @override
  String get adhkarMineCount => 'Number of times';

  @override
  String get adhkarMineDelete => 'Delete';

  @override
  String get adhkarMineDeleteAsk => 'Delete this dhikr from your adhkar?';

  @override
  String get adhkarMineEdit => 'Edit';

  @override
  String get adhkarMineEditTitle => 'Edit dhikr';

  @override
  String get adhkarMineHint =>
      'Write the dhikr you need; it is added to the end of the list with a counter like the others.';

  @override
  String get adhkarMineLess => 'Fewer';

  @override
  String get adhkarMineMore => 'More';

  @override
  String get adhkarMineSave => 'Save';

  @override
  String get adhkarMineShowIn => 'Show in';

  @override
  String get adhkarMineTag => 'Added by you';

  @override
  String get adhkarMineTextHint => 'Write the dhikr here';

  @override
  String adhkarMineTimes(String n) {
    return '$n times';
  }

  @override
  String get adhkarMorning => 'Morning';

  @override
  String get adhkarMorningTitle => 'Morning adhkar';

  @override
  String get adhkarNextCard => 'Next';

  @override
  String get adhkarOfflineNote => 'Saved on your phone; plays without internet.';

  @override
  String adhkarPercentDone(String p) {
    return '$p% done';
  }

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
  String adhkarRepeatTimes(String n) {
    return 'Repeat: $n';
  }

  @override
  String get adhkarReport => 'Report a mistake';

  @override
  String get adhkarReportIntro => 'I think there is a mistake in this dhikr (please describe it below):';

  @override
  String get adhkarReportTitle => 'Mistake in a dhikr';

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
  String get adhkarSleep => 'Adhkar before sleep';

  @override
  String get adhkarTapCounter => 'Tap the circle to count; it moves on when the count is complete';

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
  String get appName => 'Rattil wa Salli';

  @override
  String get asmaLess => 'Less';

  @override
  String get asmaLessonBy => 'Explained by Sheikh Muhammad Ratib al-Nabulsi';

  @override
  String get asmaListenLesson => 'Listen to the explanation';

  @override
  String get asmaMore => 'More';

  @override
  String asmaPart(String n) {
    return 'Lesson $n';
  }

  @override
  String get asmaSearch => 'Find a name';

  @override
  String asmaSeeAlso(String name) {
    return 'Explained together with: $name';
  }

  @override
  String get asmaSource =>
      'A simplified explanation of the 99 Names of Allah, quoted word for word from a published source.';

  @override
  String get asmaStop => 'Stop';

  @override
  String get asmaTitle => 'Names of Allah';

  @override
  String asmaLessonTitle(String name) {
    return 'Explanation of «$name»';
  }

  @override
  String get audioBasmala => 'Basmala';

  @override
  String get audioClose => 'Close player';

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
  String get ayahCopy => 'Copy the ayah';

  @override
  String get ayahCopyShort => 'Copy';

  @override
  String get ayahListen => 'Listen';

  @override
  String get ayahListenOne => 'Listen to this ayah only';

  @override
  String get ayahListenTafsir => 'Listen with tafsir';

  @override
  String get ayahListenToPageEnd => 'Listen from here to the end of the page';

  @override
  String get ayahListenToSurahEnd => 'Listen from here to the end of the surah';

  @override
  String get ayahMarkShort => 'Mark';

  @override
  String get ayahOnlyThis => 'This ayah';

  @override
  String get ayahSaveMark => 'Save a mark on this ayah';

  @override
  String get ayahShare => 'Share';

  @override
  String get ayahShareImage => 'Share as an image';

  @override
  String get ayahTafsir => 'Ayah tafsir';

  @override
  String get ayahToPageEnd => 'To page end';

  @override
  String get ayahToSurahEnd => 'To surah end';

  @override
  String get ayahUnmarkShort => 'Unmark';

  @override
  String get ayahWithTafsir => 'With tafsir';

  @override
  String bookmarksDelete(String label) {
    return 'Delete bookmark for $label';
  }

  @override
  String get bookmarksEmpty => 'No bookmarks yet';

  @override
  String get carAfhamSub => 'Every topic and lesson series';

  @override
  String carEpisodes(String n) {
    return '$n episodes';
  }

  @override
  String get carKidsRuqyahSub => 'The ruqyah verses, recited';

  @override
  String get carKidsSub => 'Teaching Mushaf · stories · ruqyah';

  @override
  String get carLibrary => 'Recitation library';

  @override
  String get carLibrarySub => 'Reciters · surah by surah';

  @override
  String get carNasheeds => 'Nasheeds';

  @override
  String get carNasheedsSub => 'Munshids';

  @override
  String get carRadio => 'Radio';

  @override
  String carSeriesCount(String n) {
    return '$n series';
  }

  @override
  String get carSharawiSub => 'Quran tafsir · Seerah · Prophets\' stories';

  @override
  String get carStories => 'Stories of the Prophets';

  @override
  String get carStoriesSub => 'Sheikh Nabil al-Awadi';

  @override
  String get carText => 'Dhikr text';

  @override
  String get commonClose => 'Close';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonOffline => 'You are offline — showing saved content';

  @override
  String get commonRetry => 'Retry';

  @override
  String get contactFailed => 'Could not send. Check your internet connection and try again.';

  @override
  String get contactIntro =>
      'Write your request and it will reach the team. Add your phone or WhatsApp number if you want a reply. If you are under 13, please ask a parent to send the message.';

  @override
  String get contactMessage => 'Message';

  @override
  String get contactMessageRequired => 'Please write your message';

  @override
  String get contactName => 'Name';

  @override
  String get contactPhone => 'Phone number (optional)';

  @override
  String get contactSend => 'Send';

  @override
  String get contactThanks => 'Your message was sent. Thank you!';

  @override
  String get contactTitle => 'Request title';

  @override
  String get contactTitleRequired => 'Please write a title';

  @override
  String get contactWhatsapp => 'WhatsApp number (optional)';

  @override
  String get dhikrHadith => 'The hadith';

  @override
  String get dhikrHadithFadl => 'Its virtue';

  @override
  String get dhikrHadithSource => 'Where it is reported';

  @override
  String get dhikrHadithText => 'The hadith about this dhikr';

  @override
  String get dhikrListen => 'Listen to this dhikr';

  @override
  String get dhikrListenFailed => 'Could not play; check your internet';

  @override
  String get dhikrListenStop => 'Stop';

  @override
  String get dhikrRemCancel => 'Cancel';

  @override
  String get dhikrRemCustom => 'Other…';

  @override
  String get dhikrRemCustomTitle => 'Every how many minutes?';

  @override
  String get dhikrRemEnable => 'Remind me of dhikr through the day';

  @override
  String get dhikrRemEnableHint =>
      'Shows on the screen; when the phone is not on silent, Sheikh Mishary Alafasy says it';

  @override
  String get dhikrRemEvery => 'How often?';

  @override
  String get dhikrRemFrom => 'From';

  @override
  String get dhikrRemHour => '1 hour';

  @override
  String dhikrRemHours(String n) {
    return '$n hours';
  }

  @override
  String dhikrRemIosCap(String n) {
    return 'iPhone allows a limited number of reminders, so they come every $n minutes in this window';
  }

  @override
  String get dhikrRemIosFull =>
      'On iPhone the adhan and its alerts come first and now take every free place, so no dhikr reminder will come. Turn off some adhan alerts (like the one before the adhan) to get them.';

  @override
  String get dhikrRemListen => 'Listen';

  @override
  String dhikrRemMinutes(String n) {
    return '$n min';
  }

  @override
  String get dhikrRemNotifTitle => 'Dhikr';

  @override
  String get dhikrRemOk => 'OK';

  @override
  String get dhikrRemPick => 'Choose the adhkar';

  @override
  String get dhikrRemPickHint => '(said in turn)';

  @override
  String get dhikrRemPickOne => 'Choose at least one dhikr';

  @override
  String dhikrRemSummary(String count) {
    return '$count reminders a day';
  }

  @override
  String get dhikrRemTitle => 'Dhikr reminders';

  @override
  String get dhikrRemTo => 'To';

  @override
  String get dhikrRemTwoHours => '2 hours';

  @override
  String get dhikrRemWindowHint => 'No reminders while you sleep';

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
  String get driveAgain => 'Start again';

  @override
  String get driveBarOpen => 'Open driving mode';

  @override
  String driveBarRep(String n, String count) {
    return 'Time $n of $count';
  }

  @override
  String get driveCarHint =>
      'Control it from the car screen, the steering-wheel buttons or the lock screen: next = next dhikr, previous = this dhikr again, pause resumes at the same count.';

  @override
  String driveCountOf(String n, String count) {
    return '$n of $count';
  }

  @override
  String get driveCues => 'Soft sound between repetitions';

  @override
  String get driveCuesSub => 'And a different sound when a dhikr is complete';

  @override
  String driveDhikrOf(String n, String total) {
    return 'Dhikr $n of $total';
  }

  @override
  String get driveFailed => 'The recording could not be downloaded. Check the internet and try again.';

  @override
  String get driveFinished => 'All the adhkar are done. May Allah accept from you.';

  @override
  String get driveNext => 'Next dhikr';

  @override
  String get driveOpen => 'Listen while driving';

  @override
  String get driveOpenSub => 'Repeats each dhikr its full count and counts for you';

  @override
  String driveOutOf(String count) {
    return 'of $count';
  }

  @override
  String get drivePause => 'Pause';

  @override
  String get drivePlay => 'Play';

  @override
  String get drivePreparing => 'Getting the recording ready…';

  @override
  String get drivePrevious => 'This dhikr again';

  @override
  String get driveRetry => 'Try again';

  @override
  String get driveSayEvery => 'Say the count out loud';

  @override
  String driveSayEveryN(String n) {
    return 'Every $n';
  }

  @override
  String get driveSayOff => 'Off';

  @override
  String get driveSettings => 'Driving mode settings';

  @override
  String get driveTitle => 'Driving mode';

  @override
  String hadithAttribution(String name, String licence) {
    return 'Sahih al-Bukhari and Sahih Muslim are copied from sunnah.com with its numbers. The other books are numbered after al-Alamiyya, from $name ($licence).';
  }

  @override
  String get hadithBackToBook => 'Back to the book';

  @override
  String get hadithBenefits => 'Lessons from the hadith';

  @override
  String hadithCount(String n) {
    return '$n hadiths';
  }

  @override
  String get hadithExplain => 'Simplified explanation';

  @override
  String get hadithExplainLess => 'Show less';

  @override
  String get hadithExplainMore => 'Read the full explanation';

  @override
  String get hadithExplainSource =>
      'The explanation is quoted word for word from a published hadith encyclopedia, not written by the app.';

  @override
  String hadithExplainedCount(String count) {
    return '$count hadiths in this book have a simplified explanation';
  }

  @override
  String get hadithExplainedOnly => 'Explained hadiths';

  @override
  String get hadithFavourites => 'Saved hadiths';

  @override
  String get hadithGoMissing => 'There is no hadith with this number in this book.';

  @override
  String hadithGoTo(String max) {
    return 'Go to hadith number (1–$max)';
  }

  @override
  String get hadithGoToSunnah => 'Go to hadith number (sunnah.com numbering, e.g. 1218)';

  @override
  String hadithGrade(String grade) {
    return 'Grade: $grade';
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
  String hadithPageOf(String n, String total) {
    return 'Hadith $n of $total';
  }

  @override
  String hadithPageSunnah(String n) {
    return 'Hadith $n (sunnah.com numbering)';
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
  String hadithSourceSunnah(String book, String n) {
    return '$book, hadith $n (sunnah.com numbering)';
  }

  @override
  String get hadithTitle => 'Main hadith books, simply explained';

  @override
  String get hadithUnsave => 'Remove from saved';

  @override
  String get hajjCounterAdd => 'Add one';

  @override
  String get hajjCounterDone => 'Complete — may Allah accept it';

  @override
  String get hajjCounterJamarat => 'Jamarat pebble counter';

  @override
  String hajjCounterProgress(String n, String total) {
    return '$n of $total';
  }

  @override
  String get hajjCounterReset => 'Reset';

  @override
  String get hajjCounterSai => 'Sa\'i round counter';

  @override
  String get hajjCounterTawaf => 'Tawaf round counter';

  @override
  String get hajjCounterUndo => 'Undo';

  @override
  String get hajjCrowdBody =>
      'The General Authority for the Care of the Two Holy Mosques shows live crowd levels for tawaf and sa\'i, and so does the official Nusuk app. Tap to open the official source.';

  @override
  String get hajjCrowdNote => 'Opens outside the app. The Authority page may only open from inside Saudi Arabia.';

  @override
  String get hajjCrowdNusuk => 'Nusuk app';

  @override
  String get hajjCrowdOfficial => 'Official Authority page';

  @override
  String get hajjCrowdTitle => 'Crowd levels at the Mataf and Mas\'a now';

  @override
  String get hajjGuideCorrections => 'Digitization typos corrected';

  @override
  String get hajjGuideHajj => 'How to perform Hajj';

  @override
  String get hajjGuideSource => 'Source';

  @override
  String get hajjGuideTypes => 'Types of Hajj';

  @override
  String get hajjGuideUmrah => 'How to perform Umrah';

  @override
  String get hajjHajj => 'Hajj';

  @override
  String get hajjHubDuas => 'Hajj & Umrah duas';

  @override
  String get hajjHubHajj => 'Hajj rites';

  @override
  String get hajjHubIhram => 'Miqat and ihram rules';

  @override
  String get hajjHubUmrah => 'Umrah steps and tawaf map';

  @override
  String get hajjHubUmrahSub => 'Umrah one step at a time';

  @override
  String get hajjIfrad => 'Ifrad';

  @override
  String get hajjIhram => 'Ihram';

  @override
  String get hajjKindIfrad => 'Hajj Ifrad';

  @override
  String get hajjKindQiran => 'Hajj Qiran';

  @override
  String get hajjKindSub => 'The steps in order, one at a time';

  @override
  String get hajjKindTamattu => 'Hajj Tamattu\'';

  @override
  String get hajjLiveTitle => 'Live from the Two Holy Mosques (audio)';

  @override
  String get hajjMadinah => 'Visiting Madinah';

  @override
  String get hajjOfficialGuide => 'The steps explained, from the official guide (Arabic)';

  @override
  String get hajjQiran => 'Qiran';

  @override
  String get hajjRef => 'Reference';

  @override
  String get hajjReviewNotice =>
      'Pending religious review: this guide has not yet been reviewed by a qualified scholar. Check with a trusted scholar before relying on it.';

  @override
  String get hajjSayTitle => 'What is said at this step';

  @override
  String get hajjSources => 'Sources of this guide';

  @override
  String hajjStage(String n) {
    return 'Stage $n';
  }

  @override
  String get hajjStepNext => 'Next';

  @override
  String hajjStepOf(String n, String total) {
    return 'Step $n of $total';
  }

  @override
  String get hajjStepPrev => 'Previous';

  @override
  String get hajjStepsInOrder => 'Hajj steps in order';

  @override
  String get hajjTagFirst => 'First tawaf only';

  @override
  String get hajjTagMen => 'Men';

  @override
  String get hajjTagWomen => 'Women';

  @override
  String get hajjTamattu => 'Tamattu\'';

  @override
  String get hajjTapStep => 'Tap a step to read its explanation';

  @override
  String get hajjTapStepOne => 'Tap a step number to show it';

  @override
  String hajjTimes(String n) {
    return '$n times';
  }

  @override
  String get hajjTitle => 'Hajj & Umrah';

  @override
  String get hajjTypeLabel => 'Type of Hajj';

  @override
  String get hajjUmrah => 'Umrah';

  @override
  String get helpA1 => 'Yes. Rattil wa Salli has no ads, no subscriptions and no purchases, and it will stay that way.';

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
      'Allow notifications for Rattil wa Salli and, on Android, \"alarms and reminders\". Some phones stop apps in the background to save battery: exclude Rattil wa Salli from battery optimisation.';

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
      'You have been using Rattil wa Salli for a few days. If it helps you, share it with someone; it is free for everyone.';

  @override
  String get helpPromptTitle => 'Share Rattil wa Salli?';

  @override
  String get helpQ1 => 'Is Rattil wa Salli really free?';

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
  String get helpRate => 'Rate Rattil wa Salli';

  @override
  String get helpRatePending => 'Rating opens once the app is in the stores.';

  @override
  String get helpShareApp => 'Share Rattil wa Salli';

  @override
  String get helpShareText => 'Rattil wa Salli: Quran, prayer times and adhkar, free with no ads.';

  @override
  String get helpSpread => 'Share and rate';

  @override
  String get helpSpreadBody => 'If Rattil wa Salli helps you, share it with family and friends.';

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
  String get homeBigHajj => 'Hajj & Umrah';

  @override
  String get homeBigLibrary => 'Recitations library';

  @override
  String get homeBigNasheeds => 'Nasheeds';

  @override
  String get homeBigPrayer => 'Adhan';

  @override
  String get homeBigQibla => 'Qibla direction';

  @override
  String get homeBigQuran => 'The Holy Quran';

  @override
  String get homeBigReels => 'Short Islamic videos';

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
  String iqamaLeft(String time) {
    return 'Iqama in $time';
  }

  @override
  String iqamaWait(String name, String time) {
    return '$name iqama in $time';
  }

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
  String get khatmaOpenPlanner => 'Full khatma planner';

  @override
  String get khatmaOpenPlannerSub => 'Khatma by days, daily portion, reminder and history';

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
  String get kidsListen => 'Listen';

  @override
  String kidsMinutes(String n) {
    return '$n min';
  }

  @override
  String get kidsNote =>
      'For children: the teaching Mushaf, stories of the prophets, meaningful stories, books, hadith and adhkar, learning wudu and salah, and ruqyah for children.';

  @override
  String get kidsOfflineNote => 'Watch or listen to any episode, or tap the download icon to use it offline.';

  @override
  String get kidsOfflinePlaying => 'Playing the copy saved on this device';

  @override
  String get kidsProphets => 'Stories of the prophets';

  @override
  String get kidsProphets3d => 'Prophets\' stories: 3D';

  @override
  String get kidsProphets3dSub => 'Modern 3D in Arabic, the prophet\'s face never shown';

  @override
  String get kidsProphetsClassic => 'Prophets\' stories: full series';

  @override
  String get kidsProphetsNew => 'Prophets\' stories: modern cartoon';

  @override
  String get kidsProphetsNewSub => 'A teacher tells the story; the prophet is shown only as light';

  @override
  String get kidsProphetsPick => 'Choose a series';

  @override
  String get kidsProphetsSub => 'Cartoon episodes: watch or listen, download for offline';

  @override
  String get kidsRamadan => 'Short meaningful stories';

  @override
  String get kidsRamadanSub => 'Short educational comics';

  @override
  String get kidsRasoul => 'Stories of the Prophet ﷺ for kids';

  @override
  String get kidsRasoulSub => 'With Sheikh Mahmoud al-Masri';

  @override
  String get kidsRuqyahSub => 'Read and listen';

  @override
  String kidsSize(String n) {
    return '$n MB';
  }

  @override
  String get kidsStories => 'Religious & educational stories';

  @override
  String get kidsStoriesSub => 'Stories from the Seerah and short meaningful stories';

  @override
  String get kidsTeacher => 'Teaching Mushaf for kids';

  @override
  String kidsTeacherAyah(String n) {
    return 'Ayah $n';
  }

  @override
  String get kidsTeacherBigger => 'Bigger text';

  @override
  String get kidsTeacherHint => 'Tap any word to hear it, or an ayah number to hear that ayah alone.';

  @override
  String get kidsTeacherHusary => 'Al-Husary (teaching)';

  @override
  String get kidsTeacherMinshawy => 'Al-Minshawy with children';

  @override
  String get kidsTeacherNext => 'Next ayah';

  @override
  String get kidsTeacherNote =>
      'Pick a surah to open the Mushaf: the sheikh reads, the word lights up, and your child repeats after him.';

  @override
  String get kidsTeacherOpen => 'Open the Mushaf';

  @override
  String get kidsTeacherPause => 'Pause';

  @override
  String get kidsTeacherPlay => 'Listen to the surah';

  @override
  String get kidsTeacherPrev => 'Previous ayah';

  @override
  String get kidsTeacherRepeat => 'Repeat the ayah 3 times';

  @override
  String get kidsTeacherSmaller => 'Smaller text';

  @override
  String kidsTeacherStars(String n) {
    return 'Your stars in this surah: $n';
  }

  @override
  String get kidsTeacherSub => 'The sheikh reads, children repeat after him';

  @override
  String kidsTeacherSurah(String name) {
    return 'Surah $name';
  }

  @override
  String get kidsTeacherWell => 'Well done! You finished the surah and earned a star';

  @override
  String get kidsTeacherWord => 'Word';

  @override
  String get kidsTitle => 'Teach your child';

  @override
  String get kidsVideoError => 'Could not play the video. Check the internet connection or download the episode first.';

  @override
  String get kidsWatch => 'Watch';

  @override
  String get kidsYtNote => 'Plays from YouTube, needs internet';

  @override
  String get kidsLearnBooks => 'Kids\' book shelf';

  @override
  String get kidsLearnBooksNote =>
      'Pick a book and read it page by page. Save a book on the device to read it offline.';

  @override
  String get kidsLearnBooksSub => 'Picture books: adhkar, faith, manners and stories, page by page';

  @override
  String get kidsLearnBoys => 'Boys';

  @override
  String get kidsLearnCardDone => 'Said it today';

  @override
  String get kidsLearnCardMark => 'I said this dhikr';

  @override
  String get kidsLearnCards => 'Adhkar cards';

  @override
  String get kidsLearnCardsSub => 'Morning and evening adhkar in text, with a counter for each';

  @override
  String kidsLearnCardsToday(String n) {
    return 'Your stars today: $n';
  }

  @override
  String kidsLearnCredit(String name) {
    return 'Text from $name';
  }

  @override
  String get kidsLearnDelete => 'Delete the saved copy';

  @override
  String get kidsLearnGirls => 'Girls';

  @override
  String get kidsLearnHadith => 'Memorise a hadith';

  @override
  String kidsLearnHadithNo(String n) {
    return 'Hadith $n';
  }

  @override
  String get kidsLearnHadithNote =>
      'Memorise one hadith a day. Start with level 1, repeat it until you know it, then tap «Memorised».';

  @override
  String get kidsLearnHadithSub => '600 hadith to memorise in four levels';

  @override
  String kidsLearnLevel(String n) {
    return 'Level $n';
  }

  @override
  String kidsLearnLevelSub(String from, String to) {
    return 'Hadith $from to $to';
  }

  @override
  String get kidsLearnMarkMemorized => 'Tap when you know it';

  @override
  String get kidsLearnMemorized => 'Memorised';

  @override
  String get kidsLearnNext => 'Next';

  @override
  String get kidsLearnOffline => 'Saved on this device';

  @override
  String kidsLearnPage(String n, String total) {
    return 'Page $n of $total';
  }

  @override
  String kidsLearnPages(String n) {
    return '$n pages';
  }

  @override
  String get kidsLearnPrev => 'Previous';

  @override
  String kidsLearnProgress(String n, String total) {
    return 'Memorised $n of $total';
  }

  @override
  String kidsLearnReads(String n) {
    return 'Repeated $n times';
  }

  @override
  String get kidsLearnSalah => 'Learn salah';

  @override
  String get kidsLearnSalahSub => 'Prayer steps in pictures';

  @override
  String get kidsLearnIslam => 'Pillars of Islam';

  @override
  String get kidsLearnIslamSub => 'The five pillars in pictures';

  @override
  String get kidsLearnIman => 'Pillars of faith';

  @override
  String get kidsLearnImanSub => 'The six pillars in pictures';

  @override
  String get kidsLearnSave => 'Save the book on this device';

  @override
  String get kidsLearnSaveFailed => 'Could not save the book. Check the connection and try again.';

  @override
  String get kidsLearnShelfAdhkar => 'Adhkar and duas';

  @override
  String get kidsLearnShelfAkhlaq => 'Manners';

  @override
  String get kidsLearnShelfAqeedah => 'Faith';

  @override
  String get kidsLearnShelfFiqh => 'Purity and prayer';

  @override
  String get kidsLearnShelfParents => 'For parents';

  @override
  String get kidsLearnShelfQuran => 'The Quran';

  @override
  String get kidsLearnShelfRamadan => 'Ramadan';

  @override
  String get kidsLearnShelfStories => 'Prophets and Seerah';

  @override
  String kidsLearnStep(String n, String total) {
    return 'Step $n of $total';
  }

  @override
  String get kidsLearnStepsDone => 'Well done! You finished all the steps';

  @override
  String get kidsLearnWudu => 'Learn wudu';

  @override
  String get kidsLearnWuduSub => 'Wudu steps in pictures';

  @override
  String get lessonsAll => 'All';

  @override
  String get lessonsAllEpisodes => 'All lessons';

  @override
  String get lessonsAllTopics => 'All topics';

  @override
  String lessonsContinue(String series, String n) {
    return 'Continue: $series · lesson $n';
  }

  @override
  String lessonsContinueBtn(String n) {
    return 'Continue lesson $n';
  }

  @override
  String lessonsCount(String n) {
    return '$n lessons';
  }

  @override
  String get lessonsDone => 'Heard';

  @override
  String get lessonsDoneHint => 'Long-press a lesson to add or remove its ✓.';

  @override
  String get lessonsDownloadAll => 'Download series';

  @override
  String get lessonsDownloadFailed => 'Download stopped. Check the internet connection and try again.';

  @override
  String get lessonsDownloadStop => 'Stop';

  @override
  String get lessonsDownloadedAll => 'Whole series downloaded';

  @override
  String lessonsDownloading(String done, String total) {
    return 'Downloading $done of $total';
  }

  @override
  String lessonsHeard(String n) {
    return '$n heard';
  }

  @override
  String lessonsHours(String n) {
    return '$n h';
  }

  @override
  String lessonsLesson(String n) {
    return 'Lesson $n';
  }

  @override
  String get lessonsLoadError => 'Could not load the list of series.';

  @override
  String lessonsMinutes(String n) {
    return '$n min';
  }

  @override
  String get lessonsNoMatch => 'No series with that name.';

  @override
  String lessonsNote(String series, String lessons) {
    return 'Complete audio series by major scholars, arranged by topic: $series series, $lessons lessons. Pick a topic, then listen online or download a lesson or the whole series to listen without internet.';
  }

  @override
  String lessonsSaved(String n) {
    return '$n saved';
  }

  @override
  String get lessonsSearch => 'Search by series or sheikh';

  @override
  String get lessonsStart => 'Start from lesson 1';

  @override
  String get lessonsTitle => 'Understand your religion';

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
  String get libraryTitle => 'Recitations library';

  @override
  String get lockNoticeHint =>
      'A quiet, lasting notification with the next prayer, its time, the time left and the day\'s times.';

  @override
  String lockNoticeIqamaTitle(String name, String time) {
    return '$name iqama: $time';
  }

  @override
  String get lockNoticeSetting => 'Next prayer on the lock screen';

  @override
  String lockNoticeTitle(String name, String time) {
    return 'Next prayer: $name $time';
  }

  @override
  String get meaningsError => 'Could not load the word meanings.';

  @override
  String get meaningsLoading => 'Loading the word meanings…';

  @override
  String get meaningsNoneAyah => 'No difficult words are explained in this ayah.';

  @override
  String get meaningsNonePage => 'No difficult words are explained on this page.';

  @override
  String meaningsOfAyah(String ref) {
    return 'Word meanings of $ref';
  }

  @override
  String meaningsOfPage(String page) {
    return 'Word meanings, page $page';
  }

  @override
  String get meaningsShort => 'Meanings';

  @override
  String get meaningsSource => 'From «Al-Siraj fi Bayan Gharib al-Quran» by Muhammad al-Khudairi (Arabic)';

  @override
  String get meaningsTitle => 'Word meanings';

  @override
  String get moreAsma => 'The Names of Allah explained';

  @override
  String get moreHajjSub => 'Umrah and the three kinds of Hajj';

  @override
  String get moreLessonsSub => 'Complete audio series by major scholars';

  @override
  String get moreSharawiSub => 'Quran tafsir, the Prophet\'s biography, prophets\' stories';

  @override
  String get moreTitle => 'Main sections';

  @override
  String mosquesAround(String place) {
    return 'Mosques around $place';
  }

  @override
  String get mosquesCompleting => 'Completing the list from the rest of the map…';

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
  String get mosquesGoogleMapsShort => 'Google Maps';

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
  String get mosquesOpenApple => 'Open in Maps';

  @override
  String get mosquesOpenGoogle => 'Open in Google Maps';

  @override
  String get mosquesOpenOther => 'Open in another maps app';

  @override
  String get mosquesOpenWaze => 'Open in Waze';

  @override
  String get mosquesRetry => 'Try again';

  @override
  String get mosquesTitle => 'Nearby mosques';

  @override
  String get mosquesUnnamed => 'Mosque (no name on the map)';

  @override
  String mosquesWidened(String from, String to) {
    return 'No mosque is mapped within $from, so these are the nearest within $to.';
  }

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
  String get nasheedsArab => 'From the Arab world';

  @override
  String nasheedsCount(String n) {
    return '$n nasheeds';
  }

  @override
  String get nasheedsEgypt => 'From Egypt';

  @override
  String get nasheedsLoadError => 'Couldn\'t load the nasheeds list.';

  @override
  String get nasheedsNext => 'Next nasheed';

  @override
  String get nasheedsNote => 'Listen to any nasheed online, or tap the download icon to keep it for offline listening.';

  @override
  String get nasheedsPrev => 'Previous nasheed';

  @override
  String get nasheedsSearch => 'Find a nasheed or munshid';

  @override
  String get nasheedsTitle => 'Nasheeds';

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
  String get navVideos => 'Videos';

  @override
  String get offlineDone => 'Saved: you can listen without internet';

  @override
  String get offlineDownload => 'Download for offline listening';

  @override
  String get offlineFailed => 'Download failed. Check the internet and try again';

  @override
  String get offlineSavedDelete => 'Saved on the phone — tap to delete';

  @override
  String get parentLockAge13plus => '13 or older';

  @override
  String get parentLockAgeAsk => 'Choose your age group';

  @override
  String get parentLockAgeTitle => 'Before you open videos';

  @override
  String get parentLockAgeUnder13 => 'Under 13';

  @override
  String get parentLockAnswer => 'Answer';

  @override
  String get parentLockBack => 'Back to children\'s videos';

  @override
  String parentLockChallenge(String a, String b) {
    return 'Question for adults: what is $a × $b?';
  }

  @override
  String get parentLockChallengeWrong => 'Wrong answer';

  @override
  String get parentLockConfirm => 'Type the PIN again to confirm';

  @override
  String get parentLockEnter => 'Type the PIN to open videos';

  @override
  String get parentLockForgot => 'Forgot the PIN?';

  @override
  String get parentLockHandOver => 'Please hand the phone to a parent to choose the PIN.';

  @override
  String get parentLockIntro =>
      'Videos and short clips come from YouTube and Instagram, so they are locked for children. A parent opens them with a PIN.';

  @override
  String get parentLockKidsNote => 'These are the kids section videos. A parent opens the other videos with the PIN.';

  @override
  String get parentLockKidsTitle => 'Videos for children';

  @override
  String get parentLockLockNow => 'Lock videos';

  @override
  String get parentLockMismatch => 'The two PINs don\'t match, start again';

  @override
  String get parentLockNext => 'Next';

  @override
  String get parentLockParentOpen => 'Parent: open all videos';

  @override
  String get parentLockPin => 'PIN';

  @override
  String get parentLockReset => 'Choose a new PIN';

  @override
  String get parentLockSave => 'Save PIN';

  @override
  String get parentLockSetTitle => 'Parent: choose a 4-digit PIN';

  @override
  String get parentLockTitle => 'Parent lock';

  @override
  String get parentLockUnlock => 'Open';

  @override
  String get parentLockWrong => 'Wrong PIN, try again';

  @override
  String get playerNext => 'Next';

  @override
  String get playerOpen => 'Back to what is playing';

  @override
  String get playerPrev => 'Previous';

  @override
  String get playerTitle => 'Audio player';

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
  String get prayerAutoLocation => 'Detect location automatically';

  @override
  String get prayerAutoLocationNote =>
      'Your location is refreshed when the app opens, so times stay right when you travel.';

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
  String get prayerCompactNote => 'To change the city, calculation method or adhan alerts, tap Edit prayer times.';

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
  String get prayerEditTimes => 'Edit prayer times';

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
  String get prayerLocationServices => 'Location services';

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
  String qiblaAccuracy(String n) {
    return 'Compass accuracy now: ± $n°';
  }

  @override
  String get qiblaCalibrateBody =>
      'Move the phone in a figure 8 a few times, keep away from metal and electrical devices, and remove a magnetic case.';

  @override
  String get qiblaCalibrateTitle => 'The compass needs calibrating';

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
  String get qiblaLocateFailed => 'Couldn\'t find your location. Turn on location services and try again.';

  @override
  String get qiblaMapCheck => 'Check on Google\'s Qibla Finder map';

  @override
  String get qiblaPlaceNote =>
      'The qibla is worked out for this place. Tap the location button if you are somewhere else.';

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
  String quranJuzInMushaf(String juz) {
    return 'Open $juz on the Mushaf pages';
  }

  @override
  String quranJuzLine(String surah, String ayah, String page) {
    return 'Starts at $surah $ayah · Page $page';
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
  String get quranTabJuz => 'Juz';

  @override
  String get quranTabQuarters => 'Quarters';

  @override
  String get quranTabSurahs => 'Surahs';

  @override
  String get radioAll => 'All radios';

  @override
  String get radioDuration => 'Play for';

  @override
  String get radioListen => 'Listen';

  @override
  String get radioLiveNote => 'Live broadcast. Pick another station from the list or from \"All radios\".';

  @override
  String get radioLonger => 'Longer';

  @override
  String radioMin(String n) {
    return '$n min';
  }

  @override
  String get radioMushaf => 'Whole-Mushaf radio (chosen reciter)';

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
  String get radiosTitle => 'Various radios';

  @override
  String get readerBack => 'Back to the index';

  @override
  String get readerBasmalaNow => 'Reciting the basmala';

  @override
  String get readerBookmarks => 'Bookmarks';

  @override
  String get readerExitFull => 'Show tools';

  @override
  String get readerFont => 'Text size';

  @override
  String get readerFontBigger => 'Bigger text';

  @override
  String get readerFontMadina => 'Madina font';

  @override
  String readerFontSize(String size) {
    return 'Text size: $size — press to enlarge';
  }

  @override
  String get readerFontSmaller => 'Smaller text';

  @override
  String get readerFontUthmani => 'Uthmani font';

  @override
  String get readerFullHint =>
      'To turn pages, swipe the page or press the arrows. To show the tools, press “Show tools”.';

  @override
  String get readerFullScreen => 'Full screen';

  @override
  String get readerGuide1 =>
      'Tap any ayah to show its options under the page: listen, ayah tafsir, bookmark, copy, share.';

  @override
  String get readerGuide2 => 'To turn pages: swipe the page, or use the page slider under it.';

  @override
  String get readerGuide3 =>
      '“Full screen” in the bottom bar hides the tools; “Show tools” at the top of the page brings them back.';

  @override
  String get readerGuide4 => '“Listen with tafsir” shows the page and its tafsir together while it is recited.';

  @override
  String get readerGuideTitle => 'How to use the Mushaf';

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
  String get readerHideTafsir => 'Hide tafsir';

  @override
  String get readerHintClose => 'Got it';

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
  String get readerNextJuz => 'Next juz';

  @override
  String get readerNextPage => 'Next page';

  @override
  String get readerNextSurah => 'Next surah';

  @override
  String get readerPickAyah => 'Tap any ayah to show its options here';

  @override
  String get readerPickJuz => 'Choose the juz';

  @override
  String get readerPlayAyah => 'Listen to this ayah';

  @override
  String get readerPlayWithTafsir => 'Listen with tafsir';

  @override
  String get readerPlayerHide => 'Hide player';

  @override
  String get readerPlayerShow => 'Show player';

  @override
  String get readerPrevJuz => 'Previous juz';

  @override
  String get readerPrevPage => 'Previous page';

  @override
  String get readerPrevSurah => 'Previous surah';

  @override
  String get readerPrintedLook =>
      'Switch between the Uthmani font and the Madina font (the Madina font is optional and downloaded from the internet)';

  @override
  String get readerPrintedLookShort => 'Madina font';

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
  String get readerTabJuz => 'Whole juz';

  @override
  String get readerTabMushaf => 'Mushaf';

  @override
  String get readerTabSurah => 'Whole surah';

  @override
  String get readerTabTafsir => 'Tafsir';

  @override
  String get readerTafsirBeside => 'Tafsir beside the page';

  @override
  String get readerTafsirBesideJuz => 'Tafsir beside the juz';

  @override
  String get readerTafsirBesideShort => 'Tafsir';

  @override
  String get readerTafsirBesideSurah => 'Tafsir beside the surah';

  @override
  String readerZoomReset(String pct) {
    return '$pct% · Normal size';
  }

  @override
  String get reelsAddChannel => 'Add channel';

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
  String get reelsMyChannels => 'Your channels';

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
  String get reelsRemoveChannel => 'Remove channel';

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
  String get reelsSearch => 'Find a channel';

  @override
  String get reelsSearchHint => 'Channel or sheikh name';

  @override
  String get reelsSearchNone => 'No results, or no internet connection.';

  @override
  String get reelsShowHidden => 'Show hidden channels';

  @override
  String get reelsSub => 'Recitations, lessons and admonitions from trusted channels';

  @override
  String get reelsSuggested => 'Suggested Islamic channels';

  @override
  String get reelsSuggestedHint => 'The app adds from these automatically based on what you watch most.';

  @override
  String get reelsTapToPlay => 'Tap to play';

  @override
  String get reelsTitle => 'Islamic reels';

  @override
  String get reelsTrusted => 'Trusted channel';

  @override
  String get reelsUndo => 'Undo';

  @override
  String get reportAction => 'Report a mistake';

  @override
  String get reportPrompt => 'Spotted a mistake on this page?';

  @override
  String reportTitle(String page) {
    return 'Mistake in: $page';
  }

  @override
  String ruqyahAyah(String surah, String n) {
    return '$surah: ayah $n';
  }

  @override
  String get ruqyahDua => 'From the Sunnah';

  @override
  String ruqyahFrom(String surah, String from, String to) {
    return '$surah: ayahs $from–$to';
  }

  @override
  String get ruqyahFull => 'The full ruqyah by Sheikh Mishary Alafasy';

  @override
  String ruqyahFullSub(String n) {
    return '$n min · tap the download icon to listen offline';
  }

  @override
  String get ruqyahHeader => 'Ruqyah';

  @override
  String get ruqyahKidsNote =>
      'What the Prophet ﷺ sought protection with for al-Hasan and al-Husayn, then al-Fatiha, Ayat al-Kursi, the end of al-Baqarah, al-Ikhlas, al-Falaq and an-Nas, then the ruqyah Jibril recited over the Prophet ﷺ. Read them over your child or listen.';

  @override
  String get ruqyahKidsTitle => 'Ruqyah for children';

  @override
  String get ruqyahListenQuran => 'Listen to the verses';

  @override
  String get ruqyahNote =>
      'The Quran verses and Sunnah duas used for ruqyah, as listed by scholars. Read or listen; tap an ayah for its tafsir.';

  @override
  String ruqyahRepeat(String n) {
    return 'Said $n times';
  }

  @override
  String get ruqyahTitle => 'Ruqyah';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAccount => 'Account & sync';

  @override
  String get settingsAccountHint => 'Optional — sync bookmarks between devices';

  @override
  String get settingsAppSection => 'The app';

  @override
  String get settingsAuto => 'Automatic';

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
  String get settingsManual => 'Manual';

  @override
  String get settingsMushafPrinted => 'Printed Mushaf look';

  @override
  String get settingsMushafPrintedDownload => 'Download all page fonts for offline reading';

  @override
  String get settingsMushafPrintedFailed => 'Download failed, try again';

  @override
  String get settingsMushafPrintedHint =>
      'Optional, downloaded from the internet: pages that look like the printed Mushaf (the Complex\'s page fonts via quran.com). The normal look is the King Fahd Complex\'s own text and font (v2.2), proven by fingerprint.';

  @override
  String settingsMushafPrintedProgress(String done, String total) {
    return 'Downloading: $done of $total';
  }

  @override
  String get settingsMushafPrintedSaved => 'All page fonts are saved on this device and won\'t be downloaded again';

  @override
  String get settingsMushafSection => 'Mushaf';

  @override
  String get settingsOurApps => 'Our apps';

  @override
  String get settingsOurAppsSoon => 'More apps coming soon, God willing';

  @override
  String get settingsPalette => 'Colour style';

  @override
  String get settingsPaletteEmerald => 'Emerald & gold';

  @override
  String get settingsPaletteMadinah => 'Madinah night';

  @override
  String get settingsPermissions => 'Permissions and background';

  @override
  String get settingsPermissionsHeader => 'Permissions the app needs';

  @override
  String get settingsPermissionsHint => 'Location, notifications, battery and adhan on silent';

  @override
  String get settingsPrayerAutoHint => 'From your location and your country\'s calculation method';

  @override
  String get settingsPrayerManualHint => 'You choose the method and adjust the minutes yourself';

  @override
  String get settingsPrayerTimes => 'Prayer times';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsSources => 'Content sources';

  @override
  String get settingsSuggest => 'Request a feature or suggest an idea';

  @override
  String get settingsSuggestTitle => 'Idea suggestion';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsTour => 'App tour';

  @override
  String get setupAlarmAction => 'Allow the alarm';

  @override
  String get setupAlarmBody =>
      'On iOS 26 or newer the whole adhan rings like an alarm clock, even when the iPhone is on silent.';

  @override
  String get setupAlarmTitle => 'Full adhan as an alarm';

  @override
  String get setupAppPage => 'App page';

  @override
  String get setupBatteryAction => 'Open battery settings';

  @override
  String get setupBatteryBody =>
      'So battery saving does not stop the adhan while the app is closed: in the list choose Rattil wa Salli, then \"Don\'t optimize\" or \"Unrestricted\".';

  @override
  String get setupBatteryOem =>
      'On some phones (Xiaomi, Oppo, Realme, Huawei, Vivo) also turn on \"Autostart\" or \"Background activity\" on the app\'s page.';

  @override
  String get setupBatteryTitle => 'Run in the background';

  @override
  String get setupDone => 'Done';

  @override
  String get setupExactBody =>
      'Turn on \"Alarms & reminders\" for this app, otherwise Android may delay the adhan by a few minutes.';

  @override
  String get setupExactTitle => 'Adhan on the minute';

  @override
  String get setupIntro =>
      'A few steps so prayer times are right and the adhan reaches you on time, even with the app closed. You can change all of this later in Settings.';

  @override
  String get setupLocationBody => 'For the prayer times and qibla where you are. Used only while the app is open.';

  @override
  String get setupLocationCity => 'Choose a city';

  @override
  String get setupLocationDenied => 'Location was not allowed. You can choose your city instead.';

  @override
  String get setupLocationTitle => 'Location';

  @override
  String get setupLocationUnavailable =>
      'Could not find your location now. Check that location is on, or choose your city.';

  @override
  String get setupLocationUse => 'Use my location';

  @override
  String get setupLockIos =>
      'For the lock screen: touch and hold the lock screen → Customize → Lock Screen → Add Widgets → Rattil wa Salli, to see the next prayer and the time left.';

  @override
  String get setupNotifAction => 'Turn on the adhan';

  @override
  String get setupNotifBody => 'Allow notifications so the adhan and reminders reach you.';

  @override
  String get setupNotifDenied => 'Notifications are not allowed. Open the app settings and turn them on.';

  @override
  String get setupNotifTitle => 'Adhan alert';

  @override
  String get setupOpenSettings => 'Open settings';

  @override
  String get setupSilentIos =>
      'On iPhone the system lets no app play a notification sound while the silent switch is on (Apple allows it only for emergency and health apps). The adhan alert then shows without sound; keep the silent switch off to hear it.';

  @override
  String get setupSilentTitle => 'Adhan when the phone is silent';

  @override
  String get setupStart => 'Start';

  @override
  String get setupTitle => 'Set up the app';

  @override
  String get setupWidgetAction => 'Add the widget';

  @override
  String get setupWidgetAndroidManual =>
      'If no add message appears: touch and hold an empty spot on the home screen → Widgets → Rattil wa Salli.';

  @override
  String get setupWidgetBody =>
      'Prayer times, the next prayer and the Hijri date on your home screen without opening the app.';

  @override
  String get setupWidgetIos =>
      'Apple does not let apps add it themselves: touch and hold an empty spot on the home screen → Edit or + → search for Rattil wa Salli → pick a size → Add Widget.';

  @override
  String get setupWidgetTitle => 'Prayer widget on the home screen';

  @override
  String shabibFromSurah(String name) {
    return 'From Surah $name';
  }

  @override
  String get shabibLoadError => 'Couldn\'t load the recitations list.';

  @override
  String get shabibMoshafs => 'Hafs from Asim - Murattal (selections) · Mujawwad';

  @override
  String get shabibMujawwad => 'Mujawwad';

  @override
  String get shabibMujawwadNote => 'Live recordings (dawn prayers, radio, evening gatherings), ordered by surah.';

  @override
  String get shabibMurattal => 'Murattal';

  @override
  String get shabibMurattalNote => 'Hafs from Asim. Some are a passage of the surah, not the whole surah.';

  @override
  String get shabibName => 'Mohamed Ahmed Shabib';

  @override
  String get shabibNoMatch => 'No recitations for this surah.';

  @override
  String shabibNote(String m, String j) {
    return 'No complete Quran recording of Sheikh Mohamed Ahmed Shabib exists, so here is what is available: $m murattal and $j mujawwad recitations. Listen online or tap the download icon to listen offline.';
  }

  @override
  String get shabibReciter => 'Sheikh Mohamed Ahmed Shabib';

  @override
  String get shabibShortSurahs => 'Short surahs';

  @override
  String shabibSurah(String name) {
    return 'Surah $name';
  }

  @override
  String shabibSurahs(String names) {
    return 'Surahs $names';
  }

  @override
  String get shabibTagFajr => 'Dawn recitation';

  @override
  String get shabibTagOct73 => 'Dawn of 6 October 1973';

  @override
  String get shabibTagRadio => 'Radio recording';

  @override
  String sharawiAyah(String n) {
    return 'Ayah $n';
  }

  @override
  String sharawiAyahs(String from, String to) {
    return 'Ayahs $from–$to';
  }

  @override
  String get sharawiChooseSurah => 'Choose a surah';

  @override
  String get sharawiIntro => 'Introduction';

  @override
  String sharawiLesson(String n) {
    return 'Lesson $n';
  }

  @override
  String sharawiLessons(String n) {
    return '$n lessons';
  }

  @override
  String get sharawiLoadError => 'Couldn\'t load the tafsir lessons.';

  @override
  String sharawiMinutes(String n) {
    return '$n min';
  }

  @override
  String get sharawiNoMatch => 'No lessons for this surah.';

  @override
  String sharawiNote(String n) {
    return 'Sheikh Muhammad Mutawalli al-Sha\'rawi\'s reflections on the Quran in his own voice, $n lessons ordered by surah. Listen to any lesson online, or tap the download icon to keep it for offline listening.';
  }

  @override
  String get sharawiPartAnbiya => 'Prophets\' stories';

  @override
  String get sharawiPartSeerah => 'The Prophet\'s life';

  @override
  String get sharawiPartTafsir => 'Quran tafsir';

  @override
  String get sharawiSearch => 'Find a surah by name or number';

  @override
  String get sharawiSection => 'Sheikh al-Sha\'rawi\'s lessons library';

  @override
  String get sharawiTitle => 'Al-Sha\'rawi tafsir';

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
  String get storiesHowTo =>
      'Each episode: tap to listen, the video icon to watch, or the download icon to listen offline.';

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
  String get storiesVideoBy => 'Sheikh Nabil Al-Awadi';

  @override
  String get storiesWatchVideo => 'Watch video';

  @override
  String get studyBalagha => 'Rhetoric';

  @override
  String get studyFawaid => 'Benefits';

  @override
  String get studyGharib => 'Rare words';

  @override
  String get studyGharibBook => 'From «al-Siraj fi Bayan Gharib al-Quran»';

  @override
  String get studyIrab => 'I\'rab';

  @override
  String get studyIrabBook => 'From «al-Jadwal fi I\'rab al-Quran» by Mahmud Safi';

  @override
  String get studyNoGharib => 'The book lists no rare words in this ayah.';

  @override
  String studyNoPart(String part) {
    return 'The book has no $part section for this ayah.';
  }

  @override
  String get studyNotes => 'Editor\'s footnotes';

  @override
  String studyRange(String from, String to, String surah) {
    return 'The book explains ayahs $from–$to of $surah together.';
  }

  @override
  String get studyRetry => 'Try again';

  @override
  String get studySarf => 'Morphology';

  @override
  String get studyTafsir => 'Tafsir';

  @override
  String get surahInfoAbout => 'About the surah';

  @override
  String get surahInfoAsbab => 'Reasons for revelation';

  @override
  String get surahInfoAyahs => 'Verses';

  @override
  String get surahInfoMissing => 'Information not available.';

  @override
  String get surahInfoNoAsbab => 'The source mentions no specific reason for revelation for this surah.';

  @override
  String get surahInfoOrder => 'Order of revelation';

  @override
  String get surahInfoPlace => 'Revealed in';

  @override
  String get surahInfoTitle => 'About the surah';

  @override
  String get surahInfoWahidi => 'From al-Wahidi, \"Asbab Nuzul al-Quran\"';

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
  String get tafsirLibAyah => 'Ayah';

  @override
  String get tafsirLibBooks => 'Tafsir books';

  @override
  String get tafsirLibCompare => 'Compare tafsirs';

  @override
  String get tafsirLibCompareSub => 'Every tafsir of the same ayah';

  @override
  String get tafsirLibDownload => 'Download for offline reading';

  @override
  String tafsirLibDownloading(String done) {
    return 'Downloading… $done of 114 surahs';
  }

  @override
  String get tafsirLibDownloadsNote =>
      'Each book downloads once and then opens without the internet. Without it, each surah downloads when you open it.';

  @override
  String get tafsirLibDownloadsTitle => 'Offline reading';

  @override
  String get tafsirLibFailed => 'The download failed. Try again.';

  @override
  String get tafsirLibInApp => 'In the app';

  @override
  String get tafsirLibIrabName => 'الجدول في إعراب القرآن وصرفه وبيانه';

  @override
  String get tafsirLibIrabSub => 'I\'rab, morphology, rhetoric and benefits of every ayah';

  @override
  String get tafsirLibLenLong => 'Long';

  @override
  String get tafsirLibLenMedium => 'Medium';

  @override
  String get tafsirLibLenShort => 'Short';

  @override
  String get tafsirLibLess => 'Show less';

  @override
  String get tafsirLibMore => 'Read all';

  @override
  String get tafsirLibReadBook => 'Open in the book';

  @override
  String get tafsirLibRemove => 'Remove from device';

  @override
  String tafsirLibResults(String n) {
    return 'Results: $n';
  }

  @override
  String get tafsirLibSaved => 'Saved on this device';

  @override
  String get tafsirLibSearch => 'Search the tafsir';

  @override
  String get tafsirLibSearchHint => 'Type an Arabic word or phrase';

  @override
  String get tafsirLibSearchNeedsDownload => 'Searching this book needs it downloaded on your device first.';

  @override
  String get tafsirLibSearchSub => 'Find a word inside any tafsir book';

  @override
  String get tafsirLibSurah => 'Surah';

  @override
  String get tafsirLibTitle => 'Tafsir books, simply explained';

  @override
  String get tagline => 'Quran, prayer and remembrance — free, no ads';

  @override
  String get tasbihAdd => 'Add';

  @override
  String get tasbihCancel => 'Cancel';

  @override
  String get tasbihChangeDhikr => 'Change dhikr';

  @override
  String get tasbihChangeLook => 'Bead style';

  @override
  String get tasbihClear => 'Clear';

  @override
  String get tasbihClearConfirm => 'Clear the whole tasbih history?';

  @override
  String get tasbihClearHistory => 'Clear history';

  @override
  String get tasbihColor => 'Colour';

  @override
  String get tasbihCount => 'Count';

  @override
  String tasbihCounter(String count, String target) {
    return 'Count $count of $target';
  }

  @override
  String get tasbihHistory => 'History';

  @override
  String get tasbihHistoryEmpty => 'Nothing counted yet.';

  @override
  String get tasbihHistoryOpen => 'Tasbih history';

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
  String tasbihOfTarget(String n) {
    return 'of $n';
  }

  @override
  String get tasbihPhrase => 'Dhikr';

  @override
  String get tasbihPickDhikr => 'Choose a dhikr';

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
  String get tasbihStyle => 'Bead style';

  @override
  String get tasbihStyleCrystal => 'Crystal';

  @override
  String get tasbihStyleGlossy => 'Glossy';

  @override
  String get tasbihStyleMarble => 'Marble';

  @override
  String get tasbihStylePearl => 'Pearl';

  @override
  String get tasbihStyleWood => 'Wood';

  @override
  String get tasbihTap => 'Tap to count';

  @override
  String get tasbihTarget => 'Target';

  @override
  String tasbihTimes(String n) {
    return '$n times';
  }

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
  String get tasbihVirtueSource => 'Hisn al-Muslim';

  @override
  String get tourAdhkarBody =>
      'Morning and evening adhkar and Hisn al-Muslim with audio, a tasbih counter, the hadith books and the Names of Allah.';

  @override
  String get tourAdhkarTitle => 'Adhkar and hadith';

  @override
  String get tourBack => 'Back';

  @override
  String get tourListenBody =>
      'Quran radios, Sha\'rawi\'s audio tafsir, stories of the Quran, and lessons and clips from trusted channels.';

  @override
  String get tourListenTitle => 'Listen and learn';

  @override
  String get tourNext => 'Next';

  @override
  String tourPage(String n, String total) {
    return 'Page $n of $total';
  }

  @override
  String get tourPrayerBody =>
      'Prayer times for where you are, an adhan alert in the muezzin\'s voice you choose, the qibla and nearby mosques.';

  @override
  String get tourPrayerTitle => 'Prayer times and adhan';

  @override
  String get tourPrivacyBody =>
      'We don\'t collect or keep any of your personal data, and the app needs no sign-in. We ask for your location only so the adhan comes at the right time and the qibla direction is accurate; this is worked out on your phone and we don\'t keep your location.';

  @override
  String get tourPrivacyTitle => 'Your data stays yours';

  @override
  String get tourQuranBody =>
      'The King Fahd Complex Mushaf, page by page, recitations by many reciters, Tafsir al-Muyassar and a khatma planner.';

  @override
  String get tourQuranTitle => 'The Holy Quran';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourWelcomeBody =>
      'A free app for the sake of Allah, with no ads and no subscriptions: the Quran, prayer and adhkar in one place.';

  @override
  String get tourWelcomeTitle => 'Welcome to Rattil wa Salli';

  @override
  String get videosClearHistory => 'Clear history';

  @override
  String get videosHistory => 'Recent searches';

  @override
  String get videosNoResults => 'No matching Islamic videos. Try other words.';

  @override
  String videosRemoveHistory(String q) {
    return 'Remove “$q” from history';
  }

  @override
  String get videosSearch => 'Search';

  @override
  String get videosSearchFailed => 'Search is not available right now. Check your connection and try again.';

  @override
  String get videosSearchHint => 'Search a recitation, lesson or admonition';

  @override
  String get videosSearchNote =>
      'Search shows Islamic videos only (recitations, lessons, admonitions), trusted channels first. Tap a video to play it, or long-press to open it in YouTube.';

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
  String get ytOfficialNote => 'Plays from the official YouTube channel and needs an internet connection.';

  @override
  String get zakatAdornment => 'Gold worn for adornment';

  @override
  String get zakatAnimalCount => 'Number of animals';

  @override
  String get zakatBasis => 'Measure the nisab by';

  @override
  String get zakatBasisGold => 'Gold (85 g)';

  @override
  String get zakatBasisSilver => 'Silver (595 g)';

  @override
  String get zakatBelowNisab => 'Below the nisab: no zakat is due';

  @override
  String get zakatCamels => 'Camels';

  @override
  String get zakatCattle => 'Cattle';

  @override
  String get zakatCropsKg => 'Harvest weight';

  @override
  String get zakatCropsNote => 'Paid on the day of harvest.';

  @override
  String get zakatCropsRule => 'The crops nisab is about 612 kg; due at harvest, no year needed.';

  @override
  String zakatDue(String zakat) {
    return 'Zakat due: $zakat';
  }

  @override
  String zakatDueAnimals(String v) {
    return 'Zakat due: $v';
  }

  @override
  String zakatDueCrops(String kg) {
    return 'Zakat due: $kg kg of the harvest';
  }

  @override
  String zakatDueDetail(String net, String nisab) {
    return 'One fortieth (2.5%) of $net; the nisab is $nisab.';
  }

  @override
  String get zakatDueEmpty => '—';

  @override
  String zakatDueGold(String g, String k) {
    return 'Zakat due: $g g of $k-carat gold';
  }

  @override
  String zakatDueMoney(String v) {
    return 'Zakat due: $v';
  }

  @override
  String get zakatDueNone => 'No zakat';

  @override
  String zakatDueShortGrams(String g) {
    return '$g g';
  }

  @override
  String zakatDueShortKg(String kg) {
    return '$kg kg';
  }

  @override
  String zakatDueShortMoney(String v) {
    return '$v EGP';
  }

  @override
  String zakatDueSilver(String g) {
    return 'Zakat due: $g g of silver';
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
  String get zakatGoldGrams => 'Weight of saved gold';

  @override
  String get zakatGoldPrice => 'Price of 1 g of 24-carat gold (optional)';

  @override
  String get zakatGoldRule => 'The gold nisab is 85 g of pure (24-carat) gold.';

  @override
  String get zakatGram => 'g';

  @override
  String get zakatGroupDebts => 'Debts you owe';

  @override
  String get zakatGroupGold => 'Gold (grams)';

  @override
  String get zakatGroupMoney => 'Money and savings';

  @override
  String get zakatIrrigated => 'Machine-watered 5%';

  @override
  String get zakatKarat => 'Carat';

  @override
  String get zakatKg => 'kg';

  @override
  String get zakatLivestockNote => 'For grazing animals after a full year.';

  @override
  String get zakatLivestockRule =>
      'Grazing animals after a full year. Camels and sheep: the zakat letter in Sahih al-Bukhari (1454); cattle: the hadith of Mu\'adh in Sunan al-Tirmidhi (623).';

  @override
  String get zakatMoney => 'Saved money (cash and bank)';

  @override
  String get zakatMoneyRule => 'Money is measured against the gold or the silver nisab; choose either.';

  @override
  String get zakatNeedGoldPrice => 'Enter the price of 24-carat gold to work out the nisab';

  @override
  String get zakatNeedPrice => 'Enter the price of a gram of 21-karat gold to work out the nisab.';

  @override
  String get zakatNeedSilverPrice => 'Enter the price of silver to work out the nisab';

  @override
  String zakatNisabIs(String v) {
    return 'Nisab now: $v';
  }

  @override
  String zakatNisabRule(String grams, String karat) {
    return 'The nisab is the value of $grams grams of $karat-karat gold, so enter today\'s market price per gram.';
  }

  @override
  String get zakatPrice => 'Price of one gram of 21-karat gold today (your currency)';

  @override
  String get zakatPriceTitle => 'Today\'s gold price';

  @override
  String get zakatRain => 'Watered at no cost (rain/river) 10%';

  @override
  String get zakatResult => 'Result';

  @override
  String get zakatReview =>
      'Pending a shar\'i review: the calculator follows the published fatwas of Egypt\'s Dar al-Ifta (linked below) and has not been reviewed by a scholar yet. If your case is unclear, ask Dar al-Ifta.';

  @override
  String get zakatSheep => 'Sheep/goats';

  @override
  String get zakatSilverGrams => 'Weight of saved silver';

  @override
  String get zakatSilverPrice => 'Price of 1 g of pure silver (optional)';

  @override
  String get zakatSilverRule => 'The silver nisab is 595 g of pure silver.';

  @override
  String zakatSources(String ref) {
    return 'Sources: fatwas of $ref';
  }

  @override
  String get zakatTabCrops => 'Crops';

  @override
  String get zakatTabGold => 'Gold';

  @override
  String get zakatTabLivestock => 'Livestock';

  @override
  String get zakatTabMoney => 'Money';

  @override
  String get zakatTabSilver => 'Silver';

  @override
  String get zakatTileSub => 'Zakat on money, after Egypt\'s Dar al-Ifta';

  @override
  String get zakatTitle => 'Calculate your zakat';

  @override
  String zakatTotalAlso(String v) {
    return 'Also: $v';
  }

  @override
  String get zakatTotalEmpty => 'Fill in what you have above to see the total here.';

  @override
  String get zakatTotalNone => 'No zakat is due on what you entered';

  @override
  String get zakatTotalTitle => 'Total zakat due';

  @override
  String get zakatUnitBintLabun => 'bint labun (2-year camel)';

  @override
  String get zakatUnitBintMakhad => 'bint makhad (1-year camel)';

  @override
  String get zakatUnitHiqqa => 'hiqqa (3-year camel)';

  @override
  String get zakatUnitJadhaa => 'jadha\'a (4-year camel)';

  @override
  String get zakatUnitMusinna => 'musinna (2-year cow)';

  @override
  String get zakatUnitSheep => 'sheep';

  @override
  String get zakatUnitTabi => 'tabi\' (1-year calf)';

  @override
  String get zakatWealth => 'Your wealth (in your currency; gold in grams)';

  @override
  String zakatYearNotPassed(String net, String nisab) {
    return 'Your wealth ($net) has reached the nisab ($nisab); zakat is due once a full Hijri year passes over it.';
  }

  @override
  String get zakatYearNote =>
      'Due when the amount has stayed at or above the nisab for a full lunar year; the rate is 2.5%.';

  @override
  String get zakatYearPassed => 'A full Hijri year has passed since my wealth reached the nisab';

  @override
  String get readerFontSmallerShort => 'Smaller';

  @override
  String get readerFontBiggerShort => 'Bigger';

  @override
  String get readerFontSwitchShort => 'Font';

  @override
  String get surahInfoShort => 'Surah info';

  @override
  String get readerPrintedOffer => 'Madina font: download the whole Mushaf once and read offline (about 140 MB)';

  @override
  String get readerPrintedDownload => 'Download';

  @override
  String get readerPrintedResume => 'Resume';

  @override
  String get readerPrintedLater => 'Later';

  @override
  String get readerPrintedSavedAll => 'The Madina font is saved for the whole Mushaf and won\'t be downloaded again';

  @override
  String get aboutProofTitle => 'Sources and proof';

  @override
  String get aboutProofBody =>
      'Where the Quran, tafsir, hadith and every recording in the app come from, with the fingerprints that prove they match the source, and how to check it yourself.';

  @override
  String get aboutProofOpen => 'Open the sources and proof page';
}
