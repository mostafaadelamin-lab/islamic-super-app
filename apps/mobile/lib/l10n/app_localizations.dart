import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// shared key "about.fonts"
  ///
  /// In en, this message translates to:
  /// **'Fonts: Quran — KFGQPC HAFS Uthmanic Script v18 (King Fahd Complex, unmodified, under its licence); interface — IBM Plex Sans Arabic, SIL Open Font License 1.1.'**
  String get aboutFonts;

  /// shared key "about.openSource"
  ///
  /// In en, this message translates to:
  /// **'Open source and free forever. No tracking, no ads, no in-app purchases.'**
  String get aboutOpenSource;

  /// shared key "about.pages"
  ///
  /// In en, this message translates to:
  /// **'Mushaf pages and lines: Madinah Mushaf, KFGQPC new edition (1441H), line breaks via quran-madina-html (Waqf General Public License 2.0), checked against the Complex\'s page and line data.'**
  String get aboutPages;

  /// shared key "about.prayerAlgo"
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated on the device with standard astronomical formulas (Meeus / USNO) and checked against the independent adhan-js library.'**
  String get aboutPrayerAlgo;

  /// shared key "about.quranText"
  ///
  /// In en, this message translates to:
  /// **'Quran text: King Fahd Glorious Quran Printing Complex, Hafs Uthmanic Data v18 (hafsData_v18.json), Hafs an Asim. Bundled exactly as published (only the trailing ayah number is removed); verified by SHA-256.'**
  String get aboutQuranText;

  /// shared key "about.translation"
  ///
  /// In en, this message translates to:
  /// **'English translation: Saheeh International, via quran-json 3.1.2 (licence review pending).'**
  String get aboutTranslation;

  /// shared key "about.tzdb"
  ///
  /// In en, this message translates to:
  /// **'Time zones: IANA tz database (public domain) via the timezone package.'**
  String get aboutTzdb;

  /// shared key "about.version"
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// shared key "account.email"
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// shared key "account.errAuth"
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get accountErrAuth;

  /// shared key "account.errEmail"
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get accountErrEmail;

  /// shared key "account.errOffline"
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your internet connection and the server address.'**
  String get accountErrOffline;

  /// shared key "account.errPassword"
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 10 characters'**
  String get accountErrPassword;

  /// shared key "account.errRateLimit"
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get accountErrRateLimit;

  /// shared key "account.errServer"
  ///
  /// In en, this message translates to:
  /// **'Server error ({code})'**
  String accountErrServer(String code);

  /// shared key "account.errSession"
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get accountErrSession;

  /// shared key "account.errTaken"
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get accountErrTaken;

  /// shared key "account.lastSync"
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String accountLastSync(String time);

  /// shared key "account.login"
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountLogin;

  /// shared key "account.logout"
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountLogout;

  /// shared key "account.optional"
  ///
  /// In en, this message translates to:
  /// **'An account is optional. Everything works offline without one.'**
  String get accountOptional;

  /// shared key "account.password"
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPassword;

  /// shared key "account.register"
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountRegister;

  /// shared key "account.registered"
  ///
  /// In en, this message translates to:
  /// **'Account created. You can sign in now.'**
  String get accountRegistered;

  /// shared key "account.saveServer"
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get accountSaveServer;

  /// shared key "account.serverInvalid"
  ///
  /// In en, this message translates to:
  /// **'Enter an http:// or https:// address'**
  String get accountServerInvalid;

  /// shared key "account.serverSaved"
  ///
  /// In en, this message translates to:
  /// **'Server address saved'**
  String get accountServerSaved;

  /// shared key "account.serverUrl"
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get accountServerUrl;

  /// shared key "account.signedInAs"
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// shared key "account.syncDone"
  ///
  /// In en, this message translates to:
  /// **'Sync complete: {count} bookmarks'**
  String accountSyncDone(String count);

  /// shared key "account.syncNow"
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// shared key "adhan.banner"
  ///
  /// In en, this message translates to:
  /// **'Adhan alerts are off. Turn them on to hear the adhan at every prayer time.'**
  String get adhanBanner;

  /// shared key "adhan.bannerAction"
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get adhanBannerAction;

  /// shared key "adhan.bellOff"
  ///
  /// In en, this message translates to:
  /// **'{name} alert off'**
  String adhanBellOff(String name);

  /// shared key "adhan.bellOn"
  ///
  /// In en, this message translates to:
  /// **'{name} alert on'**
  String adhanBellOn(String name);

  /// shared key "adhan.body"
  ///
  /// In en, this message translates to:
  /// **'{name} prayer time in {city}'**
  String adhanBody(String name, String city);

  /// shared key "adhan.continued"
  ///
  /// In en, this message translates to:
  /// **'The adhan continues. Tap to hear all of it in the app.'**
  String get adhanContinued;

  /// shared key "adhan.credit"
  ///
  /// In en, this message translates to:
  /// **'Adhan recordings:'**
  String get adhanCredit;

  /// shared key "adhan.denied"
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed. Turn them on in the system settings.'**
  String get adhanDenied;

  /// shared key "adhan.enable"
  ///
  /// In en, this message translates to:
  /// **'Notify me at prayer times'**
  String get adhanEnable;

  /// shared key "adhan.extras"
  ///
  /// In en, this message translates to:
  /// **'Reminder before the adhan and iqama'**
  String get adhanExtras;

  /// shared key "adhan.extrasNote"
  ///
  /// In en, this message translates to:
  /// **'The reminder and the iqama alert use the phone\'s short tone, not the adhan recording.'**
  String get adhanExtrasNote;

  /// shared key "adhan.fajrVoice"
  ///
  /// In en, this message translates to:
  /// **'Fajr adhan'**
  String get adhanFajrVoice;

  /// shared key "adhan.fajrVoiceNote"
  ///
  /// In en, this message translates to:
  /// **'The Fajr adhan says «prayer is better than sleep», so it has its own choice and plays only at Fajr.'**
  String get adhanFajrVoiceNote;

  /// shared key "adhan.iosAlarm"
  ///
  /// In en, this message translates to:
  /// **'Full adhan as an alarm'**
  String get adhanIosAlarm;

  /// shared key "adhan.iosAlarmDenied"
  ///
  /// In en, this message translates to:
  /// **'Allow alarms for Rattil wa Salli in the iPhone Settings, then turn this on again.'**
  String get adhanIosAlarmDenied;

  /// shared key "adhan.iosAlarmHint"
  ///
  /// In en, this message translates to:
  /// **'The whole adhan rings like an alarm clock, even when the iPhone is on silent, with a stop button on the lock screen. iOS 26 or newer.'**
  String get adhanIosAlarmHint;

  /// shared key "adhan.iosFullHint"
  ///
  /// In en, this message translates to:
  /// **'On iPhone the whole adhan rings in parts, one after another. Open the app every day or two to keep it full; otherwise only the first 30 seconds ring.'**
  String get adhanIosFullHint;

  /// shared key "adhan.iosNote"
  ///
  /// In en, this message translates to:
  /// **'On iPhone the notification plays the opening takbir only (the system allows at most 30 seconds); the full adhan in the chosen voice plays inside the app.'**
  String get adhanIosNote;

  /// shared key "adhan.iqama"
  ///
  /// In en, this message translates to:
  /// **'Iqama alert after the adhan'**
  String get adhanIqama;

  /// shared key "adhan.iqamaBody"
  ///
  /// In en, this message translates to:
  /// **'{name} iqama, {minutes} minutes after the adhan'**
  String adhanIqamaBody(String name, String minutes);

  /// shared key "adhan.iqamaDecrease"
  ///
  /// In en, this message translates to:
  /// **'One minute less before {name} iqama'**
  String adhanIqamaDecrease(String name);

  /// shared key "adhan.iqamaIncrease"
  ///
  /// In en, this message translates to:
  /// **'One minute more before {name} iqama'**
  String adhanIqamaIncrease(String name);

  /// shared key "adhan.iqamaMinutes"
  ///
  /// In en, this message translates to:
  /// **'{n} min after the adhan'**
  String adhanIqamaMinutes(String n);

  /// shared key "adhan.iqamaTitle"
  ///
  /// In en, this message translates to:
  /// **'Iqama time for {name}'**
  String adhanIqamaTitle(String name);

  /// shared key "adhan.note"
  ///
  /// In en, this message translates to:
  /// **'Scheduled ahead on this device and works even when the app is closed; opening the app renews them. If an alert is late, allow \"Alarms & reminders\" and turn off battery optimisation for the app.'**
  String get adhanNote;

  /// shared key "adhan.nowPlaying"
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get adhanNowPlaying;

  /// shared key "adhan.openApp"
  ///
  /// In en, this message translates to:
  /// **'Continue in app'**
  String get adhanOpenApp;

  /// shared key "adhan.playOnSilent"
  ///
  /// In en, this message translates to:
  /// **'Play the adhan when the phone is silent'**
  String get adhanPlayOnSilent;

  /// shared key "adhan.playOnSilentHint"
  ///
  /// In en, this message translates to:
  /// **'The adhan plays at alarm volume even on silent or vibrate, like an alarm clock. Applies to the full adhan only.'**
  String get adhanPlayOnSilentHint;

  /// shared key "adhan.pre"
  ///
  /// In en, this message translates to:
  /// **'Reminder before the adhan'**
  String get adhanPre;

  /// shared key "adhan.preBody"
  ///
  /// In en, this message translates to:
  /// **'Get ready for {name} prayer'**
  String adhanPreBody(String name);

  /// shared key "adhan.preMinutes"
  ///
  /// In en, this message translates to:
  /// **'{n} minutes before'**
  String adhanPreMinutes(String n);

  /// shared key "adhan.preOff"
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adhanPreOff;

  /// shared key "adhan.preTitle"
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes until the {name} adhan'**
  String adhanPreTitle(String minutes, String name);

  /// shared key "adhan.preview"
  ///
  /// In en, this message translates to:
  /// **'Listen to the adhan'**
  String get adhanPreview;

  /// shared key "adhan.previewStop"
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get adhanPreviewStop;

  /// shared key "adhan.settings"
  ///
  /// In en, this message translates to:
  /// **'Adhan notifications'**
  String get adhanSettings;

  /// shared key "adhan.sound"
  ///
  /// In en, this message translates to:
  /// **'Alert sound'**
  String get adhanSound;

  /// shared key "adhan.soundAdhan"
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get adhanSoundAdhan;

  /// shared key "adhan.soundGeneral"
  ///
  /// In en, this message translates to:
  /// **'Same as the general setting'**
  String get adhanSoundGeneral;

  /// shared key "adhan.soundPerPrayer"
  ///
  /// In en, this message translates to:
  /// **'Alert sound per prayer'**
  String get adhanSoundPerPrayer;

  /// shared key "adhan.soundSilent"
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get adhanSoundSilent;

  /// shared key "adhan.soundTone"
  ///
  /// In en, this message translates to:
  /// **'Notification tone'**
  String get adhanSoundTone;

  /// shared key "adhan.stop"
  ///
  /// In en, this message translates to:
  /// **'Stop adhan'**
  String get adhanStop;

  /// shared key "adhan.test"
  ///
  /// In en, this message translates to:
  /// **'Test the alert (in 10 seconds)'**
  String get adhanTest;

  /// shared key "adhan.testBody"
  ///
  /// In en, this message translates to:
  /// **'If you heard the sound, alerts work on this phone.'**
  String get adhanTestBody;

  /// shared key "adhan.testScheduled"
  ///
  /// In en, this message translates to:
  /// **'A test alert will arrive in 10 seconds; you can close the app.'**
  String get adhanTestScheduled;

  /// shared key "adhan.testTitle"
  ///
  /// In en, this message translates to:
  /// **'Adhan alert test'**
  String get adhanTestTitle;

  /// shared key "adhan.title"
  ///
  /// In en, this message translates to:
  /// **'Time for {name}'**
  String adhanTitle(String name);

  /// shared key "adhan.voice"
  ///
  /// In en, this message translates to:
  /// **'Muezzin'**
  String get adhanVoice;

  /// shared key "adhan.voiceBundled"
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get adhanVoiceBundled;

  /// shared key "adhan.voiceDownloadFailed"
  ///
  /// In en, this message translates to:
  /// **'Could not download the adhan. Check the internet and try again.'**
  String get adhanVoiceDownloadFailed;

  /// shared key "adhan.voiceDownloaded"
  ///
  /// In en, this message translates to:
  /// **'On the phone'**
  String get adhanVoiceDownloaded;

  /// shared key "adhan.voiceListen"
  ///
  /// In en, this message translates to:
  /// **'Listen to {name}'**
  String adhanVoiceListen(String name);

  /// shared key "adhan.voiceNote"
  ///
  /// In en, this message translates to:
  /// **'Dhuhr, Asr, Maghrib and Isha. Pick a muezzin and press play to listen; every voice is inside the app and works offline.'**
  String get adhanVoiceNote;

  /// shared key "adhan.voiceSearch"
  ///
  /// In en, this message translates to:
  /// **'Search by muezzin or country'**
  String get adhanVoiceSearch;

  /// shared key "adhan.voiceTapToDownload"
  ///
  /// In en, this message translates to:
  /// **'Tap to download'**
  String get adhanVoiceTapToDownload;

  /// shared key "adhkar.afterPrayer"
  ///
  /// In en, this message translates to:
  /// **'Adhkar after prayer'**
  String get adhkarAfterPrayer;

  /// shared key "adhkar.alafasy"
  ///
  /// In en, this message translates to:
  /// **'Recited by Sheikh Mishary Rashid Alafasy'**
  String get adhkarAlafasy;

  /// shared key "adhkar.arabicOnly"
  ///
  /// In en, this message translates to:
  /// **'This content is available in Arabic only.'**
  String get adhkarArabicOnly;

  /// shared key "adhkar.audioDownloadFailed"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the recording. Check your internet and try again.'**
  String get adhkarAudioDownloadFailed;

  /// shared key "adhkar.audioDownloading"
  ///
  /// In en, this message translates to:
  /// **'Downloading the recording for the first time (about 4 MB); after that it plays without internet.'**
  String get adhkarAudioDownloading;

  /// shared key "adhkar.audioWatchOnline"
  ///
  /// In en, this message translates to:
  /// **'Listen online'**
  String get adhkarAudioWatchOnline;

  /// shared key "adhkar.cards"
  ///
  /// In en, this message translates to:
  /// **'One card at a time'**
  String get adhkarCards;

  /// shared key "adhkar.copied"
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get adhkarCopied;

  /// shared key "adhkar.copy"
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get adhkarCopy;

  /// shared key "adhkar.daily"
  ///
  /// In en, this message translates to:
  /// **'Daily adhkar'**
  String get adhkarDaily;

  /// shared key "adhkar.done"
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adhkarDone;

  /// shared key "adhkar.duas"
  ///
  /// In en, this message translates to:
  /// **'Duas'**
  String get adhkarDuas;

  /// shared key "adhkar.evening"
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get adhkarEvening;

  /// shared key "adhkar.eveningTitle"
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get adhkarEveningTitle;

  /// shared key "adhkar.hisn"
  ///
  /// In en, this message translates to:
  /// **'Hisn al-Muslim'**
  String get adhkarHisn;

  /// shared key "adhkar.hisnCount"
  ///
  /// In en, this message translates to:
  /// **'{n} entries'**
  String adhkarHisnCount(String n);

  /// shared key "adhkar.hisnSearch"
  ///
  /// In en, this message translates to:
  /// **'Search chapters'**
  String get adhkarHisnSearch;

  /// shared key "adhkar.itemOf"
  ///
  /// In en, this message translates to:
  /// **'Dhikr {n} of {total}'**
  String adhkarItemOf(String n, String total);

  /// shared key "adhkar.list"
  ///
  /// In en, this message translates to:
  /// **'Show as a list'**
  String get adhkarList;

  /// shared key "adhkar.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen (Mishary Alafasy)'**
  String get adhkarListen;

  /// shared key "adhkar.listenHeader"
  ///
  /// In en, this message translates to:
  /// **'Listen to the adhkar'**
  String get adhkarListenHeader;

  /// shared key "adhkar.morning"
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get adhkarMorning;

  /// shared key "adhkar.morningTitle"
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get adhkarMorningTitle;

  /// shared key "adhkar.nextCard"
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get adhkarNextCard;

  /// shared key "adhkar.offlineNote"
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone; plays without internet.'**
  String get adhkarOfflineNote;

  /// shared key "adhkar.percentDone"
  ///
  /// In en, this message translates to:
  /// **'{p}% done'**
  String adhkarPercentDone(String p);

  /// shared key "adhkar.prevCard"
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get adhkarPrevCard;

  /// shared key "adhkar.progress"
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} completed'**
  String adhkarProgress(String done, String total);

  /// shared key "adhkar.remaining"
  ///
  /// In en, this message translates to:
  /// **'{n} left'**
  String adhkarRemaining(String n);

  /// shared key "adhkar.reminderEvening"
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar reminder'**
  String get adhkarReminderEvening;

  /// shared key "adhkar.reminderMorning"
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar reminder'**
  String get adhkarReminderMorning;

  /// shared key "adhkar.reminders"
  ///
  /// In en, this message translates to:
  /// **'Adhkar reminders'**
  String get adhkarReminders;

  /// shared key "adhkar.repeat"
  ///
  /// In en, this message translates to:
  /// **'Repeat {n}'**
  String adhkarRepeat(String n);

  /// shared key "adhkar.repeatTimes"
  ///
  /// In en, this message translates to:
  /// **'Repeat: {n}'**
  String adhkarRepeatTimes(String n);

  /// shared key "adhkar.report"
  ///
  /// In en, this message translates to:
  /// **'Report a mistake'**
  String get adhkarReport;

  /// shared key "adhkar.reportIntro"
  ///
  /// In en, this message translates to:
  /// **'I think there is a mistake in this dhikr (please describe it below):'**
  String get adhkarReportIntro;

  /// shared key "adhkar.reportTitle"
  ///
  /// In en, this message translates to:
  /// **'Mistake in a dhikr'**
  String get adhkarReportTitle;

  /// shared key "adhkar.reset"
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get adhkarReset;

  /// shared key "adhkar.reviewNotice"
  ///
  /// In en, this message translates to:
  /// **'Pending religious review. Texts: Kazi Shariar adhkar dataset (CC BY 4.0) and Hisn al-Muslim; repetition counts follow Hisn al-Muslim.'**
  String get adhkarReviewNotice;

  /// shared key "adhkar.share"
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get adhkarShare;

  /// shared key "adhkar.shareSourceChapter"
  ///
  /// In en, this message translates to:
  /// **'Hisn al-Muslim — {title} (chapter {n})'**
  String adhkarShareSourceChapter(String title, String n);

  /// shared key "adhkar.shareSourceSession"
  ///
  /// In en, this message translates to:
  /// **'Hisn al-Muslim — {session} adhkar'**
  String adhkarShareSourceSession(String session);

  /// shared key "adhkar.sleep"
  ///
  /// In en, this message translates to:
  /// **'Adhkar before sleep'**
  String get adhkarSleep;

  /// shared key "adhkar.tapCounter"
  ///
  /// In en, this message translates to:
  /// **'Tap the circle to count; it moves on when the count is complete'**
  String get adhkarTapCounter;

  /// shared key "adhkar.tapToCount"
  ///
  /// In en, this message translates to:
  /// **'Tap a card to count it'**
  String get adhkarTapToCount;

  /// shared key "alert.adhkarEveningBody"
  ///
  /// In en, this message translates to:
  /// **'Time for the evening adhkar'**
  String get alertAdhkarEveningBody;

  /// shared key "alert.adhkarEveningTitle"
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get alertAdhkarEveningTitle;

  /// shared key "alert.adhkarMorningBody"
  ///
  /// In en, this message translates to:
  /// **'Time for the morning adhkar'**
  String get alertAdhkarMorningBody;

  /// shared key "alert.adhkarMorningTitle"
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get alertAdhkarMorningTitle;

  /// shared key "alert.friday"
  ///
  /// In en, this message translates to:
  /// **'Friday reminder (Surat al-Kahf)'**
  String get alertFriday;

  /// shared key "alert.fridayBody"
  ///
  /// In en, this message translates to:
  /// **'A reminder to read Surat al-Kahf and send many blessings upon the Prophet ﷺ'**
  String get alertFridayBody;

  /// shared key "alert.fridayTitle"
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get alertFridayTitle;

  /// shared key "alert.lastThird"
  ///
  /// In en, this message translates to:
  /// **'Alert at the last third of the night'**
  String get alertLastThird;

  /// shared key "alert.lastThirdBody"
  ///
  /// In en, this message translates to:
  /// **'The last third of the night has begun'**
  String get alertLastThirdBody;

  /// shared key "alert.lastThirdTitle"
  ///
  /// In en, this message translates to:
  /// **'Last third of the night'**
  String get alertLastThirdTitle;

  /// shared key "alert.others"
  ///
  /// In en, this message translates to:
  /// **'Other alerts'**
  String get alertOthers;

  /// shared key "alert.sunrise"
  ///
  /// In en, this message translates to:
  /// **'Alert at sunrise'**
  String get alertSunrise;

  /// shared key "alert.sunriseBody"
  ///
  /// In en, this message translates to:
  /// **'The sun has risen in {city}; the Fajr time has ended'**
  String alertSunriseBody(String city);

  /// shared key "alert.sunriseTitle"
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get alertSunriseTitle;

  /// shared key "appName"
  ///
  /// In en, this message translates to:
  /// **'Rattil wa Salli'**
  String get appName;

  /// shared key "asma.less"
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get asmaLess;

  /// shared key "asma.lessonBy"
  ///
  /// In en, this message translates to:
  /// **'Explained by Sheikh Muhammad Ratib al-Nabulsi'**
  String get asmaLessonBy;

  /// shared key "asma.listenLesson"
  ///
  /// In en, this message translates to:
  /// **'Listen to the explanation'**
  String get asmaListenLesson;

  /// shared key "asma.more"
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get asmaMore;

  /// shared key "asma.part"
  ///
  /// In en, this message translates to:
  /// **'Lesson {n}'**
  String asmaPart(String n);

  /// shared key "asma.search"
  ///
  /// In en, this message translates to:
  /// **'Find a name'**
  String get asmaSearch;

  /// shared key "asma.seeAlso"
  ///
  /// In en, this message translates to:
  /// **'Explained together with: {name}'**
  String asmaSeeAlso(String name);

  /// shared key "asma.source"
  ///
  /// In en, this message translates to:
  /// **'A simplified explanation of the 99 Names of Allah, quoted word for word from a published source.'**
  String get asmaSource;

  /// shared key "asma.stop"
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get asmaStop;

  /// shared key "asma.title"
  ///
  /// In en, this message translates to:
  /// **'Names of Allah'**
  String get asmaTitle;

  /// shared key "audio.basmala"
  ///
  /// In en, this message translates to:
  /// **'Basmala'**
  String get audioBasmala;

  /// shared key "audio.close"
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get audioClose;

  /// shared key "audio.loading"
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get audioLoading;

  /// shared key "audio.next"
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get audioNext;

  /// shared key "audio.offline"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the recitation. Check your internet connection and try again.'**
  String get audioOffline;

  /// shared key "audio.pause"
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get audioPause;

  /// shared key "audio.play"
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get audioPlay;

  /// shared key "audio.previous"
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get audioPrevious;

  /// shared key "audio.reciter"
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get audioReciter;

  /// shared key "audio.repeat"
  ///
  /// In en, this message translates to:
  /// **'Repeat each ayah'**
  String get audioRepeat;

  /// shared key "audio.repeatN"
  ///
  /// In en, this message translates to:
  /// **'{n}×'**
  String audioRepeatN(String n);

  /// shared key "audio.speed"
  ///
  /// In en, this message translates to:
  /// **'Playback speed: {speed}×'**
  String audioSpeed(String speed);

  /// shared key "audio.stop"
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get audioStop;

  /// shared key "audio.streamNote"
  ///
  /// In en, this message translates to:
  /// **'Recitations are streamed from everyayah.com and need an internet connection.'**
  String get audioStreamNote;

  /// shared key "audio.tafsirToggle"
  ///
  /// In en, this message translates to:
  /// **'Tafsir with recitation'**
  String get audioTafsirToggle;

  /// shared key "audio.title"
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get audioTitle;

  /// shared key "ayah.copy"
  ///
  /// In en, this message translates to:
  /// **'Copy the ayah'**
  String get ayahCopy;

  /// shared key "ayah.copyShort"
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get ayahCopyShort;

  /// shared key "ayah.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get ayahListen;

  /// shared key "ayah.listenOne"
  ///
  /// In en, this message translates to:
  /// **'Listen to this ayah only'**
  String get ayahListenOne;

  /// shared key "ayah.listenTafsir"
  ///
  /// In en, this message translates to:
  /// **'Listen with tafsir'**
  String get ayahListenTafsir;

  /// shared key "ayah.listenToPageEnd"
  ///
  /// In en, this message translates to:
  /// **'Listen from here to the end of the page'**
  String get ayahListenToPageEnd;

  /// shared key "ayah.listenToSurahEnd"
  ///
  /// In en, this message translates to:
  /// **'Listen from here to the end of the surah'**
  String get ayahListenToSurahEnd;

  /// shared key "ayah.markShort"
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get ayahMarkShort;

  /// shared key "ayah.onlyThis"
  ///
  /// In en, this message translates to:
  /// **'This ayah'**
  String get ayahOnlyThis;

  /// shared key "ayah.saveMark"
  ///
  /// In en, this message translates to:
  /// **'Save a mark on this ayah'**
  String get ayahSaveMark;

  /// shared key "ayah.share"
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get ayahShare;

  /// shared key "ayah.shareImage"
  ///
  /// In en, this message translates to:
  /// **'Share as an image'**
  String get ayahShareImage;

  /// shared key "ayah.tafsir"
  ///
  /// In en, this message translates to:
  /// **'Ayah tafsir'**
  String get ayahTafsir;

  /// shared key "ayah.toPageEnd"
  ///
  /// In en, this message translates to:
  /// **'To page end'**
  String get ayahToPageEnd;

  /// shared key "ayah.toSurahEnd"
  ///
  /// In en, this message translates to:
  /// **'To surah end'**
  String get ayahToSurahEnd;

  /// shared key "ayah.unmarkShort"
  ///
  /// In en, this message translates to:
  /// **'Unmark'**
  String get ayahUnmarkShort;

  /// shared key "ayah.withTafsir"
  ///
  /// In en, this message translates to:
  /// **'With tafsir'**
  String get ayahWithTafsir;

  /// shared key "bookmarks.delete"
  ///
  /// In en, this message translates to:
  /// **'Delete bookmark for {label}'**
  String bookmarksDelete(String label);

  /// shared key "bookmarks.empty"
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get bookmarksEmpty;

  /// shared key "common.close"
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// shared key "common.error"
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// shared key "common.offline"
  ///
  /// In en, this message translates to:
  /// **'You are offline — showing saved content'**
  String get commonOffline;

  /// shared key "common.retry"
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// shared key "contact.failed"
  ///
  /// In en, this message translates to:
  /// **'Could not send. Check your internet connection and try again.'**
  String get contactFailed;

  /// shared key "contact.intro"
  ///
  /// In en, this message translates to:
  /// **'Write your request and it will reach the team. Add your phone or WhatsApp number if you want a reply. If you are under 13, please ask a parent to send the message.'**
  String get contactIntro;

  /// shared key "contact.message"
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessage;

  /// shared key "contact.messageRequired"
  ///
  /// In en, this message translates to:
  /// **'Please write your message'**
  String get contactMessageRequired;

  /// shared key "contact.name"
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactName;

  /// shared key "contact.phone"
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get contactPhone;

  /// shared key "contact.send"
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactSend;

  /// shared key "contact.thanks"
  ///
  /// In en, this message translates to:
  /// **'Your message was sent. Thank you!'**
  String get contactThanks;

  /// shared key "contact.title"
  ///
  /// In en, this message translates to:
  /// **'Request title'**
  String get contactTitle;

  /// shared key "contact.titleRequired"
  ///
  /// In en, this message translates to:
  /// **'Please write a title'**
  String get contactTitleRequired;

  /// shared key "contact.whatsapp"
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number (optional)'**
  String get contactWhatsapp;

  /// shared key "dhikr.hadith"
  ///
  /// In en, this message translates to:
  /// **'The hadith'**
  String get dhikrHadith;

  /// shared key "dhikr.hadithFadl"
  ///
  /// In en, this message translates to:
  /// **'Its virtue'**
  String get dhikrHadithFadl;

  /// shared key "dhikr.hadithSource"
  ///
  /// In en, this message translates to:
  /// **'Where it is reported'**
  String get dhikrHadithSource;

  /// shared key "dhikr.hadithText"
  ///
  /// In en, this message translates to:
  /// **'The hadith about this dhikr'**
  String get dhikrHadithText;

  /// shared key "dhikr.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen to this dhikr'**
  String get dhikrListen;

  /// shared key "dhikr.listenFailed"
  ///
  /// In en, this message translates to:
  /// **'Could not play; check your internet'**
  String get dhikrListenFailed;

  /// shared key "dhikr.listenStop"
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get dhikrListenStop;

  /// shared key "dhikrRem.cancel"
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dhikrRemCancel;

  /// shared key "dhikrRem.custom"
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get dhikrRemCustom;

  /// shared key "dhikrRem.customTitle"
  ///
  /// In en, this message translates to:
  /// **'Every how many minutes?'**
  String get dhikrRemCustomTitle;

  /// shared key "dhikrRem.enable"
  ///
  /// In en, this message translates to:
  /// **'Remind me of dhikr through the day'**
  String get dhikrRemEnable;

  /// shared key "dhikrRem.enableHint"
  ///
  /// In en, this message translates to:
  /// **'Shows on the screen; when the phone is not on silent, Sheikh Mishary Alafasy says it'**
  String get dhikrRemEnableHint;

  /// shared key "dhikrRem.every"
  ///
  /// In en, this message translates to:
  /// **'How often?'**
  String get dhikrRemEvery;

  /// shared key "dhikrRem.from"
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dhikrRemFrom;

  /// shared key "dhikrRem.hour"
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get dhikrRemHour;

  /// shared key "dhikrRem.hours"
  ///
  /// In en, this message translates to:
  /// **'{n} hours'**
  String dhikrRemHours(String n);

  /// shared key "dhikrRem.iosCap"
  ///
  /// In en, this message translates to:
  /// **'iPhone allows a limited number of reminders, so they come every {n} minutes in this window'**
  String dhikrRemIosCap(String n);

  /// shared key "dhikrRem.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get dhikrRemListen;

  /// shared key "dhikrRem.minutes"
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String dhikrRemMinutes(String n);

  /// shared key "dhikrRem.notifTitle"
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get dhikrRemNotifTitle;

  /// shared key "dhikrRem.ok"
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dhikrRemOk;

  /// shared key "dhikrRem.pick"
  ///
  /// In en, this message translates to:
  /// **'Choose the adhkar'**
  String get dhikrRemPick;

  /// shared key "dhikrRem.pickHint"
  ///
  /// In en, this message translates to:
  /// **'(said in turn)'**
  String get dhikrRemPickHint;

  /// shared key "dhikrRem.pickOne"
  ///
  /// In en, this message translates to:
  /// **'Choose at least one dhikr'**
  String get dhikrRemPickOne;

  /// shared key "dhikrRem.summary"
  ///
  /// In en, this message translates to:
  /// **'{count} reminders a day'**
  String dhikrRemSummary(String count);

  /// shared key "dhikrRem.title"
  ///
  /// In en, this message translates to:
  /// **'Dhikr reminders'**
  String get dhikrRemTitle;

  /// shared key "dhikrRem.to"
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dhikrRemTo;

  /// shared key "dhikrRem.twoHours"
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get dhikrRemTwoHours;

  /// shared key "dhikrRem.windowHint"
  ///
  /// In en, this message translates to:
  /// **'No reminders while you sleep'**
  String get dhikrRemWindowHint;

  /// shared key "downloads.cancel"
  ///
  /// In en, this message translates to:
  /// **'Stop download'**
  String get downloadsCancel;

  /// shared key "downloads.delete"
  ///
  /// In en, this message translates to:
  /// **'Delete download'**
  String get downloadsDelete;

  /// shared key "downloads.deleteAll"
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get downloadsDeleteAll;

  /// shared key "downloads.download"
  ///
  /// In en, this message translates to:
  /// **'Download surah'**
  String get downloadsDownload;

  /// shared key "downloads.failed"
  ///
  /// In en, this message translates to:
  /// **'The download failed. Check the connection and try again; files already saved are kept.'**
  String get downloadsFailed;

  /// shared key "downloads.note"
  ///
  /// In en, this message translates to:
  /// **'Downloaded surahs play without internet. Downloads are for the reciter chosen now.'**
  String get downloadsNote;

  /// shared key "downloads.reciter"
  ///
  /// In en, this message translates to:
  /// **'Reciter: {name}'**
  String downloadsReciter(String name);

  /// shared key "downloads.title"
  ///
  /// In en, this message translates to:
  /// **'Downloaded recitations'**
  String get downloadsTitle;

  /// shared key "downloads.used"
  ///
  /// In en, this message translates to:
  /// **'Space used: {mb} MB'**
  String downloadsUsed(String mb);

  /// shared key "drive.again"
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get driveAgain;

  /// shared key "drive.carHint"
  ///
  /// In en, this message translates to:
  /// **'Control it from the car screen, the steering-wheel buttons or the lock screen: next = next dhikr, previous = this dhikr again, pause resumes at the same count.'**
  String get driveCarHint;

  /// shared key "drive.countOf"
  ///
  /// In en, this message translates to:
  /// **'{n} of {count}'**
  String driveCountOf(String n, String count);

  /// shared key "drive.cues"
  ///
  /// In en, this message translates to:
  /// **'Soft sound between repetitions'**
  String get driveCues;

  /// shared key "drive.cuesSub"
  ///
  /// In en, this message translates to:
  /// **'And a different sound when a dhikr is complete'**
  String get driveCuesSub;

  /// shared key "drive.dhikrOf"
  ///
  /// In en, this message translates to:
  /// **'Dhikr {n} of {total}'**
  String driveDhikrOf(String n, String total);

  /// shared key "drive.failed"
  ///
  /// In en, this message translates to:
  /// **'The recording could not be downloaded. Check the internet and try again.'**
  String get driveFailed;

  /// shared key "drive.finished"
  ///
  /// In en, this message translates to:
  /// **'All the adhkar are done. May Allah accept from you.'**
  String get driveFinished;

  /// shared key "drive.next"
  ///
  /// In en, this message translates to:
  /// **'Next dhikr'**
  String get driveNext;

  /// shared key "drive.open"
  ///
  /// In en, this message translates to:
  /// **'Listen while driving'**
  String get driveOpen;

  /// shared key "drive.openSub"
  ///
  /// In en, this message translates to:
  /// **'Repeats each dhikr its full count and counts for you'**
  String get driveOpenSub;

  /// shared key "drive.outOf"
  ///
  /// In en, this message translates to:
  /// **'of {count}'**
  String driveOutOf(String count);

  /// shared key "drive.pause"
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get drivePause;

  /// shared key "drive.play"
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get drivePlay;

  /// shared key "drive.preparing"
  ///
  /// In en, this message translates to:
  /// **'Getting the recording ready…'**
  String get drivePreparing;

  /// shared key "drive.previous"
  ///
  /// In en, this message translates to:
  /// **'This dhikr again'**
  String get drivePrevious;

  /// shared key "drive.retry"
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get driveRetry;

  /// shared key "drive.sayEvery"
  ///
  /// In en, this message translates to:
  /// **'Say the count out loud'**
  String get driveSayEvery;

  /// shared key "drive.sayEveryN"
  ///
  /// In en, this message translates to:
  /// **'Every {n}'**
  String driveSayEveryN(String n);

  /// shared key "drive.sayOff"
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get driveSayOff;

  /// shared key "drive.settings"
  ///
  /// In en, this message translates to:
  /// **'Driving mode settings'**
  String get driveSettings;

  /// shared key "drive.title"
  ///
  /// In en, this message translates to:
  /// **'Driving mode'**
  String get driveTitle;

  /// shared key "hadith.attribution"
  ///
  /// In en, this message translates to:
  /// **'Hadiths numbered as in al-Alamiyya, from the {name} project ({licence}).'**
  String hadithAttribution(String name, String licence);

  /// shared key "hadith.backToBook"
  ///
  /// In en, this message translates to:
  /// **'Back to the book'**
  String get hadithBackToBook;

  /// shared key "hadith.benefits"
  ///
  /// In en, this message translates to:
  /// **'Lessons from the hadith'**
  String get hadithBenefits;

  /// shared key "hadith.count"
  ///
  /// In en, this message translates to:
  /// **'{n} hadiths'**
  String hadithCount(String n);

  /// shared key "hadith.explain"
  ///
  /// In en, this message translates to:
  /// **'Simplified explanation'**
  String get hadithExplain;

  /// shared key "hadith.explainLess"
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get hadithExplainLess;

  /// shared key "hadith.explainMore"
  ///
  /// In en, this message translates to:
  /// **'Read the full explanation'**
  String get hadithExplainMore;

  /// shared key "hadith.explainSource"
  ///
  /// In en, this message translates to:
  /// **'The explanation is quoted word for word from a published hadith encyclopedia, not written by the app.'**
  String get hadithExplainSource;

  /// shared key "hadith.explainedCount"
  ///
  /// In en, this message translates to:
  /// **'{count} hadiths in this book have a simplified explanation'**
  String hadithExplainedCount(String count);

  /// shared key "hadith.explainedOnly"
  ///
  /// In en, this message translates to:
  /// **'Explained hadiths'**
  String get hadithExplainedOnly;

  /// shared key "hadith.favourites"
  ///
  /// In en, this message translates to:
  /// **'Saved hadiths'**
  String get hadithFavourites;

  /// shared key "hadith.goTo"
  ///
  /// In en, this message translates to:
  /// **'Go to hadith number (1–{max})'**
  String hadithGoTo(String max);

  /// shared key "hadith.grade"
  ///
  /// In en, this message translates to:
  /// **'Grade: {grade}'**
  String hadithGrade(String grade);

  /// shared key "hadith.loadError"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this part of the book.'**
  String get hadithLoadError;

  /// shared key "hadith.next"
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get hadithNext;

  /// shared key "hadith.noFavourites"
  ///
  /// In en, this message translates to:
  /// **'No saved hadiths yet. Tap the star next to any hadith.'**
  String get hadithNoFavourites;

  /// shared key "hadith.number"
  ///
  /// In en, this message translates to:
  /// **'Hadith {n}'**
  String hadithNumber(String n);

  /// shared key "hadith.pageOf"
  ///
  /// In en, this message translates to:
  /// **'Hadith {n} of {total}'**
  String hadithPageOf(String n, String total);

  /// shared key "hadith.prev"
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get hadithPrev;

  /// shared key "hadith.range"
  ///
  /// In en, this message translates to:
  /// **'Hadiths {from}–{to} of {count}'**
  String hadithRange(String from, String to, String count);

  /// shared key "hadith.results"
  ///
  /// In en, this message translates to:
  /// **'{n} results'**
  String hadithResults(String n);

  /// shared key "hadith.resultsMany"
  ///
  /// In en, this message translates to:
  /// **'First {n} results (add more words to narrow it)'**
  String hadithResultsMany(String n);

  /// shared key "hadith.review"
  ///
  /// In en, this message translates to:
  /// **'Under shar\'i review: the hadith texts are copied unchanged from the open Open-Hadith-Data database and have not yet been checked against a printed edition. If you find a mistake, please report it.'**
  String get hadithReview;

  /// shared key "hadith.save"
  ///
  /// In en, this message translates to:
  /// **'Save hadith'**
  String get hadithSave;

  /// shared key "hadith.search"
  ///
  /// In en, this message translates to:
  /// **'Search {book}'**
  String hadithSearch(String book);

  /// shared key "hadith.searching"
  ///
  /// In en, this message translates to:
  /// **'Searching… part {done} of {total}'**
  String hadithSearching(String done, String total);

  /// shared key "hadith.source"
  ///
  /// In en, this message translates to:
  /// **'{book}, hadith {n} (al-Alamiyya numbering)'**
  String hadithSource(String book, String n);

  /// shared key "hadith.title"
  ///
  /// In en, this message translates to:
  /// **'Hadith books'**
  String get hadithTitle;

  /// shared key "hadith.unsave"
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get hadithUnsave;

  /// shared key "hajj.counter.add"
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get hajjCounterAdd;

  /// shared key "hajj.counter.done"
  ///
  /// In en, this message translates to:
  /// **'Complete — may Allah accept it'**
  String get hajjCounterDone;

  /// shared key "hajj.counter.jamarat"
  ///
  /// In en, this message translates to:
  /// **'Jamarat pebble counter'**
  String get hajjCounterJamarat;

  /// shared key "hajj.counter.progress"
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String hajjCounterProgress(String n, String total);

  /// shared key "hajj.counter.reset"
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get hajjCounterReset;

  /// shared key "hajj.counter.sai"
  ///
  /// In en, this message translates to:
  /// **'Sa\'i round counter'**
  String get hajjCounterSai;

  /// shared key "hajj.counter.tawaf"
  ///
  /// In en, this message translates to:
  /// **'Tawaf round counter'**
  String get hajjCounterTawaf;

  /// shared key "hajj.counter.undo"
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get hajjCounterUndo;

  /// shared key "hajj.crowd.body"
  ///
  /// In en, this message translates to:
  /// **'The General Authority for the Care of the Two Holy Mosques shows live crowd levels for tawaf and sa\'i, and so does the official Nusuk app. Tap to open the official source.'**
  String get hajjCrowdBody;

  /// shared key "hajj.crowd.note"
  ///
  /// In en, this message translates to:
  /// **'Opens outside the app. The Authority page may only open from inside Saudi Arabia.'**
  String get hajjCrowdNote;

  /// shared key "hajj.crowd.nusuk"
  ///
  /// In en, this message translates to:
  /// **'Nusuk app'**
  String get hajjCrowdNusuk;

  /// shared key "hajj.crowd.official"
  ///
  /// In en, this message translates to:
  /// **'Official Authority page'**
  String get hajjCrowdOfficial;

  /// shared key "hajj.crowd.title"
  ///
  /// In en, this message translates to:
  /// **'Crowd levels at the Mataf and Mas\'a now'**
  String get hajjCrowdTitle;

  /// shared key "hajj.guideCorrections"
  ///
  /// In en, this message translates to:
  /// **'Digitization typos corrected'**
  String get hajjGuideCorrections;

  /// shared key "hajj.guideHajj"
  ///
  /// In en, this message translates to:
  /// **'How to perform Hajj'**
  String get hajjGuideHajj;

  /// shared key "hajj.guideSource"
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get hajjGuideSource;

  /// shared key "hajj.guideTypes"
  ///
  /// In en, this message translates to:
  /// **'Types of Hajj'**
  String get hajjGuideTypes;

  /// shared key "hajj.guideUmrah"
  ///
  /// In en, this message translates to:
  /// **'How to perform Umrah'**
  String get hajjGuideUmrah;

  /// shared key "hajj.hajj"
  ///
  /// In en, this message translates to:
  /// **'Hajj'**
  String get hajjHajj;

  /// shared key "hajj.hub.duas"
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah duas'**
  String get hajjHubDuas;

  /// shared key "hajj.hub.hajj"
  ///
  /// In en, this message translates to:
  /// **'Hajj rites'**
  String get hajjHubHajj;

  /// shared key "hajj.hub.ihram"
  ///
  /// In en, this message translates to:
  /// **'Miqat and ihram rules'**
  String get hajjHubIhram;

  /// shared key "hajj.hub.umrah"
  ///
  /// In en, this message translates to:
  /// **'Umrah steps and tawaf map'**
  String get hajjHubUmrah;

  /// shared key "hajj.hub.umrahSub"
  ///
  /// In en, this message translates to:
  /// **'Umrah one step at a time'**
  String get hajjHubUmrahSub;

  /// shared key "hajj.ifrad"
  ///
  /// In en, this message translates to:
  /// **'Ifrad'**
  String get hajjIfrad;

  /// shared key "hajj.ihram"
  ///
  /// In en, this message translates to:
  /// **'Ihram'**
  String get hajjIhram;

  /// shared key "hajj.kind.ifrad"
  ///
  /// In en, this message translates to:
  /// **'Hajj Ifrad'**
  String get hajjKindIfrad;

  /// shared key "hajj.kind.qiran"
  ///
  /// In en, this message translates to:
  /// **'Hajj Qiran'**
  String get hajjKindQiran;

  /// shared key "hajj.kind.sub"
  ///
  /// In en, this message translates to:
  /// **'The steps in order, one at a time'**
  String get hajjKindSub;

  /// shared key "hajj.kind.tamattu"
  ///
  /// In en, this message translates to:
  /// **'Hajj Tamattu\''**
  String get hajjKindTamattu;

  /// shared key "hajj.live.title"
  ///
  /// In en, this message translates to:
  /// **'Live from the Two Holy Mosques (audio)'**
  String get hajjLiveTitle;

  /// shared key "hajj.madinah"
  ///
  /// In en, this message translates to:
  /// **'Visiting Madinah'**
  String get hajjMadinah;

  /// shared key "hajj.officialGuide"
  ///
  /// In en, this message translates to:
  /// **'The steps explained, from the official guide (Arabic)'**
  String get hajjOfficialGuide;

  /// shared key "hajj.qiran"
  ///
  /// In en, this message translates to:
  /// **'Qiran'**
  String get hajjQiran;

  /// shared key "hajj.ref"
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get hajjRef;

  /// shared key "hajj.reviewNotice"
  ///
  /// In en, this message translates to:
  /// **'Pending religious review: this guide has not yet been reviewed by a qualified scholar. Check with a trusted scholar before relying on it.'**
  String get hajjReviewNotice;

  /// shared key "hajj.say.title"
  ///
  /// In en, this message translates to:
  /// **'What is said at this step'**
  String get hajjSayTitle;

  /// shared key "hajj.sources"
  ///
  /// In en, this message translates to:
  /// **'Sources of this guide'**
  String get hajjSources;

  /// shared key "hajj.stage"
  ///
  /// In en, this message translates to:
  /// **'Stage {n}'**
  String hajjStage(String n);

  /// shared key "hajj.stepNext"
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get hajjStepNext;

  /// shared key "hajj.stepOf"
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String hajjStepOf(String n, String total);

  /// shared key "hajj.stepPrev"
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get hajjStepPrev;

  /// shared key "hajj.stepsInOrder"
  ///
  /// In en, this message translates to:
  /// **'Hajj steps in order'**
  String get hajjStepsInOrder;

  /// shared key "hajj.tag.first"
  ///
  /// In en, this message translates to:
  /// **'First tawaf only'**
  String get hajjTagFirst;

  /// shared key "hajj.tag.men"
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get hajjTagMen;

  /// shared key "hajj.tag.women"
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get hajjTagWomen;

  /// shared key "hajj.tamattu"
  ///
  /// In en, this message translates to:
  /// **'Tamattu\''**
  String get hajjTamattu;

  /// shared key "hajj.tapStep"
  ///
  /// In en, this message translates to:
  /// **'Tap a step to read its explanation'**
  String get hajjTapStep;

  /// shared key "hajj.tapStepOne"
  ///
  /// In en, this message translates to:
  /// **'Tap a step number to show it'**
  String get hajjTapStepOne;

  /// shared key "hajj.times"
  ///
  /// In en, this message translates to:
  /// **'{n} times'**
  String hajjTimes(String n);

  /// shared key "hajj.title"
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah'**
  String get hajjTitle;

  /// shared key "hajj.typeLabel"
  ///
  /// In en, this message translates to:
  /// **'Type of Hajj'**
  String get hajjTypeLabel;

  /// shared key "hajj.umrah"
  ///
  /// In en, this message translates to:
  /// **'Umrah'**
  String get hajjUmrah;

  /// shared key "help.a1"
  ///
  /// In en, this message translates to:
  /// **'Yes. Rattil wa Salli has no ads, no subscriptions and no purchases, and it will stay that way.'**
  String get helpA1;

  /// shared key "help.a2"
  ///
  /// In en, this message translates to:
  /// **'The Quran text, tafsir, prayer times, qibla, adhkar, tasbih and your bookmarks all work offline. Recitations stream from the internet unless you save the surahs first (More → Downloads).'**
  String get helpA2;

  /// shared key "help.a3"
  ///
  /// In en, this message translates to:
  /// **'Mosques use different calculation methods and add a few minutes for caution. Choose your country\'s method and Asr school in the prayer settings, and adjust each prayer by minutes if needed.'**
  String get helpA3;

  /// shared key "help.a4"
  ///
  /// In en, this message translates to:
  /// **'In Settings → Recitation, or from the player itself while a recitation is playing.'**
  String get helpA4;

  /// shared key "help.a5"
  ///
  /// In en, this message translates to:
  /// **'On this phone only: bookmarks, khatma, worship tracker and settings never leave it unless you turn on account sync yourself.'**
  String get helpA5;

  /// shared key "help.a6"
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for Rattil wa Salli and, on Android, \"alarms and reminders\". Some phones stop apps in the background to save battery: exclude Rattil wa Salli from battery optimisation.'**
  String get helpA6;

  /// shared key "help.a7"
  ///
  /// In en, this message translates to:
  /// **'Use \"Report a mistake\" under the dhikr, or write to us below. Religious texts come from published sources and go through a review.'**
  String get helpA7;

  /// shared key "help.contact"
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get helpContact;

  /// shared key "help.contactPending"
  ///
  /// In en, this message translates to:
  /// **'The contact address will be added soon.'**
  String get helpContactPending;

  /// shared key "help.email"
  ///
  /// In en, this message translates to:
  /// **'Send us an email'**
  String get helpEmail;

  /// shared key "help.faq"
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get helpFaq;

  /// shared key "help.notNow"
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get helpNotNow;

  /// shared key "help.promptBody"
  ///
  /// In en, this message translates to:
  /// **'You have been using Rattil wa Salli for a few days. If it helps you, share it with someone; it is free for everyone.'**
  String get helpPromptBody;

  /// shared key "help.promptTitle"
  ///
  /// In en, this message translates to:
  /// **'Share Rattil wa Salli?'**
  String get helpPromptTitle;

  /// shared key "help.q1"
  ///
  /// In en, this message translates to:
  /// **'Is Rattil wa Salli really free?'**
  String get helpQ1;

  /// shared key "help.q2"
  ///
  /// In en, this message translates to:
  /// **'What works without the internet?'**
  String get helpQ2;

  /// shared key "help.q3"
  ///
  /// In en, this message translates to:
  /// **'Why do the prayer times differ from my mosque?'**
  String get helpQ3;

  /// shared key "help.q4"
  ///
  /// In en, this message translates to:
  /// **'How do I change the reciter or the speed?'**
  String get helpQ4;

  /// shared key "help.q5"
  ///
  /// In en, this message translates to:
  /// **'Where is my data kept?'**
  String get helpQ5;

  /// shared key "help.q6"
  ///
  /// In en, this message translates to:
  /// **'Why did the adhan not sound?'**
  String get helpQ6;

  /// shared key "help.q7"
  ///
  /// In en, this message translates to:
  /// **'I found a mistake in a text. What should I do?'**
  String get helpQ7;

  /// shared key "help.rate"
  ///
  /// In en, this message translates to:
  /// **'Rate Rattil wa Salli'**
  String get helpRate;

  /// shared key "help.ratePending"
  ///
  /// In en, this message translates to:
  /// **'Rating opens once the app is in the stores.'**
  String get helpRatePending;

  /// shared key "help.shareApp"
  ///
  /// In en, this message translates to:
  /// **'Share Rattil wa Salli'**
  String get helpShareApp;

  /// shared key "help.shareText"
  ///
  /// In en, this message translates to:
  /// **'Rattil wa Salli: Quran, prayer times and adhkar, free with no ads.'**
  String get helpShareText;

  /// shared key "help.spread"
  ///
  /// In en, this message translates to:
  /// **'Share and rate'**
  String get helpSpread;

  /// shared key "help.spreadBody"
  ///
  /// In en, this message translates to:
  /// **'If Rattil wa Salli helps you, share it with family and friends.'**
  String get helpSpreadBody;

  /// shared key "help.title"
  ///
  /// In en, this message translates to:
  /// **'Help & contact'**
  String get helpTitle;

  /// shared key "hisn.section.food"
  ///
  /// In en, this message translates to:
  /// **'Food and fasting'**
  String get hisnSectionFood;

  /// shared key "hisn.section.hajj"
  ///
  /// In en, this message translates to:
  /// **'Hajj and umrah'**
  String get hisnSectionHajj;

  /// shared key "hisn.section.hardship"
  ///
  /// In en, this message translates to:
  /// **'Worry and hardship'**
  String get hisnSectionHardship;

  /// shared key "hisn.section.home"
  ///
  /// In en, this message translates to:
  /// **'Home and clothing'**
  String get hisnSectionHome;

  /// shared key "hisn.section.illness"
  ///
  /// In en, this message translates to:
  /// **'Illness and death'**
  String get hisnSectionIllness;

  /// shared key "hisn.section.morningEvening"
  ///
  /// In en, this message translates to:
  /// **'Morning and evening'**
  String get hisnSectionMorningEvening;

  /// shared key "hisn.section.nature"
  ///
  /// In en, this message translates to:
  /// **'Rain, wind and the new moon'**
  String get hisnSectionNature;

  /// shared key "hisn.section.people"
  ///
  /// In en, this message translates to:
  /// **'Family and people'**
  String get hisnSectionPeople;

  /// shared key "hisn.section.prayer"
  ///
  /// In en, this message translates to:
  /// **'Purification, mosque and prayer'**
  String get hisnSectionPrayer;

  /// shared key "hisn.section.remembrance"
  ///
  /// In en, this message translates to:
  /// **'Remembrance and its virtue'**
  String get hisnSectionRemembrance;

  /// shared key "hisn.section.sleep"
  ///
  /// In en, this message translates to:
  /// **'Sleep and waking'**
  String get hisnSectionSleep;

  /// shared key "hisn.section.travel"
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get hisnSectionTravel;

  /// shared key "hisn.sectionAll"
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hisnSectionAll;

  /// shared key "home.big.adhkar"
  ///
  /// In en, this message translates to:
  /// **'Adhkar & Dua'**
  String get homeBigAdhkar;

  /// shared key "home.big.hajj"
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah'**
  String get homeBigHajj;

  /// shared key "home.big.library"
  ///
  /// In en, this message translates to:
  /// **'Recitations library'**
  String get homeBigLibrary;

  /// shared key "home.big.nasheeds"
  ///
  /// In en, this message translates to:
  /// **'Nasheeds'**
  String get homeBigNasheeds;

  /// shared key "home.big.prayer"
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get homeBigPrayer;

  /// shared key "home.big.qibla"
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get homeBigQibla;

  /// shared key "home.big.quran"
  ///
  /// In en, this message translates to:
  /// **'The Holy Quran'**
  String get homeBigQuran;

  /// shared key "home.big.reels"
  ///
  /// In en, this message translates to:
  /// **'Short Islamic videos'**
  String get homeBigReels;

  /// shared key "home.big.stories"
  ///
  /// In en, this message translates to:
  /// **'Prophets\' stories'**
  String get homeBigStories;

  /// shared key "home.big.tasbih"
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get homeBigTasbih;

  /// shared key "home.calendar"
  ///
  /// In en, this message translates to:
  /// **'Prayer calendar'**
  String get homeCalendar;

  /// shared key "home.elapsed"
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String homeElapsed(String time);

  /// shared key "home.hijriDate"
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year} AH'**
  String homeHijriDate(String day, String month, String year);

  /// shared key "home.lastPage"
  ///
  /// In en, this message translates to:
  /// **'Last page: {page}'**
  String homeLastPage(String page);

  /// shared key "home.left"
  ///
  /// In en, this message translates to:
  /// **'Time left {time}'**
  String homeLeft(String time);

  /// shared key "home.mainSections"
  ///
  /// In en, this message translates to:
  /// **'Main sections'**
  String get homeMainSections;

  /// shared key "home.nextPrayer"
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get homeNextPrayer;

  /// shared key "home.openMushaf"
  ///
  /// In en, this message translates to:
  /// **'Open the Mushaf'**
  String get homeOpenMushaf;

  /// shared key "home.prayerOf"
  ///
  /// In en, this message translates to:
  /// **'{name} prayer'**
  String homePrayerOf(String name);

  /// shared key "home.quickLinks"
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get homeQuickLinks;

  /// shared key "home.sections"
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get homeSections;

  /// shared key "home.sunrise"
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get homeSunrise;

  /// shared key "home.sunset"
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get homeSunset;

  /// shared key "home.timingFor"
  ///
  /// In en, this message translates to:
  /// **'Times for'**
  String get homeTimingFor;

  /// shared key "home.todayTimes"
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayer times'**
  String get homeTodayTimes;

  /// shared key "home.tomorrowTimes"
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s times'**
  String get homeTomorrowTimes;

  /// shared key "home.welcome"
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you'**
  String get homeWelcome;

  /// shared key "khatma.ahead"
  ///
  /// In en, this message translates to:
  /// **'{n} portions ahead of the plan, may Allah bless you.'**
  String khatmaAhead(String n);

  /// shared key "khatma.behind"
  ///
  /// In en, this message translates to:
  /// **'{n} days behind the plan.'**
  String khatmaBehind(String n);

  /// shared key "khatma.byDays"
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get khatmaByDays;

  /// shared key "khatma.byPages"
  ///
  /// In en, this message translates to:
  /// **'Pages per day'**
  String get khatmaByPages;

  /// shared key "khatma.currentWird"
  ///
  /// In en, this message translates to:
  /// **'Current portion ({n} of {total})'**
  String khatmaCurrentWird(String n, String total);

  /// shared key "khatma.days"
  ///
  /// In en, this message translates to:
  /// **'Finish in (days)'**
  String get khatmaDays;

  /// shared key "khatma.daysN"
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String khatmaDaysN(String n);

  /// shared key "khatma.defaultName"
  ///
  /// In en, this message translates to:
  /// **'My khatma'**
  String get khatmaDefaultName;

  /// shared key "khatma.delete"
  ///
  /// In en, this message translates to:
  /// **'Delete khatma'**
  String get khatmaDelete;

  /// shared key "khatma.deleteConfirm"
  ///
  /// In en, this message translates to:
  /// **'Delete this khatma? This cannot be undone.'**
  String get khatmaDeleteConfirm;

  /// shared key "khatma.endsOn"
  ///
  /// In en, this message translates to:
  /// **'Finishes on: {date}'**
  String khatmaEndsOn(String date);

  /// shared key "khatma.finishedOn"
  ///
  /// In en, this message translates to:
  /// **'completed on {date} in {days} days'**
  String khatmaFinishedOn(String date, String days);

  /// shared key "khatma.history"
  ///
  /// In en, this message translates to:
  /// **'Completed khatmas'**
  String get khatmaHistory;

  /// shared key "khatma.historyEmpty"
  ///
  /// In en, this message translates to:
  /// **'You have not completed a khatma yet.'**
  String get khatmaHistoryEmpty;

  /// shared key "khatma.juz"
  ///
  /// In en, this message translates to:
  /// **'Juz {n}'**
  String khatmaJuz(String n);

  /// shared key "khatma.markDone"
  ///
  /// In en, this message translates to:
  /// **'I have read it'**
  String get khatmaMarkDone;

  /// shared key "khatma.name"
  ///
  /// In en, this message translates to:
  /// **'Khatma name'**
  String get khatmaName;

  /// shared key "khatma.new"
  ///
  /// In en, this message translates to:
  /// **'New khatma'**
  String get khatmaNew;

  /// shared key "khatma.openPlanner"
  ///
  /// In en, this message translates to:
  /// **'Full khatma planner'**
  String get khatmaOpenPlanner;

  /// shared key "khatma.openPlannerSub"
  ///
  /// In en, this message translates to:
  /// **'Khatma by days, daily portion, reminder and history'**
  String get khatmaOpenPlannerSub;

  /// shared key "khatma.opening"
  ///
  /// In en, this message translates to:
  /// **'من قوله تعالى:'**
  String get khatmaOpening;

  /// shared key "khatma.pagesPerDay"
  ///
  /// In en, this message translates to:
  /// **'Pages each day'**
  String get khatmaPagesPerDay;

  /// shared key "khatma.preview"
  ///
  /// In en, this message translates to:
  /// **'{wirds} portions, about {pages} pages a day, finishing on {end}.'**
  String khatmaPreview(String wirds, String pages, String end);

  /// shared key "khatma.range"
  ///
  /// In en, this message translates to:
  /// **'From surah {fromSurah} ayah {fromAyah}, page {fromPage} to surah {toSurah} ayah {toAyah}, page {toPage}'**
  String khatmaRange(String fromSurah, String fromAyah, String fromPage, String toSurah, String toAyah, String toPage);

  /// shared key "khatma.read"
  ///
  /// In en, this message translates to:
  /// **'Read the portion'**
  String get khatmaRead;

  /// shared key "khatma.remainingDays"
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get khatmaRemainingDays;

  /// shared key "khatma.remainingWirds"
  ///
  /// In en, this message translates to:
  /// **'Portions left'**
  String get khatmaRemainingWirds;

  /// shared key "khatma.reminder"
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get khatmaReminder;

  /// shared key "khatma.reminderBody"
  ///
  /// In en, this message translates to:
  /// **'Time for today\'s portion of “{name}”'**
  String khatmaReminderBody(String name);

  /// shared key "khatma.reminderTitle"
  ///
  /// In en, this message translates to:
  /// **'Khatma portion'**
  String get khatmaReminderTitle;

  /// shared key "khatma.rename"
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get khatmaRename;

  /// shared key "khatma.reschedule"
  ///
  /// In en, this message translates to:
  /// **'Spread the rest again'**
  String get khatmaReschedule;

  /// shared key "khatma.showAll"
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get khatmaShowAll;

  /// shared key "khatma.start"
  ///
  /// In en, this message translates to:
  /// **'Start the khatma'**
  String get khatmaStart;

  /// shared key "khatma.tileSub"
  ///
  /// In en, this message translates to:
  /// **'A daily plan to complete the Mushaf'**
  String get khatmaTileSub;

  /// shared key "khatma.title"
  ///
  /// In en, this message translates to:
  /// **'Quran khatma'**
  String get khatmaTitle;

  /// shared key "kids.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get kidsListen;

  /// shared key "kids.minutes"
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String kidsMinutes(String n);

  /// shared key "kids.note"
  ///
  /// In en, this message translates to:
  /// **'For children: stories of the prophets, the teaching Mushaf, meaningful stories and ruqyah for children.'**
  String get kidsNote;

  /// shared key "kids.offlineNote"
  ///
  /// In en, this message translates to:
  /// **'Watch or listen to any episode, or tap the download icon to use it offline.'**
  String get kidsOfflineNote;

  /// shared key "kids.offlinePlaying"
  ///
  /// In en, this message translates to:
  /// **'Playing the copy saved on this device'**
  String get kidsOfflinePlaying;

  /// shared key "kids.prophets"
  ///
  /// In en, this message translates to:
  /// **'Stories of the prophets'**
  String get kidsProphets;

  /// shared key "kids.prophets3d"
  ///
  /// In en, this message translates to:
  /// **'Prophets\' stories: 3D'**
  String get kidsProphets3d;

  /// shared key "kids.prophets3dSub"
  ///
  /// In en, this message translates to:
  /// **'Modern 3D in Arabic, the prophet\'s face never shown'**
  String get kidsProphets3dSub;

  /// shared key "kids.prophetsClassic"
  ///
  /// In en, this message translates to:
  /// **'Prophets\' stories: full series'**
  String get kidsProphetsClassic;

  /// shared key "kids.prophetsNew"
  ///
  /// In en, this message translates to:
  /// **'Prophets\' stories: modern cartoon'**
  String get kidsProphetsNew;

  /// shared key "kids.prophetsNewSub"
  ///
  /// In en, this message translates to:
  /// **'A teacher tells the story; the prophet is shown only as light'**
  String get kidsProphetsNewSub;

  /// shared key "kids.prophetsPick"
  ///
  /// In en, this message translates to:
  /// **'Choose a series'**
  String get kidsProphetsPick;

  /// shared key "kids.prophetsSub"
  ///
  /// In en, this message translates to:
  /// **'Cartoon episodes: watch or listen, download for offline'**
  String get kidsProphetsSub;

  /// shared key "kids.ramadan"
  ///
  /// In en, this message translates to:
  /// **'Short meaningful stories'**
  String get kidsRamadan;

  /// shared key "kids.ramadanSub"
  ///
  /// In en, this message translates to:
  /// **'Short educational comics'**
  String get kidsRamadanSub;

  /// shared key "kids.rasoul"
  ///
  /// In en, this message translates to:
  /// **'Stories of the Prophet ﷺ for kids'**
  String get kidsRasoul;

  /// shared key "kids.rasoulSub"
  ///
  /// In en, this message translates to:
  /// **'With Sheikh Mahmoud al-Masri'**
  String get kidsRasoulSub;

  /// shared key "kids.ruqyahSub"
  ///
  /// In en, this message translates to:
  /// **'Read and listen'**
  String get kidsRuqyahSub;

  /// shared key "kids.size"
  ///
  /// In en, this message translates to:
  /// **'{n} MB'**
  String kidsSize(String n);

  /// shared key "kids.stories"
  ///
  /// In en, this message translates to:
  /// **'Religious & educational stories'**
  String get kidsStories;

  /// shared key "kids.storiesSub"
  ///
  /// In en, this message translates to:
  /// **'Stories from the Seerah and short meaningful stories'**
  String get kidsStoriesSub;

  /// shared key "kids.teacher"
  ///
  /// In en, this message translates to:
  /// **'Teaching Mushaf for kids'**
  String get kidsTeacher;

  /// shared key "kids.teacherAyah"
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}'**
  String kidsTeacherAyah(String n);

  /// shared key "kids.teacherBigger"
  ///
  /// In en, this message translates to:
  /// **'Bigger text'**
  String get kidsTeacherBigger;

  /// shared key "kids.teacherHint"
  ///
  /// In en, this message translates to:
  /// **'Tap any word to hear it, or an ayah number to hear that ayah alone.'**
  String get kidsTeacherHint;

  /// shared key "kids.teacherHusary"
  ///
  /// In en, this message translates to:
  /// **'Al-Husary (teaching)'**
  String get kidsTeacherHusary;

  /// shared key "kids.teacherMinshawy"
  ///
  /// In en, this message translates to:
  /// **'Al-Minshawy with children'**
  String get kidsTeacherMinshawy;

  /// shared key "kids.teacherNext"
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get kidsTeacherNext;

  /// shared key "kids.teacherNote"
  ///
  /// In en, this message translates to:
  /// **'Pick a surah to open the Mushaf: the sheikh reads, the word lights up, and your child repeats after him.'**
  String get kidsTeacherNote;

  /// shared key "kids.teacherOpen"
  ///
  /// In en, this message translates to:
  /// **'Open the Mushaf'**
  String get kidsTeacherOpen;

  /// shared key "kids.teacherPause"
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get kidsTeacherPause;

  /// shared key "kids.teacherPlay"
  ///
  /// In en, this message translates to:
  /// **'Listen to the surah'**
  String get kidsTeacherPlay;

  /// shared key "kids.teacherPrev"
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get kidsTeacherPrev;

  /// shared key "kids.teacherRepeat"
  ///
  /// In en, this message translates to:
  /// **'Repeat the ayah 3 times'**
  String get kidsTeacherRepeat;

  /// shared key "kids.teacherSmaller"
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get kidsTeacherSmaller;

  /// shared key "kids.teacherStars"
  ///
  /// In en, this message translates to:
  /// **'Your stars in this surah: {n}'**
  String kidsTeacherStars(String n);

  /// shared key "kids.teacherSub"
  ///
  /// In en, this message translates to:
  /// **'The sheikh reads, children repeat after him'**
  String get kidsTeacherSub;

  /// shared key "kids.teacherSurah"
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String kidsTeacherSurah(String name);

  /// shared key "kids.teacherWell"
  ///
  /// In en, this message translates to:
  /// **'Well done! You finished the surah and earned a star'**
  String get kidsTeacherWell;

  /// shared key "kids.teacherWord"
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get kidsTeacherWord;

  /// shared key "kids.title"
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get kidsTitle;

  /// shared key "kids.videoError"
  ///
  /// In en, this message translates to:
  /// **'Could not play the video. Check the internet connection or download the episode first.'**
  String get kidsVideoError;

  /// shared key "kids.watch"
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get kidsWatch;

  /// shared key "kids.ytNote"
  ///
  /// In en, this message translates to:
  /// **'Plays from YouTube, needs internet'**
  String get kidsYtNote;

  /// shared key "kidsLearn.books"
  ///
  /// In en, this message translates to:
  /// **'Kids\' book shelf'**
  String get kidsLearnBooks;

  /// shared key "kidsLearn.booksNote"
  ///
  /// In en, this message translates to:
  /// **'Pick a book and read it page by page. Save a book on the device to read it offline.'**
  String get kidsLearnBooksNote;

  /// shared key "kidsLearn.booksSub"
  ///
  /// In en, this message translates to:
  /// **'Picture books: adhkar, faith, manners and stories, page by page'**
  String get kidsLearnBooksSub;

  /// shared key "kidsLearn.boys"
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get kidsLearnBoys;

  /// shared key "kidsLearn.cardDone"
  ///
  /// In en, this message translates to:
  /// **'Said it today'**
  String get kidsLearnCardDone;

  /// shared key "kidsLearn.cardMark"
  ///
  /// In en, this message translates to:
  /// **'I said this dhikr'**
  String get kidsLearnCardMark;

  /// shared key "kidsLearn.cards"
  ///
  /// In en, this message translates to:
  /// **'Adhkar cards'**
  String get kidsLearnCards;

  /// shared key "kidsLearn.cardsSub"
  ///
  /// In en, this message translates to:
  /// **'Morning and evening adhkar in text, with a counter for each'**
  String get kidsLearnCardsSub;

  /// shared key "kidsLearn.cardsToday"
  ///
  /// In en, this message translates to:
  /// **'Your stars today: {n}'**
  String kidsLearnCardsToday(String n);

  /// shared key "kidsLearn.credit"
  ///
  /// In en, this message translates to:
  /// **'Text from {name}'**
  String kidsLearnCredit(String name);

  /// shared key "kidsLearn.delete"
  ///
  /// In en, this message translates to:
  /// **'Delete the saved copy'**
  String get kidsLearnDelete;

  /// shared key "kidsLearn.girls"
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get kidsLearnGirls;

  /// shared key "kidsLearn.hadith"
  ///
  /// In en, this message translates to:
  /// **'Memorise a hadith'**
  String get kidsLearnHadith;

  /// shared key "kidsLearn.hadithNo"
  ///
  /// In en, this message translates to:
  /// **'Hadith {n}'**
  String kidsLearnHadithNo(String n);

  /// shared key "kidsLearn.hadithNote"
  ///
  /// In en, this message translates to:
  /// **'Memorise one hadith a day. Start with level 1, repeat it until you know it, then tap «Memorised».'**
  String get kidsLearnHadithNote;

  /// shared key "kidsLearn.hadithSub"
  ///
  /// In en, this message translates to:
  /// **'600 hadith to memorise in four levels'**
  String get kidsLearnHadithSub;

  /// shared key "kidsLearn.level"
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String kidsLearnLevel(String n);

  /// shared key "kidsLearn.levelSub"
  ///
  /// In en, this message translates to:
  /// **'Hadith {from} to {to}'**
  String kidsLearnLevelSub(String from, String to);

  /// shared key "kidsLearn.markMemorized"
  ///
  /// In en, this message translates to:
  /// **'Tap when you know it'**
  String get kidsLearnMarkMemorized;

  /// shared key "kidsLearn.memorized"
  ///
  /// In en, this message translates to:
  /// **'Memorised'**
  String get kidsLearnMemorized;

  /// shared key "kidsLearn.next"
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get kidsLearnNext;

  /// shared key "kidsLearn.offline"
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get kidsLearnOffline;

  /// shared key "kidsLearn.page"
  ///
  /// In en, this message translates to:
  /// **'Page {n} of {total}'**
  String kidsLearnPage(String n, String total);

  /// shared key "kidsLearn.pages"
  ///
  /// In en, this message translates to:
  /// **'{n} pages'**
  String kidsLearnPages(String n);

  /// shared key "kidsLearn.prev"
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get kidsLearnPrev;

  /// shared key "kidsLearn.progress"
  ///
  /// In en, this message translates to:
  /// **'Memorised {n} of {total}'**
  String kidsLearnProgress(String n, String total);

  /// shared key "kidsLearn.reads"
  ///
  /// In en, this message translates to:
  /// **'Repeated {n} times'**
  String kidsLearnReads(String n);

  /// shared key "kidsLearn.salah"
  ///
  /// In en, this message translates to:
  /// **'Learn salah'**
  String get kidsLearnSalah;

  /// shared key "kidsLearn.salahSub"
  ///
  /// In en, this message translates to:
  /// **'Prayer steps in pictures'**
  String get kidsLearnSalahSub;

  /// shared key "kidsLearn.save"
  ///
  /// In en, this message translates to:
  /// **'Save the book on this device'**
  String get kidsLearnSave;

  /// shared key "kidsLearn.saveFailed"
  ///
  /// In en, this message translates to:
  /// **'Could not save the book. Check the connection and try again.'**
  String get kidsLearnSaveFailed;

  /// shared key "kidsLearn.shelfAdhkar"
  ///
  /// In en, this message translates to:
  /// **'Adhkar and duas'**
  String get kidsLearnShelfAdhkar;

  /// shared key "kidsLearn.shelfAkhlaq"
  ///
  /// In en, this message translates to:
  /// **'Manners'**
  String get kidsLearnShelfAkhlaq;

  /// shared key "kidsLearn.shelfAqeedah"
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get kidsLearnShelfAqeedah;

  /// shared key "kidsLearn.shelfFiqh"
  ///
  /// In en, this message translates to:
  /// **'Purity and prayer'**
  String get kidsLearnShelfFiqh;

  /// shared key "kidsLearn.shelfParents"
  ///
  /// In en, this message translates to:
  /// **'For parents'**
  String get kidsLearnShelfParents;

  /// shared key "kidsLearn.shelfQuran"
  ///
  /// In en, this message translates to:
  /// **'The Quran'**
  String get kidsLearnShelfQuran;

  /// shared key "kidsLearn.shelfRamadan"
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get kidsLearnShelfRamadan;

  /// shared key "kidsLearn.shelfStories"
  ///
  /// In en, this message translates to:
  /// **'Prophets and Seerah'**
  String get kidsLearnShelfStories;

  /// shared key "kidsLearn.step"
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String kidsLearnStep(String n, String total);

  /// shared key "kidsLearn.stepsDone"
  ///
  /// In en, this message translates to:
  /// **'Well done! You finished all the steps'**
  String get kidsLearnStepsDone;

  /// shared key "kidsLearn.wudu"
  ///
  /// In en, this message translates to:
  /// **'Learn wudu'**
  String get kidsLearnWudu;

  /// shared key "kidsLearn.wuduSub"
  ///
  /// In en, this message translates to:
  /// **'Wudu steps in pictures'**
  String get kidsLearnWuduSub;

  /// shared key "library.allRiwayat"
  ///
  /// In en, this message translates to:
  /// **'All riwayat'**
  String get libraryAllRiwayat;

  /// shared key "library.empty"
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get libraryEmpty;

  /// shared key "library.live"
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get libraryLive;

  /// shared key "library.loadError"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list. Check your connection and try again.'**
  String get libraryLoadError;

  /// shared key "library.radios"
  ///
  /// In en, this message translates to:
  /// **'Radios'**
  String get libraryRadios;

  /// shared key "library.reciters"
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get libraryReciters;

  /// shared key "library.retry"
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get libraryRetry;

  /// shared key "library.rewaya"
  ///
  /// In en, this message translates to:
  /// **'Riwaya'**
  String get libraryRewaya;

  /// shared key "library.search"
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get librarySearch;

  /// shared key "library.source"
  ///
  /// In en, this message translates to:
  /// **'Recitations and radios are streamed over the internet.'**
  String get librarySource;

  /// shared key "library.surahCount"
  ///
  /// In en, this message translates to:
  /// **'{n} surahs'**
  String librarySurahCount(String n);

  /// shared key "library.surahTitle"
  ///
  /// In en, this message translates to:
  /// **'{reciter} — Surah {surah}'**
  String librarySurahTitle(String reciter, String surah);

  /// shared key "library.title"
  ///
  /// In en, this message translates to:
  /// **'Recitations library: all Quran reciters'**
  String get libraryTitle;

  /// shared key "meanings.error"
  ///
  /// In en, this message translates to:
  /// **'Could not load the word meanings.'**
  String get meaningsError;

  /// shared key "meanings.loading"
  ///
  /// In en, this message translates to:
  /// **'Loading the word meanings…'**
  String get meaningsLoading;

  /// shared key "meanings.noneAyah"
  ///
  /// In en, this message translates to:
  /// **'No difficult words are explained in this ayah.'**
  String get meaningsNoneAyah;

  /// shared key "meanings.nonePage"
  ///
  /// In en, this message translates to:
  /// **'No difficult words are explained on this page.'**
  String get meaningsNonePage;

  /// shared key "meanings.ofAyah"
  ///
  /// In en, this message translates to:
  /// **'Word meanings of {ref}'**
  String meaningsOfAyah(String ref);

  /// shared key "meanings.ofPage"
  ///
  /// In en, this message translates to:
  /// **'Word meanings, page {page}'**
  String meaningsOfPage(String page);

  /// shared key "meanings.short"
  ///
  /// In en, this message translates to:
  /// **'Meanings'**
  String get meaningsShort;

  /// shared key "meanings.source"
  ///
  /// In en, this message translates to:
  /// **'From «Al-Siraj fi Bayan Gharib al-Quran» by Muhammad al-Khudairi (Arabic)'**
  String get meaningsSource;

  /// shared key "meanings.title"
  ///
  /// In en, this message translates to:
  /// **'Word meanings'**
  String get meaningsTitle;

  /// shared key "more.title"
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// shared key "mosques.around"
  ///
  /// In en, this message translates to:
  /// **'Mosques around {place}'**
  String mosquesAround(String place);

  /// shared key "mosques.count"
  ///
  /// In en, this message translates to:
  /// **'{n} mosques, nearest first. Tap one for directions.'**
  String mosquesCount(String n);

  /// shared key "mosques.error"
  ///
  /// In en, this message translates to:
  /// **'Could not reach OpenStreetMap. Check your internet connection.'**
  String get mosquesError;

  /// shared key "mosques.geoFallback"
  ///
  /// In en, this message translates to:
  /// **'Your location is not available (turn on GPS and allow location). Showing mosques around your prayer-times city.'**
  String get mosquesGeoFallback;

  /// shared key "mosques.km"
  ///
  /// In en, this message translates to:
  /// **'{n} km'**
  String mosquesKm(String n);

  /// shared key "mosques.loading"
  ///
  /// In en, this message translates to:
  /// **'Searching for mosques…'**
  String get mosquesLoading;

  /// shared key "mosques.locate"
  ///
  /// In en, this message translates to:
  /// **'Update my location'**
  String get mosquesLocate;

  /// shared key "mosques.locating"
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get mosquesLocating;

  /// shared key "mosques.meters"
  ///
  /// In en, this message translates to:
  /// **'{n} m'**
  String mosquesMeters(String n);

  /// shared key "mosques.myLocation"
  ///
  /// In en, this message translates to:
  /// **'your current location'**
  String get mosquesMyLocation;

  /// shared key "mosques.none"
  ///
  /// In en, this message translates to:
  /// **'No mosques are mapped within this distance. Try a larger one.'**
  String get mosquesNone;

  /// shared key "mosques.note"
  ///
  /// In en, this message translates to:
  /// **'Straight-line distance. Data from the open OpenStreetMap map; it can be incomplete in some places.'**
  String get mosquesNote;

  /// shared key "mosques.offline"
  ///
  /// In en, this message translates to:
  /// **'(last saved result, you are offline)'**
  String get mosquesOffline;

  /// shared key "mosques.onGoogleMaps"
  ///
  /// In en, this message translates to:
  /// **'Open nearby mosques in Google Maps'**
  String get mosquesOnGoogleMaps;

  /// shared key "mosques.openApple"
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get mosquesOpenApple;

  /// shared key "mosques.openGoogle"
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get mosquesOpenGoogle;

  /// shared key "mosques.openOther"
  ///
  /// In en, this message translates to:
  /// **'Open in another maps app'**
  String get mosquesOpenOther;

  /// shared key "mosques.openWaze"
  ///
  /// In en, this message translates to:
  /// **'Open in Waze'**
  String get mosquesOpenWaze;

  /// shared key "mosques.retry"
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mosquesRetry;

  /// shared key "mosques.title"
  ///
  /// In en, this message translates to:
  /// **'Nearby mosques'**
  String get mosquesTitle;

  /// shared key "mosques.unnamed"
  ///
  /// In en, this message translates to:
  /// **'Mosque (no name on the map)'**
  String get mosquesUnnamed;

  /// shared key "mushaf.copied"
  ///
  /// In en, this message translates to:
  /// **'Ayah copied'**
  String get mushafCopied;

  /// shared key "mushaf.copy"
  ///
  /// In en, this message translates to:
  /// **'Copy ayah'**
  String get mushafCopy;

  /// shared key "mushaf.playFromHere"
  ///
  /// In en, this message translates to:
  /// **'Listen from here'**
  String get mushafPlayFromHere;

  /// shared key "mushaf.playPage"
  ///
  /// In en, this message translates to:
  /// **'Listen to this page'**
  String get mushafPlayPage;

  /// shared key "mushaf.playSurah"
  ///
  /// In en, this message translates to:
  /// **'Listen to the surah'**
  String get mushafPlaySurah;

  /// shared key "mushaf.readAsList"
  ///
  /// In en, this message translates to:
  /// **'Read as a list'**
  String get mushafReadAsList;

  /// shared key "mushaf.shareImage"
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get mushafShareImage;

  /// shared key "mushaf.shareImageTitle"
  ///
  /// In en, this message translates to:
  /// **'Ayah image'**
  String get mushafShareImageTitle;

  /// shared key "mushaf.shareNow"
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get mushafShareNow;

  /// shared key "mushaf.slider"
  ///
  /// In en, this message translates to:
  /// **'Page {page} of 604'**
  String mushafSlider(String page);

  /// shared key "mushaf.tapHint"
  ///
  /// In en, this message translates to:
  /// **'Tap an ayah for listening, bookmark and copy'**
  String get mushafTapHint;

  /// shared key "mushaf.toggleControls"
  ///
  /// In en, this message translates to:
  /// **'Show or hide controls'**
  String get mushafToggleControls;

  /// shared key "nasheeds.arab"
  ///
  /// In en, this message translates to:
  /// **'From the Arab world'**
  String get nasheedsArab;

  /// shared key "nasheeds.count"
  ///
  /// In en, this message translates to:
  /// **'{n} nasheeds'**
  String nasheedsCount(String n);

  /// shared key "nasheeds.egypt"
  ///
  /// In en, this message translates to:
  /// **'From Egypt'**
  String get nasheedsEgypt;

  /// shared key "nasheeds.loadError"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the nasheeds list.'**
  String get nasheedsLoadError;

  /// shared key "nasheeds.next"
  ///
  /// In en, this message translates to:
  /// **'Next nasheed'**
  String get nasheedsNext;

  /// shared key "nasheeds.note"
  ///
  /// In en, this message translates to:
  /// **'Listen to any nasheed online, or tap the download icon to keep it for offline listening.'**
  String get nasheedsNote;

  /// shared key "nasheeds.prev"
  ///
  /// In en, this message translates to:
  /// **'Previous nasheed'**
  String get nasheedsPrev;

  /// shared key "nasheeds.search"
  ///
  /// In en, this message translates to:
  /// **'Find a nasheed or munshid'**
  String get nasheedsSearch;

  /// shared key "nasheeds.title"
  ///
  /// In en, this message translates to:
  /// **'Nasheeds'**
  String get nasheedsTitle;

  /// shared key "nav.adhkar"
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get navAdhkar;

  /// shared key "nav.bookmarks"
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get navBookmarks;

  /// shared key "nav.home"
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// shared key "nav.more"
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// shared key "nav.prayer"
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get navPrayer;

  /// shared key "nav.quran"
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// shared key "nav.settings"
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// shared key "nav.videos"
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get navVideos;

  /// shared key "offline.done"
  ///
  /// In en, this message translates to:
  /// **'Saved: you can listen without internet'**
  String get offlineDone;

  /// shared key "offline.download"
  ///
  /// In en, this message translates to:
  /// **'Download for offline listening'**
  String get offlineDownload;

  /// shared key "offline.failed"
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check the internet and try again'**
  String get offlineFailed;

  /// shared key "offline.savedDelete"
  ///
  /// In en, this message translates to:
  /// **'Saved on the phone — tap to delete'**
  String get offlineSavedDelete;

  /// shared key "parentLock.age13plus"
  ///
  /// In en, this message translates to:
  /// **'13 or older'**
  String get parentLockAge13plus;

  /// shared key "parentLock.ageAsk"
  ///
  /// In en, this message translates to:
  /// **'Choose your age group'**
  String get parentLockAgeAsk;

  /// shared key "parentLock.ageTitle"
  ///
  /// In en, this message translates to:
  /// **'Before you open videos'**
  String get parentLockAgeTitle;

  /// shared key "parentLock.ageUnder13"
  ///
  /// In en, this message translates to:
  /// **'Under 13'**
  String get parentLockAgeUnder13;

  /// shared key "parentLock.answer"
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get parentLockAnswer;

  /// shared key "parentLock.back"
  ///
  /// In en, this message translates to:
  /// **'Back to children\'s videos'**
  String get parentLockBack;

  /// shared key "parentLock.challenge"
  ///
  /// In en, this message translates to:
  /// **'Question for adults: what is {a} × {b}?'**
  String parentLockChallenge(String a, String b);

  /// shared key "parentLock.challengeWrong"
  ///
  /// In en, this message translates to:
  /// **'Wrong answer'**
  String get parentLockChallengeWrong;

  /// shared key "parentLock.confirm"
  ///
  /// In en, this message translates to:
  /// **'Type the PIN again to confirm'**
  String get parentLockConfirm;

  /// shared key "parentLock.enter"
  ///
  /// In en, this message translates to:
  /// **'Type the PIN to open videos'**
  String get parentLockEnter;

  /// shared key "parentLock.forgot"
  ///
  /// In en, this message translates to:
  /// **'Forgot the PIN?'**
  String get parentLockForgot;

  /// shared key "parentLock.handOver"
  ///
  /// In en, this message translates to:
  /// **'Please hand the phone to a parent to choose the PIN.'**
  String get parentLockHandOver;

  /// shared key "parentLock.intro"
  ///
  /// In en, this message translates to:
  /// **'Videos and short clips come from YouTube and Instagram, so they are locked for children. A parent opens them with a PIN.'**
  String get parentLockIntro;

  /// shared key "parentLock.kidsNote"
  ///
  /// In en, this message translates to:
  /// **'These are the kids section videos. A parent opens the other videos with the PIN.'**
  String get parentLockKidsNote;

  /// shared key "parentLock.kidsTitle"
  ///
  /// In en, this message translates to:
  /// **'Videos for children'**
  String get parentLockKidsTitle;

  /// shared key "parentLock.lockNow"
  ///
  /// In en, this message translates to:
  /// **'Lock videos'**
  String get parentLockLockNow;

  /// shared key "parentLock.mismatch"
  ///
  /// In en, this message translates to:
  /// **'The two PINs don\'t match, start again'**
  String get parentLockMismatch;

  /// shared key "parentLock.next"
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get parentLockNext;

  /// shared key "parentLock.parentOpen"
  ///
  /// In en, this message translates to:
  /// **'Parent: open all videos'**
  String get parentLockParentOpen;

  /// shared key "parentLock.pin"
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get parentLockPin;

  /// shared key "parentLock.reset"
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN'**
  String get parentLockReset;

  /// shared key "parentLock.save"
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get parentLockSave;

  /// shared key "parentLock.setTitle"
  ///
  /// In en, this message translates to:
  /// **'Parent: choose a 4-digit PIN'**
  String get parentLockSetTitle;

  /// shared key "parentLock.title"
  ///
  /// In en, this message translates to:
  /// **'Parent lock'**
  String get parentLockTitle;

  /// shared key "parentLock.unlock"
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get parentLockUnlock;

  /// shared key "parentLock.wrong"
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN, try again'**
  String get parentLockWrong;

  /// shared key "player.open"
  ///
  /// In en, this message translates to:
  /// **'Back to what is playing'**
  String get playerOpen;

  /// shared key "prayer.adjust"
  ///
  /// In en, this message translates to:
  /// **'Manual adjustment (minutes)'**
  String get prayerAdjust;

  /// shared key "prayer.asr"
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// shared key "prayer.asrHanafi"
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get prayerAsrHanafi;

  /// shared key "prayer.asrMethod"
  ///
  /// In en, this message translates to:
  /// **'Asr method'**
  String get prayerAsrMethod;

  /// shared key "prayer.asrStandard"
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi\'i, Maliki, Hanbali)'**
  String get prayerAsrStandard;

  /// shared key "prayer.autoLocation"
  ///
  /// In en, this message translates to:
  /// **'Detect location automatically'**
  String get prayerAutoLocation;

  /// shared key "prayer.autoLocationNote"
  ///
  /// In en, this message translates to:
  /// **'Your location is refreshed when the app opens, so times stay right when you travel.'**
  String get prayerAutoLocationNote;

  /// shared key "prayer.backToToday"
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get prayerBackToToday;

  /// shared key "prayer.calendarTitle"
  ///
  /// In en, this message translates to:
  /// **'Monthly prayer calendar'**
  String get prayerCalendarTitle;

  /// shared key "prayer.city"
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get prayerCity;

  /// shared key "prayer.clock"
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get prayerClock;

  /// shared key "prayer.clock12"
  ///
  /// In en, this message translates to:
  /// **'12-hour (1:05 PM)'**
  String get prayerClock12;

  /// shared key "prayer.clock24"
  ///
  /// In en, this message translates to:
  /// **'24-hour (13:05)'**
  String get prayerClock24;

  /// shared key "prayer.compactNote"
  ///
  /// In en, this message translates to:
  /// **'To change the city, calculation method or adhan alerts, tap Edit prayer times.'**
  String get prayerCompactNote;

  /// shared key "prayer.compassLabel"
  ///
  /// In en, this message translates to:
  /// **'Compass: qibla is {deg}° clockwise from north'**
  String prayerCompassLabel(String deg);

  /// shared key "prayer.date"
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String prayerDate(String date);

  /// shared key "prayer.dayCol"
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get prayerDayCol;

  /// shared key "prayer.decrease"
  ///
  /// In en, this message translates to:
  /// **'Subtract a minute from {name}'**
  String prayerDecrease(String name);

  /// shared key "prayer.dhuhr"
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// shared key "prayer.editTimes"
  ///
  /// In en, this message translates to:
  /// **'Edit prayer times'**
  String get prayerEditTimes;

  /// shared key "prayer.fajr"
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// shared key "prayer.geoDenied"
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. Choose a city from the list instead.'**
  String get prayerGeoDenied;

  /// shared key "prayer.geoUnavailable"
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Turn on location services or choose a city.'**
  String get prayerGeoUnavailable;

  /// shared key "prayer.gregorian"
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get prayerGregorian;

  /// shared key "prayer.highLat"
  ///
  /// In en, this message translates to:
  /// **'High-latitude rule applied to: {list}'**
  String prayerHighLat(String list);

  /// shared key "prayer.hijri"
  ///
  /// In en, this message translates to:
  /// **'Hijri'**
  String get prayerHijri;

  /// shared key "prayer.hijriCol"
  ///
  /// In en, this message translates to:
  /// **'Hijri'**
  String get prayerHijriCol;

  /// shared key "prayer.in"
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String prayerIn(String time);

  /// shared key "prayer.increase"
  ///
  /// In en, this message translates to:
  /// **'Add a minute to {name}'**
  String prayerIncrease(String name);

  /// shared key "prayer.isha"
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// shared key "prayer.locating"
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get prayerLocating;

  /// shared key "prayer.locationServices"
  ///
  /// In en, this message translates to:
  /// **'Location services'**
  String get prayerLocationServices;

  /// shared key "prayer.maghrib"
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// shared key "prayer.method"
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get prayerMethod;

  /// shared key "prayer.minutesValue"
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String prayerMinutesValue(String n);

  /// shared key "prayer.next"
  ///
  /// In en, this message translates to:
  /// **'Next prayer: {name}'**
  String prayerNext(String name);

  /// shared key "prayer.nextDay"
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get prayerNextDay;

  /// shared key "prayer.nextMonth"
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get prayerNextMonth;

  /// shared key "prayer.noPrayerToday"
  ///
  /// In en, this message translates to:
  /// **'Prayer times cannot be calculated here today (polar day or night)'**
  String get prayerNoPrayerToday;

  /// shared key "prayer.north"
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get prayerNorth;

  /// shared key "prayer.openCalendar"
  ///
  /// In en, this message translates to:
  /// **'Monthly calendar'**
  String get prayerOpenCalendar;

  /// shared key "prayer.prevDay"
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get prayerPrevDay;

  /// shared key "prayer.prevMonth"
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get prayerPrevMonth;

  /// shared key "prayer.qibla"
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get prayerQibla;

  /// shared key "prayer.qiblaDeg"
  ///
  /// In en, this message translates to:
  /// **'{deg}° from true north'**
  String prayerQiblaDeg(String deg);

  /// shared key "prayer.qiblaNote"
  ///
  /// In en, this message translates to:
  /// **'Static diagram: hold the phone with the top pointing to true north.'**
  String get prayerQiblaNote;

  /// shared key "prayer.resetAdjust"
  ///
  /// In en, this message translates to:
  /// **'Reset adjustments'**
  String get prayerResetAdjust;

  /// shared key "prayer.searchCity"
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get prayerSearchCity;

  /// shared key "prayer.selectCity"
  ///
  /// In en, this message translates to:
  /// **'Choose city'**
  String get prayerSelectCity;

  /// shared key "prayer.shareCalendar"
  ///
  /// In en, this message translates to:
  /// **'Share the calendar'**
  String get prayerShareCalendar;

  /// shared key "prayer.sunrise"
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// shared key "prayer.timezone"
  ///
  /// In en, this message translates to:
  /// **'Time zone: {tz}'**
  String prayerTimezone(String tz);

  /// shared key "prayer.title"
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTitle;

  /// shared key "prayer.useLocation"
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get prayerUseLocation;

  /// shared key "qibla.accuracy"
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy now: ± {n}°'**
  String qiblaAccuracy(String n);

  /// shared key "qibla.calibrateBody"
  ///
  /// In en, this message translates to:
  /// **'Move the phone in a figure 8 a few times, keep away from metal and electrical devices, and remove a magnetic case.'**
  String get qiblaCalibrateBody;

  /// shared key "qibla.calibrateTitle"
  ///
  /// In en, this message translates to:
  /// **'The compass needs calibrating'**
  String get qiblaCalibrateTitle;

  /// shared key "qibla.declination"
  ///
  /// In en, this message translates to:
  /// **'Corrected from magnetic to true north: {deg}°'**
  String qiblaDeclination(String deg);

  /// shared key "qibla.direction"
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get qiblaDirection;

  /// shared key "qibla.distance"
  ///
  /// In en, this message translates to:
  /// **'Distance to the Kaaba'**
  String get qiblaDistance;

  /// shared key "qibla.east"
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get qiblaEast;

  /// shared key "qibla.facing"
  ///
  /// In en, this message translates to:
  /// **'You are facing the qibla'**
  String get qiblaFacing;

  /// shared key "qibla.heading"
  ///
  /// In en, this message translates to:
  /// **'Phone heading: {deg}°'**
  String qiblaHeading(String deg);

  /// shared key "qibla.liveNote"
  ///
  /// In en, this message translates to:
  /// **'Hold the phone flat, away from metal and magnets; if the reading jumps, move it in a figure 8. The phone\'s compass points to magnetic north; the app corrects it to true north for your city.'**
  String get qiblaLiveNote;

  /// shared key "qibla.locateFailed"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location. Turn on location services and try again.'**
  String get qiblaLocateFailed;

  /// shared key "qibla.mapCheck"
  ///
  /// In en, this message translates to:
  /// **'Check on Google\'s Qibla Finder map'**
  String get qiblaMapCheck;

  /// shared key "qibla.placeNote"
  ///
  /// In en, this message translates to:
  /// **'The qibla is worked out for this place. Tap the location button if you are somewhere else.'**
  String get qiblaPlaceNote;

  /// shared key "qibla.south"
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get qiblaSouth;

  /// shared key "qibla.static"
  ///
  /// In en, this message translates to:
  /// **'No compass reading on this device: the diagram shows the qibla from true north.'**
  String get qiblaStatic;

  /// shared key "qibla.tipsTitle"
  ///
  /// In en, this message translates to:
  /// **'For an accurate reading'**
  String get qiblaTipsTitle;

  /// shared key "qibla.title"
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// shared key "qibla.turnLeft"
  ///
  /// In en, this message translates to:
  /// **'Turn left {deg}°'**
  String qiblaTurnLeft(String deg);

  /// shared key "qibla.turnRight"
  ///
  /// In en, this message translates to:
  /// **'Turn right {deg}°'**
  String qiblaTurnRight(String deg);

  /// shared key "qibla.waiting"
  ///
  /// In en, this message translates to:
  /// **'Reading the compass…'**
  String get qiblaWaiting;

  /// shared key "qibla.west"
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get qiblaWest;

  /// shared key "quran.ayahCount"
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String quranAyahCount(String count);

  /// shared key "quran.ayahN"
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}'**
  String quranAyahN(String n);

  /// shared key "quran.bookmark"
  ///
  /// In en, this message translates to:
  /// **'Bookmark ayah'**
  String get quranBookmark;

  /// shared key "quran.bookmarkRemoved"
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get quranBookmarkRemoved;

  /// shared key "quran.bookmarked"
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get quranBookmarked;

  /// shared key "quran.clearSearch"
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get quranClearSearch;

  /// shared key "quran.continueReading"
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get quranContinueReading;

  /// shared key "quran.filter"
  ///
  /// In en, this message translates to:
  /// **'Filter surahs'**
  String get quranFilter;

  /// shared key "quran.filterHint"
  ///
  /// In en, this message translates to:
  /// **'Name or number'**
  String get quranFilterHint;

  /// shared key "quran.go"
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get quranGo;

  /// shared key "quran.goToPage"
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get quranGoToPage;

  /// shared key "quran.hizbN"
  ///
  /// In en, this message translates to:
  /// **'Hizb {n}'**
  String quranHizbN(String n);

  /// shared key "quran.index"
  ///
  /// In en, this message translates to:
  /// **'Quran index'**
  String get quranIndex;

  /// shared key "quran.indexSearch"
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get quranIndexSearch;

  /// shared key "quran.juz"
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String quranJuz(String juz);

  /// shared key "quran.juzInMushaf"
  ///
  /// In en, this message translates to:
  /// **'Open {juz} on the Mushaf pages'**
  String quranJuzInMushaf(String juz);

  /// shared key "quran.juzLine"
  ///
  /// In en, this message translates to:
  /// **'Starts at {surah} {ayah} · Page {page}'**
  String quranJuzLine(String surah, String ayah, String page);

  /// shared key "quran.juzOrdinals"
  ///
  /// In en, this message translates to:
  /// **'1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30'**
  String get quranJuzOrdinals;

  /// shared key "quran.juzTitle"
  ///
  /// In en, this message translates to:
  /// **'Juz {ordinal}'**
  String quranJuzTitle(String ordinal);

  /// shared key "quran.listView"
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get quranListView;

  /// shared key "quran.meccan"
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get quranMeccan;

  /// shared key "quran.medinan"
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get quranMedinan;

  /// shared key "quran.nextPage"
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get quranNextPage;

  /// shared key "quran.noResults"
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get quranNoResults;

  /// shared key "quran.openMushaf"
  ///
  /// In en, this message translates to:
  /// **'Open Mushaf pages'**
  String get quranOpenMushaf;

  /// shared key "quran.page"
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String quranPage(String page);

  /// shared key "quran.pageInvalid"
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 604'**
  String get quranPageInvalid;

  /// shared key "quran.pageNumberHint"
  ///
  /// In en, this message translates to:
  /// **'1–604'**
  String get quranPageNumberHint;

  /// shared key "quran.pages"
  ///
  /// In en, this message translates to:
  /// **'Mushaf pages'**
  String get quranPages;

  /// shared key "quran.prevPage"
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get quranPrevPage;

  /// shared key "quran.quarterLine"
  ///
  /// In en, this message translates to:
  /// **'{surah} {ayah} · Page {page}'**
  String quranQuarterLine(String surah, String ayah, String page);

  /// shared key "quran.quarterOfHizb"
  ///
  /// In en, this message translates to:
  /// **'Quarter {q} of hizb {n}'**
  String quranQuarterOfHizb(String q, String n);

  /// shared key "quran.removeBookmark"
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get quranRemoveBookmark;

  /// shared key "quran.resultsCount"
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String quranResultsCount(String count);

  /// shared key "quran.search"
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get quranSearch;

  /// shared key "quran.searchAction"
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get quranSearchAction;

  /// shared key "quran.searchHint"
  ///
  /// In en, this message translates to:
  /// **'Type an Arabic word'**
  String get quranSearchHint;

  /// shared key "quran.searchPrompt"
  ///
  /// In en, this message translates to:
  /// **'Search ignores diacritics (tashkeel)'**
  String get quranSearchPrompt;

  /// shared key "quran.searchTooShort"
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 Arabic letters'**
  String get quranSearchTooShort;

  /// shared key "quran.showTranslation"
  ///
  /// In en, this message translates to:
  /// **'Show English translation'**
  String get quranShowTranslation;

  /// shared key "quran.startReading"
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get quranStartReading;

  /// shared key "quran.surahAyah"
  ///
  /// In en, this message translates to:
  /// **'{surah} : {ayah}'**
  String quranSurahAyah(String surah, String ayah);

  /// shared key "quran.surahLine"
  ///
  /// In en, this message translates to:
  /// **'Page {page} · {count} ayahs · {kind}'**
  String quranSurahLine(String page, String count, String kind);

  /// shared key "quran.surahN"
  ///
  /// In en, this message translates to:
  /// **'Surah {n}'**
  String quranSurahN(String n);

  /// shared key "quran.surahTitle"
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String quranSurahTitle(String name);

  /// shared key "quran.surahs"
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get quranSurahs;

  /// shared key "quran.tabJuz"
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get quranTabJuz;

  /// shared key "quran.tabQuarters"
  ///
  /// In en, this message translates to:
  /// **'Quarters'**
  String get quranTabQuarters;

  /// shared key "quran.tabSurahs"
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get quranTabSurahs;

  /// shared key "radio.all"
  ///
  /// In en, this message translates to:
  /// **'All radios'**
  String get radioAll;

  /// shared key "radio.duration"
  ///
  /// In en, this message translates to:
  /// **'Play for'**
  String get radioDuration;

  /// shared key "radio.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get radioListen;

  /// shared key "radio.liveNote"
  ///
  /// In en, this message translates to:
  /// **'Live broadcast. Pick another station from the list or from \"All radios\".'**
  String get radioLiveNote;

  /// shared key "radio.longer"
  ///
  /// In en, this message translates to:
  /// **'Longer'**
  String get radioLonger;

  /// shared key "radio.min"
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String radioMin(String n);

  /// shared key "radio.mushaf"
  ///
  /// In en, this message translates to:
  /// **'Whole-Mushaf radio (chosen reciter)'**
  String get radioMushaf;

  /// shared key "radio.note"
  ///
  /// In en, this message translates to:
  /// **'Continuous recitation of the whole Mushaf, starting from a random surah.'**
  String get radioNote;

  /// shared key "radio.nowPlaying"
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}'**
  String radioNowPlaying(String surah);

  /// shared key "radio.pause"
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get radioPause;

  /// shared key "radio.shorter"
  ///
  /// In en, this message translates to:
  /// **'Shorter'**
  String get radioShorter;

  /// shared key "radio.title"
  ///
  /// In en, this message translates to:
  /// **'Quran radio'**
  String get radioTitle;

  /// shared key "radio.unlimited"
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get radioUnlimited;

  /// shared key "radios.featured"
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get radiosFeatured;

  /// shared key "radios.more"
  ///
  /// In en, this message translates to:
  /// **'More radios'**
  String get radiosMore;

  /// shared key "radios.title"
  ///
  /// In en, this message translates to:
  /// **'Quran radios'**
  String get radiosTitle;

  /// shared key "reader.back"
  ///
  /// In en, this message translates to:
  /// **'Back to the index'**
  String get readerBack;

  /// shared key "reader.basmalaNow"
  ///
  /// In en, this message translates to:
  /// **'Reciting the basmala'**
  String get readerBasmalaNow;

  /// shared key "reader.bookmarks"
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get readerBookmarks;

  /// shared key "reader.exitFull"
  ///
  /// In en, this message translates to:
  /// **'Show tools'**
  String get readerExitFull;

  /// shared key "reader.font"
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get readerFont;

  /// shared key "reader.fontBigger"
  ///
  /// In en, this message translates to:
  /// **'Bigger text'**
  String get readerFontBigger;

  /// shared key "reader.fontSize"
  ///
  /// In en, this message translates to:
  /// **'Text size: {size} — press to enlarge'**
  String readerFontSize(String size);

  /// shared key "reader.fontSmaller"
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get readerFontSmaller;

  /// shared key "reader.fullHint"
  ///
  /// In en, this message translates to:
  /// **'To turn pages, swipe the page or press the arrows. To show the tools, press “Show tools”.'**
  String get readerFullHint;

  /// shared key "reader.fullScreen"
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get readerFullScreen;

  /// shared key "reader.guide1"
  ///
  /// In en, this message translates to:
  /// **'Tap any ayah to show its options under the page: listen, ayah tafsir, bookmark, copy, share.'**
  String get readerGuide1;

  /// shared key "reader.guide2"
  ///
  /// In en, this message translates to:
  /// **'To turn pages: swipe the page, or use the page slider under it.'**
  String get readerGuide2;

  /// shared key "reader.guide3"
  ///
  /// In en, this message translates to:
  /// **'“Full screen” in the bottom bar hides the tools; “Show tools” at the top of the page brings them back.'**
  String get readerGuide3;

  /// shared key "reader.guide4"
  ///
  /// In en, this message translates to:
  /// **'“Listen with tafsir” shows the page and its tafsir together while it is recited.'**
  String get readerGuide4;

  /// shared key "reader.guideTitle"
  ///
  /// In en, this message translates to:
  /// **'How to use the Mushaf'**
  String get readerGuideTitle;

  /// shared key "reader.help"
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get readerHelp;

  /// shared key "reader.help1"
  ///
  /// In en, this message translates to:
  /// **'Swipe the page to turn it, or use the page slider.'**
  String get readerHelp1;

  /// shared key "reader.help2"
  ///
  /// In en, this message translates to:
  /// **'Tap any ayah to listen to it and read its tafsir.'**
  String get readerHelp2;

  /// shared key "reader.help3"
  ///
  /// In en, this message translates to:
  /// **'“Listen with tafsir” splits the screen in two: the ayah being recited, and its short tafsir below it.'**
  String get readerHelp3;

  /// shared key "reader.helpTitle"
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get readerHelpTitle;

  /// shared key "reader.hideTafsir"
  ///
  /// In en, this message translates to:
  /// **'Hide tafsir'**
  String get readerHideTafsir;

  /// shared key "reader.hintClose"
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get readerHintClose;

  /// shared key "reader.index"
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get readerIndex;

  /// shared key "reader.khatma"
  ///
  /// In en, this message translates to:
  /// **'Khatma'**
  String get readerKhatma;

  /// shared key "reader.khatmaContinue"
  ///
  /// In en, this message translates to:
  /// **'Continue from page {page}'**
  String readerKhatmaContinue(String page);

  /// shared key "reader.khatmaDone"
  ///
  /// In en, this message translates to:
  /// **'Khatma complete. May Allah accept it from you.'**
  String get readerKhatmaDone;

  /// shared key "reader.khatmaLeft"
  ///
  /// In en, this message translates to:
  /// **'{left} pages left'**
  String readerKhatmaLeft(String left);

  /// shared key "reader.khatmaNone"
  ///
  /// In en, this message translates to:
  /// **'No khatma yet. Start one and your progress is counted from the last page you read.'**
  String get readerKhatmaNone;

  /// shared key "reader.khatmaProgress"
  ///
  /// In en, this message translates to:
  /// **'Read {done} of 604 pages ({pct}%)'**
  String readerKhatmaProgress(String done, String pct);

  /// shared key "reader.khatmaReset"
  ///
  /// In en, this message translates to:
  /// **'Cancel the khatma'**
  String get readerKhatmaReset;

  /// shared key "reader.khatmaSince"
  ///
  /// In en, this message translates to:
  /// **'Started on {date}'**
  String readerKhatmaSince(String date);

  /// shared key "reader.khatmaStart"
  ///
  /// In en, this message translates to:
  /// **'Start a new khatma from al-Fatihah'**
  String get readerKhatmaStart;

  /// shared key "reader.khatmaTitle"
  ///
  /// In en, this message translates to:
  /// **'Khatma (complete reading)'**
  String get readerKhatmaTitle;

  /// shared key "reader.listenWithTafsir"
  ///
  /// In en, this message translates to:
  /// **'Listen with tafsir'**
  String get readerListenWithTafsir;

  /// shared key "reader.nextJuz"
  ///
  /// In en, this message translates to:
  /// **'Next juz'**
  String get readerNextJuz;

  /// shared key "reader.nextPage"
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get readerNextPage;

  /// shared key "reader.nextSurah"
  ///
  /// In en, this message translates to:
  /// **'Next surah'**
  String get readerNextSurah;

  /// shared key "reader.pickAyah"
  ///
  /// In en, this message translates to:
  /// **'Tap any ayah to show its options here'**
  String get readerPickAyah;

  /// shared key "reader.pickJuz"
  ///
  /// In en, this message translates to:
  /// **'Choose the juz'**
  String get readerPickJuz;

  /// shared key "reader.playAyah"
  ///
  /// In en, this message translates to:
  /// **'Listen to this ayah'**
  String get readerPlayAyah;

  /// shared key "reader.playWithTafsir"
  ///
  /// In en, this message translates to:
  /// **'Listen with tafsir'**
  String get readerPlayWithTafsir;

  /// shared key "reader.playerHide"
  ///
  /// In en, this message translates to:
  /// **'Hide player'**
  String get readerPlayerHide;

  /// shared key "reader.playerShow"
  ///
  /// In en, this message translates to:
  /// **'Show player'**
  String get readerPlayerShow;

  /// shared key "reader.prevJuz"
  ///
  /// In en, this message translates to:
  /// **'Previous juz'**
  String get readerPrevJuz;

  /// shared key "reader.prevPage"
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get readerPrevPage;

  /// shared key "reader.prevSurah"
  ///
  /// In en, this message translates to:
  /// **'Previous surah'**
  String get readerPrevSurah;

  /// shared key "reader.repeatN"
  ///
  /// In en, this message translates to:
  /// **'Repeat: {n}'**
  String readerRepeatN(String n);

  /// shared key "reader.search"
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get readerSearch;

  /// shared key "reader.showPage"
  ///
  /// In en, this message translates to:
  /// **'Show the page'**
  String get readerShowPage;

  /// shared key "reader.splitTafsir"
  ///
  /// In en, this message translates to:
  /// **'Short tafsir'**
  String get readerSplitTafsir;

  /// shared key "reader.splitTitle"
  ///
  /// In en, this message translates to:
  /// **'Now reciting'**
  String get readerSplitTitle;

  /// shared key "reader.tabAyat"
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get readerTabAyat;

  /// shared key "reader.tabJuz"
  ///
  /// In en, this message translates to:
  /// **'Whole juz'**
  String get readerTabJuz;

  /// shared key "reader.tabMushaf"
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get readerTabMushaf;

  /// shared key "reader.tabSurah"
  ///
  /// In en, this message translates to:
  /// **'Whole surah'**
  String get readerTabSurah;

  /// shared key "reader.tabTafsir"
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get readerTabTafsir;

  /// shared key "reader.tafsirBeside"
  ///
  /// In en, this message translates to:
  /// **'Tafsir beside the page'**
  String get readerTafsirBeside;

  /// shared key "reader.tafsirBesideJuz"
  ///
  /// In en, this message translates to:
  /// **'Tafsir beside the juz'**
  String get readerTafsirBesideJuz;

  /// shared key "reader.tafsirBesideShort"
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get readerTafsirBesideShort;

  /// shared key "reader.tafsirBesideSurah"
  ///
  /// In en, this message translates to:
  /// **'Tafsir beside the surah'**
  String get readerTafsirBesideSurah;

  /// shared key "reader.zoomReset"
  ///
  /// In en, this message translates to:
  /// **'{pct}% · Normal size'**
  String readerZoomReset(String pct);

  /// shared key "reels.addChannel"
  ///
  /// In en, this message translates to:
  /// **'Add channel'**
  String get reelsAddChannel;

  /// shared key "reels.cat.admonition"
  ///
  /// In en, this message translates to:
  /// **'Advice & admonition'**
  String get reelsCatAdmonition;

  /// shared key "reels.cat.lesson"
  ///
  /// In en, this message translates to:
  /// **'Religious lesson'**
  String get reelsCatLesson;

  /// shared key "reels.cat.recitation"
  ///
  /// In en, this message translates to:
  /// **'Quran recitation'**
  String get reelsCatRecitation;

  /// shared key "reels.empty"
  ///
  /// In en, this message translates to:
  /// **'No reels to show right now.'**
  String get reelsEmpty;

  /// shared key "reels.feed"
  ///
  /// In en, this message translates to:
  /// **'reels'**
  String get reelsFeed;

  /// shared key "reels.hidden"
  ///
  /// In en, this message translates to:
  /// **'{name} hidden'**
  String reelsHidden(String name);

  /// shared key "reels.hide"
  ///
  /// In en, this message translates to:
  /// **'Hide this channel'**
  String get reelsHide;

  /// shared key "reels.loading"
  ///
  /// In en, this message translates to:
  /// **'Fetching the newest reels…'**
  String get reelsLoading;

  /// shared key "reels.myChannels"
  ///
  /// In en, this message translates to:
  /// **'Your channels'**
  String get reelsMyChannels;

  /// shared key "reels.next"
  ///
  /// In en, this message translates to:
  /// **'Next reel'**
  String get reelsNext;

  /// shared key "reels.note"
  ///
  /// In en, this message translates to:
  /// **'Reels play from YouTube and Instagram in their official players, and come automatically from trusted Islamic channels the app approved (Quran recitations, religious lessons, advice and admonitions).'**
  String get reelsNote;

  /// shared key "reels.offline"
  ///
  /// In en, this message translates to:
  /// **'Could not reach YouTube. Check your internet connection and try again.'**
  String get reelsOffline;

  /// shared key "reels.open.instagram"
  ///
  /// In en, this message translates to:
  /// **'Open on Instagram'**
  String get reelsOpenInstagram;

  /// shared key "reels.open.youtube"
  ///
  /// In en, this message translates to:
  /// **'Open on YouTube'**
  String get reelsOpenYoutube;

  /// shared key "reels.pending"
  ///
  /// In en, this message translates to:
  /// **'This reel has not been religiously reviewed yet — you see it because reviewer mode is on'**
  String get reelsPending;

  /// shared key "reels.platform.instagram"
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get reelsPlatformInstagram;

  /// shared key "reels.platform.youtube"
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get reelsPlatformYoutube;

  /// shared key "reels.position"
  ///
  /// In en, this message translates to:
  /// **'Reel {n} of {total}'**
  String reelsPosition(String n, String total);

  /// shared key "reels.prev"
  ///
  /// In en, this message translates to:
  /// **'Previous reel'**
  String get reelsPrev;

  /// shared key "reels.removeChannel"
  ///
  /// In en, this message translates to:
  /// **'Remove channel'**
  String get reelsRemoveChannel;

  /// shared key "reels.retry"
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get reelsRetry;

  /// shared key "reels.reviewedBy"
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {name}'**
  String reelsReviewedBy(String name);

  /// shared key "reels.reviewerHint"
  ///
  /// In en, this message translates to:
  /// **'show reels that are not reviewed yet'**
  String get reelsReviewerHint;

  /// shared key "reels.reviewerMode"
  ///
  /// In en, this message translates to:
  /// **'Reviewer mode'**
  String get reelsReviewerMode;

  /// shared key "reels.search"
  ///
  /// In en, this message translates to:
  /// **'Find a channel'**
  String get reelsSearch;

  /// shared key "reels.searchHint"
  ///
  /// In en, this message translates to:
  /// **'Channel or sheikh name'**
  String get reelsSearchHint;

  /// shared key "reels.searchNone"
  ///
  /// In en, this message translates to:
  /// **'No results, or no internet connection.'**
  String get reelsSearchNone;

  /// shared key "reels.showHidden"
  ///
  /// In en, this message translates to:
  /// **'Show hidden channels'**
  String get reelsShowHidden;

  /// shared key "reels.sub"
  ///
  /// In en, this message translates to:
  /// **'Recitations, lessons and admonitions from trusted channels'**
  String get reelsSub;

  /// shared key "reels.suggested"
  ///
  /// In en, this message translates to:
  /// **'Suggested Islamic channels'**
  String get reelsSuggested;

  /// shared key "reels.suggestedHint"
  ///
  /// In en, this message translates to:
  /// **'The app adds from these automatically based on what you watch most.'**
  String get reelsSuggestedHint;

  /// shared key "reels.tapToPlay"
  ///
  /// In en, this message translates to:
  /// **'Tap to play'**
  String get reelsTapToPlay;

  /// shared key "reels.title"
  ///
  /// In en, this message translates to:
  /// **'Islamic reels'**
  String get reelsTitle;

  /// shared key "reels.trusted"
  ///
  /// In en, this message translates to:
  /// **'Trusted channel'**
  String get reelsTrusted;

  /// shared key "reels.undo"
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get reelsUndo;

  /// shared key "ruqyah.ayah"
  ///
  /// In en, this message translates to:
  /// **'{surah}: ayah {n}'**
  String ruqyahAyah(String surah, String n);

  /// shared key "ruqyah.dua"
  ///
  /// In en, this message translates to:
  /// **'From the Sunnah'**
  String get ruqyahDua;

  /// shared key "ruqyah.from"
  ///
  /// In en, this message translates to:
  /// **'{surah}: ayahs {from}–{to}'**
  String ruqyahFrom(String surah, String from, String to);

  /// shared key "ruqyah.full"
  ///
  /// In en, this message translates to:
  /// **'The full ruqyah by Sheikh Mishary Alafasy'**
  String get ruqyahFull;

  /// shared key "ruqyah.fullSub"
  ///
  /// In en, this message translates to:
  /// **'{n} min · tap the download icon to listen offline'**
  String ruqyahFullSub(String n);

  /// shared key "ruqyah.header"
  ///
  /// In en, this message translates to:
  /// **'Ruqyah'**
  String get ruqyahHeader;

  /// shared key "ruqyah.kidsNote"
  ///
  /// In en, this message translates to:
  /// **'What the Prophet ﷺ sought protection with for al-Hasan and al-Husayn, then al-Fatiha, Ayat al-Kursi, the end of al-Baqarah, al-Ikhlas, al-Falaq and an-Nas, then the ruqyah Jibril recited over the Prophet ﷺ. Read them over your child or listen.'**
  String get ruqyahKidsNote;

  /// shared key "ruqyah.kidsTitle"
  ///
  /// In en, this message translates to:
  /// **'Ruqyah for children'**
  String get ruqyahKidsTitle;

  /// shared key "ruqyah.listenQuran"
  ///
  /// In en, this message translates to:
  /// **'Listen to the verses'**
  String get ruqyahListenQuran;

  /// shared key "ruqyah.note"
  ///
  /// In en, this message translates to:
  /// **'The Quran verses and Sunnah duas used for ruqyah, as listed by scholars. Read or listen; tap an ayah for its tafsir.'**
  String get ruqyahNote;

  /// shared key "ruqyah.repeat"
  ///
  /// In en, this message translates to:
  /// **'Said {n} times'**
  String ruqyahRepeat(String n);

  /// shared key "ruqyah.title"
  ///
  /// In en, this message translates to:
  /// **'Ruqyah'**
  String get ruqyahTitle;

  /// shared key "settings.about"
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// shared key "settings.account"
  ///
  /// In en, this message translates to:
  /// **'Account & sync'**
  String get settingsAccount;

  /// shared key "settings.accountHint"
  ///
  /// In en, this message translates to:
  /// **'Optional — sync bookmarks between devices'**
  String get settingsAccountHint;

  /// shared key "settings.auto"
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsAuto;

  /// shared key "settings.fontPreview"
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsFontPreview;

  /// shared key "settings.fontSize"
  ///
  /// In en, this message translates to:
  /// **'Quran font size'**
  String get settingsFontSize;

  /// shared key "settings.free"
  ///
  /// In en, this message translates to:
  /// **'A free app made for the sake of Allah: no charge and no ads.'**
  String get settingsFree;

  /// shared key "settings.hijriOffset"
  ///
  /// In en, this message translates to:
  /// **'Hijri date adjustment'**
  String get settingsHijriOffset;

  /// shared key "settings.hijriOffsetHint"
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura. Shift by a day or two to match the moon sighting announced in your country.'**
  String get settingsHijriOffsetHint;

  /// shared key "settings.language"
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// shared key "settings.languageAr"
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLanguageAr;

  /// shared key "settings.languageEn"
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// shared key "settings.manual"
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get settingsManual;

  /// shared key "settings.mushafPrinted"
  ///
  /// In en, this message translates to:
  /// **'Printed Mushaf look'**
  String get settingsMushafPrinted;

  /// shared key "settings.mushafPrintedDownload"
  ///
  /// In en, this message translates to:
  /// **'Download all page fonts for offline reading'**
  String get settingsMushafPrintedDownload;

  /// shared key "settings.mushafPrintedFailed"
  ///
  /// In en, this message translates to:
  /// **'Download failed, try again'**
  String get settingsMushafPrintedFailed;

  /// shared key "settings.mushafPrintedHint"
  ///
  /// In en, this message translates to:
  /// **'Each page in the King Fahd Complex\'s own page font, exactly like the printed Mushaf. A page needs the internet the first time only.'**
  String get settingsMushafPrintedHint;

  /// shared key "settings.mushafPrintedProgress"
  ///
  /// In en, this message translates to:
  /// **'Downloading: {done} of {total}'**
  String settingsMushafPrintedProgress(String done, String total);

  /// shared key "settings.mushafPrintedSaved"
  ///
  /// In en, this message translates to:
  /// **'All page fonts are saved on this device'**
  String get settingsMushafPrintedSaved;

  /// shared key "settings.mushafSection"
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get settingsMushafSection;

  /// shared key "settings.ourApps"
  ///
  /// In en, this message translates to:
  /// **'Our apps'**
  String get settingsOurApps;

  /// shared key "settings.ourAppsSoon"
  ///
  /// In en, this message translates to:
  /// **'More apps coming soon, God willing'**
  String get settingsOurAppsSoon;

  /// shared key "settings.palette"
  ///
  /// In en, this message translates to:
  /// **'Colour style'**
  String get settingsPalette;

  /// shared key "settings.paletteEmerald"
  ///
  /// In en, this message translates to:
  /// **'Emerald & gold'**
  String get settingsPaletteEmerald;

  /// shared key "settings.paletteMadinah"
  ///
  /// In en, this message translates to:
  /// **'Madinah night'**
  String get settingsPaletteMadinah;

  /// shared key "settings.permissions"
  ///
  /// In en, this message translates to:
  /// **'Permissions and background'**
  String get settingsPermissions;

  /// shared key "settings.permissionsHint"
  ///
  /// In en, this message translates to:
  /// **'Location, notifications, battery and adhan on silent'**
  String get settingsPermissionsHint;

  /// shared key "settings.prayerAutoHint"
  ///
  /// In en, this message translates to:
  /// **'From your location and your country\'s calculation method'**
  String get settingsPrayerAutoHint;

  /// shared key "settings.prayerManualHint"
  ///
  /// In en, this message translates to:
  /// **'You choose the method and adjust the minutes yourself'**
  String get settingsPrayerManualHint;

  /// shared key "settings.prayerTimes"
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get settingsPrayerTimes;

  /// shared key "settings.sources"
  ///
  /// In en, this message translates to:
  /// **'Content sources'**
  String get settingsSources;

  /// shared key "settings.theme"
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// shared key "settings.themeDark"
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// shared key "settings.themeLight"
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// shared key "settings.themeSystem"
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// shared key "settings.tour"
  ///
  /// In en, this message translates to:
  /// **'App tour'**
  String get settingsTour;

  /// shared key "setup.appPage"
  ///
  /// In en, this message translates to:
  /// **'App page'**
  String get setupAppPage;

  /// shared key "setup.batteryAction"
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get setupBatteryAction;

  /// shared key "setup.batteryBody"
  ///
  /// In en, this message translates to:
  /// **'So battery saving does not stop the adhan while the app is closed: in the list choose Rattil wa Salli, then \"Don\'t optimize\" or \"Unrestricted\".'**
  String get setupBatteryBody;

  /// shared key "setup.batteryOem"
  ///
  /// In en, this message translates to:
  /// **'On some phones (Xiaomi, Oppo, Realme, Huawei, Vivo) also turn on \"Autostart\" or \"Background activity\" on the app\'s page.'**
  String get setupBatteryOem;

  /// shared key "setup.batteryTitle"
  ///
  /// In en, this message translates to:
  /// **'Run in the background'**
  String get setupBatteryTitle;

  /// shared key "setup.done"
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get setupDone;

  /// shared key "setup.exactBody"
  ///
  /// In en, this message translates to:
  /// **'Turn on \"Alarms & reminders\" for this app, otherwise Android may delay the adhan by a few minutes.'**
  String get setupExactBody;

  /// shared key "setup.exactTitle"
  ///
  /// In en, this message translates to:
  /// **'Adhan on the minute'**
  String get setupExactTitle;

  /// shared key "setup.intro"
  ///
  /// In en, this message translates to:
  /// **'A few steps so prayer times are right and the adhan reaches you on time, even with the app closed. You can change all of this later in Settings.'**
  String get setupIntro;

  /// shared key "setup.locationBody"
  ///
  /// In en, this message translates to:
  /// **'For the prayer times and qibla where you are. Used only while the app is open.'**
  String get setupLocationBody;

  /// shared key "setup.locationCity"
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get setupLocationCity;

  /// shared key "setup.locationDenied"
  ///
  /// In en, this message translates to:
  /// **'Location was not allowed. You can choose your city instead.'**
  String get setupLocationDenied;

  /// shared key "setup.locationTitle"
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get setupLocationTitle;

  /// shared key "setup.locationUnavailable"
  ///
  /// In en, this message translates to:
  /// **'Could not find your location now. Check that location is on, or choose your city.'**
  String get setupLocationUnavailable;

  /// shared key "setup.locationUse"
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get setupLocationUse;

  /// shared key "setup.notifAction"
  ///
  /// In en, this message translates to:
  /// **'Turn on the adhan'**
  String get setupNotifAction;

  /// shared key "setup.notifBody"
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so the adhan and reminders reach you.'**
  String get setupNotifBody;

  /// shared key "setup.notifDenied"
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed. Open the app settings and turn them on.'**
  String get setupNotifDenied;

  /// shared key "setup.notifTitle"
  ///
  /// In en, this message translates to:
  /// **'Adhan alert'**
  String get setupNotifTitle;

  /// shared key "setup.openSettings"
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get setupOpenSettings;

  /// shared key "setup.silentIos"
  ///
  /// In en, this message translates to:
  /// **'On iPhone the system lets no app play a notification sound while the silent switch is on (Apple allows it only for emergency and health apps). The adhan alert then shows without sound; keep the silent switch off to hear it.'**
  String get setupSilentIos;

  /// shared key "setup.silentTitle"
  ///
  /// In en, this message translates to:
  /// **'Adhan when the phone is silent'**
  String get setupSilentTitle;

  /// shared key "setup.start"
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get setupStart;

  /// shared key "setup.title"
  ///
  /// In en, this message translates to:
  /// **'Set up the app'**
  String get setupTitle;

  /// shared key "shabib.fromSurah"
  ///
  /// In en, this message translates to:
  /// **'From Surah {name}'**
  String shabibFromSurah(String name);

  /// shared key "shabib.loadError"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the recitations list.'**
  String get shabibLoadError;

  /// shared key "shabib.moshafs"
  ///
  /// In en, this message translates to:
  /// **'Hafs from Asim - Murattal (selections) · Mujawwad'**
  String get shabibMoshafs;

  /// shared key "shabib.mujawwad"
  ///
  /// In en, this message translates to:
  /// **'Mujawwad'**
  String get shabibMujawwad;

  /// shared key "shabib.mujawwadNote"
  ///
  /// In en, this message translates to:
  /// **'Live recordings (dawn prayers, radio, evening gatherings), ordered by surah.'**
  String get shabibMujawwadNote;

  /// shared key "shabib.murattal"
  ///
  /// In en, this message translates to:
  /// **'Murattal'**
  String get shabibMurattal;

  /// shared key "shabib.murattalNote"
  ///
  /// In en, this message translates to:
  /// **'Hafs from Asim. Some are a passage of the surah, not the whole surah.'**
  String get shabibMurattalNote;

  /// shared key "shabib.name"
  ///
  /// In en, this message translates to:
  /// **'Mohamed Ahmed Shabib'**
  String get shabibName;

  /// shared key "shabib.noMatch"
  ///
  /// In en, this message translates to:
  /// **'No recitations for this surah.'**
  String get shabibNoMatch;

  /// shared key "shabib.note"
  ///
  /// In en, this message translates to:
  /// **'No complete Quran recording of Sheikh Mohamed Ahmed Shabib exists, so here is what is available: {m} murattal and {j} mujawwad recitations. Listen online or tap the download icon to listen offline.'**
  String shabibNote(String m, String j);

  /// shared key "shabib.reciter"
  ///
  /// In en, this message translates to:
  /// **'Sheikh Mohamed Ahmed Shabib'**
  String get shabibReciter;

  /// shared key "shabib.shortSurahs"
  ///
  /// In en, this message translates to:
  /// **'Short surahs'**
  String get shabibShortSurahs;

  /// shared key "shabib.surah"
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String shabibSurah(String name);

  /// shared key "shabib.surahs"
  ///
  /// In en, this message translates to:
  /// **'Surahs {names}'**
  String shabibSurahs(String names);

  /// shared key "shabib.tag.fajr"
  ///
  /// In en, this message translates to:
  /// **'Dawn recitation'**
  String get shabibTagFajr;

  /// shared key "shabib.tag.oct73"
  ///
  /// In en, this message translates to:
  /// **'Dawn of 6 October 1973'**
  String get shabibTagOct73;

  /// shared key "shabib.tag.radio"
  ///
  /// In en, this message translates to:
  /// **'Radio recording'**
  String get shabibTagRadio;

  /// shared key "sharawi.ayah"
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}'**
  String sharawiAyah(String n);

  /// shared key "sharawi.ayahs"
  ///
  /// In en, this message translates to:
  /// **'Ayahs {from}–{to}'**
  String sharawiAyahs(String from, String to);

  /// shared key "sharawi.intro"
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get sharawiIntro;

  /// shared key "sharawi.lesson"
  ///
  /// In en, this message translates to:
  /// **'Lesson {n}'**
  String sharawiLesson(String n);

  /// shared key "sharawi.lessons"
  ///
  /// In en, this message translates to:
  /// **'{n} lessons'**
  String sharawiLessons(String n);

  /// shared key "sharawi.loadError"
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the tafsir lessons.'**
  String get sharawiLoadError;

  /// shared key "sharawi.minutes"
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String sharawiMinutes(String n);

  /// shared key "sharawi.noMatch"
  ///
  /// In en, this message translates to:
  /// **'No lessons for this surah.'**
  String get sharawiNoMatch;

  /// shared key "sharawi.note"
  ///
  /// In en, this message translates to:
  /// **'Sheikh Muhammad Mutawalli al-Sha\'rawi\'s reflections on the Quran in his own voice, {n} lessons ordered by surah. Listen to any lesson online, or tap the download icon to keep it for offline listening.'**
  String sharawiNote(String n);

  /// shared key "sharawi.search"
  ///
  /// In en, this message translates to:
  /// **'Find a surah by name or number'**
  String get sharawiSearch;

  /// shared key "sharawi.title"
  ///
  /// In en, this message translates to:
  /// **'Al-Sha\'rawi tafsir'**
  String get sharawiTitle;

  /// shared key "shortcut.adhkar"
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get shortcutAdhkar;

  /// shared key "shortcut.prayer"
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get shortcutPrayer;

  /// shared key "shortcut.quran"
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get shortcutQuran;

  /// shared key "shortcut.tasbih"
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get shortcutTasbih;

  /// shared key "stories.ayahs"
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String storiesAyahs(String count);

  /// shared key "stories.back"
  ///
  /// In en, this message translates to:
  /// **'All stories'**
  String get storiesBack;

  /// shared key "stories.cat.others"
  ///
  /// In en, this message translates to:
  /// **'Stories and lessons from the Quran'**
  String get storiesCatOthers;

  /// shared key "stories.cat.prophets"
  ///
  /// In en, this message translates to:
  /// **'Stories of the prophets in the Quran'**
  String get storiesCatProphets;

  /// shared key "stories.episodeError"
  ///
  /// In en, this message translates to:
  /// **'The episode could not be played. Check your internet connection.'**
  String get storiesEpisodeError;

  /// shared key "stories.episodePending"
  ///
  /// In en, this message translates to:
  /// **'This episode has not been religiously reviewed yet — shown because reviewer mode is on'**
  String get storiesEpisodePending;

  /// shared key "stories.episodes"
  ///
  /// In en, this message translates to:
  /// **'{count} episodes'**
  String storiesEpisodes(String count);

  /// shared key "stories.forward"
  ///
  /// In en, this message translates to:
  /// **'Forward 30 seconds'**
  String get storiesForward;

  /// shared key "stories.from"
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, ayahs {from}–{to}'**
  String storiesFrom(String surah, String from, String to);

  /// shared key "stories.howTo"
  ///
  /// In en, this message translates to:
  /// **'Each episode: tap to listen, the video icon to watch, or the download icon to listen offline.'**
  String get storiesHowTo;

  /// shared key "stories.intro"
  ///
  /// In en, this message translates to:
  /// **'Listen to the stories of the prophets in a calm voice before sleep, or read each story\'s verses from the Mushaf with Tafsir al-Muyassar.'**
  String get storiesIntro;

  /// shared key "stories.listen"
  ///
  /// In en, this message translates to:
  /// **'Listen to the story\'s verses'**
  String get storiesListen;

  /// shared key "stories.minutes"
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String storiesMinutes(String n);

  /// shared key "stories.nowPlaying"
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get storiesNowPlaying;

  /// shared key "stories.onlineOnly"
  ///
  /// In en, this message translates to:
  /// **'Episodes are streamed over the internet'**
  String get storiesOnlineOnly;

  /// shared key "stories.pause"
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get storiesPause;

  /// shared key "stories.play"
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get storiesPlay;

  /// shared key "stories.readVerses"
  ///
  /// In en, this message translates to:
  /// **'Read the story\'s verses'**
  String get storiesReadVerses;

  /// shared key "stories.reciter"
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get storiesReciter;

  /// shared key "stories.reviewedBy"
  ///
  /// In en, this message translates to:
  /// **'Reviewed by: {name}'**
  String storiesReviewedBy(String name);

  /// shared key "stories.reviewerMode"
  ///
  /// In en, this message translates to:
  /// **'Reviewer mode (show unreviewed episodes)'**
  String get storiesReviewerMode;

  /// shared key "stories.rewind"
  ///
  /// In en, this message translates to:
  /// **'Back 30 seconds'**
  String get storiesRewind;

  /// shared key "stories.seriesHidden"
  ///
  /// In en, this message translates to:
  /// **'The episodes of “{title}” by {narrator} appear here once they have been religiously reviewed.'**
  String storiesSeriesHidden(String title, String narrator);

  /// shared key "stories.seriesSource"
  ///
  /// In en, this message translates to:
  /// **'Source: {source}. {licence}'**
  String storiesSeriesSource(String source, String licence);

  /// shared key "stories.sleep"
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get storiesSleep;

  /// shared key "stories.sleepLeft"
  ///
  /// In en, this message translates to:
  /// **'Audio stops in {time} min'**
  String storiesSleepLeft(String time);

  /// shared key "stories.sleepMin"
  ///
  /// In en, this message translates to:
  /// **'After {n} min'**
  String storiesSleepMin(String n);

  /// shared key "stories.sleepOff"
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get storiesSleepOff;

  /// shared key "stories.source"
  ///
  /// In en, this message translates to:
  /// **'Source: the Madinah Mushaf text and Tafsir al-Muyassar (King Fahd Glorious Quran Printing Complex).'**
  String get storiesSource;

  /// shared key "stories.stop"
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get storiesStop;

  /// shared key "stories.sub"
  ///
  /// In en, this message translates to:
  /// **'Stories of the prophets, in audio and in their verses'**
  String get storiesSub;

  /// shared key "stories.tafsirHint"
  ///
  /// In en, this message translates to:
  /// **'Tap any ayah to see its Tafsir al-Muyassar.'**
  String get storiesTafsirHint;

  /// shared key "stories.title"
  ///
  /// In en, this message translates to:
  /// **'Quranic stories (audio)'**
  String get storiesTitle;

  /// shared key "stories.versesIntro"
  ///
  /// In en, this message translates to:
  /// **'Each story here is its own Quranic verses (Madinah Mushaf), recited by the reciter you choose, with Tafsir al-Muyassar for every ayah.'**
  String get storiesVersesIntro;

  /// shared key "stories.versesTitle"
  ///
  /// In en, this message translates to:
  /// **'The stories\' verses from the Mushaf'**
  String get storiesVersesTitle;

  /// shared key "stories.videoBy"
  ///
  /// In en, this message translates to:
  /// **'Sheikh Nabil Al-Awadi'**
  String get storiesVideoBy;

  /// shared key "stories.watchVideo"
  ///
  /// In en, this message translates to:
  /// **'Watch video'**
  String get storiesWatchVideo;

  /// shared key "study.balagha"
  ///
  /// In en, this message translates to:
  /// **'Rhetoric'**
  String get studyBalagha;

  /// shared key "study.fawaid"
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get studyFawaid;

  /// shared key "study.gharib"
  ///
  /// In en, this message translates to:
  /// **'Rare words'**
  String get studyGharib;

  /// shared key "study.gharibBook"
  ///
  /// In en, this message translates to:
  /// **'From «al-Siraj fi Bayan Gharib al-Quran»'**
  String get studyGharibBook;

  /// shared key "study.irab"
  ///
  /// In en, this message translates to:
  /// **'I\'rab'**
  String get studyIrab;

  /// shared key "study.irabBook"
  ///
  /// In en, this message translates to:
  /// **'From «al-Jadwal fi I\'rab al-Quran» by Mahmud Safi'**
  String get studyIrabBook;

  /// shared key "study.noGharib"
  ///
  /// In en, this message translates to:
  /// **'The book lists no rare words in this ayah.'**
  String get studyNoGharib;

  /// shared key "study.noPart"
  ///
  /// In en, this message translates to:
  /// **'The book has no {part} section for this ayah.'**
  String studyNoPart(String part);

  /// shared key "study.notes"
  ///
  /// In en, this message translates to:
  /// **'Editor\'s footnotes'**
  String get studyNotes;

  /// shared key "study.range"
  ///
  /// In en, this message translates to:
  /// **'The book explains ayahs {from}–{to} of {surah} together.'**
  String studyRange(String from, String to, String surah);

  /// shared key "study.retry"
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get studyRetry;

  /// shared key "study.sarf"
  ///
  /// In en, this message translates to:
  /// **'Morphology'**
  String get studySarf;

  /// shared key "study.tafsir"
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get studyTafsir;

  /// shared key "surahInfo.about"
  ///
  /// In en, this message translates to:
  /// **'About the surah'**
  String get surahInfoAbout;

  /// shared key "surahInfo.asbab"
  ///
  /// In en, this message translates to:
  /// **'Reasons for revelation'**
  String get surahInfoAsbab;

  /// shared key "surahInfo.ayahs"
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get surahInfoAyahs;

  /// shared key "surahInfo.missing"
  ///
  /// In en, this message translates to:
  /// **'Information not available.'**
  String get surahInfoMissing;

  /// shared key "surahInfo.noAsbab"
  ///
  /// In en, this message translates to:
  /// **'The source mentions no specific reason for revelation for this surah.'**
  String get surahInfoNoAsbab;

  /// shared key "surahInfo.order"
  ///
  /// In en, this message translates to:
  /// **'Order of revelation'**
  String get surahInfoOrder;

  /// shared key "surahInfo.place"
  ///
  /// In en, this message translates to:
  /// **'Revealed in'**
  String get surahInfoPlace;

  /// shared key "surahInfo.title"
  ///
  /// In en, this message translates to:
  /// **'About the surah'**
  String get surahInfoTitle;

  /// shared key "surahInfo.wahidi"
  ///
  /// In en, this message translates to:
  /// **'From al-Wahidi, \"Asbab Nuzul al-Quran\"'**
  String get surahInfoWahidi;

  /// shared key "tafsir.arabicOnly"
  ///
  /// In en, this message translates to:
  /// **'This tafsir is available in Arabic only.'**
  String get tafsirArabicOnly;

  /// shared key "tafsir.error"
  ///
  /// In en, this message translates to:
  /// **'The tafsir could not be loaded.'**
  String get tafsirError;

  /// shared key "tafsir.loading"
  ///
  /// In en, this message translates to:
  /// **'Loading the tafsir…'**
  String get tafsirLoading;

  /// shared key "tafsir.next"
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get tafsirNext;

  /// shared key "tafsir.prev"
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get tafsirPrev;

  /// shared key "tafsir.source"
  ///
  /// In en, this message translates to:
  /// **'King Fahd Glorious Quran Printing Complex'**
  String get tafsirSource;

  /// shared key "tafsir.title"
  ///
  /// In en, this message translates to:
  /// **'Al-Tafsir al-Muyassar'**
  String get tafsirTitle;

  /// shared key "tafsirLib.ayah"
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get tafsirLibAyah;

  /// shared key "tafsirLib.books"
  ///
  /// In en, this message translates to:
  /// **'Tafsir books'**
  String get tafsirLibBooks;

  /// shared key "tafsirLib.compare"
  ///
  /// In en, this message translates to:
  /// **'Compare tafsirs'**
  String get tafsirLibCompare;

  /// shared key "tafsirLib.compareSub"
  ///
  /// In en, this message translates to:
  /// **'Every tafsir of the same ayah'**
  String get tafsirLibCompareSub;

  /// shared key "tafsirLib.download"
  ///
  /// In en, this message translates to:
  /// **'Download for offline reading'**
  String get tafsirLibDownload;

  /// shared key "tafsirLib.downloading"
  ///
  /// In en, this message translates to:
  /// **'Downloading… {done} of 114 surahs'**
  String tafsirLibDownloading(String done);

  /// shared key "tafsirLib.downloadsNote"
  ///
  /// In en, this message translates to:
  /// **'Each book downloads once and then opens without the internet. Without it, each surah downloads when you open it.'**
  String get tafsirLibDownloadsNote;

  /// shared key "tafsirLib.downloadsTitle"
  ///
  /// In en, this message translates to:
  /// **'Offline reading'**
  String get tafsirLibDownloadsTitle;

  /// shared key "tafsirLib.failed"
  ///
  /// In en, this message translates to:
  /// **'The download failed. Try again.'**
  String get tafsirLibFailed;

  /// shared key "tafsirLib.inApp"
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get tafsirLibInApp;

  /// shared key "tafsirLib.irabName"
  ///
  /// In en, this message translates to:
  /// **'الجدول في إعراب القرآن وصرفه وبيانه'**
  String get tafsirLibIrabName;

  /// shared key "tafsirLib.irabSub"
  ///
  /// In en, this message translates to:
  /// **'I\'rab, morphology, rhetoric and benefits of every ayah'**
  String get tafsirLibIrabSub;

  /// shared key "tafsirLib.lenLong"
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get tafsirLibLenLong;

  /// shared key "tafsirLib.lenMedium"
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get tafsirLibLenMedium;

  /// shared key "tafsirLib.lenShort"
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get tafsirLibLenShort;

  /// shared key "tafsirLib.less"
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get tafsirLibLess;

  /// shared key "tafsirLib.more"
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get tafsirLibMore;

  /// shared key "tafsirLib.readBook"
  ///
  /// In en, this message translates to:
  /// **'Open in the book'**
  String get tafsirLibReadBook;

  /// shared key "tafsirLib.remove"
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get tafsirLibRemove;

  /// shared key "tafsirLib.results"
  ///
  /// In en, this message translates to:
  /// **'Results: {n}'**
  String tafsirLibResults(String n);

  /// shared key "tafsirLib.saved"
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get tafsirLibSaved;

  /// shared key "tafsirLib.search"
  ///
  /// In en, this message translates to:
  /// **'Search the tafsir'**
  String get tafsirLibSearch;

  /// shared key "tafsirLib.searchHint"
  ///
  /// In en, this message translates to:
  /// **'Type an Arabic word or phrase'**
  String get tafsirLibSearchHint;

  /// shared key "tafsirLib.searchNeedsDownload"
  ///
  /// In en, this message translates to:
  /// **'Searching this book needs it downloaded on your device first.'**
  String get tafsirLibSearchNeedsDownload;

  /// shared key "tafsirLib.searchSub"
  ///
  /// In en, this message translates to:
  /// **'Find a word inside any tafsir book'**
  String get tafsirLibSearchSub;

  /// shared key "tafsirLib.surah"
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get tafsirLibSurah;

  /// shared key "tafsirLib.title"
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsirLibTitle;

  /// shared key "tagline"
  ///
  /// In en, this message translates to:
  /// **'Quran, prayer and remembrance — free, no ads'**
  String get tagline;

  /// shared key "tasbih.add"
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tasbihAdd;

  /// shared key "tasbih.cancel"
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tasbihCancel;

  /// shared key "tasbih.changeDhikr"
  ///
  /// In en, this message translates to:
  /// **'Change dhikr'**
  String get tasbihChangeDhikr;

  /// shared key "tasbih.changeLook"
  ///
  /// In en, this message translates to:
  /// **'Bead style'**
  String get tasbihChangeLook;

  /// shared key "tasbih.clear"
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tasbihClear;

  /// shared key "tasbih.clearConfirm"
  ///
  /// In en, this message translates to:
  /// **'Clear the whole tasbih history?'**
  String get tasbihClearConfirm;

  /// shared key "tasbih.clearHistory"
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get tasbihClearHistory;

  /// shared key "tasbih.color"
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get tasbihColor;

  /// shared key "tasbih.count"
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get tasbihCount;

  /// shared key "tasbih.counter"
  ///
  /// In en, this message translates to:
  /// **'Count {count} of {target}'**
  String tasbihCounter(String count, String target);

  /// shared key "tasbih.history"
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tasbihHistory;

  /// shared key "tasbih.historyEmpty"
  ///
  /// In en, this message translates to:
  /// **'Nothing counted yet.'**
  String get tasbihHistoryEmpty;

  /// shared key "tasbih.historyOpen"
  ///
  /// In en, this message translates to:
  /// **'Tasbih history'**
  String get tasbihHistoryOpen;

  /// shared key "tasbih.mine"
  ///
  /// In en, this message translates to:
  /// **'My adhkar'**
  String get tasbihMine;

  /// shared key "tasbih.mode"
  ///
  /// In en, this message translates to:
  /// **'Counter style'**
  String get tasbihMode;

  /// shared key "tasbih.modeBeads"
  ///
  /// In en, this message translates to:
  /// **'Beads'**
  String get tasbihModeBeads;

  /// shared key "tasbih.modeButton"
  ///
  /// In en, this message translates to:
  /// **'Big button'**
  String get tasbihModeButton;

  /// shared key "tasbih.newDhikr"
  ///
  /// In en, this message translates to:
  /// **'Type a dhikr to count'**
  String get tasbihNewDhikr;

  /// shared key "tasbih.ofTarget"
  ///
  /// In en, this message translates to:
  /// **'of {n}'**
  String tasbihOfTarget(String n);

  /// shared key "tasbih.phrase"
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get tasbihPhrase;

  /// shared key "tasbih.pickDhikr"
  ///
  /// In en, this message translates to:
  /// **'Choose a dhikr'**
  String get tasbihPickDhikr;

  /// shared key "tasbih.remove"
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”'**
  String tasbihRemove(String name);

  /// shared key "tasbih.reset"
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// shared key "tasbih.rounds"
  ///
  /// In en, this message translates to:
  /// **'Rounds: {n}'**
  String tasbihRounds(String n);

  /// shared key "tasbih.sound"
  ///
  /// In en, this message translates to:
  /// **'Sound on each count'**
  String get tasbihSound;

  /// shared key "tasbih.style"
  ///
  /// In en, this message translates to:
  /// **'Bead style'**
  String get tasbihStyle;

  /// shared key "tasbih.style.crystal"
  ///
  /// In en, this message translates to:
  /// **'Crystal'**
  String get tasbihStyleCrystal;

  /// shared key "tasbih.style.glossy"
  ///
  /// In en, this message translates to:
  /// **'Glossy'**
  String get tasbihStyleGlossy;

  /// shared key "tasbih.style.marble"
  ///
  /// In en, this message translates to:
  /// **'Marble'**
  String get tasbihStyleMarble;

  /// shared key "tasbih.style.pearl"
  ///
  /// In en, this message translates to:
  /// **'Pearl'**
  String get tasbihStylePearl;

  /// shared key "tasbih.style.wood"
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get tasbihStyleWood;

  /// shared key "tasbih.tap"
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get tasbihTap;

  /// shared key "tasbih.target"
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get tasbihTarget;

  /// shared key "tasbih.times"
  ///
  /// In en, this message translates to:
  /// **'{n} times'**
  String tasbihTimes(String n);

  /// shared key "tasbih.title"
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihTitle;

  /// shared key "tasbih.today"
  ///
  /// In en, this message translates to:
  /// **'Today for this dhikr: {n}'**
  String tasbihToday(String n);

  /// shared key "tasbih.total"
  ///
  /// In en, this message translates to:
  /// **'Total: {n}'**
  String tasbihTotal(String n);

  /// shared key "tasbih.undo"
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tasbihUndo;

  /// shared key "tasbih.vibrate"
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get tasbihVibrate;

  /// shared key "tasbih.virtueSource"
  ///
  /// In en, this message translates to:
  /// **'Hisn al-Muslim'**
  String get tasbihVirtueSource;

  /// shared key "tour.adhkarBody"
  ///
  /// In en, this message translates to:
  /// **'Morning and evening adhkar and Hisn al-Muslim with audio, a tasbih counter, the hadith books and the Names of Allah.'**
  String get tourAdhkarBody;

  /// shared key "tour.adhkarTitle"
  ///
  /// In en, this message translates to:
  /// **'Adhkar and hadith'**
  String get tourAdhkarTitle;

  /// shared key "tour.back"
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// shared key "tour.listenBody"
  ///
  /// In en, this message translates to:
  /// **'Quran radios, Sha\'rawi\'s audio tafsir, stories of the Quran, and lessons and clips from trusted channels.'**
  String get tourListenBody;

  /// shared key "tour.listenTitle"
  ///
  /// In en, this message translates to:
  /// **'Listen and learn'**
  String get tourListenTitle;

  /// shared key "tour.next"
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// shared key "tour.page"
  ///
  /// In en, this message translates to:
  /// **'Page {n} of {total}'**
  String tourPage(String n, String total);

  /// shared key "tour.prayerBody"
  ///
  /// In en, this message translates to:
  /// **'Prayer times for where you are, an adhan alert in the muezzin\'s voice you choose, the qibla and nearby mosques.'**
  String get tourPrayerBody;

  /// shared key "tour.prayerTitle"
  ///
  /// In en, this message translates to:
  /// **'Prayer times and adhan'**
  String get tourPrayerTitle;

  /// shared key "tour.quranBody"
  ///
  /// In en, this message translates to:
  /// **'The King Fahd Complex Mushaf, page by page, recitations by many reciters, Tafsir al-Muyassar and a khatma planner.'**
  String get tourQuranBody;

  /// shared key "tour.quranTitle"
  ///
  /// In en, this message translates to:
  /// **'The Holy Quran'**
  String get tourQuranTitle;

  /// shared key "tour.skip"
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// shared key "tour.welcomeBody"
  ///
  /// In en, this message translates to:
  /// **'A free app for the sake of Allah, with no ads and no subscriptions: the Quran, prayer and adhkar in one place.'**
  String get tourWelcomeBody;

  /// shared key "tour.welcomeTitle"
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rattil wa Salli'**
  String get tourWelcomeTitle;

  /// shared key "videos.clearHistory"
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get videosClearHistory;

  /// shared key "videos.history"
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get videosHistory;

  /// shared key "videos.noResults"
  ///
  /// In en, this message translates to:
  /// **'No matching Islamic videos. Try other words.'**
  String get videosNoResults;

  /// shared key "videos.removeHistory"
  ///
  /// In en, this message translates to:
  /// **'Remove “{q}” from history'**
  String videosRemoveHistory(String q);

  /// shared key "videos.search"
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get videosSearch;

  /// shared key "videos.searchFailed"
  ///
  /// In en, this message translates to:
  /// **'Search is not available right now. Check your connection and try again.'**
  String get videosSearchFailed;

  /// shared key "videos.searchHint"
  ///
  /// In en, this message translates to:
  /// **'Search a recitation, lesson or admonition'**
  String get videosSearchHint;

  /// shared key "videos.searchNote"
  ///
  /// In en, this message translates to:
  /// **'Search shows Islamic videos only (recitations, lessons, admonitions), trusted channels first. Tap a video to play it, or long-press to open it in YouTube.'**
  String get videosSearchNote;

  /// shared key "worship.fasted"
  ///
  /// In en, this message translates to:
  /// **'Fasting days: {n}'**
  String worshipFasted(String n);

  /// shared key "worship.fasting"
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get worshipFasting;

  /// shared key "worship.fullDays"
  ///
  /// In en, this message translates to:
  /// **'Full days: {n}'**
  String worshipFullDays(String n);

  /// shared key "worship.month"
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get worshipMonth;

  /// shared key "worship.note"
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get worshipNote;

  /// shared key "worship.prayedOf"
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} prayers'**
  String worshipPrayedOf(String n, String total);

  /// shared key "worship.prayers"
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get worshipPrayers;

  /// shared key "worship.private"
  ///
  /// In en, this message translates to:
  /// **'Kept on this device only.'**
  String get worshipPrivate;

  /// shared key "worship.streak"
  ///
  /// In en, this message translates to:
  /// **'Days in a row with all five prayers: {n}'**
  String worshipStreak(String n);

  /// shared key "worship.title"
  ///
  /// In en, this message translates to:
  /// **'Worship tracker'**
  String get worshipTitle;

  /// shared key "worship.today"
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get worshipToday;

  /// shared key "worship.week"
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get worshipWeek;

  /// shared key "yt.officialNote"
  ///
  /// In en, this message translates to:
  /// **'Plays from the official YouTube channel and needs an internet connection.'**
  String get ytOfficialNote;

  /// shared key "zakat.adornment"
  ///
  /// In en, this message translates to:
  /// **'Gold worn for adornment'**
  String get zakatAdornment;

  /// shared key "zakat.animalCount"
  ///
  /// In en, this message translates to:
  /// **'Number of animals'**
  String get zakatAnimalCount;

  /// shared key "zakat.basis"
  ///
  /// In en, this message translates to:
  /// **'Measure the nisab by'**
  String get zakatBasis;

  /// shared key "zakat.basisGold"
  ///
  /// In en, this message translates to:
  /// **'Gold (85 g)'**
  String get zakatBasisGold;

  /// shared key "zakat.basisSilver"
  ///
  /// In en, this message translates to:
  /// **'Silver (595 g)'**
  String get zakatBasisSilver;

  /// shared key "zakat.belowNisab"
  ///
  /// In en, this message translates to:
  /// **'Below the nisab: no zakat is due'**
  String get zakatBelowNisab;

  /// shared key "zakat.camels"
  ///
  /// In en, this message translates to:
  /// **'Camels'**
  String get zakatCamels;

  /// shared key "zakat.cattle"
  ///
  /// In en, this message translates to:
  /// **'Cattle'**
  String get zakatCattle;

  /// shared key "zakat.cropsKg"
  ///
  /// In en, this message translates to:
  /// **'Harvest weight'**
  String get zakatCropsKg;

  /// shared key "zakat.cropsNote"
  ///
  /// In en, this message translates to:
  /// **'Paid on the day of harvest.'**
  String get zakatCropsNote;

  /// shared key "zakat.cropsRule"
  ///
  /// In en, this message translates to:
  /// **'The crops nisab is about 612 kg; due at harvest, no year needed.'**
  String get zakatCropsRule;

  /// shared key "zakat.due"
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {zakat}'**
  String zakatDue(String zakat);

  /// shared key "zakat.dueAnimals"
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {v}'**
  String zakatDueAnimals(String v);

  /// shared key "zakat.dueCrops"
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {kg} kg of the harvest'**
  String zakatDueCrops(String kg);

  /// shared key "zakat.dueDetail"
  ///
  /// In en, this message translates to:
  /// **'One fortieth (2.5%) of {net}; the nisab is {nisab}.'**
  String zakatDueDetail(String net, String nisab);

  /// shared key "zakat.dueEmpty"
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get zakatDueEmpty;

  /// shared key "zakat.dueGold"
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {g} g of {k}-carat gold'**
  String zakatDueGold(String g, String k);

  /// shared key "zakat.dueMoney"
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {v}'**
  String zakatDueMoney(String v);

  /// shared key "zakat.dueNone"
  ///
  /// In en, this message translates to:
  /// **'No zakat'**
  String get zakatDueNone;

  /// shared key "zakat.dueShortGrams"
  ///
  /// In en, this message translates to:
  /// **'{g} g'**
  String zakatDueShortGrams(String g);

  /// shared key "zakat.dueShortKg"
  ///
  /// In en, this message translates to:
  /// **'{kg} kg'**
  String zakatDueShortKg(String kg);

  /// shared key "zakat.dueShortMoney"
  ///
  /// In en, this message translates to:
  /// **'{v} EGP'**
  String zakatDueShortMoney(String v);

  /// shared key "zakat.dueSilver"
  ///
  /// In en, this message translates to:
  /// **'Zakat due: {g} g of silver'**
  String zakatDueSilver(String g);

  /// shared key "zakat.fatwa"
  ///
  /// In en, this message translates to:
  /// **'Fatwa no. {n} on Dar al-Ifta\'s website'**
  String zakatFatwa(String n);

  /// shared key "zakat.field.cash"
  ///
  /// In en, this message translates to:
  /// **'Cash and bank balances'**
  String get zakatFieldCash;

  /// shared key "zakat.field.certificateReturns"
  ///
  /// In en, this message translates to:
  /// **'Certificate returns you add to the capital at year end'**
  String get zakatFieldCertificateReturns;

  /// shared key "zakat.field.certificates"
  ///
  /// In en, this message translates to:
  /// **'Bank certificates and deposits (principal)'**
  String get zakatFieldCertificates;

  /// shared key "zakat.field.debts"
  ///
  /// In en, this message translates to:
  /// **'Debts now due from you (subtracted)'**
  String get zakatFieldDebts;

  /// shared key "zakat.field.gold18"
  ///
  /// In en, this message translates to:
  /// **'Gold kept as savings or investment, 18 karat (grams)'**
  String get zakatFieldGold18;

  /// shared key "zakat.field.gold21"
  ///
  /// In en, this message translates to:
  /// **'Gold kept as savings or investment, 21 karat (grams)'**
  String get zakatFieldGold21;

  /// shared key "zakat.field.gold24"
  ///
  /// In en, this message translates to:
  /// **'Gold kept as savings or investment, 24 karat (grams)'**
  String get zakatFieldGold24;

  /// shared key "zakat.field.shares"
  ///
  /// In en, this message translates to:
  /// **'Shares kept as savings (today\'s value with profits)'**
  String get zakatFieldShares;

  /// shared key "zakat.field.trade"
  ///
  /// In en, this message translates to:
  /// **'Trade goods (market price)'**
  String get zakatFieldTrade;

  /// shared key "zakat.goldGrams"
  ///
  /// In en, this message translates to:
  /// **'Weight of saved gold'**
  String get zakatGoldGrams;

  /// shared key "zakat.goldPrice"
  ///
  /// In en, this message translates to:
  /// **'Price of 1 g of 24-carat gold (optional)'**
  String get zakatGoldPrice;

  /// shared key "zakat.goldRule"
  ///
  /// In en, this message translates to:
  /// **'The gold nisab is 85 g of pure (24-carat) gold.'**
  String get zakatGoldRule;

  /// shared key "zakat.gram"
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get zakatGram;

  /// shared key "zakat.groupDebts"
  ///
  /// In en, this message translates to:
  /// **'Debts you owe'**
  String get zakatGroupDebts;

  /// shared key "zakat.groupGold"
  ///
  /// In en, this message translates to:
  /// **'Gold (grams)'**
  String get zakatGroupGold;

  /// shared key "zakat.groupMoney"
  ///
  /// In en, this message translates to:
  /// **'Money and savings'**
  String get zakatGroupMoney;

  /// shared key "zakat.irrigated"
  ///
  /// In en, this message translates to:
  /// **'Machine-watered 5%'**
  String get zakatIrrigated;

  /// shared key "zakat.karat"
  ///
  /// In en, this message translates to:
  /// **'Carat'**
  String get zakatKarat;

  /// shared key "zakat.kg"
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get zakatKg;

  /// shared key "zakat.livestockNote"
  ///
  /// In en, this message translates to:
  /// **'For grazing animals after a full year.'**
  String get zakatLivestockNote;

  /// shared key "zakat.livestockRule"
  ///
  /// In en, this message translates to:
  /// **'Grazing animals after a full year. Camels and sheep: the zakat letter in Sahih al-Bukhari (1454); cattle: the hadith of Mu\'adh in Sunan al-Tirmidhi (623).'**
  String get zakatLivestockRule;

  /// shared key "zakat.money"
  ///
  /// In en, this message translates to:
  /// **'Saved money (cash and bank)'**
  String get zakatMoney;

  /// shared key "zakat.moneyRule"
  ///
  /// In en, this message translates to:
  /// **'Money is measured against the gold or the silver nisab; choose either.'**
  String get zakatMoneyRule;

  /// shared key "zakat.needGoldPrice"
  ///
  /// In en, this message translates to:
  /// **'Enter the price of 24-carat gold to work out the nisab'**
  String get zakatNeedGoldPrice;

  /// shared key "zakat.needPrice"
  ///
  /// In en, this message translates to:
  /// **'Enter the price of a gram of 21-karat gold to work out the nisab.'**
  String get zakatNeedPrice;

  /// shared key "zakat.needSilverPrice"
  ///
  /// In en, this message translates to:
  /// **'Enter the price of silver to work out the nisab'**
  String get zakatNeedSilverPrice;

  /// shared key "zakat.nisabIs"
  ///
  /// In en, this message translates to:
  /// **'Nisab now: {v}'**
  String zakatNisabIs(String v);

  /// shared key "zakat.nisabRule"
  ///
  /// In en, this message translates to:
  /// **'The nisab is the value of {grams} grams of {karat}-karat gold, so enter today\'s market price per gram.'**
  String zakatNisabRule(String grams, String karat);

  /// shared key "zakat.price"
  ///
  /// In en, this message translates to:
  /// **'Price of one gram of 21-karat gold today (your currency)'**
  String get zakatPrice;

  /// shared key "zakat.priceTitle"
  ///
  /// In en, this message translates to:
  /// **'Today\'s gold price'**
  String get zakatPriceTitle;

  /// shared key "zakat.rain"
  ///
  /// In en, this message translates to:
  /// **'Watered at no cost (rain/river) 10%'**
  String get zakatRain;

  /// shared key "zakat.result"
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get zakatResult;

  /// shared key "zakat.review"
  ///
  /// In en, this message translates to:
  /// **'Pending a shar\'i review: the calculator follows the published fatwas of Egypt\'s Dar al-Ifta (linked below) and has not been reviewed by a scholar yet. If your case is unclear, ask Dar al-Ifta.'**
  String get zakatReview;

  /// shared key "zakat.sheep"
  ///
  /// In en, this message translates to:
  /// **'Sheep/goats'**
  String get zakatSheep;

  /// shared key "zakat.silverGrams"
  ///
  /// In en, this message translates to:
  /// **'Weight of saved silver'**
  String get zakatSilverGrams;

  /// shared key "zakat.silverPrice"
  ///
  /// In en, this message translates to:
  /// **'Price of 1 g of pure silver (optional)'**
  String get zakatSilverPrice;

  /// shared key "zakat.silverRule"
  ///
  /// In en, this message translates to:
  /// **'The silver nisab is 595 g of pure silver.'**
  String get zakatSilverRule;

  /// shared key "zakat.sources"
  ///
  /// In en, this message translates to:
  /// **'Sources: fatwas of {ref}'**
  String zakatSources(String ref);

  /// shared key "zakat.tabCrops"
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get zakatTabCrops;

  /// shared key "zakat.tabGold"
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get zakatTabGold;

  /// shared key "zakat.tabLivestock"
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get zakatTabLivestock;

  /// shared key "zakat.tabMoney"
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get zakatTabMoney;

  /// shared key "zakat.tabSilver"
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get zakatTabSilver;

  /// shared key "zakat.tileSub"
  ///
  /// In en, this message translates to:
  /// **'Zakat on money, after Egypt\'s Dar al-Ifta'**
  String get zakatTileSub;

  /// shared key "zakat.title"
  ///
  /// In en, this message translates to:
  /// **'Zakat calculator'**
  String get zakatTitle;

  /// shared key "zakat.totalAlso"
  ///
  /// In en, this message translates to:
  /// **'Also: {v}'**
  String zakatTotalAlso(String v);

  /// shared key "zakat.totalEmpty"
  ///
  /// In en, this message translates to:
  /// **'Fill in what you have above to see the total here.'**
  String get zakatTotalEmpty;

  /// shared key "zakat.totalNone"
  ///
  /// In en, this message translates to:
  /// **'No zakat is due on what you entered'**
  String get zakatTotalNone;

  /// shared key "zakat.totalTitle"
  ///
  /// In en, this message translates to:
  /// **'Total zakat due'**
  String get zakatTotalTitle;

  /// shared key "zakat.unitBintLabun"
  ///
  /// In en, this message translates to:
  /// **'bint labun (2-year camel)'**
  String get zakatUnitBintLabun;

  /// shared key "zakat.unitBintMakhad"
  ///
  /// In en, this message translates to:
  /// **'bint makhad (1-year camel)'**
  String get zakatUnitBintMakhad;

  /// shared key "zakat.unitHiqqa"
  ///
  /// In en, this message translates to:
  /// **'hiqqa (3-year camel)'**
  String get zakatUnitHiqqa;

  /// shared key "zakat.unitJadhaa"
  ///
  /// In en, this message translates to:
  /// **'jadha\'a (4-year camel)'**
  String get zakatUnitJadhaa;

  /// shared key "zakat.unitMusinna"
  ///
  /// In en, this message translates to:
  /// **'musinna (2-year cow)'**
  String get zakatUnitMusinna;

  /// shared key "zakat.unitSheep"
  ///
  /// In en, this message translates to:
  /// **'sheep'**
  String get zakatUnitSheep;

  /// shared key "zakat.unitTabi"
  ///
  /// In en, this message translates to:
  /// **'tabi\' (1-year calf)'**
  String get zakatUnitTabi;

  /// shared key "zakat.wealth"
  ///
  /// In en, this message translates to:
  /// **'Your wealth (in your currency; gold in grams)'**
  String get zakatWealth;

  /// shared key "zakat.yearNotPassed"
  ///
  /// In en, this message translates to:
  /// **'Your wealth ({net}) has reached the nisab ({nisab}); zakat is due once a full Hijri year passes over it.'**
  String zakatYearNotPassed(String net, String nisab);

  /// shared key "zakat.yearNote"
  ///
  /// In en, this message translates to:
  /// **'Due when the amount has stayed at or above the nisab for a full lunar year; the rate is 2.5%.'**
  String get zakatYearNote;

  /// shared key "zakat.yearPassed"
  ///
  /// In en, this message translates to:
  /// **'A full Hijri year has passed since my wealth reached the nisab'**
  String get zakatYearPassed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
