// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get aboutFonts => 'الخطوط: Amiri Quran وIBM Plex Sans Arabic — رخصة SIL المفتوحة للخطوط ١٫١.';

  @override
  String get aboutOpenSource => 'مفتوح المصدر ومجاني للأبد. بلا تتبع ولا إعلانات ولا مشتريات داخل التطبيق.';

  @override
  String get aboutPages =>
      'حدود صفحات المصحف: مصحف المدينة ١٤٠٥هـ (مجمع الملك فهد) عبر بيانات QuranMeHelp — رخصة الوقف العامة ٢٫٠.';

  @override
  String get aboutPrayerAlgo =>
      'تُحسب المواقيت على الجهاز بالمعادلات الفلكية المعيارية (ميوس / المرصد البحري الأمريكي) وتُقارن بمكتبة adhan-js المستقلة.';

  @override
  String get aboutQuranText =>
      'نص القرآن: الرسم العثماني من موسوعة القرآن الكريم (quranenc.com)، رواية حفص عن عاصم، عبر quran-json 3.1.2 — رخصة CC BY 4.0. مضمَّن دون أي تعديل ومُتحقَّق منه ببصمة SHA-256.';

  @override
  String get aboutTranslation =>
      'الترجمة الإنجليزية: صحيح إنترناشونال عبر quran-json 3.1.2 (مراجعة الترخيص قيد الإجراء).';

  @override
  String get aboutTzdb => 'المناطق الزمنية: قاعدة بيانات IANA (ملكية عامة) عبر حزمة timezone.';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get accountEmail => 'البريد الإلكتروني';

  @override
  String get accountErrAuth => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get accountErrEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get accountErrOffline => 'تعذّر الوصول إلى الخادم. تحقّق من اتصالك بالإنترنت ومن عنوان الخادم.';

  @override
  String get accountErrPassword => 'يجب ألا تقل كلمة المرور عن ١٠ أحرف';

  @override
  String get accountErrRateLimit => 'محاولات كثيرة. انتظر دقيقة ثم أعد المحاولة.';

  @override
  String accountErrServer(String code) {
    return 'خطأ في الخادم ($code)';
  }

  @override
  String get accountErrSession => 'انتهت الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get accountErrTaken => 'هذا البريد مسجّل مسبقًا';

  @override
  String accountLastSync(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get accountLogin => 'تسجيل الدخول';

  @override
  String get accountLogout => 'تسجيل الخروج';

  @override
  String get accountOptional => 'الحساب اختياري، وكل الميزات تعمل دون اتصال من غيره.';

  @override
  String get accountPassword => 'كلمة المرور';

  @override
  String get accountRegister => 'إنشاء حساب';

  @override
  String get accountRegistered => 'تم إنشاء الحساب. يمكنك تسجيل الدخول الآن.';

  @override
  String get accountSaveServer => 'حفظ العنوان';

  @override
  String get accountServerInvalid => 'أدخل عنوانًا يبدأ بـ http:// أو https://';

  @override
  String get accountServerSaved => 'تم حفظ عنوان الخادم';

  @override
  String get accountServerUrl => 'عنوان الخادم';

  @override
  String accountSignedInAs(String email) {
    return 'مسجّل الدخول باسم $email';
  }

  @override
  String accountSyncDone(String count) {
    return 'اكتملت المزامنة: $count علامة';
  }

  @override
  String get accountSyncNow => 'زامن الآن';

  @override
  String get adhanBanner => 'تنبيه الأذان مقفول. فعّله عشان يوصلك تنبيه بصوت الأذان في كل صلاة.';

  @override
  String get adhanBannerAction => 'تفعيل';

  @override
  String adhanBellOff(String name) {
    return 'تنبيه $name مقفول';
  }

  @override
  String adhanBellOn(String name) {
    return 'تنبيه $name شغّال';
  }

  @override
  String adhanBody(String name, String city) {
    return 'دخل وقت صلاة $name حسب توقيت $city';
  }

  @override
  String get adhanCredit => 'تسجيل الأذان: «Beautiful adhan» من ويكيميديا كومنز (Adam-synagda)، ملكية عامة CC0.';

  @override
  String get adhanDenied => 'الإشعارات غير مسموح بها. فعّلها من إعدادات النظام.';

  @override
  String get adhanEnable => 'نبّهني عند دخول وقت الصلاة';

  @override
  String get adhanIosNote => 'على الآيفون يُسمع التكبير الأول فقط في الإشعار (النظام يسمح بـ٣٠ ثانية بحد أقصى).';

  @override
  String get adhanNote =>
      'تُجدول على هذا الجهاز مسبقًا وتشتغل حتى لو التطبيق مقفول، ويجدّدها فتح التطبيق. لو التنبيه اتأخر، اسمح للتطبيق بـ«المنبّهات والتذكيرات» وأوقف توفير البطارية له.';

  @override
  String get adhanPreview => 'اسمع الأذان';

  @override
  String get adhanPreviewStop => 'إيقاف';

  @override
  String get adhanSettings => 'تنبيهات الأذان';

  @override
  String get adhanSound => 'صوت التنبيه';

  @override
  String get adhanSoundAdhan => 'الأذان';

  @override
  String get adhanSoundSilent => 'بدون صوت';

  @override
  String get adhanSoundTone => 'نغمة الإشعارات';

  @override
  String get adhanStop => 'إيقاف الأذان';

  @override
  String get adhanTest => 'جرّب التنبيه (بعد ١٠ ثوانٍ)';

  @override
  String get adhanTestBody => 'لو سمعت الصوت، فالتنبيه شغّال على جهازك.';

  @override
  String get adhanTestScheduled => 'هيوصلك تنبيه تجريبي بعد ١٠ ثوانٍ، ممكن تقفل التطبيق.';

  @override
  String get adhanTestTitle => 'تجربة تنبيه الأذان';

  @override
  String adhanTitle(String name) {
    return 'حان وقت صلاة $name';
  }

  @override
  String get adhkarArabicOnly => 'هذا المحتوى متاح بالعربية فقط.';

  @override
  String get adhkarCopied => 'تم النسخ';

  @override
  String get adhkarCopy => 'نسخ';

  @override
  String get adhkarDone => 'تمّ';

  @override
  String get adhkarEvening => 'المساء';

  @override
  String get adhkarEveningTitle => 'أذكار المساء';

  @override
  String get adhkarHisn => 'حصن المسلم';

  @override
  String adhkarHisnCount(String n) {
    return 'عدد الأذكار: $n';
  }

  @override
  String get adhkarHisnSearch => 'ابحث في الأبواب';

  @override
  String get adhkarMorning => 'الصباح';

  @override
  String get adhkarMorningTitle => 'أذكار الصباح';

  @override
  String adhkarProgress(String done, String total) {
    return 'أُنجز $done من $total';
  }

  @override
  String adhkarRemaining(String n) {
    return 'متبقٍّ $n';
  }

  @override
  String adhkarRepeat(String n) {
    return 'التكرار $n';
  }

  @override
  String get adhkarReset => 'البدء من جديد';

  @override
  String get adhkarReviewNotice =>
      'بانتظار المراجعة الشرعية. النصوص من مجموعة أذكار Kazi Shariar (CC BY 4.0) ومن حصن المسلم، وأعداد التكرار وفق حصن المسلم.';

  @override
  String get adhkarTapToCount => 'اضغط على البطاقة للعدّ';

  @override
  String get appName => 'رتّل';

  @override
  String get audioBasmala => 'البسملة';

  @override
  String get audioLoading => 'جارٍ التحميل…';

  @override
  String get audioNext => 'الآية التالية';

  @override
  String get audioOffline => 'تعذّر تحميل التلاوة. تحقّق من اتصالك بالإنترنت ثم أعد المحاولة.';

  @override
  String get audioPause => 'إيقاف مؤقت';

  @override
  String get audioPlay => 'تشغيل';

  @override
  String get audioPrevious => 'الآية السابقة';

  @override
  String get audioReciter => 'القارئ';

  @override
  String get audioRepeat => 'تكرار كل آية';

  @override
  String audioRepeatN(String n) {
    return '$n×';
  }

  @override
  String get audioStop => 'إيقاف';

  @override
  String get audioStreamNote => 'تُبثّ التلاوات من موقع everyayah.com وتحتاج إلى اتصال بالإنترنت.';

  @override
  String get audioTafsirToggle => 'التفسير مع التلاوة';

  @override
  String get audioTitle => 'التلاوة';

  @override
  String bookmarksDelete(String label) {
    return 'حذف علامة $label';
  }

  @override
  String get bookmarksEmpty => 'لا توجد علامات بعد';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonError => 'حدث خطأ';

  @override
  String get commonOffline => 'أنت غير متصل — يُعرض المحتوى المحفوظ';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get hajjHajj => 'الحج';

  @override
  String get hajjIhram => 'الإحرام';

  @override
  String get hajjReviewNotice =>
      'بانتظار المراجعة الشرعية: لم يراجع هذا الدليلَ عالمٌ مختص بعد. تحقّق من عالم موثوق قبل الاعتماد عليه.';

  @override
  String get hajjTitle => 'الحج والعمرة';

  @override
  String get hajjUmrah => 'العمرة';

  @override
  String get homeBigAdhkar => 'الأذكار والدعاء';

  @override
  String get homeBigPrayer => 'مواقيت الصلاة';

  @override
  String get homeBigQibla => 'اتجاه القبلة';

  @override
  String get homeBigQuran => 'القرآن الكريم';

  @override
  String get homeBigReels => 'ريلز إسلامية';

  @override
  String get homeBigStories => 'قصص الأنبياء';

  @override
  String get homeBigTasbih => 'التسبيح';

  @override
  String get homeCalendar => 'تقويم الصلاة';

  @override
  String homeHijriDate(String day, String month, String year) {
    return '$day $month $year هـ';
  }

  @override
  String homeLastPage(String page) {
    return 'آخر صفحة: $page';
  }

  @override
  String homeLeft(String time) {
    return 'متبقي $time';
  }

  @override
  String get homeMainSections => 'الأقسام الرئيسية';

  @override
  String get homeNextPrayer => 'الصلاة القادمة';

  @override
  String get homeOpenMushaf => 'افتح المصحف';

  @override
  String homePrayerOf(String name) {
    return 'صلاة $name';
  }

  @override
  String get homeQuickLinks => 'روابط سريعة';

  @override
  String get homeSections => 'الأقسام';

  @override
  String get homeSunrise => 'الشروق';

  @override
  String get homeSunset => 'الغروب';

  @override
  String get homeTimingFor => 'توقيت';

  @override
  String get homeTodayTimes => 'مواقيت اليوم';

  @override
  String get homeTomorrowTimes => 'مواقيت الغد';

  @override
  String get homeWelcome => 'السلام عليكم';

  @override
  String get moreTitle => 'المزيد';

  @override
  String get mushafCopied => 'نُسخت الآية';

  @override
  String get mushafCopy => 'نسخ الآية';

  @override
  String get mushafPlayFromHere => 'استمع من هنا';

  @override
  String get mushafPlayPage => 'استمع إلى الصفحة';

  @override
  String get mushafPlaySurah => 'استمع إلى السورة';

  @override
  String get mushafReadAsList => 'اقرأ السورة آيةً آية';

  @override
  String mushafSlider(String page) {
    return 'الصفحة $page من ٦٠٤';
  }

  @override
  String get mushafTapHint => 'اضغط على آية للاستماع أو الحفظ أو النسخ';

  @override
  String get mushafToggleControls => 'إظهار عناصر التحكم أو إخفاؤها';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navBookmarks => 'العلامات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMore => 'المزيد';

  @override
  String get navPrayer => 'الصلاة';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get prayerAdjust => 'تعديل يدوي (بالدقائق)';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerAsrHanafi => 'الحنفي';

  @override
  String get prayerAsrMethod => 'مذهب العصر';

  @override
  String get prayerAsrStandard => 'الجمهور (الشافعي والمالكي والحنبلي)';

  @override
  String get prayerCity => 'المدينة';

  @override
  String prayerCompassLabel(String deg) {
    return 'البوصلة: القبلة على $deg° باتجاه عقارب الساعة من الشمال';
  }

  @override
  String prayerDate(String date) {
    return 'التاريخ: $date';
  }

  @override
  String prayerDecrease(String name) {
    return 'إنقاص دقيقة من $name';
  }

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String prayerHighLat(String list) {
    return 'طُبّقت قاعدة خطوط العرض العليا على: $list';
  }

  @override
  String prayerIn(String time) {
    return 'بعد $time';
  }

  @override
  String prayerIncrease(String name) {
    return 'زيادة دقيقة إلى $name';
  }

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerMethod => 'طريقة الحساب';

  @override
  String prayerMinutesValue(String n) {
    return '$n دقيقة';
  }

  @override
  String prayerNext(String name) {
    return 'الصلاة القادمة: $name';
  }

  @override
  String get prayerNoPrayerToday => 'لا يمكن حساب المواقيت هنا اليوم (نهار أو ليل قطبي)';

  @override
  String get prayerNorth => 'ش';

  @override
  String get prayerQibla => 'اتجاه القبلة';

  @override
  String prayerQiblaDeg(String deg) {
    return '$deg° من الشمال الجغرافي';
  }

  @override
  String get prayerQiblaNote => 'رسم ثابت: وجّه أعلى الهاتف نحو الشمال الجغرافي.';

  @override
  String get prayerResetAdjust => 'إعادة ضبط التعديلات';

  @override
  String get prayerSearchCity => 'ابحث عن مدينة';

  @override
  String get prayerSelectCity => 'اختر المدينة';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String prayerTimezone(String tz) {
    return 'المنطقة الزمنية: $tz';
  }

  @override
  String get prayerTitle => 'مواقيت الصلاة';

  @override
  String get qiblaFacing => 'أنت متجه نحو القبلة';

  @override
  String qiblaHeading(String deg) {
    return 'اتجاه الهاتف: $deg°';
  }

  @override
  String get qiblaLiveNote =>
      'أمسك الهاتف أفقيًا بعيدًا عن المعادن والمغناطيس، وإن اضطربت القراءة فحرّكه على شكل الرقم ٨. تقيس البوصلة الشمال المغناطيسي، وقد يختلف عن الشمال الحقيقي بضع درجات.';

  @override
  String get qiblaStatic =>
      'لا تتوفر قراءة للبوصلة على هذا الجهاز: يبيّن الرسم اتجاه القبلة بالنسبة إلى الشمال الحقيقي.';

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String qiblaTurnLeft(String deg) {
    return 'استدر يسارًا $deg°';
  }

  @override
  String qiblaTurnRight(String deg) {
    return 'استدر يمينًا $deg°';
  }

  @override
  String get qiblaWaiting => 'جارٍ قراءة البوصلة…';

  @override
  String quranAyahCount(String count) {
    return '$count آية';
  }

  @override
  String quranAyahN(String n) {
    return 'الآية $n';
  }

  @override
  String get quranBookmark => 'حفظ علامة على الآية';

  @override
  String get quranBookmarkRemoved => 'تم حذف العلامة';

  @override
  String get quranBookmarked => 'تم حفظ العلامة';

  @override
  String get quranClearSearch => 'مسح البحث';

  @override
  String get quranContinueReading => 'متابعة القراءة';

  @override
  String get quranFilter => 'تصفية السور';

  @override
  String get quranFilterHint => 'الاسم أو الرقم';

  @override
  String get quranGo => 'اذهب';

  @override
  String get quranGoToPage => 'اذهب إلى صفحة';

  @override
  String quranHizbN(String n) {
    return 'الحزب $n';
  }

  @override
  String get quranIndex => 'فهرس السور';

  @override
  String get quranIndexSearch => 'البحث';

  @override
  String quranJuz(String juz) {
    return 'الجزء $juz';
  }

  @override
  String get quranJuzOrdinals =>
      'الأول|الثاني|الثالث|الرابع|الخامس|السادس|السابع|الثامن|التاسع|العاشر|الحادي عشر|الثاني عشر|الثالث عشر|الرابع عشر|الخامس عشر|السادس عشر|السابع عشر|الثامن عشر|التاسع عشر|العشرون|الحادي والعشرون|الثاني والعشرون|الثالث والعشرون|الرابع والعشرون|الخامس والعشرون|السادس والعشرون|السابع والعشرون|الثامن والعشرون|التاسع والعشرون|الثلاثون';

  @override
  String quranJuzTitle(String ordinal) {
    return 'الجزء $ordinal';
  }

  @override
  String get quranListView => 'عرض كقائمة';

  @override
  String get quranMeccan => 'مكية';

  @override
  String get quranMedinan => 'مدنية';

  @override
  String get quranNextPage => 'الصفحة التالية';

  @override
  String get quranNoResults => 'لا توجد نتائج';

  @override
  String get quranOpenMushaf => 'فتح صفحات المصحف';

  @override
  String quranPage(String page) {
    return 'صفحة $page';
  }

  @override
  String get quranPageInvalid => 'أدخل رقمًا صحيحًا من ١ إلى ٦٠٤';

  @override
  String get quranPageNumberHint => '١–٦٠٤';

  @override
  String get quranPages => 'صفحات المصحف';

  @override
  String get quranPrevPage => 'الصفحة السابقة';

  @override
  String quranQuarterLine(String surah, String ayah, String page) {
    return '$surah: $ayah - الصفحة $page';
  }

  @override
  String quranQuarterOfHizb(String q, String n) {
    return 'الربع $q من الحزب $n';
  }

  @override
  String get quranRemoveBookmark => 'حذف العلامة';

  @override
  String quranResultsCount(String count) {
    return '$count نتيجة';
  }

  @override
  String get quranSearch => 'البحث في القرآن';

  @override
  String get quranSearchAction => 'ابحث';

  @override
  String get quranSearchHint => 'اكتب كلمة';

  @override
  String get quranSearchPrompt => 'البحث يتجاهل التشكيل';

  @override
  String get quranSearchTooShort => 'اكتب حرفين عربيين على الأقل';

  @override
  String get quranShowTranslation => 'إظهار الترجمة الإنجليزية';

  @override
  String get quranStartReading => 'ابدأ القراءة';

  @override
  String quranSurahAyah(String surah, String ayah) {
    return '$surah : $ayah';
  }

  @override
  String quranSurahLine(String page, String count, String kind) {
    return 'الصفحة $page - آياتها $count - $kind';
  }

  @override
  String quranSurahN(String n) {
    return 'سورة $n';
  }

  @override
  String quranSurahTitle(String name) {
    return 'سورة $name';
  }

  @override
  String get quranSurahs => 'السور';

  @override
  String get quranTabQuarters => 'الأرباع';

  @override
  String get quranTabSurahs => 'السور';

  @override
  String get radioDuration => 'مدة التشغيل';

  @override
  String get radioListen => 'استماع';

  @override
  String get radioLonger => 'زيادة المدة';

  @override
  String radioMin(String n) {
    return '$n دقيقة';
  }

  @override
  String get radioNote => 'تلاوة متصلة للمصحف كاملًا تبدأ من سورة عشوائية.';

  @override
  String radioNowPlaying(String surah) {
    return 'سورة $surah';
  }

  @override
  String get radioPause => 'إيقاف مؤقت';

  @override
  String get radioShorter => 'تقليل المدة';

  @override
  String get radioTitle => 'إذاعة القرآن الكريم';

  @override
  String get radioUnlimited => 'غير محدود';

  @override
  String get readerBack => 'رجوع إلى الفهرس';

  @override
  String get readerBasmalaNow => 'تُتلى البسملة الآن';

  @override
  String get readerBookmarks => 'إشارات مرجعية';

  @override
  String get readerFont => 'حجم الخط';

  @override
  String readerFontSize(String size) {
    return 'حجم الخط: $size — اضغط للتكبير';
  }

  @override
  String get readerHelp => 'مساعدة';

  @override
  String get readerHelp1 => 'اسحب الصفحة يمينًا للتالية ويسارًا للسابقة، أو استخدم شريط الصفحات.';

  @override
  String get readerHelp2 => 'المس أي آية لتستمع إليها وترى تفسيرها.';

  @override
  String get readerHelp3 => 'زر «استماع مع التفسير» يقسم الشاشة نصفين: الآية التي تُتلى الآن، وتحتها تفسيرها المختصر.';

  @override
  String get readerHelpTitle => 'طريقة الاستخدام';

  @override
  String get readerIndex => 'الفهرس';

  @override
  String get readerKhatma => 'الختمة';

  @override
  String readerKhatmaContinue(String page) {
    return 'تابع من الصفحة $page';
  }

  @override
  String get readerKhatmaDone => 'أتممت الختمة، تقبّل الله منك.';

  @override
  String readerKhatmaLeft(String left) {
    return 'بقي $left صفحة';
  }

  @override
  String get readerKhatmaNone => 'لم تبدأ ختمة بعد. ابدأ ختمة جديدة وسيُحسب تقدمك من آخر صفحة تقرؤها.';

  @override
  String readerKhatmaProgress(String done, String pct) {
    return 'قرأت $done من ٦٠٤ صفحة ($pct٪)';
  }

  @override
  String get readerKhatmaReset => 'إلغاء الختمة';

  @override
  String readerKhatmaSince(String date) {
    return 'بدأت في $date';
  }

  @override
  String get readerKhatmaStart => 'ابدأ ختمة جديدة من الفاتحة';

  @override
  String get readerKhatmaTitle => 'الختمة';

  @override
  String get readerListenWithTafsir => 'استماع مع التفسير';

  @override
  String get readerPlayAyah => 'استمع للآية';

  @override
  String get readerPlayWithTafsir => 'استماع مع التفسير';

  @override
  String readerRepeatN(String n) {
    return 'التكرار: $n';
  }

  @override
  String get readerSearch => 'البحث';

  @override
  String get readerShowPage => 'عرض الصفحة';

  @override
  String get readerSplitTafsir => 'تفسير مختصر';

  @override
  String get readerSplitTitle => 'الآية التي تُتلى الآن';

  @override
  String get readerTabAyat => 'الآيات';

  @override
  String get readerTabMushaf => 'المصحف';

  @override
  String get readerTabTafsir => 'التفسير';

  @override
  String get reelsCatLesson => 'درس ديني مختصر';

  @override
  String get reelsCatRecitation => 'تلاوة خاشعة';

  @override
  String get reelsEmpty => 'لا توجد مقاطع مراجَعة بعد. تُضاف المقاطع بعد مراجعتها شرعياً.';

  @override
  String get reelsFeed => 'مقاطع';

  @override
  String get reelsNext => 'المقطع التالي';

  @override
  String get reelsNote =>
      'المقاطع معروضة من يوتيوب بمشغّله الرسمي، وتقتصر على التلاوات الخاشعة والدروس الدينية المختصرة الموافقة للكتاب والسنة، ولا يُعرض إلا ما راجعه مختص.';

  @override
  String get reelsOpen => 'افتح على يوتيوب';

  @override
  String get reelsPending => 'لم تتم مراجعة هذا المقطع شرعياً بعد — يظهر لك لأن وضع المراجعة مفعّل';

  @override
  String reelsPosition(String n, String total) {
    return 'المقطع $n من $total';
  }

  @override
  String get reelsPrev => 'المقطع السابق';

  @override
  String reelsReviewedBy(String name) {
    return 'راجعه: $name';
  }

  @override
  String get reelsReviewerHint => 'لعرض المقاطع التي لم تُراجع بعد';

  @override
  String get reelsReviewerMode => 'وضع المراجعة';

  @override
  String get reelsSub => 'مقاطع قصيرة مراجَعة';

  @override
  String get reelsTitle => 'ريلز إسلامية';

  @override
  String get settingsAbout => 'عن التطبيق';

  @override
  String get settingsAccount => 'الحساب والمزامنة';

  @override
  String get settingsAccountHint => 'اختياري — مزامنة العلامات بين الأجهزة';

  @override
  String get settingsFontPreview => 'معاينة';

  @override
  String get settingsFontSize => 'حجم خط المصحف';

  @override
  String get settingsFree => 'التطبيق مجاني بالكامل: بلا إعلانات ولا اشتراكات ولا مشتريات.';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageAr => 'العربية';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsSources => 'مصادر المحتوى';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeSystem => 'حسب الجهاز';

  @override
  String storiesAyahs(String count) {
    return '$count آية';
  }

  @override
  String get storiesBack => 'كل القصص';

  @override
  String get storiesCatOthers => 'قصص وعِبَر من القرآن';

  @override
  String get storiesCatProphets => 'قصص الأنبياء في القرآن';

  @override
  String get storiesEpisodeError => 'تعذّر تشغيل الحلقة. تأكد من اتصالك بالإنترنت.';

  @override
  String get storiesEpisodePending => 'لم تتم مراجعة هذه الحلقة شرعياً بعد — تظهر لك لأن وضع المراجعة مفعّل';

  @override
  String storiesEpisodes(String count) {
    return '$count حلقة';
  }

  @override
  String get storiesForward => 'تقديم ٣٠ ثانية';

  @override
  String storiesFrom(String surah, String from, String to) {
    return 'سورة $surah، الآيات $from–$to';
  }

  @override
  String get storiesIntro =>
      'استمع إلى قصص الأنبياء بصوت هادئ قبل النوم، أو اقرأ آيات كل قصة من المصحف مع التفسير الميسّر.';

  @override
  String get storiesListen => 'استمع إلى آيات القصة';

  @override
  String storiesMinutes(String n) {
    return '$n دقيقة';
  }

  @override
  String get storiesNowPlaying => 'تُسمع الآن';

  @override
  String get storiesOnlineOnly => 'الحلقات تُسمع عبر الإنترنت';

  @override
  String get storiesPause => 'إيقاف مؤقت';

  @override
  String get storiesPlay => 'استمع';

  @override
  String get storiesReadVerses => 'اقرأ آيات القصة';

  @override
  String get storiesReciter => 'القارئ';

  @override
  String storiesReviewedBy(String name) {
    return 'راجعها: $name';
  }

  @override
  String get storiesReviewerMode => 'وضع المراجعة (عرض الحلقات غير المراجَعة)';

  @override
  String get storiesRewind => 'رجوع ٣٠ ثانية';

  @override
  String storiesSeriesHidden(String title, String narrator) {
    return 'حلقات «$title» للشيخ $narrator تظهر هنا بعد مراجعتها شرعياً.';
  }

  @override
  String storiesSeriesSource(String source, String licence) {
    return 'المصدر: $source. $licence';
  }

  @override
  String get storiesSleep => 'مؤقت النوم';

  @override
  String storiesSleepLeft(String time) {
    return 'يتوقف الصوت بعد $time دقيقة';
  }

  @override
  String storiesSleepMin(String n) {
    return 'بعد $n دقيقة';
  }

  @override
  String get storiesSleepOff => 'بدون';

  @override
  String get storiesSource => 'المصدر: نص مصحف المدينة، والتفسير الميسّر (مجمع الملك فهد لطباعة المصحف الشريف).';

  @override
  String get storiesStop => 'إيقاف';

  @override
  String get storiesSub => 'قصص الأنبياء صوتياً وآياتها';

  @override
  String get storiesTafsirHint => 'اضغط على أي آية لعرض تفسيرها الميسّر.';

  @override
  String get storiesTitle => 'قصص قرآنية مسموعة';

  @override
  String get storiesVersesIntro =>
      'كل قصة هنا هي آياتها من القرآن الكريم (مصحف المدينة)، تُتلى بصوت القارئ الذي تختاره، مع التفسير الميسّر لكل آية.';

  @override
  String get storiesVersesTitle => 'آيات القصص من المصحف';

  @override
  String get tafsirArabicOnly => 'هذا التفسير متاح بالعربية فقط.';

  @override
  String get tafsirError => 'تعذّر تحميل التفسير.';

  @override
  String get tafsirLoading => 'جارٍ تحميل التفسير…';

  @override
  String get tafsirNext => 'الآية التالية';

  @override
  String get tafsirPrev => 'الآية السابقة';

  @override
  String get tafsirSource => 'مجمع الملك فهد لطباعة المصحف الشريف';

  @override
  String get tafsirTitle => 'التفسير الميسر';

  @override
  String get tagline => 'القرآن والصلاة والذكر — مجاني بلا إعلانات';

  @override
  String tasbihCounter(String count, String target) {
    return 'العدد $count من $target';
  }

  @override
  String get tasbihReset => 'تصفير';

  @override
  String tasbihRounds(String n) {
    return 'الدورات: $n';
  }

  @override
  String get tasbihTap => 'اضغط للتسبيح';

  @override
  String get tasbihTarget => 'العدد المستهدف';

  @override
  String get tasbihTitle => 'المسبحة';

  @override
  String tasbihTotal(String n) {
    return 'الإجمالي: $n';
  }
}
