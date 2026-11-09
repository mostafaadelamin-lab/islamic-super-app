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
  /// **'Fonts: Amiri Quran and IBM Plex Sans Arabic — SIL Open Font License 1.1.'**
  String get aboutFonts;

  /// shared key "about.openSource"
  ///
  /// In en, this message translates to:
  /// **'Open source and free forever. No tracking, no ads, no in-app purchases.'**
  String get aboutOpenSource;

  /// shared key "about.pages"
  ///
  /// In en, this message translates to:
  /// **'Mushaf page boundaries: Madinah Mushaf 1405H (KFGQPC) via QuranMeHelp manifest — Waqf General Public License 2.0.'**
  String get aboutPages;

  /// shared key "about.prayerAlgo"
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated on the device with standard astronomical formulas (Meeus / USNO) and checked against the independent adhan-js library.'**
  String get aboutPrayerAlgo;

  /// shared key "about.quranText"
  ///
  /// In en, this message translates to:
  /// **'Quran text: The Noble Qur\'an Encyclopedia (quranenc.com) Uthmani text, Hafs an Asim, via quran-json 3.1.2 — CC BY 4.0. Bundled unchanged; verified by SHA-256.'**
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

  /// shared key "adhan.credit"
  ///
  /// In en, this message translates to:
  /// **'Adhan recording: \"Beautiful adhan\" from Wikimedia Commons (Adam-synagda), public domain CC0.'**
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

  /// shared key "adhan.iosNote"
  ///
  /// In en, this message translates to:
  /// **'On iPhone the notification plays the opening takbir only (the system allows at most 30 seconds).'**
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

  /// shared key "adhkar.arabicOnly"
  ///
  /// In en, this message translates to:
  /// **'This content is available in Arabic only.'**
  String get adhkarArabicOnly;

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

  /// shared key "adhkar.done"
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adhkarDone;

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

  /// shared key "adhkar.repeat"
  ///
  /// In en, this message translates to:
  /// **'Repeat {n}'**
  String adhkarRepeat(String n);

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

  /// shared key "adhkar.tapToCount"
  ///
  /// In en, this message translates to:
  /// **'Tap a card to count it'**
  String get adhkarTapToCount;

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
  /// **'Rattil'**
  String get appName;

  /// shared key "audio.basmala"
  ///
  /// In en, this message translates to:
  /// **'Basmala'**
  String get audioBasmala;

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

  /// shared key "hajj.hajj"
  ///
  /// In en, this message translates to:
  /// **'Hajj'**
  String get hajjHajj;

  /// shared key "hajj.ihram"
  ///
  /// In en, this message translates to:
  /// **'Ihram'**
  String get hajjIhram;

  /// shared key "hajj.reviewNotice"
  ///
  /// In en, this message translates to:
  /// **'Pending religious review: this guide has not yet been reviewed by a qualified scholar. Check with a trusted scholar before relying on it.'**
  String get hajjReviewNotice;

  /// shared key "hajj.title"
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah'**
  String get hajjTitle;

  /// shared key "hajj.umrah"
  ///
  /// In en, this message translates to:
  /// **'Umrah'**
  String get hajjUmrah;

  /// shared key "home.big.adhkar"
  ///
  /// In en, this message translates to:
  /// **'Adhkar & Dua'**
  String get homeBigAdhkar;

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
  /// **'Islamic reels'**
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

  /// shared key "mosques.meters"
  ///
  /// In en, this message translates to:
  /// **'{n} m'**
  String mosquesMeters(String n);

  /// shared key "mosques.none"
  ///
  /// In en, this message translates to:
  /// **'No mosques are mapped within this distance. Try a larger one.'**
  String get mosquesNone;

  /// shared key "mosques.note"
  ///
  /// In en, this message translates to:
  /// **'Straight-line distance around your prayer-times city. Data from the open OpenStreetMap map; it can be incomplete in some places.'**
  String get mosquesNote;

  /// shared key "mosques.offline"
  ///
  /// In en, this message translates to:
  /// **'(last saved result, you are offline)'**
  String get mosquesOffline;

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

  /// shared key "qibla.declination"
  ///
  /// In en, this message translates to:
  /// **'Corrected from magnetic to true north: {deg}°'**
  String qiblaDeclination(String deg);

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

  /// shared key "qibla.static"
  ///
  /// In en, this message translates to:
  /// **'No compass reading on this device: the diagram shows the qibla from true north.'**
  String get qiblaStatic;

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

  /// shared key "reader.font"
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get readerFont;

  /// shared key "reader.fontSize"
  ///
  /// In en, this message translates to:
  /// **'Text size: {size} — press to enlarge'**
  String readerFontSize(String size);

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

  /// shared key "reader.tabMushaf"
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get readerTabMushaf;

  /// shared key "reader.tabTafsir"
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get readerTabTafsir;

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
  /// **'No reviewed reels yet. Reels are added after a religious review.'**
  String get reelsEmpty;

  /// shared key "reels.feed"
  ///
  /// In en, this message translates to:
  /// **'reels'**
  String get reelsFeed;

  /// shared key "reels.next"
  ///
  /// In en, this message translates to:
  /// **'Next reel'**
  String get reelsNext;

  /// shared key "reels.note"
  ///
  /// In en, this message translates to:
  /// **'Reels play from YouTube and Instagram through their official players. They are limited to Quran recitations, religious lessons, and advice and admonitions in line with the Quran and Sunnah, and only reviewed reels are shown.'**
  String get reelsNote;

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

  /// shared key "reels.sub"
  ///
  /// In en, this message translates to:
  /// **'Reviewed short videos'**
  String get reelsSub;

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
  /// **'This app is completely free: no ads, no subscriptions, no purchases.'**
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

  /// shared key "tagline"
  ///
  /// In en, this message translates to:
  /// **'Quran, prayer and remembrance — free, no ads'**
  String get tagline;

  /// shared key "tasbih.counter"
  ///
  /// In en, this message translates to:
  /// **'Count {count} of {target}'**
  String tasbihCounter(String count, String target);

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

  /// shared key "tasbih.title"
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihTitle;

  /// shared key "tasbih.total"
  ///
  /// In en, this message translates to:
  /// **'Total: {n}'**
  String tasbihTotal(String n);
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
