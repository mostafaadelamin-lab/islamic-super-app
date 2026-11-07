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

  /// shared key "adhan.body"
  ///
  /// In en, this message translates to:
  /// **'{name} prayer time in {city}'**
  String adhanBody(String name, String city);

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

  /// shared key "adhan.note"
  ///
  /// In en, this message translates to:
  /// **'Scheduled on this device for the next 7 days; opening the app renews them.'**
  String get adhanNote;

  /// shared key "adhan.settings"
  ///
  /// In en, this message translates to:
  /// **'Adhan notifications'**
  String get adhanSettings;

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

  /// shared key "home.todayTimes"
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayer times'**
  String get homeTodayTimes;

  /// shared key "home.welcome"
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you'**
  String get homeWelcome;

  /// shared key "more.title"
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

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

  /// shared key "prayer.city"
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get prayerCity;

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

  /// shared key "prayer.highLat"
  ///
  /// In en, this message translates to:
  /// **'High-latitude rule applied to: {list}'**
  String prayerHighLat(String list);

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
  /// **'Hold the phone flat, away from metal and magnets; if the reading jumps, move it in a figure 8. The compass measures magnetic north, so it can differ from true north by a few degrees.'**
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

  /// shared key "quran.juz"
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String quranJuz(String juz);

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

  /// shared key "quran.surahN"
  ///
  /// In en, this message translates to:
  /// **'Surah {n}'**
  String quranSurahN(String n);

  /// shared key "quran.surahs"
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get quranSurahs;

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
