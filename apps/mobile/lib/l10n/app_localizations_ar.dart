// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get aboutFonts =>
      'الخطوط: خط المصحف — خط مجمع الملك فهد (حفص، الإصدار ١٨) دون أي تعديل وفق رخصة المجمع؛ خط الواجهة — IBM Plex Sans Arabic برخصة SIL المفتوحة ١٫١.';

  @override
  String get aboutOpenSource => 'مفتوح المصدر ومجاني للأبد. بلا تتبع ولا إعلانات ولا مشتريات داخل التطبيق.';

  @override
  String get aboutPages =>
      'صفحات المصحف وأسطره: مصحف المدينة، طبعة مجمع الملك فهد الجديدة (١٤٤١هـ)، وتقسيم الأسطر عبر quran-madina-html (رخصة الوقف العامة ٢٫٠) مع مطابقته ببيانات المجمع للصفحات والأسطر.';

  @override
  String get aboutPrayerAlgo =>
      'تُحسب المواقيت على الجهاز بالمعادلات الفلكية المعيارية (ميوس / المرصد البحري الأمريكي) وتُقارن بمكتبة adhan-js المستقلة.';

  @override
  String get aboutQuranText =>
      'نص القرآن: مجمع الملك فهد لطباعة المصحف الشريف، بيانات حفص العثمانية الإصدار ١٨ (hafsData_v18.json)، رواية حفص عن عاصم. مضمَّن كما نشره المجمع حرفيًا (حُذف رقم الآية الملحق فقط)، ويُتحقق منه ببصمة SHA-256.';

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
  String get adhanCredit => 'تسجيلات الأذان:';

  @override
  String get adhanDenied => 'الإشعارات غير مسموح بها. فعّلها من إعدادات النظام.';

  @override
  String get adhanEnable => 'نبّهني عند دخول وقت الصلاة';

  @override
  String get adhanExtras => 'تنبيهات قبل الأذان والإقامة';

  @override
  String get adhanExtrasNote => 'يصدر تنبيه قبل الأذان وتنبيه الإقامة بنغمة الهاتف القصيرة، وليس بصوت الأذان.';

  @override
  String get adhanFajrVoice => 'أذان الفجر';

  @override
  String get adhanFajrVoiceNote =>
      'أذان الفجر فيه «الصلاة خير من النوم»، لذلك له اختيار مستقل ويعمل وحده في وقت الفجر.';

  @override
  String get adhanIosNote =>
      'على الآيفون يُسمع التكبير الأول فقط في الإشعار (النظام يسمح بـ٣٠ ثانية بحد أقصى)، والأذان كاملًا بالصوت المختار داخل التطبيق.';

  @override
  String get adhanIqama => 'تنبيه الإقامة بعد الأذان';

  @override
  String adhanIqamaBody(String name, String minutes) {
    return 'إقامة صلاة $name بعد $minutes دقيقة من الأذان';
  }

  @override
  String adhanIqamaDecrease(String name) {
    return 'إنقاص دقيقة من إقامة $name';
  }

  @override
  String adhanIqamaIncrease(String name) {
    return 'زيادة دقيقة لإقامة $name';
  }

  @override
  String adhanIqamaMinutes(String n) {
    return '$n دقيقة بعد الأذان';
  }

  @override
  String adhanIqamaTitle(String name) {
    return 'حان موعد إقامة صلاة $name';
  }

  @override
  String get adhanNote =>
      'تُجدول على هذا الجهاز مسبقًا وتشتغل حتى لو التطبيق مقفول، ويجدّدها فتح التطبيق. لو التنبيه اتأخر، اسمح للتطبيق بـ«المنبّهات والتذكيرات» وأوقف توفير البطارية له.';

  @override
  String get adhanPlayOnSilent => 'تشغيل الأذان والهاتف صامت';

  @override
  String get adhanPlayOnSilentHint =>
      'يعمل الأذان بصوت المنبّه حتى لو كان الهاتف على الصامت أو الاهتزاز، مثل ساعة المنبّه. يخص الأذان الكامل فقط.';

  @override
  String get adhanPre => 'تنبيه قبل الأذان';

  @override
  String adhanPreBody(String name) {
    return 'استعد لصلاة $name';
  }

  @override
  String adhanPreMinutes(String n) {
    return 'قبل $n دقيقة';
  }

  @override
  String get adhanPreOff => 'بدون';

  @override
  String adhanPreTitle(String minutes, String name) {
    return 'بقي $minutes دقيقة على أذان $name';
  }

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
  String get adhanSoundGeneral => 'حسب الإعداد العام';

  @override
  String get adhanSoundPerPrayer => 'صوت التنبيه لكل صلاة';

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
  String get adhanVoice => 'مؤذن الصلوات';

  @override
  String get adhanVoiceBundled => 'موجود في التطبيق';

  @override
  String get adhanVoiceDownloadFailed => 'تعذّر تحميل الأذان. تأكد من الإنترنت وحاول مرة أخرى.';

  @override
  String get adhanVoiceDownloaded => 'محمّل على الموبايل';

  @override
  String adhanVoiceListen(String name) {
    return 'اسمع $name';
  }

  @override
  String get adhanVoiceNote =>
      'أذان الظهر والعصر والمغرب والعشاء. اختر المؤذن واضغط زر التشغيل لتسمعه؛ كل الأصوات محفوظة داخل التطبيق وتعمل بدون إنترنت.';

  @override
  String get adhanVoiceSearch => 'ابحث باسم المؤذن أو البلد';

  @override
  String get adhanVoiceTapToDownload => 'اضغط للتحميل';

  @override
  String get adhkarAfterPrayer => 'أذكار بعد الصلاة';

  @override
  String get adhkarAlafasy => 'بصوت الشيخ مشاري راشد العفاسي';

  @override
  String get adhkarArabicOnly => 'هذا المحتوى متاح بالعربية فقط.';

  @override
  String get adhkarAudioDownloadFailed => 'تعذّر تحميل التسجيل. تأكد من الإنترنت ثم أعد المحاولة.';

  @override
  String get adhkarAudioDownloading => 'جارٍ تحميل التسجيل لأول مرة (حوالي ٤ ميجا)، وبعدها يعمل بدون إنترنت.';

  @override
  String get adhkarAudioWatchOnline => 'استمع عبر الإنترنت';

  @override
  String get adhkarCards => 'بطاقة بطاقة';

  @override
  String get adhkarCopied => 'تم النسخ';

  @override
  String get adhkarCopy => 'نسخ';

  @override
  String get adhkarDaily => 'الأذكار اليومية';

  @override
  String get adhkarDone => 'تمّ';

  @override
  String get adhkarDuas => 'الأدعية';

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
  String adhkarItemOf(String n, String total) {
    return 'الذكر $n من $total';
  }

  @override
  String get adhkarList => 'عرض كقائمة';

  @override
  String get adhkarListen => 'استمع بصوت الشيخ مشاري العفاسي';

  @override
  String get adhkarListenHeader => 'استمع إلى الأذكار';

  @override
  String get adhkarMorning => 'الصباح';

  @override
  String get adhkarMorningTitle => 'أذكار الصباح';

  @override
  String get adhkarNextCard => 'التالي';

  @override
  String get adhkarOfflineNote => 'محفوظة على جهازك، تعمل بدون إنترنت.';

  @override
  String adhkarPercentDone(String p) {
    return 'تم $p٪';
  }

  @override
  String get adhkarPrevCard => 'السابق';

  @override
  String adhkarProgress(String done, String total) {
    return 'أُنجز $done من $total';
  }

  @override
  String adhkarRemaining(String n) {
    return 'متبقٍّ $n';
  }

  @override
  String get adhkarReminderEvening => 'تذكير بأذكار المساء';

  @override
  String get adhkarReminderMorning => 'تذكير بأذكار الصباح';

  @override
  String get adhkarReminders => 'تذكير الأذكار';

  @override
  String adhkarRepeat(String n) {
    return 'التكرار $n';
  }

  @override
  String adhkarRepeatTimes(String n) {
    return 'التكرار: $n';
  }

  @override
  String get adhkarReport => 'الإبلاغ عن خطأ';

  @override
  String get adhkarReportIntro => 'أظن أن في هذا الذكر خطأ (اكتب التفاصيل بالأسفل):';

  @override
  String get adhkarReportTitle => 'خطأ في ذكر';

  @override
  String get adhkarReset => 'البدء من جديد';

  @override
  String get adhkarReviewNotice =>
      'بانتظار المراجعة الشرعية. النصوص من مجموعة أذكار Kazi Shariar (CC BY 4.0) ومن حصن المسلم، وأعداد التكرار وفق حصن المسلم.';

  @override
  String get adhkarShare => 'مشاركة';

  @override
  String adhkarShareSourceChapter(String title, String n) {
    return 'حصن المسلم — $title (الباب $n)';
  }

  @override
  String adhkarShareSourceSession(String session) {
    return 'حصن المسلم — أذكار $session';
  }

  @override
  String get adhkarSleep => 'أذكار النوم';

  @override
  String get adhkarTapCounter => 'اضغط على الدائرة للعدّ، ولما يكمل العدد ينتقل للذكر اللي بعده';

  @override
  String get adhkarTapToCount => 'اضغط على البطاقة للعدّ';

  @override
  String get alertAdhkarEveningBody => 'حان وقت أذكار المساء';

  @override
  String get alertAdhkarEveningTitle => 'أذكار المساء';

  @override
  String get alertAdhkarMorningBody => 'حان وقت أذكار الصباح';

  @override
  String get alertAdhkarMorningTitle => 'أذكار الصباح';

  @override
  String get alertFriday => 'تذكير الجمعة (سورة الكهف)';

  @override
  String get alertFridayBody => 'تذكير بقراءة سورة الكهف والإكثار من الصلاة على النبي ﷺ';

  @override
  String get alertFridayTitle => 'يوم الجمعة';

  @override
  String get alertLastThird => 'تنبيه الثلث الأخير من الليل';

  @override
  String get alertLastThirdBody => 'بدأ الثلث الأخير من الليل';

  @override
  String get alertLastThirdTitle => 'الثلث الأخير من الليل';

  @override
  String get alertOthers => 'تنبيهات أخرى';

  @override
  String get alertSunrise => 'تنبيه عند الشروق';

  @override
  String alertSunriseBody(String city) {
    return 'أشرقت الشمس في $city، وانتهى وقت صلاة الفجر';
  }

  @override
  String get alertSunriseTitle => 'الشروق';

  @override
  String get appName => 'رتّل وصلِّ';

  @override
  String get asmaLess => 'أقل';

  @override
  String get asmaLessonBy => 'شرح الشيخ محمد راتب النابلسي';

  @override
  String get asmaListenLesson => 'استمع لشرح الاسم';

  @override
  String get asmaMore => 'المزيد';

  @override
  String asmaPart(String n) {
    return 'الدرس $n';
  }

  @override
  String get asmaSearch => 'ابحث عن اسم';

  @override
  String asmaSeeAlso(String name) {
    return 'يأتي شرحه مع: $name';
  }

  @override
  String get asmaSource => 'شرح مبسّط لأسماء الله الحسنى التسعة والتسعين، منقول بنصّه من مصدر منشور.';

  @override
  String get asmaStop => 'إيقاف';

  @override
  String get asmaTitle => 'أسماء الله الحسنى';

  @override
  String get audioBasmala => 'البسملة';

  @override
  String get audioClose => 'إغلاق المشغّل';

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
  String audioSpeed(String speed) {
    return 'سرعة التلاوة: $speed×';
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
  String get ayahCopy => 'نسخ الآية';

  @override
  String get ayahCopyShort => 'نسخ';

  @override
  String get ayahListen => 'استماع';

  @override
  String get ayahListenOne => 'استمع للآية المختارة فقط';

  @override
  String get ayahListenTafsir => 'استمع مع التفسير';

  @override
  String get ayahListenToPageEnd => 'استمع من هذه الآية إلى آخر الصفحة';

  @override
  String get ayahListenToSurahEnd => 'استمع من هذه الآية إلى آخر السورة';

  @override
  String get ayahMarkShort => 'علامة';

  @override
  String get ayahOnlyThis => 'الآية فقط';

  @override
  String get ayahSaveMark => 'حفظ علامة الآية';

  @override
  String get ayahShare => 'مشاركة';

  @override
  String get ayahShareImage => 'مشاركة كصورة';

  @override
  String get ayahTafsir => 'تفسير الآية';

  @override
  String get ayahToPageEnd => 'لآخر الصفحة';

  @override
  String get ayahToSurahEnd => 'لآخر السورة';

  @override
  String get ayahUnmarkShort => 'حذف العلامة';

  @override
  String get ayahWithTafsir => 'مع التفسير';

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
  String get contactFailed => 'تعذّر الإرسال. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.';

  @override
  String get contactIntro =>
      'اكتب طلبك وهيوصل لفريق العمل. لو عايز نرد عليك، اكتب رقم تليفونك أو الواتساب. لو سنك أقل من 13 سنة، خلّي حد من أهلك هو اللي يبعت الرسالة.';

  @override
  String get contactMessage => 'المحتوى';

  @override
  String get contactMessageRequired => 'اكتب رسالتك أولًا';

  @override
  String get contactName => 'الاسم';

  @override
  String get contactPhone => 'رقم التليفون (اختياري)';

  @override
  String get contactSend => 'إرسال';

  @override
  String get contactThanks => 'وصلت رسالتك، جزاك الله خيرًا.';

  @override
  String get contactTitle => 'عنوان الطلب';

  @override
  String get contactTitleRequired => 'اكتب عنوان الطلب';

  @override
  String get contactWhatsapp => 'رقم الواتساب (اختياري)';

  @override
  String get dhikrHadith => 'الحديث';

  @override
  String get dhikrHadithFadl => 'فضله';

  @override
  String get dhikrHadithSource => 'التخريج';

  @override
  String get dhikrHadithText => 'الحديث الوارد في هذا الذكر';

  @override
  String get dhikrListen => 'استمع لهذا الذكر';

  @override
  String get dhikrListenFailed => 'تعذّر التشغيل، تأكد من الإنترنت';

  @override
  String get dhikrListenStop => 'إيقاف الصوت';

  @override
  String get dhikrRemCancel => 'إلغاء';

  @override
  String get dhikrRemCustom => 'وقت تاني…';

  @override
  String get dhikrRemCustomTitle => 'كل كام دقيقة؟';

  @override
  String get dhikrRemEnable => 'تذكير بالذكر طول اليوم';

  @override
  String get dhikrRemEnableHint => 'يظهر على الشاشة، ولو الموبايل مش صامت يتقال بصوت الشيخ مشاري العفاسي';

  @override
  String get dhikrRemEvery => 'كل قد إيه؟';

  @override
  String get dhikrRemFrom => 'من';

  @override
  String get dhikrRemHour => 'ساعة';

  @override
  String dhikrRemHours(String n) {
    return '$n ساعات';
  }

  @override
  String dhikrRemIosCap(String n) {
    return 'آيفون بيسمح بعدد محدود من التنبيهات، فهتيجي كل $n دقيقة في الفترة دي';
  }

  @override
  String get dhikrRemListen => 'استمع';

  @override
  String dhikrRemMinutes(String n) {
    return '$n دقيقة';
  }

  @override
  String get dhikrRemNotifTitle => 'ذكر';

  @override
  String get dhikrRemOk => 'تم';

  @override
  String get dhikrRemPick => 'اختار الأذكار';

  @override
  String get dhikrRemPickHint => '(تتقال بالدور)';

  @override
  String get dhikrRemPickOne => 'اختار ذكر واحد على الأقل';

  @override
  String dhikrRemSummary(String count) {
    return '$count تذكير في اليوم';
  }

  @override
  String get dhikrRemTitle => 'تنبيهات الأذكار';

  @override
  String get dhikrRemTo => 'إلى';

  @override
  String get dhikrRemTwoHours => 'ساعتين';

  @override
  String get dhikrRemWindowHint => 'مفيش تنبيهات وقت النوم';

  @override
  String get downloadsCancel => 'إيقاف التحميل';

  @override
  String get downloadsDelete => 'حذف التحميل';

  @override
  String get downloadsDeleteAll => 'حذف الكل';

  @override
  String get downloadsDownload => 'تحميل السورة';

  @override
  String get downloadsFailed => 'تعذّر التحميل. تأكد من الاتصال وحاول مرة أخرى؛ الملفات اللي اتحمّلت محفوظة.';

  @override
  String get downloadsNote => 'السور المحمّلة تشتغل بدون إنترنت. التحميل للقارئ المختار حاليًا.';

  @override
  String downloadsReciter(String name) {
    return 'القارئ: $name';
  }

  @override
  String get downloadsTitle => 'تحميل التلاوات';

  @override
  String downloadsUsed(String mb) {
    return 'المساحة المستخدمة: $mb ميجابايت';
  }

  @override
  String get driveAgain => 'ابدأ من الأول';

  @override
  String get driveCarHint =>
      'تتحكم فيه من شاشة العربية أو أزرار الدركسيون أو شاشة القفل: التالي = الذكر اللي بعده، السابق = إعادة الذكر الحالي، والإيقاف يكمّل من نفس العدّة.';

  @override
  String driveCountOf(String n, String count) {
    return '$n من $count';
  }

  @override
  String get driveCues => 'صوت خفيف بين كل مرة والتانية';

  @override
  String get driveCuesSub => 'وصوت مختلف لما الذكر يخلص';

  @override
  String driveDhikrOf(String n, String total) {
    return 'الذكر $n من $total';
  }

  @override
  String get driveFailed => 'تعذّر تنزيل التسجيل. تأكد من الإنترنت وحاول مرة أخرى.';

  @override
  String get driveFinished => 'انتهت الأذكار، تقبّل الله منك.';

  @override
  String get driveNext => 'الذكر التالي';

  @override
  String get driveOpen => 'استمع أثناء القيادة';

  @override
  String get driveOpenSub => 'يكرر كل ذكر بعدده ويعدّ عنك';

  @override
  String driveOutOf(String count) {
    return 'من $count';
  }

  @override
  String get drivePause => 'إيقاف مؤقت';

  @override
  String get drivePlay => 'تشغيل';

  @override
  String get drivePreparing => 'جارٍ تجهيز التسجيل…';

  @override
  String get drivePrevious => 'أعد الذكر';

  @override
  String get driveRetry => 'حاول مرة أخرى';

  @override
  String get driveSayEvery => 'قول العدد بالصوت';

  @override
  String driveSayEveryN(String n) {
    return 'كل $n';
  }

  @override
  String get driveSayOff => 'لا';

  @override
  String get driveSettings => 'إعدادات وضع القيادة';

  @override
  String get driveTitle => 'وضع القيادة';

  @override
  String hadithAttribution(String name, String licence) {
    return 'الأحاديث بترقيم العالمية، من مشروع $name ($licence).';
  }

  @override
  String get hadithBackToBook => 'العودة إلى الكتاب';

  @override
  String get hadithBenefits => 'من فوائد الحديث';

  @override
  String hadithCount(String n) {
    return '$n حديثًا';
  }

  @override
  String get hadithExplain => 'الشرح المبسّط';

  @override
  String get hadithExplainLess => 'إخفاء بقية الشرح';

  @override
  String get hadithExplainMore => 'اقرأ الشرح كاملًا';

  @override
  String get hadithExplainSource => 'الشرح منقول بنصّه من موسوعة حديثية منشورة، وليس من كتابة التطبيق.';

  @override
  String hadithExplainedCount(String count) {
    return '$count حديثًا في هذا الكتاب لها شرح مبسّط';
  }

  @override
  String get hadithExplainedOnly => 'الأحاديث المشروحة';

  @override
  String get hadithFavourites => 'الأحاديث المحفوظة';

  @override
  String hadithGoTo(String max) {
    return 'اذهب إلى حديث رقم (١–$max)';
  }

  @override
  String hadithGrade(String grade) {
    return 'الدرجة: $grade';
  }

  @override
  String get hadithLoadError => 'تعذّر فتح هذا الجزء من الكتاب.';

  @override
  String get hadithNext => 'التالي';

  @override
  String get hadithNoFavourites => 'لم تحفظ أحاديث بعد. اضغط على النجمة بجانب أي حديث.';

  @override
  String hadithNumber(String n) {
    return 'حديث $n';
  }

  @override
  String hadithPageOf(String n, String total) {
    return 'الحديث $n من $total';
  }

  @override
  String get hadithPrev => 'السابق';

  @override
  String hadithRange(String from, String to, String count) {
    return 'الأحاديث $from–$to من $count';
  }

  @override
  String hadithResults(String n) {
    return '$n نتيجة';
  }

  @override
  String hadithResultsMany(String n) {
    return 'أول $n نتيجة (ضيّق البحث بكلمات أكثر)';
  }

  @override
  String get hadithReview =>
      'قيد المراجعة الشرعية: نصوص الأحاديث منقولة كما هي من قاعدة Open-Hadith-Data المفتوحة، ولم تُقابَل بعد بطبعة مطبوعة. إن وجدت خطأ فأبلغنا.';

  @override
  String get hadithSave => 'احفظ الحديث';

  @override
  String hadithSearch(String book) {
    return 'ابحث في $book';
  }

  @override
  String hadithSearching(String done, String total) {
    return 'جارٍ البحث… الجزء $done من $total';
  }

  @override
  String hadithSource(String book, String n) {
    return '$book، حديث رقم $n (ترقيم العالمية)';
  }

  @override
  String get hadithTitle => 'كتب السنة';

  @override
  String get hadithUnsave => 'إلغاء الحفظ';

  @override
  String get hajjCounterAdd => 'أتممت شوطًا';

  @override
  String get hajjCounterDone => 'اكتمل العدد — تقبّل الله';

  @override
  String get hajjCounterJamarat => 'عدّاد حصى الجمرات';

  @override
  String hajjCounterProgress(String n, String total) {
    return '$n من $total';
  }

  @override
  String get hajjCounterReset => 'تصفير';

  @override
  String get hajjCounterSai => 'عدّاد أشواط السعي';

  @override
  String get hajjCounterTawaf => 'عدّاد أشواط الطواف';

  @override
  String get hajjCounterUndo => 'تراجع';

  @override
  String get hajjCrowdBody =>
      'الهيئة العامة للعناية بشؤون المسجد الحرام والمسجد النبوي تعرض نسب الزحام في المطاف والمسعى لحظة بلحظة، وكذلك تطبيق نُسك الرسمي. اضغط لفتح المصدر الرسمي.';

  @override
  String get hajjCrowdNote => 'تفتح خارج التطبيق. صفحة الهيئة قد لا تفتح إلا من داخل المملكة العربية السعودية.';

  @override
  String get hajjCrowdNusuk => 'تطبيق نُسك';

  @override
  String get hajjCrowdOfficial => 'صفحة الهيئة الرسمية';

  @override
  String get hajjCrowdTitle => 'حالة الزحام في المطاف والمسعى الآن';

  @override
  String get hajjGuideCorrections => 'تصحيحات أخطاء الرقمنة';

  @override
  String get hajjGuideHajj => 'صفة الحج';

  @override
  String get hajjGuideSource => 'المصدر';

  @override
  String get hajjGuideTypes => 'أنواع النسك';

  @override
  String get hajjGuideUmrah => 'صفة العمرة';

  @override
  String get hajjHajj => 'الحج';

  @override
  String get hajjHubDuas => 'أدعية الحج والعمرة';

  @override
  String get hajjHubHajj => 'مناسك الحج';

  @override
  String get hajjHubIhram => 'المواقيت ومحظورات الإحرام';

  @override
  String get hajjHubUmrah => 'خطوات العمرة وخريطة الطواف';

  @override
  String get hajjHubUmrahSub => 'خطوات العمرة خطوة خطوة';

  @override
  String get hajjIfrad => 'الإفراد';

  @override
  String get hajjIhram => 'الإحرام';

  @override
  String get hajjKindIfrad => 'حج الإفراد';

  @override
  String get hajjKindQiran => 'حج القِران';

  @override
  String get hajjKindSub => 'الخطوات بالترتيب، خطوة خطوة';

  @override
  String get hajjKindTamattu => 'حج التمتع';

  @override
  String get hajjLiveTitle => 'بث مباشر من الحرمين (صوت)';

  @override
  String get hajjMadinah => 'زيارة المدينة';

  @override
  String get hajjOfficialGuide => 'شرح الخطوات من الدليل الرسمي';

  @override
  String get hajjQiran => 'القِران';

  @override
  String get hajjRef => 'المرجع';

  @override
  String get hajjReviewNotice =>
      'بانتظار المراجعة الشرعية: لم يراجع هذا الدليلَ عالمٌ مختص بعد. تحقّق من عالم موثوق قبل الاعتماد عليه.';

  @override
  String get hajjSayTitle => 'ما يُقال في هذه الخطوة';

  @override
  String get hajjSources => 'مصادر الدليل';

  @override
  String hajjStage(String n) {
    return 'المرحلة $n';
  }

  @override
  String get hajjStepNext => 'التالي';

  @override
  String hajjStepOf(String n, String total) {
    return 'الخطوة $n من $total';
  }

  @override
  String get hajjStepPrev => 'السابق';

  @override
  String get hajjStepsInOrder => 'خطوات الحج بالترتيب';

  @override
  String get hajjTagFirst => 'في الطواف الأول فقط';

  @override
  String get hajjTagMen => 'للرجال';

  @override
  String get hajjTagWomen => 'للنساء';

  @override
  String get hajjTamattu => 'التمتع';

  @override
  String get hajjTapStep => 'اضغط على أي خطوة لقراءة شرحها';

  @override
  String get hajjTapStepOne => 'اضغط على رقم الخطوة لعرضها';

  @override
  String hajjTimes(String n) {
    return '$n مرات';
  }

  @override
  String get hajjTitle => 'الحج والعمرة';

  @override
  String get hajjTypeLabel => 'نوع النسك';

  @override
  String get hajjUmrah => 'العمرة';

  @override
  String get helpA1 => 'نعم. لا إعلانات ولا اشتراكات ولا مشتريات، وسيبقى كذلك.';

  @override
  String get helpA2 =>
      'نص القرآن والتفسير ومواقيت الصلاة والقبلة والأذكار والسبحة والعلامات كلها تعمل دون اتصال. التلاوات تُبثّ من الإنترنت إلا إذا حفظت السور أولًا (المزيد ← التنزيلات).';

  @override
  String get helpA3 =>
      'تختلف المساجد في طريقة الحساب وتضيف دقائق للاحتياط. اختر طريقة بلدك ومذهب العصر من إعدادات الصلاة، وعدّل كل صلاة بالدقائق إن احتجت.';

  @override
  String get helpA4 => 'من الإعدادات ← التلاوة، أو من المشغّل نفسه أثناء التلاوة.';

  @override
  String get helpA5 =>
      'على هذا الهاتف فقط: العلامات والختمة ومتابعة العبادات والإعدادات لا تغادره إلا إذا فعّلت مزامنة الحساب بنفسك.';

  @override
  String get helpA6 =>
      'اسمح لتطبيق «رتّل وصلِّ» بالإشعارات، وفي أندرويد بـ«المنبهات والتذكيرات». بعض الهواتف توقف التطبيقات في الخلفية لتوفير البطارية: استثنِ «رتّل وصلِّ» من تحسين البطارية.';

  @override
  String get helpA7 =>
      'استخدم «الإبلاغ عن خطأ» تحت الذكر، أو راسلنا بالأسفل. النصوص الدينية مأخوذة من مصادر منشورة وتمر بمراجعة.';

  @override
  String get helpContact => 'تواصل معنا';

  @override
  String get helpContactPending => 'سيُضاف عنوان التواصل قريبًا.';

  @override
  String get helpEmail => 'راسلنا بالبريد';

  @override
  String get helpFaq => 'الأسئلة الشائعة';

  @override
  String get helpNotNow => 'ليس الآن';

  @override
  String get helpPromptBody => 'تستخدم «رتّل وصلِّ» منذ أيام. إن نفعك فشاركه مع غيرك، فهو مجاني للجميع.';

  @override
  String get helpPromptTitle => 'تشارك «رتّل وصلِّ»؟';

  @override
  String get helpQ1 => 'هل «رتّل وصلِّ» مجاني فعلًا؟';

  @override
  String get helpQ2 => 'ما الذي يعمل دون إنترنت؟';

  @override
  String get helpQ3 => 'لماذا تختلف المواقيت عن مسجدي؟';

  @override
  String get helpQ4 => 'كيف أغيّر القارئ أو السرعة؟';

  @override
  String get helpQ5 => 'أين تُحفظ بياناتي؟';

  @override
  String get helpQ6 => 'لماذا لم يُرفع الأذان؟';

  @override
  String get helpQ7 => 'وجدت خطأ في نص، ماذا أفعل؟';

  @override
  String get helpRate => 'قيّم «رتّل وصلِّ»';

  @override
  String get helpRatePending => 'التقييم متاح بعد نشر التطبيق في المتاجر.';

  @override
  String get helpShareApp => 'شارك «رتّل وصلِّ»';

  @override
  String get helpShareText => '«رتّل وصلِّ»: القرآن ومواقيت الصلاة والأذكار، مجانًا بلا إعلانات.';

  @override
  String get helpSpread => 'شارك وقيّم';

  @override
  String get helpSpreadBody => 'إن نفعك «رتّل وصلِّ» فشاركه مع أهلك وأصدقائك.';

  @override
  String get helpTitle => 'المساعدة والتواصل';

  @override
  String get hisnSectionFood => 'الطعام والصيام';

  @override
  String get hisnSectionHajj => 'الحج والعمرة';

  @override
  String get hisnSectionHardship => 'الهم والشدائد';

  @override
  String get hisnSectionHome => 'البيت واللباس';

  @override
  String get hisnSectionIllness => 'المرض والموت';

  @override
  String get hisnSectionMorningEvening => 'الصباح والمساء';

  @override
  String get hisnSectionNature => 'المطر والريح والهلال';

  @override
  String get hisnSectionPeople => 'الأهل والناس';

  @override
  String get hisnSectionPrayer => 'الطهارة والمسجد والصلاة';

  @override
  String get hisnSectionRemembrance => 'الذكر وفضله';

  @override
  String get hisnSectionSleep => 'النوم والاستيقاظ';

  @override
  String get hisnSectionTravel => 'السفر';

  @override
  String get hisnSectionAll => 'الكل';

  @override
  String get homeBigAdhkar => 'الأذكار والدعاء';

  @override
  String get homeBigHajj => 'الحج والعمرة';

  @override
  String get homeBigLibrary => 'مكتبة التلاوات';

  @override
  String get homeBigNasheeds => 'الأناشيد';

  @override
  String get homeBigPrayer => 'مواقيت الصلاة';

  @override
  String get homeBigQibla => 'اتجاه القبلة';

  @override
  String get homeBigQuran => 'القرآن الكريم';

  @override
  String get homeBigReels => 'فيديوهات إسلامية مختصرة';

  @override
  String get homeBigStories => 'قصص الأنبياء';

  @override
  String get homeBigTasbih => 'التسبيح';

  @override
  String get homeCalendar => 'تقويم الصلاة';

  @override
  String homeElapsed(String time) {
    return 'مضى $time';
  }

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
  String khatmaAhead(String n) {
    return 'متقدم $n ورد على الخطة، بارك الله فيك.';
  }

  @override
  String khatmaBehind(String n) {
    return 'متأخر $n يوم عن الخطة.';
  }

  @override
  String get khatmaByDays => 'عدد الأيام';

  @override
  String get khatmaByPages => 'عدد الصفحات يوميًا';

  @override
  String khatmaCurrentWird(String n, String total) {
    return 'الورد الحالي ($n من $total)';
  }

  @override
  String get khatmaDays => 'أختم خلال (يوم)';

  @override
  String khatmaDaysN(String n) {
    return '$n يومًا';
  }

  @override
  String get khatmaDefaultName => 'ختمتي';

  @override
  String get khatmaDelete => 'حذف الختمة';

  @override
  String get khatmaDeleteConfirm => 'حذف هذه الختمة؟ لا يمكن التراجع.';

  @override
  String khatmaEndsOn(String date) {
    return 'تختم في: $date';
  }

  @override
  String khatmaFinishedOn(String date, String days) {
    return 'خُتمت في $date خلال $days يومًا';
  }

  @override
  String get khatmaHistory => 'سجل الختمات';

  @override
  String get khatmaHistoryEmpty => 'ليس لديك ختمة كاملة بعد.';

  @override
  String khatmaJuz(String n) {
    return 'الجزء $n';
  }

  @override
  String get khatmaMarkDone => 'أتممت القراءة';

  @override
  String get khatmaName => 'اسم الختمة';

  @override
  String get khatmaNew => 'ختمة جديدة';

  @override
  String get khatmaOpenPlanner => 'مخطط الختمة الكامل';

  @override
  String get khatmaOpenPlannerSub => 'ختمة بعدد أيام، ورد يومي، تذكير، وسجل الختمات';

  @override
  String get khatmaOpening => 'من قوله تعالى:';

  @override
  String get khatmaPagesPerDay => 'صفحات كل يوم';

  @override
  String khatmaPreview(String wirds, String pages, String end) {
    return '$wirds وردًا، نحو $pages صفحة يوميًا، وتختم يوم $end.';
  }

  @override
  String khatmaRange(String fromSurah, String fromAyah, String fromPage, String toSurah, String toAyah, String toPage) {
    return 'من سورة $fromSurah آية $fromAyah صفحة $fromPage إلى سورة $toSurah آية $toAyah صفحة $toPage';
  }

  @override
  String get khatmaRead => 'اقرأ الورد';

  @override
  String get khatmaRemainingDays => 'الأيام المتبقية';

  @override
  String get khatmaRemainingWirds => 'الأوراد المتبقية';

  @override
  String get khatmaReminder => 'تذكير يومي بالورد';

  @override
  String khatmaReminderBody(String name) {
    return 'حان وقت وردك اليومي من «$name»';
  }

  @override
  String get khatmaReminderTitle => 'ورد الختمة';

  @override
  String get khatmaRename => 'تعديل';

  @override
  String get khatmaReschedule => 'أعد توزيع الأوراد';

  @override
  String get khatmaShowAll => 'عرض الكل';

  @override
  String get khatmaStart => 'ابدأ الختمة';

  @override
  String get khatmaTileSub => 'خطة يومية لختم المصحف';

  @override
  String get khatmaTitle => 'ختمة القرآن';

  @override
  String get kidsListen => 'استمع';

  @override
  String kidsMinutes(String n) {
    return '$n دقيقة';
  }

  @override
  String get kidsNote => 'قسم للأطفال: قصص الأنبياء، والمصحف المعلّم، وقصص هادفة، والرقية الشرعية للأطفال.';

  @override
  String get kidsOfflineNote => 'شاهد أو استمع لأي حلقة مباشرة، أو اضغط أيقونة التحميل لتعمل بدون إنترنت.';

  @override
  String get kidsOfflinePlaying => 'يعمل من النسخة المحفوظة على الجهاز';

  @override
  String get kidsProphets => 'قصص الأنبياء';

  @override
  String get kidsProphets3d => 'قصص الأنبياء: ثلاثي الأبعاد';

  @override
  String get kidsProphets3dSub => 'رسوم حديثة ثلاثية الأبعاد بالفصحى، بلا إظهار وجه النبي';

  @override
  String get kidsProphetsClassic => 'قصص الأنبياء: الحلقات الكاملة';

  @override
  String get kidsProphetsNew => 'قصص الأنبياء: رسوم حديثة';

  @override
  String get kidsProphetsNewSub => 'مُعلّمة تحكي القصة للأطفال، والنبي يظهر نورًا بلا ملامح';

  @override
  String get kidsProphetsPick => 'اختر المسلسل';

  @override
  String get kidsProphetsSub => 'حلقات كرتون، شاهد أو استمع، وحمّلها لتعمل بدون إنترنت';

  @override
  String get kidsRamadan => 'قصص قصيرة هادفة';

  @override
  String get kidsRamadanSub => 'كوميكس تعليمي قصير';

  @override
  String get kidsRasoul => 'قصص الرسول ﷺ للأطفال';

  @override
  String get kidsRasoulSub => 'مع الشيخ محمود المصري';

  @override
  String get kidsRuqyahSub => 'مقروءة ومسموعة';

  @override
  String kidsSize(String n) {
    return '$n ميجا';
  }

  @override
  String get kidsStories => 'قصص دينية وتعليمية';

  @override
  String get kidsStoriesSub => 'قصص من السيرة وقصص قصيرة هادفة';

  @override
  String get kidsTeacher => 'المصحف المعلّم للأطفال';

  @override
  String kidsTeacherAyah(String n) {
    return 'الآية $n';
  }

  @override
  String get kidsTeacherBigger => 'تكبير الخط';

  @override
  String get kidsTeacherHint => 'اضغط على أي كلمة لتسمعها، أو على رقم الآية لتسمعها وحدها.';

  @override
  String get kidsTeacherHusary => 'الحصري (المصحف المعلّم)';

  @override
  String get kidsTeacherMinshawy => 'المنشاوي مع ترديد الأطفال';

  @override
  String get kidsTeacherNext => 'الآية التالية';

  @override
  String get kidsTeacherNote => 'اختر السورة ليفتح المصحف: الشيخ يقرأ والكلمة تضيء، والطفل يردد وراءه.';

  @override
  String get kidsTeacherOpen => 'افتح المصحف';

  @override
  String get kidsTeacherPause => 'إيقاف';

  @override
  String get kidsTeacherPlay => 'اسمع السورة';

  @override
  String get kidsTeacherPrev => 'الآية السابقة';

  @override
  String get kidsTeacherRepeat => 'كرّر الآية ٣ مرات';

  @override
  String get kidsTeacherSmaller => 'تصغير الخط';

  @override
  String kidsTeacherStars(String n) {
    return 'نجومك في هذه السورة: $n';
  }

  @override
  String get kidsTeacherSub => 'الشيخ يقرأ الآية والأطفال يرددون وراءه';

  @override
  String kidsTeacherSurah(String name) {
    return 'سورة $name';
  }

  @override
  String get kidsTeacherWell => 'أحسنت! ختمت السورة وكسبت نجمة';

  @override
  String get kidsTeacherWord => 'الكلمة';

  @override
  String get kidsTitle => 'الأطفال';

  @override
  String get kidsVideoError => 'تعذّر تشغيل الفيديو. تأكد من الاتصال بالإنترنت أو حمّل الحلقة أولًا.';

  @override
  String get kidsWatch => 'شاهد';

  @override
  String get kidsYtNote => 'تُعرض من يوتيوب وتحتاج إنترنت';

  @override
  String get kidsLearnBooks => 'مكتبة كتب الأطفال';

  @override
  String get kidsLearnBooksNote => 'اختر كتابًا واقرأه صفحة صفحة. احفظ الكتاب على الجهاز ليُقرأ بدون إنترنت.';

  @override
  String get kidsLearnBooksSub => 'كتب مصورة: أذكار وعقيدة وأخلاق وقصص، تُقرأ صفحة صفحة';

  @override
  String get kidsLearnBoys => 'بنين';

  @override
  String get kidsLearnCardDone => 'قلته اليوم';

  @override
  String get kidsLearnCardMark => 'قلت هذا الذكر';

  @override
  String get kidsLearnCards => 'بطاقات الأذكار';

  @override
  String get kidsLearnCardsSub => 'بطاقات مصورة للأولاد والبنات، واجمع نجمة كل يوم';

  @override
  String kidsLearnCardsToday(String n) {
    return 'نجومك اليوم: $n';
  }

  @override
  String kidsLearnCredit(String name) {
    return 'الصور من $name';
  }

  @override
  String get kidsLearnDelete => 'احذف النسخة المحفوظة';

  @override
  String get kidsLearnGirls => 'بنات';

  @override
  String get kidsLearnHadith => 'احفظ حديث';

  @override
  String kidsLearnHadithNo(String n) {
    return 'الحديث $n';
  }

  @override
  String get kidsLearnHadithNote => 'احفظ حديثًا كل يوم. ابدأ بالمستوى الأول، وكرر الحديث حتى تحفظه ثم اضغط «حفظته».';

  @override
  String get kidsLearnHadithSub => '٦٠٠ حديث للحفظ في أربعة مستويات';

  @override
  String kidsLearnLevel(String n) {
    return 'المستوى $n';
  }

  @override
  String kidsLearnLevelSub(String from, String to) {
    return 'الأحاديث من $from إلى $to';
  }

  @override
  String get kidsLearnMarkMemorized => 'اضغط عندما تحفظه';

  @override
  String get kidsLearnMemorized => 'حفظته';

  @override
  String get kidsLearnNext => 'التالي';

  @override
  String get kidsLearnOffline => 'محفوظ على الجهاز';

  @override
  String kidsLearnPage(String n, String total) {
    return 'صفحة $n من $total';
  }

  @override
  String kidsLearnPages(String n) {
    return '$n صفحة';
  }

  @override
  String get kidsLearnPrev => 'السابق';

  @override
  String kidsLearnProgress(String n, String total) {
    return 'حفظت $n من $total';
  }

  @override
  String kidsLearnReads(String n) {
    return 'كررته $n مرة';
  }

  @override
  String get kidsLearnSalah => 'تعلّم الصلاة';

  @override
  String get kidsLearnSalahSub => 'خطوات الصلاة بالصور';

  @override
  String get kidsLearnSave => 'احفظ الكتاب على الجهاز';

  @override
  String get kidsLearnSaveFailed => 'تعذّر حفظ الكتاب. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.';

  @override
  String get kidsLearnShelfAdhkar => 'الأذكار والأدعية';

  @override
  String get kidsLearnShelfAkhlaq => 'الأخلاق والآداب';

  @override
  String get kidsLearnShelfAqeedah => 'العقيدة والإيمان';

  @override
  String get kidsLearnShelfFiqh => 'الطهارة والصلاة';

  @override
  String get kidsLearnShelfParents => 'للآباء والأمهات';

  @override
  String get kidsLearnShelfQuran => 'القرآن الكريم';

  @override
  String get kidsLearnShelfRamadan => 'رمضان';

  @override
  String get kidsLearnShelfStories => 'قصص الأنبياء والسيرة';

  @override
  String kidsLearnStep(String n, String total) {
    return 'الخطوة $n من $total';
  }

  @override
  String get kidsLearnStepsDone => 'أحسنت! أتممت كل الخطوات';

  @override
  String get kidsLearnWudu => 'تعلّم الوضوء';

  @override
  String get kidsLearnWuduSub => 'خطوات الوضوء بالصور';

  @override
  String get libraryAllRiwayat => 'كل الروايات';

  @override
  String get libraryEmpty => 'لا نتائج.';

  @override
  String get libraryLive => 'بث مباشر';

  @override
  String get libraryLoadError => 'تعذّر تحميل القائمة. تأكد من اتصالك بالإنترنت ثم أعد المحاولة.';

  @override
  String get libraryRadios => 'الإذاعات';

  @override
  String get libraryReciters => 'القرّاء';

  @override
  String get libraryRetry => 'إعادة المحاولة';

  @override
  String get libraryRewaya => 'الرواية';

  @override
  String get librarySearch => 'ابحث بالاسم';

  @override
  String get librarySource => 'التلاوات والإذاعات تُسمع عبر الإنترنت.';

  @override
  String librarySurahCount(String n) {
    return '$n سورة';
  }

  @override
  String librarySurahTitle(String reciter, String surah) {
    return '$reciter — سورة $surah';
  }

  @override
  String get libraryTitle => 'مكتبة التلاوات لجميع قراء القرآن الكريم';

  @override
  String get meaningsError => 'تعذّر تحميل معاني الكلمات.';

  @override
  String get meaningsLoading => 'جارٍ تحميل معاني الكلمات…';

  @override
  String get meaningsNoneAyah => 'لا توجد كلمات غريبة مشروحة في هذه الآية.';

  @override
  String get meaningsNonePage => 'لا توجد كلمات غريبة مشروحة في هذه الصفحة.';

  @override
  String meaningsOfAyah(String ref) {
    return 'معاني كلمات $ref';
  }

  @override
  String meaningsOfPage(String page) {
    return 'معاني كلمات الصفحة $page';
  }

  @override
  String get meaningsShort => 'المعاني';

  @override
  String get meaningsSource => 'من كتاب «السراج في بيان غريب القرآن» — محمد بن عبد العزيز الخضيري';

  @override
  String get meaningsTitle => 'معاني الكلمات';

  @override
  String get moreTitle => 'المزيد';

  @override
  String mosquesAround(String place) {
    return 'المساجد حول $place';
  }

  @override
  String mosquesCount(String n) {
    return '$n مسجد، الأقرب أولًا. اضغط على المسجد لفتح الاتجاهات.';
  }

  @override
  String get mosquesError => 'تعذّر الوصول إلى خريطة OpenStreetMap. تأكد من الاتصال بالإنترنت.';

  @override
  String get mosquesGeoFallback =>
      'تعذّر معرفة موقعك (افتح الـ GPS واسمح للتطبيق بالموقع). نعرض المساجد حول مدينة المواقيت.';

  @override
  String mosquesKm(String n) {
    return '$n كم';
  }

  @override
  String get mosquesLoading => 'جارٍ البحث عن المساجد…';

  @override
  String get mosquesLocate => 'حدّث موقعي';

  @override
  String get mosquesLocating => 'جارٍ تحديد موقعك…';

  @override
  String mosquesMeters(String n) {
    return '$n م';
  }

  @override
  String get mosquesMyLocation => 'موقعك الحالي';

  @override
  String get mosquesNone => 'لا توجد مساجد مسجلة على الخريطة في هذه المسافة. جرّب مسافة أكبر.';

  @override
  String get mosquesNote =>
      'المسافة في خط مستقيم. البيانات من خريطة OpenStreetMap المفتوحة وقد تكون ناقصة في بعض الأماكن.';

  @override
  String get mosquesOffline => '(آخر نتيجة محفوظة، أنت غير متصل)';

  @override
  String get mosquesOnGoogleMaps => 'افتح المساجد القريبة على خرائط جوجل';

  @override
  String get mosquesOpenApple => 'فتح في الخرائط';

  @override
  String get mosquesOpenGoogle => 'فتح في خرائط جوجل';

  @override
  String get mosquesOpenOther => 'فتح في تطبيق خرائط آخر';

  @override
  String get mosquesOpenWaze => 'فتح في Waze';

  @override
  String get mosquesRetry => 'إعادة المحاولة';

  @override
  String get mosquesTitle => 'المساجد القريبة';

  @override
  String get mosquesUnnamed => 'مسجد (بدون اسم على الخريطة)';

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
  String get mushafShareImage => 'مشاركة كصورة';

  @override
  String get mushafShareImageTitle => 'صورة الآية';

  @override
  String get mushafShareNow => 'مشاركة';

  @override
  String mushafSlider(String page) {
    return 'الصفحة $page من ٦٠٤';
  }

  @override
  String get mushafTapHint => 'اضغط على آية للاستماع أو الحفظ أو النسخ';

  @override
  String get mushafToggleControls => 'إظهار عناصر التحكم أو إخفاؤها';

  @override
  String get nasheedsArab => 'من العالم العربي';

  @override
  String nasheedsCount(String n) {
    return '$n نشيد';
  }

  @override
  String get nasheedsEgypt => 'من مصر';

  @override
  String get nasheedsLoadError => 'تعذّر تحميل قائمة الأناشيد.';

  @override
  String get nasheedsNext => 'النشيد التالي';

  @override
  String get nasheedsNote => 'استمع لأي نشيد مباشرة، أو اضغط أيقونة التحميل لتسمعه بدون إنترنت.';

  @override
  String get nasheedsPrev => 'النشيد السابق';

  @override
  String get nasheedsSearch => 'ابحث عن نشيد أو منشد';

  @override
  String get nasheedsTitle => 'أناشيد';

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
  String get navVideos => 'فيديوهات';

  @override
  String get offlineDone => 'تم الحفظ، يمكنك الاستماع بدون إنترنت';

  @override
  String get offlineDownload => 'تحميل للاستماع بدون إنترنت';

  @override
  String get offlineFailed => 'تعذّر التحميل، تحقّق من الإنترنت وحاول مرة أخرى';

  @override
  String get offlineSavedDelete => 'محفوظة على الهاتف — اضغط للحذف';

  @override
  String get parentLockAge13plus => '13 أو أكثر';

  @override
  String get parentLockAgeAsk => 'اختر فئتك العمرية';

  @override
  String get parentLockAgeTitle => 'قبل ما تفتح الفيديوهات';

  @override
  String get parentLockAgeUnder13 => 'أقل من 13';

  @override
  String get parentLockAnswer => 'الإجابة';

  @override
  String get parentLockBack => 'رجوع لفيديوهات الأطفال';

  @override
  String parentLockChallenge(String a, String b) {
    return 'سؤال للكبار: كام حاصل ضرب $a × $b؟';
  }

  @override
  String get parentLockChallengeWrong => 'الإجابة غلط';

  @override
  String get parentLockConfirm => 'اكتب الرقم مرة تانية للتأكيد';

  @override
  String get parentLockEnter => 'اكتب الرقم السري لفتح الفيديوهات';

  @override
  String get parentLockForgot => 'نسيت الرقم؟';

  @override
  String get parentLockHandOver => 'ادّي الموبايل لولي الأمر عشان يختار الرقم السري.';

  @override
  String get parentLockIntro =>
      'الفيديوهات والمقاطع القصيرة جاية من YouTube و Instagram، فهي مقفولة للأطفال ويفتحها ولي الأمر برقم سري.';

  @override
  String get parentLockKidsNote => 'دي فيديوهات قسم الأطفال. باقي الفيديوهات بيفتحها ولي الأمر بالرقم السري.';

  @override
  String get parentLockKidsTitle => 'فيديوهات للأطفال';

  @override
  String get parentLockLockNow => 'اقفل الفيديوهات';

  @override
  String get parentLockMismatch => 'الرقمين مش زي بعض، ابدأ من الأول';

  @override
  String get parentLockNext => 'التالي';

  @override
  String get parentLockParentOpen => 'ولي الأمر: افتح كل الفيديوهات';

  @override
  String get parentLockPin => 'الرقم السري';

  @override
  String get parentLockReset => 'اختار رقم جديد';

  @override
  String get parentLockSave => 'حفظ الرقم';

  @override
  String get parentLockSetTitle => 'ولي الأمر: اختار رقم سري من 4 أرقام';

  @override
  String get parentLockTitle => 'قفل ولي الأمر';

  @override
  String get parentLockUnlock => 'فتح';

  @override
  String get parentLockWrong => 'الرقم غلط، حاول تاني';

  @override
  String get playerOpen => 'ارجع لشاشة اللي شغال';

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
  String get prayerAutoLocation => 'تحديد الموقع تلقائيًا';

  @override
  String get prayerAutoLocationNote => 'يُحدَّث موقعك عند فتح التطبيق لتبقى المواقيت صحيحة إذا سافرت.';

  @override
  String get prayerBackToToday => 'العودة إلى اليوم';

  @override
  String get prayerCalendarTitle => 'تقويم الصلاة الشهري';

  @override
  String get prayerCity => 'المدينة';

  @override
  String get prayerClock => 'صيغة الوقت';

  @override
  String get prayerClock12 => '١٢ ساعة (١:٠٥ م)';

  @override
  String get prayerClock24 => '٢٤ ساعة (١٣:٠٥)';

  @override
  String get prayerCompactNote => 'لتغيير المدينة أو طريقة الحساب أو تنبيهات الأذان اضغط تعديل أوقات الصلاة.';

  @override
  String prayerCompassLabel(String deg) {
    return 'البوصلة: القبلة على $deg° باتجاه عقارب الساعة من الشمال';
  }

  @override
  String prayerDate(String date) {
    return 'التاريخ: $date';
  }

  @override
  String get prayerDayCol => 'اليوم';

  @override
  String prayerDecrease(String name) {
    return 'إنقاص دقيقة من $name';
  }

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerEditTimes => 'تعديل أوقات الصلاة';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerGeoDenied => 'رُفض إذن الموقع. اختر مدينة من القائمة بدلًا من ذلك.';

  @override
  String get prayerGeoUnavailable => 'تعذّر تحديد الموقع. تأكد من تشغيل خدمة الموقع أو اختر مدينة.';

  @override
  String get prayerGregorian => 'ميلادي';

  @override
  String prayerHighLat(String list) {
    return 'طُبّقت قاعدة خطوط العرض العليا على: $list';
  }

  @override
  String get prayerHijri => 'هجري';

  @override
  String get prayerHijriCol => 'هجري';

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
  String get prayerLocating => 'جارٍ تحديد الموقع…';

  @override
  String get prayerLocationServices => 'خدمات الموقع';

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
  String get prayerNextDay => 'اليوم التالي';

  @override
  String get prayerNextMonth => 'الشهر التالي';

  @override
  String get prayerNoPrayerToday => 'لا يمكن حساب المواقيت هنا اليوم (نهار أو ليل قطبي)';

  @override
  String get prayerNorth => 'ش';

  @override
  String get prayerOpenCalendar => 'التقويم الشهري';

  @override
  String get prayerPrevDay => 'اليوم السابق';

  @override
  String get prayerPrevMonth => 'الشهر السابق';

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
  String get prayerShareCalendar => 'مشاركة التقويم';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String prayerTimezone(String tz) {
    return 'المنطقة الزمنية: $tz';
  }

  @override
  String get prayerTitle => 'مواقيت الصلاة';

  @override
  String get prayerUseLocation => 'استخدم موقعي';

  @override
  String qiblaAccuracy(String n) {
    return 'دقة البوصلة الآن: ± $n°';
  }

  @override
  String get qiblaCalibrateBody =>
      'حرّك الهاتف في الهواء على شكل الرقم ٨ عدة مرات، وابتعد عن المعادن والأجهزة الكهربائية، وانزع الجراب إن كان فيه مغناطيس.';

  @override
  String get qiblaCalibrateTitle => 'البوصلة تحتاج معايرة';

  @override
  String qiblaDeclination(String deg) {
    return 'مع تصحيح فرق الشمال المغناطيسي عن الحقيقي: $deg°';
  }

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get qiblaDistance => 'المسافة إلى الكعبة';

  @override
  String get qiblaEast => 'ق';

  @override
  String get qiblaFacing => 'أنت متجه نحو القبلة';

  @override
  String qiblaHeading(String deg) {
    return 'اتجاه الهاتف: $deg°';
  }

  @override
  String get qiblaLiveNote =>
      'أمسك الهاتف أفقيًا بعيدًا عن المعادن والمغناطيس، وإن اضطربت القراءة فحرّكه على شكل الرقم ٨. تشير بوصلة الهاتف إلى الشمال المغناطيسي، ويصحّحها التطبيق إلى الشمال الحقيقي لمدينتك.';

  @override
  String get qiblaLocateFailed => 'تعذّر تحديد موقعك. فعّل خدمات الموقع وحاول مرة أخرى.';

  @override
  String get qiblaMapCheck => 'تأكّد من الاتجاه على خريطة جوجل للقبلة';

  @override
  String get qiblaPlaceNote => 'اتجاه القبلة محسوب لهذا الموقع. اضغط زر الموقع إن كنت في مكان آخر.';

  @override
  String get qiblaSouth => 'ج';

  @override
  String get qiblaStatic =>
      'لا تتوفر قراءة للبوصلة على هذا الجهاز: يبيّن الرسم اتجاه القبلة بالنسبة إلى الشمال الحقيقي.';

  @override
  String get qiblaTipsTitle => 'لقراءة دقيقة';

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
  String get qiblaWest => 'غ';

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
  String quranJuzInMushaf(String juz) {
    return 'افتح $juz في صفحات المصحف';
  }

  @override
  String quranJuzLine(String surah, String ayah, String page) {
    return 'يبدأ من $surah: $ayah - الصفحة $page';
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
  String get quranTabJuz => 'الأجزاء';

  @override
  String get quranTabQuarters => 'الأرباع';

  @override
  String get quranTabSurahs => 'السور';

  @override
  String get radioAll => 'كل الإذاعات';

  @override
  String get radioDuration => 'مدة التشغيل';

  @override
  String get radioListen => 'استماع';

  @override
  String get radioLiveNote => 'بث مباشر. اختار إذاعة تانية من القائمة أو من \"كل الإذاعات\".';

  @override
  String get radioLonger => 'زيادة المدة';

  @override
  String radioMin(String n) {
    return '$n دقيقة';
  }

  @override
  String get radioMushaf => 'إذاعة المصحف كاملًا بصوت القارئ';

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
  String get radiosFeatured => 'بث مباشر';

  @override
  String get radiosMore => 'إذاعات أخرى';

  @override
  String get radiosTitle => 'إذاعات القرآن الكريم';

  @override
  String get readerBack => 'رجوع إلى الفهرس';

  @override
  String get readerBasmalaNow => 'تُتلى البسملة الآن';

  @override
  String get readerBookmarks => 'إشارات مرجعية';

  @override
  String get readerExitFull => 'إظهار الأدوات';

  @override
  String get readerFont => 'حجم الخط';

  @override
  String get readerFontBigger => 'تكبير الخط';

  @override
  String readerFontSize(String size) {
    return 'حجم الخط: $size — اضغط للتكبير';
  }

  @override
  String get readerFontSmaller => 'تصغير الخط';

  @override
  String get readerFullHint => 'للتقليب: اسحب الصفحة أو اضغط السهمين. لإظهار الأدوات اضغط «إظهار الأدوات».';

  @override
  String get readerFullScreen => 'ملء الشاشة';

  @override
  String get readerGuide1 => 'اضغط على أي آية لتظهر خياراتها تحت الصفحة: استماع، تفسير الآية، علامة، نسخ، مشاركة.';

  @override
  String get readerGuide2 => 'للتقليب: اسحب الصفحة، أو استخدم شريط الصفحات تحتها.';

  @override
  String get readerGuide3 => 'زر «ملء الشاشة» في الشريط السفلي يخفي الأدوات، وزر «إظهار الأدوات» أعلى الصفحة يرجعها.';

  @override
  String get readerGuide4 => '«استماع مع التفسير» يعرض الصفحة وتفسيرها معًا أثناء التلاوة.';

  @override
  String get readerGuideTitle => 'طريقة استخدام المصحف';

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
  String get readerHideTafsir => 'إخفاء التفسير';

  @override
  String get readerHintClose => 'فهمت';

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
  String get readerNextJuz => 'الجزء التالي';

  @override
  String get readerNextPage => 'الصفحة التالية';

  @override
  String get readerNextSurah => 'السورة التالية';

  @override
  String get readerPickAyah => 'اضغط على أي آية لتظهر خياراتها هنا';

  @override
  String get readerPickJuz => 'اختر الجزء';

  @override
  String get readerPlayAyah => 'استمع للآية';

  @override
  String get readerPlayWithTafsir => 'استماع مع التفسير';

  @override
  String get readerPlayerHide => 'إخفاء المشغّل';

  @override
  String get readerPlayerShow => 'إظهار المشغّل';

  @override
  String get readerPrevJuz => 'الجزء السابق';

  @override
  String get readerPrevPage => 'الصفحة السابقة';

  @override
  String get readerPrevSurah => 'السورة السابقة';

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
  String get readerTabJuz => 'الجزء كاملاً';

  @override
  String get readerTabMushaf => 'المصحف';

  @override
  String get readerTabSurah => 'السورة كاملة';

  @override
  String get readerTabTafsir => 'التفسير';

  @override
  String get readerTafsirBeside => 'التفسير بجانب الصفحة';

  @override
  String get readerTafsirBesideJuz => 'التفسير بجانب الجزء';

  @override
  String get readerTafsirBesideShort => 'التفسير';

  @override
  String get readerTafsirBesideSurah => 'التفسير بجانب السورة';

  @override
  String readerZoomReset(String pct) {
    return '$pct٪ · الحجم العادي';
  }

  @override
  String get reelsAddChannel => 'أضف القناة';

  @override
  String get reelsCatAdmonition => 'نصائح ومواعظ';

  @override
  String get reelsCatLesson => 'درس ديني';

  @override
  String get reelsCatRecitation => 'تلاوة قرآنية';

  @override
  String get reelsEmpty => 'لا توجد مقاطع لعرضها الآن.';

  @override
  String get reelsFeed => 'مقاطع';

  @override
  String reelsHidden(String name) {
    return 'تم إخفاء $name';
  }

  @override
  String get reelsHide => 'إخفاء هذه القناة';

  @override
  String get reelsLoading => 'جارٍ جلب أحدث المقاطع…';

  @override
  String get reelsMyChannels => 'قنواتك';

  @override
  String get reelsNext => 'المقطع التالي';

  @override
  String get reelsNote =>
      'المقاطع معروضة من يوتيوب وإنستجرام بمشغّلاتها الرسمية، وتأتي تلقائيًا من قنوات إسلامية موثوقة اعتمدها التطبيق (تلاوات القرآن الكريم والدروس الدينية والنصائح والمواعظ).';

  @override
  String get reelsOffline => 'تعذّر الوصول إلى يوتيوب. تحقّق من الاتصال بالإنترنت ثم أعد المحاولة.';

  @override
  String get reelsOpenInstagram => 'افتح على إنستجرام';

  @override
  String get reelsOpenYoutube => 'افتح على يوتيوب';

  @override
  String get reelsPending => 'لم تتم مراجعة هذا المقطع شرعياً بعد — يظهر لك لأن وضع المراجعة مفعّل';

  @override
  String get reelsPlatformInstagram => 'إنستجرام';

  @override
  String get reelsPlatformYoutube => 'يوتيوب';

  @override
  String reelsPosition(String n, String total) {
    return 'المقطع $n من $total';
  }

  @override
  String get reelsPrev => 'المقطع السابق';

  @override
  String get reelsRemoveChannel => 'احذف القناة';

  @override
  String get reelsRetry => 'إعادة المحاولة';

  @override
  String reelsReviewedBy(String name) {
    return 'راجعه: $name';
  }

  @override
  String get reelsReviewerHint => 'لعرض المقاطع التي لم تُراجع بعد';

  @override
  String get reelsReviewerMode => 'وضع المراجعة';

  @override
  String get reelsSearch => 'ابحث عن قناة';

  @override
  String get reelsSearchHint => 'اكتب اسم القناة أو الشيخ';

  @override
  String get reelsSearchNone => 'لا توجد نتائج، أو لا يوجد اتصال بالإنترنت.';

  @override
  String get reelsShowHidden => 'إظهار القنوات المخفية';

  @override
  String get reelsSub => 'تلاوات ودروس ومواعظ من قنوات موثوقة';

  @override
  String get reelsSuggested => 'قنوات إسلامية مقترحة لك';

  @override
  String get reelsSuggestedHint => 'التطبيق بيضيف من القنوات دي تلقائيًا حسب اللي بتتفرج عليه أكتر.';

  @override
  String get reelsTapToPlay => 'اضغط للتشغيل';

  @override
  String get reelsTitle => 'ريلز إسلامية';

  @override
  String get reelsTrusted => 'قناة موثوقة';

  @override
  String get reelsUndo => 'تراجع';

  @override
  String ruqyahAyah(String surah, String n) {
    return '$surah: الآية $n';
  }

  @override
  String get ruqyahDua => 'من السنة';

  @override
  String ruqyahFrom(String surah, String from, String to) {
    return '$surah: الآيات $from–$to';
  }

  @override
  String get ruqyahFull => 'الرقية كاملة بصوت الشيخ مشاري العفاسي';

  @override
  String ruqyahFullSub(String n) {
    return '$n دقيقة · اضغط أيقونة التحميل لتسمعها بدون إنترنت';
  }

  @override
  String get ruqyahHeader => 'الرقية الشرعية';

  @override
  String get ruqyahKidsNote =>
      'ما كان النبي ﷺ يعوّذ به الحسن والحسين، ثم الفاتحة وآية الكرسي وخواتيم البقرة والإخلاص والمعوذتين، ثم رقية جبريل للنبي ﷺ. اقرأها على طفلك أو استمع لها.';

  @override
  String get ruqyahKidsTitle => 'الرقية الشرعية للأطفال';

  @override
  String get ruqyahListenQuran => 'استمع للآيات';

  @override
  String get ruqyahNote =>
      'آيات القرآن وأدعية السنة التي يُرقى بها، كما ذكرها أهل العلم. اقرأها أو استمع لها، واضغط على أي آية لترى تفسيرها.';

  @override
  String ruqyahRepeat(String n) {
    return 'تُقال $n مرات';
  }

  @override
  String get ruqyahTitle => 'الرقية الشرعية';

  @override
  String get settingsAbout => 'عن التطبيق';

  @override
  String get settingsAccount => 'الحساب والمزامنة';

  @override
  String get settingsAccountHint => 'اختياري — مزامنة العلامات بين الأجهزة';

  @override
  String get settingsAuto => 'تلقائي';

  @override
  String get settingsFontPreview => 'معاينة';

  @override
  String get settingsFontSize => 'حجم خط المصحف';

  @override
  String get settingsFree => 'تطبيق مجاني تم إنشاؤه لوجه الله تعالى، بدون مقابل وبدون إعلانات.';

  @override
  String get settingsHijriOffset => 'تعديل التاريخ الهجري';

  @override
  String get settingsHijriOffsetHint => 'أم القرى. عدّله بيوم أو يومين ليطابق الرؤية المعلنة في بلدك.';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageAr => 'العربية';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsManual => 'يدوي';

  @override
  String get settingsMushafPrinted => 'شكل المصحف المطبوع';

  @override
  String get settingsMushafPrintedDownload => 'حمّل خطوط كل الصفحات للقراءة بدون إنترنت';

  @override
  String get settingsMushafPrintedFailed => 'تعذّر التحميل، حاول مرة أخرى';

  @override
  String get settingsMushafPrintedHint =>
      'كل صفحة بخط مجمع الملك فهد الخاص بها، مثل المصحف الورقي تمامًا. تحتاج الصفحة إلى الإنترنت أول مرة فقط.';

  @override
  String settingsMushafPrintedProgress(String done, String total) {
    return 'جارٍ التحميل: $done من $total';
  }

  @override
  String get settingsMushafPrintedSaved => 'خطوط كل الصفحات محفوظة على الجهاز';

  @override
  String get settingsMushafSection => 'المصحف';

  @override
  String get settingsOurApps => 'تطبيقاتنا';

  @override
  String get settingsOurAppsSoon => 'تطبيقات أخرى قريبًا إن شاء الله';

  @override
  String get settingsPalette => 'لون التصميم';

  @override
  String get settingsPaletteEmerald => 'زمردي وذهبي';

  @override
  String get settingsPaletteMadinah => 'ليل المدينة';

  @override
  String get settingsPermissions => 'الصلاحيات والعمل في الخلفية';

  @override
  String get settingsPermissionsHint => 'الموقع، الإشعارات، البطارية، والأذان والهاتف صامت';

  @override
  String get settingsPrayerAutoHint => 'حسب موقعك وطريقة الحساب المعتمدة في بلدك';

  @override
  String get settingsPrayerManualHint => 'أنت تختار طريقة الحساب وتعدّل الدقائق بنفسك';

  @override
  String get settingsPrayerTimes => 'أوقات الصلاة';

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
  String get settingsTour => 'جولة تعريفية بالتطبيق';

  @override
  String get setupAppPage => 'صفحة التطبيق';

  @override
  String get setupBatteryAction => 'فتح إعداد البطارية';

  @override
  String get setupBatteryBody =>
      'حتى لا يوقف توفير البطارية الأذان والتطبيق مغلق: من القائمة اختر «رتّل وصلِّ» ثم «عدم التحسين» أو «غير مقيّد».';

  @override
  String get setupBatteryOem =>
      'في بعض الهواتف (شاومي، أوبو، ريلمي، هواوي، فيفو) فعّل كذلك «التشغيل التلقائي» أو «النشاط في الخلفية» من صفحة التطبيق.';

  @override
  String get setupBatteryTitle => 'العمل في الخلفية';

  @override
  String get setupDone => 'تم';

  @override
  String get setupExactBody => 'فعّل «المنبّهات والتذكيرات» لهذا التطبيق، وإلا قد يؤخر أندرويد الأذان بضع دقائق.';

  @override
  String get setupExactTitle => 'الأذان في الدقيقة نفسها';

  @override
  String get setupIntro =>
      'خطوات قليلة حتى تكون المواقيت صحيحة ويصلك الأذان في وقته حتى والتطبيق مغلق. يمكنك تغيير كل ذلك لاحقًا من الإعدادات.';

  @override
  String get setupLocationBody => 'لحساب مواقيت الصلاة واتجاه القبلة لمكانك. يُستخدم أثناء فتح التطبيق فقط.';

  @override
  String get setupLocationCity => 'اختيار مدينة';

  @override
  String get setupLocationDenied => 'لم يُسمح بالموقع. يمكنك اختيار مدينتك بدلًا منه.';

  @override
  String get setupLocationTitle => 'الموقع';

  @override
  String get setupLocationUnavailable => 'تعذّر تحديد الموقع الآن. تأكد من تشغيل الموقع في الهاتف أو اختر مدينتك.';

  @override
  String get setupLocationUse => 'استخدم موقعي';

  @override
  String get setupNotifAction => 'تفعيل الأذان';

  @override
  String get setupNotifBody => 'اسمح بالإشعارات حتى يصلك الأذان والتذكيرات.';

  @override
  String get setupNotifDenied => 'الإشعارات غير مسموح بها. افتح إعدادات التطبيق وفعّلها.';

  @override
  String get setupNotifTitle => 'تنبيه الأذان';

  @override
  String get setupOpenSettings => 'فتح الإعدادات';

  @override
  String get setupSilentIos =>
      'على الآيفون لا يسمح النظام لأي تطبيق بتشغيل صوت الإشعار وزر الصامت مفعّل (تسمح Apple بذلك لتطبيقات الطوارئ والصحة فقط). يظهر تنبيه الأذان بلا صوت؛ اترك زر الصامت مغلقًا لتسمع الأذان.';

  @override
  String get setupSilentTitle => 'الأذان والهاتف صامت';

  @override
  String get setupStart => 'ابدأ';

  @override
  String get setupTitle => 'تجهيز التطبيق';

  @override
  String shabibFromSurah(String name) {
    return 'ما تيسّر من سورة $name';
  }

  @override
  String get shabibLoadError => 'تعذّر تحميل قائمة التلاوات.';

  @override
  String get shabibMoshafs => 'حفص عن عاصم - مرتل (ما تيسّر) · تلاوات مجودة';

  @override
  String get shabibMujawwad => 'تلاوات مجودة';

  @override
  String get shabibMujawwadNote => 'تسجيلات حية من قرآن الفجر والإذاعة والأمسيات، مرتبة حسب السور.';

  @override
  String get shabibMurattal => 'مرتل';

  @override
  String get shabibMurattalNote => 'برواية حفص عن عاصم. بعضها مقطع من السورة وليس السورة كاملة.';

  @override
  String get shabibName => 'محمد أحمد شبيب';

  @override
  String get shabibNoMatch => 'لا توجد تلاوات لهذه السورة.';

  @override
  String shabibNote(String m, String j) {
    return 'لا يوجد للشيخ محمد أحمد شبيب رحمه الله تسجيل كامل للمصحف، فجمعنا هنا ما تيسّر من تلاواته: $m تلاوة مرتلة و$j تلاوة مجودة. استمع مباشرة أو اضغط أيقونة التحميل لتسمع بدون إنترنت.';
  }

  @override
  String get shabibReciter => 'الشيخ محمد أحمد شبيب';

  @override
  String get shabibShortSurahs => 'قصار السور';

  @override
  String shabibSurah(String name) {
    return 'سورة $name';
  }

  @override
  String shabibSurahs(String names) {
    return 'سور $names';
  }

  @override
  String get shabibTagFajr => 'قرآن الفجر';

  @override
  String get shabibTagOct73 => 'فجر ٦ أكتوبر ١٩٧٣';

  @override
  String get shabibTagRadio => 'تسجيل إذاعي';

  @override
  String sharawiAyah(String n) {
    return 'الآية $n';
  }

  @override
  String sharawiAyahs(String from, String to) {
    return 'الآيات $from–$to';
  }

  @override
  String get sharawiIntro => 'المقدمة';

  @override
  String sharawiLesson(String n) {
    return 'الدرس $n';
  }

  @override
  String sharawiLessons(String n) {
    return '$n درس';
  }

  @override
  String get sharawiLoadError => 'تعذّر تحميل قائمة دروس التفسير.';

  @override
  String sharawiMinutes(String n) {
    return '$n دقيقة';
  }

  @override
  String get sharawiNoMatch => 'لا توجد دروس لهذه السورة.';

  @override
  String sharawiNote(String n) {
    return 'خواطر الشيخ محمد متولي الشعراوي في تفسير القرآن الكريم بصوته، $n درسًا مرتبة حسب السور. استمع لأي درس مباشرة، أو اضغط أيقونة التحميل لتسمعه بدون إنترنت.';
  }

  @override
  String get sharawiSearch => 'ابحث باسم السورة أو رقمها';

  @override
  String get sharawiTitle => 'تفسير الشعراوي';

  @override
  String get shortcutAdhkar => 'الأذكار';

  @override
  String get shortcutPrayer => 'مواقيت الصلاة';

  @override
  String get shortcutQuran => 'المصحف';

  @override
  String get shortcutTasbih => 'السبحة';

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
  String get storiesHowTo =>
      'لكل حلقة: اضغط للاستماع، أو أيقونة الفيديو للمشاهدة، أو أيقونة التحميل للسماع بدون إنترنت.';

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
  String get storiesVideoBy => 'الشيخ نبيل العوضي';

  @override
  String get storiesWatchVideo => 'مشاهدة فيديو';

  @override
  String get studyBalagha => 'البلاغة';

  @override
  String get studyFawaid => 'الفوائد';

  @override
  String get studyGharib => 'غريب القرآن';

  @override
  String get studyGharibBook => 'من كتاب «السراج في بيان غريب القرآن»';

  @override
  String get studyIrab => 'الإعراب';

  @override
  String get studyIrabBook => 'من كتاب «الجدول في إعراب القرآن وصرفه وبيانه» لمحمود صافي';

  @override
  String get studyNoGharib => 'لم يذكر الكتاب كلمات غريبة في هذه الآية.';

  @override
  String studyNoPart(String part) {
    return 'لم يذكر الكتاب $part في هذه الآية.';
  }

  @override
  String get studyNotes => 'حواشي المحقق';

  @override
  String studyRange(String from, String to, String surah) {
    return 'الكتاب يشرح الآيات $from–$to من سورة $surah معًا.';
  }

  @override
  String get studyRetry => 'أعد المحاولة';

  @override
  String get studySarf => 'الصرف';

  @override
  String get studyTafsir => 'التفسير';

  @override
  String get surahInfoAbout => 'نبذة عن السورة';

  @override
  String get surahInfoAsbab => 'أسباب النزول';

  @override
  String get surahInfoAyahs => 'عدد الآيات';

  @override
  String get surahInfoMissing => 'المعلومات غير متاحة الآن.';

  @override
  String get surahInfoNoAsbab => 'لم يُذكر للسورة سبب نزول خاص في المصدر.';

  @override
  String get surahInfoOrder => 'ترتيب النزول';

  @override
  String get surahInfoPlace => 'مكان النزول';

  @override
  String get surahInfoTitle => 'عن السورة وأسباب نزولها';

  @override
  String get surahInfoWahidi => 'من كتاب «أسباب نزول القرآن» للواحدي';

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
  String get tafsirLibAyah => 'الآية';

  @override
  String get tafsirLibBooks => 'كتب التفسير';

  @override
  String get tafsirLibCompare => 'مقارنة التفاسير';

  @override
  String get tafsirLibCompareSub => 'كل التفاسير للآية نفسها تحت بعضها';

  @override
  String get tafsirLibDownload => 'تنزيل للقراءة بدون نت';

  @override
  String tafsirLibDownloading(String done) {
    return 'جارٍ التنزيل… $done من ١١٤ سورة';
  }

  @override
  String get tafsirLibDownloadsNote =>
      'كل كتاب يتنزّل مرة واحدة، وبعدها يفتح بدون إنترنت. وبدون تنزيل، تتنزّل كل سورة لما تفتحها.';

  @override
  String get tafsirLibDownloadsTitle => 'التنزيل للقراءة بدون نت';

  @override
  String get tafsirLibFailed => 'تعذّر التنزيل، حاول مرة أخرى.';

  @override
  String get tafsirLibInApp => 'موجود في التطبيق';

  @override
  String get tafsirLibIrabName => 'الجدول في إعراب القرآن وصرفه وبيانه';

  @override
  String get tafsirLibIrabSub => 'الإعراب والصرف والبلاغة والفوائد لكل آية';

  @override
  String get tafsirLibLenLong => 'مطوّل';

  @override
  String get tafsirLibLenMedium => 'متوسط';

  @override
  String get tafsirLibLenShort => 'مختصر';

  @override
  String get tafsirLibLess => 'اختصر';

  @override
  String get tafsirLibMore => 'اقرأ الكل';

  @override
  String get tafsirLibReadBook => 'افتح في الكتاب';

  @override
  String get tafsirLibRemove => 'حذف من الجهاز';

  @override
  String tafsirLibResults(String n) {
    return 'عدد النتائج: $n';
  }

  @override
  String get tafsirLibSaved => 'منزّل على جهازك';

  @override
  String get tafsirLibSearch => 'البحث في التفسير';

  @override
  String get tafsirLibSearchHint => 'اكتب كلمة أو جملة';

  @override
  String get tafsirLibSearchNeedsDownload => 'البحث في هذا الكتاب يحتاج تنزيله على جهازك أولًا.';

  @override
  String get tafsirLibSearchSub => 'ابحث عن كلمة داخل أي كتاب تفسير';

  @override
  String get tafsirLibSurah => 'السورة';

  @override
  String get tafsirLibTitle => 'التفسير';

  @override
  String get tagline => 'القرآن والصلاة والذكر — مجاني بلا إعلانات';

  @override
  String get tasbihAdd => 'إضافة';

  @override
  String get tasbihCancel => 'إلغاء';

  @override
  String get tasbihChangeDhikr => 'تغيير التسبيحة';

  @override
  String get tasbihChangeLook => 'شكل الخرز';

  @override
  String get tasbihClear => 'مسح';

  @override
  String get tasbihClearConfirm => 'مسح سجل التسبيح كله؟';

  @override
  String get tasbihClearHistory => 'مسح السجل';

  @override
  String get tasbihColor => 'اللون';

  @override
  String get tasbihCount => 'عدد التسبيحات';

  @override
  String tasbihCounter(String count, String target) {
    return 'العدد $count من $target';
  }

  @override
  String get tasbihHistory => 'السجل';

  @override
  String get tasbihHistoryEmpty => 'لا يوجد تسبيح مسجل بعد.';

  @override
  String get tasbihHistoryOpen => 'سجل التسبيحات';

  @override
  String get tasbihMine => 'أذكاري';

  @override
  String get tasbihMode => 'شكل العداد';

  @override
  String get tasbihModeBeads => 'خرز السبحة';

  @override
  String get tasbihModeButton => 'زر كبير';

  @override
  String get tasbihNewDhikr => 'اكتب ذكرًا تريد عدّه';

  @override
  String tasbihOfTarget(String n) {
    return 'من $n';
  }

  @override
  String get tasbihPhrase => 'الذكر';

  @override
  String get tasbihPickDhikr => 'اختر التسبيحة';

  @override
  String tasbihRemove(String name) {
    return 'حذف «$name»';
  }

  @override
  String get tasbihReset => 'تصفير';

  @override
  String tasbihRounds(String n) {
    return 'الدورات: $n';
  }

  @override
  String get tasbihSound => 'صوت مع كل تسبيحة';

  @override
  String get tasbihStyle => 'شكل الخرز';

  @override
  String get tasbihStyleCrystal => 'كريستال';

  @override
  String get tasbihStyleGlossy => 'لامع';

  @override
  String get tasbihStyleMarble => 'رخام';

  @override
  String get tasbihStylePearl => 'لؤلؤ';

  @override
  String get tasbihStyleWood => 'خشب';

  @override
  String get tasbihTap => 'اضغط للتسبيح';

  @override
  String get tasbihTarget => 'العدد المستهدف';

  @override
  String tasbihTimes(String n) {
    return '$n مرة';
  }

  @override
  String get tasbihTitle => 'المسبحة';

  @override
  String tasbihToday(String n) {
    return 'اليوم لهذا الذكر: $n';
  }

  @override
  String tasbihTotal(String n) {
    return 'الإجمالي: $n';
  }

  @override
  String get tasbihUndo => 'تراجع';

  @override
  String get tasbihVibrate => 'اهتزاز';

  @override
  String get tasbihVirtueSource => 'حصن المسلم';

  @override
  String get tourAdhkarBody => 'أذكار الصباح والمساء وحصن المسلم مسموعة، والمسبحة، وكتب الحديث، وأسماء الله الحسنى.';

  @override
  String get tourAdhkarTitle => 'الأذكار والحديث';

  @override
  String get tourBack => 'السابق';

  @override
  String get tourListenBody =>
      'إذاعات القرآن الكريم، وتفسير الشعراوي الصوتي، وقصص القرآن، ودروس ومقاطع من قنوات موثوقة.';

  @override
  String get tourListenTitle => 'استمع وتعلّم';

  @override
  String get tourNext => 'التالي';

  @override
  String tourPage(String n, String total) {
    return 'الصفحة $n من $total';
  }

  @override
  String get tourPrayerBody =>
      'مواقيت الصلاة حسب موقعك، وتنبيه بالأذان بصوت المؤذن الذي تختاره، واتجاه القبلة والمساجد القريبة.';

  @override
  String get tourPrayerTitle => 'مواقيت الصلاة والأذان';

  @override
  String get tourQuranBody =>
      'مصحف مجمع الملك فهد بصفحاته كاملة، والاستماع بأصوات عدد من القرّاء، والتفسير الميسر، وخطة لختم القرآن.';

  @override
  String get tourQuranTitle => 'المصحف الشريف';

  @override
  String get tourSkip => 'تخطي';

  @override
  String get tourWelcomeBody =>
      'تطبيق مجاني لوجه الله تعالى، بلا إعلانات ولا اشتراكات: القرآن الكريم والصلاة والأذكار في مكان واحد.';

  @override
  String get tourWelcomeTitle => 'أهلًا بك في «رتّل وصلِّ»';

  @override
  String get videosClearHistory => 'مسح السجل';

  @override
  String get videosHistory => 'عمليات البحث السابقة';

  @override
  String get videosNoResults => 'لا توجد فيديوهات إسلامية مطابقة. جرّب كلمات أخرى.';

  @override
  String videosRemoveHistory(String q) {
    return 'حذف «$q» من السجل';
  }

  @override
  String get videosSearch => 'بحث';

  @override
  String get videosSearchFailed => 'تعذّر البحث الآن. تحقّق من الاتصال بالإنترنت ثم أعد المحاولة.';

  @override
  String get videosSearchHint => 'ابحث عن تلاوة أو درس أو موعظة';

  @override
  String get videosSearchNote =>
      'نتائج البحث فيديوهات إسلامية فقط (تلاوات ودروس ومواعظ)، والقنوات الموثوقة أولًا. اضغط على الفيديو لتشغيله، أو اضغط مطولًا لفتحه في يوتيوب.';

  @override
  String worshipFasted(String n) {
    return 'أيام صيام: $n';
  }

  @override
  String get worshipFasting => 'صائم';

  @override
  String worshipFullDays(String n) {
    return 'أيام كاملة: $n';
  }

  @override
  String get worshipMonth => 'الشهر';

  @override
  String get worshipNote => 'ملاحظة';

  @override
  String worshipPrayedOf(String n, String total) {
    return '$n من $total صلاة';
  }

  @override
  String get worshipPrayers => 'الصلوات';

  @override
  String get worshipPrivate => 'البيانات محفوظة على جهازك فقط.';

  @override
  String worshipStreak(String n) {
    return 'أيام متتالية بالصلوات الخمس: $n';
  }

  @override
  String get worshipTitle => 'متابعة العبادات';

  @override
  String get worshipToday => 'اليوم';

  @override
  String get worshipWeek => 'آخر ٧ أيام';

  @override
  String get ytOfficialNote => 'يُشغَّل من القناة الرسمية على يوتيوب، ويحتاج إلى اتصال بالإنترنت.';

  @override
  String get zakatAdornment => 'ذهب الزينة';

  @override
  String get zakatAnimalCount => 'عدد الرؤوس';

  @override
  String get zakatBasis => 'احسب النصاب على';

  @override
  String get zakatBasisGold => 'الذهب (85 جرام)';

  @override
  String get zakatBasisSilver => 'الفضة (595 جرام)';

  @override
  String get zakatBelowNisab => 'لم يبلغ النصاب، فلا زكاة عليه';

  @override
  String get zakatCamels => 'إبل';

  @override
  String get zakatCattle => 'بقر';

  @override
  String get zakatCropsKg => 'وزن المحصول بعد الحصاد';

  @override
  String get zakatCropsNote => 'تُخرج يوم الحصاد.';

  @override
  String get zakatCropsRule => 'نصاب الزروع والثمار نحو 612 كيلو، وتُخرج عند الحصاد بلا انتظار عام.';

  @override
  String zakatDue(String zakat) {
    return 'الزكاة الواجبة: $zakat';
  }

  @override
  String zakatDueAnimals(String v) {
    return 'الزكاة الواجبة: $v';
  }

  @override
  String zakatDueCrops(String kg) {
    return 'الزكاة الواجبة: $kg كيلو من المحصول';
  }

  @override
  String zakatDueDetail(String net, String nisab) {
    return 'ربع العشر (٢٫٥٪) من $net، والنصاب $nisab.';
  }

  @override
  String get zakatDueEmpty => '—';

  @override
  String zakatDueGold(String g, String k) {
    return 'الزكاة الواجبة: $g جرام ذهب عيار $k';
  }

  @override
  String zakatDueMoney(String v) {
    return 'الزكاة الواجبة: $v جنيه';
  }

  @override
  String get zakatDueNone => 'لا زكاة';

  @override
  String zakatDueShortGrams(String g) {
    return '$g جرام';
  }

  @override
  String zakatDueShortKg(String kg) {
    return '$kg كيلو';
  }

  @override
  String zakatDueShortMoney(String v) {
    return '$v جنيه';
  }

  @override
  String zakatDueSilver(String g) {
    return 'الزكاة الواجبة: $g جرام فضة';
  }

  @override
  String zakatFatwa(String n) {
    return 'الفتوى رقم $n على موقع دار الإفتاء';
  }

  @override
  String get zakatFieldCash => 'النقود والأرصدة في البنك';

  @override
  String get zakatFieldCertificateReturns => 'عائد الشهادات الذي تضمه لرأس المال آخر العام';

  @override
  String get zakatFieldCertificates => 'الشهادات والودائع البنكية (أصل المبلغ)';

  @override
  String get zakatFieldDebts => 'ديون حالّة عليك (تُطرح)';

  @override
  String get zakatFieldGold18 => 'ذهب للادخار أو الاستثمار عيار ١٨ (جرام)';

  @override
  String get zakatFieldGold21 => 'ذهب للادخار أو الاستثمار عيار ٢١ (جرام)';

  @override
  String get zakatFieldGold24 => 'ذهب للادخار أو الاستثمار عيار ٢٤ (جرام)';

  @override
  String get zakatFieldShares => 'الأسهم المدخرة (قيمتها اليوم مع أرباحها)';

  @override
  String get zakatFieldTrade => 'بضاعة التجارة (بسعر السوق)';

  @override
  String get zakatGoldGrams => 'وزن الذهب المدّخر';

  @override
  String get zakatGoldPrice => 'سعر جرام الذهب عيار 24 بالجنيه (اختياري)';

  @override
  String get zakatGoldRule => 'نصاب الذهب 85 جرامًا من الذهب الخالص (عيار 24).';

  @override
  String get zakatGram => 'جرام';

  @override
  String get zakatGroupDebts => 'الديون عليك';

  @override
  String get zakatGroupGold => 'الذهب (بالجرام)';

  @override
  String get zakatGroupMoney => 'النقود والمدخرات';

  @override
  String get zakatIrrigated => 'تُروى بالآلات 5٪';

  @override
  String get zakatKarat => 'العيار';

  @override
  String get zakatKg => 'كيلو';

  @override
  String get zakatLivestockNote => 'للأنعام السائمة بعد مرور عام.';

  @override
  String get zakatLivestockRule =>
      'الأنعام السائمة (التي ترعى أكثر العام) إذا مرّ عليها عام. الإبل والغنم: كتاب الصدقة في صحيح البخاري (1454)، والبقر: حديث معاذ في سنن الترمذي (623).';

  @override
  String get zakatMoney => 'المال المدّخر (نقدًا وفي البنك)';

  @override
  String get zakatMoneyRule => 'النقود تُقاس على نصاب الذهب أو نصاب الفضة، واختار أي الطريقتين.';

  @override
  String get zakatNeedGoldPrice => 'اكتب سعر جرام الذهب عيار 24 عشان نحسب النصاب';

  @override
  String get zakatNeedPrice => 'اكتب سعر جرام الذهب عيار ٢١ ليُحسب النصاب.';

  @override
  String get zakatNeedSilverPrice => 'اكتب سعر جرام الفضة عشان نحسب النصاب';

  @override
  String zakatNisabIs(String v) {
    return 'النصاب الآن: $v جنيه';
  }

  @override
  String zakatNisabRule(String grams, String karat) {
    return 'النصاب قيمة $grams جرامًا من الذهب عيار $karat، فاكتب سعر الجرام من السوق يوم الحساب.';
  }

  @override
  String get zakatPrice => 'سعر جرام الذهب عيار ٢١ اليوم (بعملتك)';

  @override
  String get zakatPriceTitle => 'سعر الذهب اليوم';

  @override
  String get zakatRain => 'تُروى بلا تكلفة (مطر/نهر) 10٪';

  @override
  String get zakatResult => 'النتيجة';

  @override
  String get zakatReview =>
      'قيد المراجعة الشرعية: الحاسبة تتبع فتاوى دار الإفتاء المصرية المنشورة (روابطها بالأسفل)، ولم تراجعها جهة شرعية بعد. إن كانت حالتك غير واضحة فاسأل دار الإفتاء.';

  @override
  String get zakatSheep => 'غنم';

  @override
  String get zakatSilverGrams => 'وزن الفضة المدّخرة';

  @override
  String get zakatSilverPrice => 'سعر جرام الفضة الخالصة بالجنيه (اختياري)';

  @override
  String get zakatSilverRule => 'نصاب الفضة 595 جرامًا من الفضة الخالصة.';

  @override
  String zakatSources(String ref) {
    return 'المصادر: فتاوى $ref';
  }

  @override
  String get zakatTabCrops => 'زكاة المحاصيل';

  @override
  String get zakatTabGold => 'زكاة الذهب';

  @override
  String get zakatTabLivestock => 'زكاة الأنعام';

  @override
  String get zakatTabMoney => 'زكاة المال';

  @override
  String get zakatTabSilver => 'زكاة الفضة';

  @override
  String get zakatTileSub => 'زكاة المال على فتاوى دار الإفتاء المصرية';

  @override
  String get zakatTitle => 'حاسبة الزكاة';

  @override
  String zakatTotalAlso(String v) {
    return 'وأيضًا: $v';
  }

  @override
  String get zakatTotalEmpty => 'اكتب ما عندك في الأقسام فوق ليظهر الإجمالي هنا.';

  @override
  String get zakatTotalNone => 'لا زكاة عليك فيما كتبته';

  @override
  String get zakatTotalTitle => 'إجمالي الزكاة المطلوبة';

  @override
  String get zakatUnitBintLabun => 'بنت لبون';

  @override
  String get zakatUnitBintMakhad => 'بنت مخاض';

  @override
  String get zakatUnitHiqqa => 'حِقّة';

  @override
  String get zakatUnitJadhaa => 'جَذَعة';

  @override
  String get zakatUnitMusinna => 'مُسِنّة';

  @override
  String get zakatUnitSheep => 'شاة';

  @override
  String get zakatUnitTabi => 'تبيع';

  @override
  String get zakatWealth => 'مالك (بعملتك، والذهب بالجرام)';

  @override
  String zakatYearNotPassed(String net, String nisab) {
    return 'مالك ($net) بلغ النصاب ($nisab)، وتجب زكاته حين يمرّ عليه عام هجري كامل.';
  }

  @override
  String get zakatYearNote => 'تجب الزكاة إذا مرّ على المال عام هجري كامل وهو بالغ النصاب، ومقدارها ربع العشر (2.5٪).';

  @override
  String get zakatYearPassed => 'مرّ عام هجري كامل منذ بلغ مالي النصاب';
}
