# macOS build

`CosmicSaucerDrift-macos-universal-unsigned.zip` holds `Cosmic Saucer Drift.app`
(universal: Intel and Apple Silicon).

- **Unsigned and not notarized.** macOS will block it ("can't be opened") for most players.
  Before it goes to Steam, GOG or itch.io it needs a **Developer ID** signature and
  **notarization**. Both need the Apple Developer Program ($99/year). Then either:
  - on a Mac: `codesign` + `xcrun notarytool submit --wait` + `xcrun stapler staple`, or
  - set the Godot "macOS" preset's code signing and notarization fields and export again.
- To try it yourself now: right-click the app > Open, then confirm.
