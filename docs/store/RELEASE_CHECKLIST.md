# «رتّل وصلِّ» — قائمة النشر النهائية

آخر تحديث: 2026-11-14 · فرع الإصدار: `release/1.1` · الترتيب: **App Store أولًا، بعدين Google Play**

## أ) قبل البناء (أنا)

- [x] دمج ثريد «إذاعة الحرم + اتجاه الطواف» (التطبيق والموقع).
- [x] دمج ثريد «تصميم الموقع للكمبيوتر» (الموقع بس).
- [x] رقم الإصدار **1.2.0** (رقم البناء في Codemagic = 1000 + عدّاد Codemagic، وفي ملف Android اليدوي = رقم pubspec).
- [x] كل الاختبارات (تطبيق + موقع) ناجحة (Flutter 595، الموقع 539).
- [x] زرار «قيّم التطبيق»: على الآيفون بيفتح App Store بس (ومخفي لحد ما يبقى فيه لينك)، وعلى Android بيفتح Google Play.
- [x] مزامنة الحساب مخفية في نسخ المتاجر (`RATTIL_STORE=true`).
- [x] الإيميل مش ظاهر جوه التطبيق، والتواصل بالفورم بس.
- [ ] الموقع النهائي على Bluehost (rattilwasalli.com).
- [ ] نسخة على `E:\Quaran-App-Project` + GitLab (`push-to-gitlab.bat`).

## ب) App Store (إنت، بالترتيب)

1. `push-to-gitlab.bat` (بعد ما أقولك إن النسخة النهائية جاهزة).
2. developer.apple.com ← Identifiers ← `org.rattil.app` (لو لسه).
3. App Store Connect ← New App: الاسم «رتّل وصلِّ»، Arabic، `org.rattil.app`، SKU `rattil-ios-001`.
4. مفتاح API (Users and Access ← Integrations ← App Manager) ← ملف `.p8` + Issuer ID + Key ID.
5. مفتاح الشهادة من Git Bash (الأمر في `STORE_RELEASE.md`).
6. Codemagic ← group `app_store_credentials` (4 قيم).
7. Codemagic ← Start build ← **iOS → TestFlight** ← الفرع `release/1.1`.
8. جرّب من TestFlight على الآيفون.
9. صفحة المتجر من `LISTING.md` + صور الشاشة (هجهزها) + Privacy Policy URL `https://rattilwasalli.com/privacy-policy.html` + Support URL `https://rattilwasalli.com/ar/help/`.
10. App Privacy حسب جدول `LISTING.md` (الاسم، التليفون، الرسالة، للرد بس، مفيش تتبع). Age Rating 4+. Free.
11. اختار البناء، واكتب ملاحظات المراجعة، و **Submit for Review** (إنت بنفسك، بعد ما نراجع مع بعض).

## ج) Google Play (بعد Apple)

1. رقم D-U-N-S لـ Zool Academy ← حساب Play كشركة ← 25$ ← التحقق.
2. Create app ← Internal testing ← ارفع ملف `.aab` النهائي (هبنيه بمفتاح الرفع) ← Google-generated signing key.
3. Store listing + App content (Data safety حسب `LISTING.md`، إقرار المنبهات الدقيقة و Foreground service للأذان).
4. Production بعد موافقتك.

## د) قبل النشر للعامة (قرارات مفتوحة)

- أصوات مؤذنين من إسلام ويب (علي ملا، محمد رفعت، الدغريري، العفاسي): شروطهم بتمنع إعادة النشر بدون إذن. لازم إذن مكتوب أو نشيلهم قبل Production.
- حساب Apple فردي: اسمك هو اللي هيظهر كناشر. لو عايز «Zool Academy»، نحوّله لحساب شركة بنفس رقم D-U-N-S.
