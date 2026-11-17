# **COSMIC SAUCER DRIFT** · builds

Every build has its own folder. Version **1.0.0** (build 1) unless noted.
Rebuild any of them with `bash build_all.sh <name>` (see the top of the script).

| Folder | What's in it | Size | Built | Checked | Goes to |
|---|---|---|---|---|---|
| [`web/`](web/) | Browser build (Godot no-threads web export) | 46 MB | 2026-11-17 | Plays in the published page | itch.io (HTML5), web portals, your Claude page |
| [`android-apk-debug/`](android-apk-debug/) | Test APK, debug-signed | 61 MB | 2026-11-11 | Signature verified (APK Signature Scheme v2) | Your phone and testers only, never a store |
| [`android-aab-release/`](android-aab-release/) | **Empty.** The Play Store bundle (AAB) | – | – | Blocked here, see its README | Google Play, Samsung Galaxy Store, Amazon (Fire) |
| [`ios-xcode/`](ios-xcode/) | Xcode project in two zip parts | 100 MB | 2026-11-17 | Zip parts tested | Apple App Store (needs a Mac or a cloud Mac) |
| [`windows/`](windows/) | 64-bit Windows game (one .exe, zipped) | 42 MB | 2026-11-17 | Exported cleanly | Steam, GOG, itch.io, Epic, Microsoft Store |
| [`macos/`](macos/) | Universal (Intel + Apple Silicon) .app, **unsigned** | 64 MB | 2026-11-17 | Exported cleanly | Steam, GOG, itch.io (after signing and notarizing) |
| [`linux/`](linux/) | 64-bit Linux game, zipped | 33 MB | 2026-11-17 | Started and quit cleanly | Steam (and Steam Deck), GOG, itch.io |
| [`desktop-shortcuts/`](desktop-shortcuts/) | Desktop icons that open the web version | 4 MB | 2026-11-17 | – | Friends and family on a PC or Mac |

Notes
- Big files are zipped to stay under GitHub's 100 MB limit per file.
- Rebuilding replaces these files; git keeps the old ones in history.
- Signing keys and passwords never go in this folder or in git.
