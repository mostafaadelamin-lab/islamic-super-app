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
  String get appName => 'رتّل';

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
  String get homeNextPrayer => 'الصلاة القادمة';

  @override
  String get homeQuickLinks => 'روابط سريعة';

  @override
  String get homeWelcome => 'السلام عليكم';

  @override
  String get navBookmarks => 'العلامات';

  @override
  String get navHome => 'الرئيسية';

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
  String quranJuz(String juz) {
    return 'الجزء $juz';
  }

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
  String quranSurahN(String n) {
    return 'سورة $n';
  }

  @override
  String get quranSurahs => 'السور';

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
  String get tagline => 'القرآن والصلاة والذكر — مجاني بلا إعلانات';
}
