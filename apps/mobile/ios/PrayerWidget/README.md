# iOS prayer widgets (PrayerWidget)

Small (home screen), medium (home screen: the six times) and lock screen (iOS 16+) widgets.
Code: `PrayerWidget.swift`. The extension target `PrayerWidgetExtension` is in
`Runner.xcodeproj` (added by `tools/ios_add_widget_target.py`, no Mac needed). The app
writes the data (`lib/data/home_widget_sync.dart`, key `rattil.widget` in the App Group).

## One-time setup on developer.apple.com (a browser on any computer)

Signing fails until this is done, because the widget and the app share an App Group.

1. Certificates, Identifiers & Profiles → Identifiers → **+** → **App Groups** →
   description `Rattil`, identifier `group.org.rattil.app` → Register.
2. Identifiers → `org.rattil.app` → tick **App Groups** → Configure → tick
   `group.org.rattil.app` → Save (confirm). Keep CarPlay as it is.
3. Identifiers → **+** → App IDs → App → description `Rattil Widget`, Bundle ID (Explicit)
   `org.rattil.app.PrayerWidget` → tick **App Groups** → Continue → Register. Then open it,
   App Groups → Configure → tick `group.org.rattil.app` → Save.
4. Profiles: step 2 changed the app's capabilities, so its App Store profile must be made
   again: delete the old `org.rattil.app` App Store profile, **+** → App Store Connect →
   App ID `org.rattil.app` → certificate → (Entitlements: **CarPlay Audio**) → name → Generate.
5. Profiles → **+** → App Store Connect → App ID `org.rattil.app.PrayerWidget` →
   certificate → name → Generate.
6. Codemagic: run `ios-testflight` again (it fetches both profiles).

## الخطوات بالعربي (مرة واحدة، من أي متصفح)

1. في developer.apple.com ← Identifiers ← زر + ← App Groups ← المعرّف `group.org.rattil.app`.
2. افتح `org.rattil.app` ← فعّل App Groups ← Configure ← اختار `group.org.rattil.app` ← Save.
3. زر + ← App IDs ← App ← المعرّف `org.rattil.app.PrayerWidget` ← فعّل App Groups ← Register،
   وبعدين افتحه ← App Groups ← Configure ← اختار نفس الجروب ← Save.
4. Profiles: امسح بروفايل App Store القديم بتاع `org.rattil.app` واعمل واحد جديد بنفس الطريقة
   (مع CarPlay Audio في Entitlements).
5. اعمل بروفايل App Store جديد لـ `org.rattil.app.PrayerWidget`.
6. شغّل ios-testflight على Codemagic تاني.
