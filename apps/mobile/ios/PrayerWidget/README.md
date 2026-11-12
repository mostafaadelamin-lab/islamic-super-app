# iOS home-screen widget (PrayerWidget)

The Swift code is ready (`PrayerWidget.swift`), but the extension target has to be
added once in Xcode on a Mac. After that, Codemagic builds it with the app.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File → New → Target → **Widget Extension**. Name it `PrayerWidget` and untick
   "Include Configuration Intent". Delete the files Xcode generates, then add
   `PrayerWidget.swift` from this folder to the target.
3. Runner target → Signing & Capabilities → + **App Groups** → `group.org.rattil.app`.
   Do the same for the PrayerWidget target.
4. On developer.apple.com, register the App Group `group.org.rattil.app` and the
   bundle id `org.rattil.app.PrayerWidget`. Refresh the provisioning profiles
   (Codemagic: re-fetch the signing files).
5. Set the PrayerWidget deployment target to iOS 14 or later.

The app already writes the data (`lib/data/home_widget_sync.dart`, key `rattil.widget`
in the App Group). Nothing else changes.
