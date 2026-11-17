# **CANOPY CROSSING: iOS build (iPhone + iPad)**

**Store:** Apple App Store (test with TestFlight first).

| File | Use |
|---|---|
| `CanopyCrossing-iOS-XcodeProject.zip` | The Xcode project Godot exports (made on Linux) |
| `CanopyCrossing.ipa` | Appears here once the project is archived on a Mac |

**Finishing it needs macOS + Xcode** (your own Mac, a cloud Mac such as
MacinCloud or a GitHub Actions macOS runner) and a paid Apple Developer
account:

1. Unzip, open `CanopyCrossing.xcodeproj` in Xcode.
2. Signing & Capabilities: choose your Team (the export preset still has the
   placeholder Team ID `ABCDE12345`: put your real one in
   `export_presets.cfg` > iOS > `application/app_store_team_id`).
3. Product > Archive, then Distribute App > App Store Connect > Upload.
4. In App Store Connect the build appears under TestFlight after processing.

**Before Apple accepts it:** an app icon with no transparency (the current
1024 px icon has see-through corners), real StoreKit purchases instead of the
sandbox store, App Tracking Transparency only if ads track, and the privacy
details. See `../../LAUNCH/apple-app-store/`.
