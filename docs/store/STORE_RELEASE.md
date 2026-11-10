# نشر تطبيق «رتّل» على App Store و Google Play

آخر تحديث: 2026-11-10 · الفرع: `feature/all-features`

## الفكرة باختصار

- **Codemagic** (موقع بناء مجاني 500 دقيقة/شهر) بيسحب الكود من GitLab، يبني نسخة iPhone ونسخة Android، ويرفعهم للمتاجر. مش محتاج Mac.
- كل البناءات **يدوية**: مفيش حاجة بتتبني أو تترفع لوحدها.
- اللي بيترفع **خاص** مش عام:
  - iPhone ← TestFlight بس (إنت والمختبرين اللي تضيفهم).
  - Android ← مسار «اختبار داخلي» كمسودة.
- **النشر للناس** خطوة يدوية منفصلة في App Store Connect و Play Console، ومش هتتعمل غير بعد موافقتك.

## ثوابت التطبيق (متتغيرش بعد أول رفع)

| البند | القيمة |
|---|---|
| Bundle ID (iPhone) | `org.rattil.app` |
| Package name (Android) | `org.rattil.app` |
| اسم التطبيق على الشاشة | رتّل |
| الإصدار الأول | 1.0.0 (رقم البناء بيزيد تلقائي من Codemagic) |
| أقل إصدار | iOS 13 · Android 7 (API 24) |

---

## خطوات لازم تعملها إنت (بالترتيب)

### أ) Apple (مرة واحدة)

1. ادخل https://developer.apple.com/account ← **Certificates, Identifiers & Profiles** ← **Identifiers** ← زرار **+** ← App IDs ← App.
   - Description: `Rattil` · Bundle ID: **Explicit** = `org.rattil.app` · سيب الـ Capabilities زي ما هي ← Register.
2. ادخل https://appstoreconnect.apple.com ← **Apps** ← **+** ← New App:
   - Platform: iOS · Name: `رتّل - القرآن والأذان` (لو الاسم محجوز جرّب `رتّل: مصحف وأذان`) · Primary language: Arabic · Bundle ID: `org.rattil.app` · SKU: `rattil-ios-001` · User access: Full Access.
3. اعمل **مفتاح API** (بدل كلمة السر، ومتبعتش كلمة السر لأي حد):
   App Store Connect ← **Users and Access** ← تبويب **Integrations** ← **App Store Connect API** ← Team Keys ← **+**
   - Name: `Codemagic` · Access: **App Manager** ← Generate.
   - انزّل ملف `AuthKey_XXXX.p8` (بيتنزّل **مرة واحدة بس**، احفظه في مكان آمن).
   - اكتب عندك: **Issuer ID** (فوق الجدول) و **Key ID** (جنب المفتاح).
4. اعمل مفتاح الشهادة (Certificate key) على جهازك: افتح **Git Bash** (اتثبت مع Git) واكتب:
   ```
   ssh-keygen -t rsa -b 2048 -m PEM -f ~/rattil_cert_key -q -N ""
   ```
   هيطلع ملف اسمه `rattil_cert_key` في مجلد المستخدم بتاعك. ده سرّي، متشاركهوش.

### ب) Google Play

5. أكّد إن حساب Google Play Developer شغال (https://play.google.com/console) وقولّي: **شخصي ولا شركة؟ واتعمل إمتى تقريبًا؟**
   (الحسابات الشخصية الجديدة لازم تعمل «اختبار مغلق» بـ 12 مختبر لمدة 14 يوم قبل النشر للعامة.)
6. في Play Console ← **Create app**: الاسم `رتّل - القرآن والأذان` · Default language: العربية · App · Free ← وافق على الإقرارات ← Create.

### ج) Codemagic (مرة واحدة)

7. سجّل في https://codemagic.io بحساب **GitLab** بتاعك ← **Add application** ← GitLab ← اختار `islamic-super-app` ← Flutter App ← هيلاقي ملف `codemagic.yaml` لوحده.
8. **Teams ← Personal Account ← Team settings ← codemagic.yaml settings ← Environment variables** ← اعمل مجموعة (group) اسمها `app_store_credentials` وفيها 4 متغيرات كلها **Secure**:
   | الاسم | القيمة |
   |---|---|
   | `APP_STORE_CONNECT_ISSUER_ID` | الـ Issuer ID من خطوة 3 |
   | `APP_STORE_CONNECT_KEY_IDENTIFIER` | الـ Key ID من خطوة 3 |
   | `APP_STORE_CONNECT_PRIVATE_KEY` | افتح ملف `.p8` بـ Notepad وانسخ كل اللي فيه |
   | `CERTIFICATE_PRIVATE_KEY` | افتح ملف `rattil_cert_key` بـ Notepad وانسخ كل اللي فيه |
9. **Code signing identities ← Android keystores ← Upload keystore**:
   - الملف: `E:\Quaran-App-Project\store\keys\rattil-upload.jks`
   - Reference name: `rattil_upload`
   - كلمة السر والـ alias: موجودين في `E:\Quaran-App-Project\store\keys\rattil-upload-keystore.txt`
   - احتفظ بالملفين دول في نسخة احتياطية (فلاشة/Drive خاص). لو ضاعوا يتعمل غيرهم عن طريق دعم جوجل، بس الموضوع بياخد أيام.

### د) أول بناء

10. في Codemagic ← التطبيق ← **Start new build** ← Branch: `feature/all-features`:
    - Workflow **iOS → TestFlight (private)**: هيبني نسخة iPhone ويرفعها لـ TestFlight (حوالي 20–30 دقيقة).
    - Workflow **Android → signed .aab (download only)**: هيبني ملف `.aab` نزّله من صفحة البناء.
11. **أول رفع على Google Play لازم يكون يدوي**: Play Console ← التطبيق ← **Testing ← Internal testing ← Create new release** ← ارفع ملف `.aab` ← Play App Signing: **Use Google-generated key** ← Save (متعملش Rollout قبل ما نراجع مع بعض).
12. على الآيفون: نزّل تطبيق **TestFlight** من App Store ← هتلاقي «رتّل» بعد ما Apple تخلّص المعالجة (10–30 دقيقة) ← جرّبه.

### هـ) بعد كده (اختياري، عشان Android يترفع أوتوماتيك)

13. Google Cloud: اعمل Service account وفعّل Google Play Android Developer API، نزّل مفتاح JSON، وفي Play Console ← **Users and permissions** ← Invite ← إيميل الـ service account ← صلاحية Release لتطبيق «رتّل».
    في Codemagic: group اسمها `google_play` فيها `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` = محتوى ملف JSON. بعدها استخدم Workflow **Android → Play internal testing (draft)**.

---

## قبل النشر للعامة (هنعملها مع بعض)

- **رابط سياسة الخصوصية** (إجباري في المتجرين) ورابط دعم: لازم صفحة **عامة**. المسودة جاهزة في `docs/store/privacy-policy.html`.
- **إيميل دعم** (إجباري في المتجرين، بيظهر للناس).
- **صور الشاشة**: iPhone 6.9" (1320×2868) وiPad 13" (2064×2752) و Android phone. هجهزها من التطبيق.
- بيانات صفحة المتجر: `docs/store/LISTING.md`.
- استبيان التصنيف العمري (Apple: 4+ · Google: IARC للجميع)، و Data safety / App Privacy (الإجابات في `LISTING.md`).
- Google Play بيطلب إقرار لاستخدام **المنبهات الدقيقة (Exact alarms)** و **Foreground service (تشغيل الأذان)**: السبب = الأذان في وقت الصلاة بالظبط. ممكن يطلبوا فيديو قصير يوضح الميزة.

## ملاحظات مهمة قبل المراجعة

- **مزامنة الحساب** مخفية في نسخ المتاجر (`--dart-define=RATTIL_STORE=true`) لحد ما السيرفر يتحط على استضافة؛ لأن Apple بترفض أي ميزة مش شغالة، ولو فيه تسجيل حساب لازم يبقى فيه حذف حساب.
- **أصوات المؤذنين** المأخوذة من موقع شروطه بتمنع إعادة النشر بدون إذن مكتوب (قرارك مسجل في `apps/mobile/assets/audio/ADHAN_AUDIO.md`): ده ممكن يعمل شكوى حقوق ملكية بعد النشر ويتشال التطبيق. الأفضل تاخد إذن مكتوب من الموقع أو نستخدم تسجيلات برخصة مفتوحة قبل النشر للعامة.
- Apple ساعات بترفض تطبيقات المصحف بحجة «فئة مزدحمة» (Guideline 4.3). ميزات «رتّل» الكتير (أذان، قبلة، ختمة، أحاديث، زكاة، قصص) بتساعد، وهنكتبها في ملاحظات المراجعة.
