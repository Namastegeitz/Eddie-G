# iOS Xcode project (App Store)

Godot exports an **Xcode project**. Turning it into an app for the App Store needs Xcode,
which runs only on a Mac: your own, or a cloud Mac (Codemagic, GitHub Actions macOS runners,
MacinCloud).

Already in it: bundle id `com.aethertek.cosmicsaucerdrift`, version 1.0.0 (1), iPhone + iPad,
landscape, an opaque 1024 px app icon (Apple refuses icons with transparency), and Godot's
privacy manifest (`PrivacyInfo.xcprivacy`).

**On the Mac**
1. Put both parts in one folder and join them:
   `zip -s 0 CosmicSaucerDrift-ios-xcode.zip --out ios-project.zip && unzip ios-project.zip -d CosmicSaucerDrift-ios`
2. Open `CosmicSaucerDrift.xcodeproj` in the current Xcode.
3. Signing & Capabilities: choose your team (Apple Developer Program). Replace the
   placeholder Team ID `ABCDE12345` in the Godot "iOS" preset next time you export.
4. Product > Archive, then Distribute App > App Store Connect > Upload.
5. In App Store Connect: TestFlight first, then submit for review.
