# **MACOS** build

| | |
|---|---|
| File | `BugsEyeView-macos.zip` (69 MB) - one Universal app (Apple silicon + Intel) |
| Version | 1.0.0 (build 1), exported 28 Nov 2026 |
| Runs on | macOS 11 Big Sur or newer |
| Stores | itch.io, GOG now; Steam and Epic once notarized |

## Play it
1. Unzip and move **Bug's-Eye View.app** to Applications.
2. The first time: **right-click > Open > Open** (the app isn't notarized yet, so a plain double-click is blocked).

## Notarizing (needed for Steam and Epic on Mac)
Needs the Apple Developer account from checklist phase 4 and a *Developer ID Application* certificate. Godot can notarize at export with `rcodesign` and an App Store Connect API key - no Mac required. Tell Claude when the account is ready.
