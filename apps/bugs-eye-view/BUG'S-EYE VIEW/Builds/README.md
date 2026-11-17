# **BUILDS**

Every platform's build in its own folder. Version 1.0.0 (build 1), exported 17 Nov 2026 from the same code.

| Platform | File | Size | For |
|---|---|---|---|
| [Windows](Windows/) | `BugsEyeView-windows.zip` | 47 MB | Steam, GOG, Epic, Microsoft, itch.io |
| [macOS](macOS/) | `BugsEyeView-macos.zip` | 69 MB | itch.io, GOG (Steam/Epic once notarized) |
| [Linux](Linux/) | `BugsEyeView-linux.zip` | 37 MB | Steam, GOG, itch.io |
| [Web](Web/) | `BugsEyeView-web.zip` | 21 MB | itch.io, playing in a browser |
| [Android](Android/) | `BugsEyeView-test.apk` | 68 MB | testing on phones (Google Play needs the signed .aab) |
| [iOS](iOS/) | Xcode project made at build time | - | App Store (built on a Mac or cloud Mac) |

Each folder's README says how to run the build and what each store needs.
Claude re-exports all of them with every update; the zips are under GitHub's 100 MB file limit.

**Remake them:** `tools/release/export_builds.sh` (Godot 4.7.2 with export templates; Android SDK for the APK).
