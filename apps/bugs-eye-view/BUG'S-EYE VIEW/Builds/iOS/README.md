# **IPHONE AND IPAD** build

No finished file here: Apple builds must be signed by Xcode on a Mac, and the exported Xcode project is too big for git (about 390 MB, mostly the engine library).

## What's ready
- Export preset *iOS*: bundle ID `com.aethertek.bugseyeview`, version 1.0.0 (build 1), iPhone + iPad, arm64.
- Checked on 17 Nov 2026 by exporting the Xcode project in the cloud: it includes the UIScene manifest Apple now requires, `ITSAppUsesNonExemptEncryption = NO`, and a privacy manifest with tracking off and no data collected.
- Team ID is the placeholder `ABCDE12345`: replace it with yours (checklist phase 4).

## How the build gets made (pick one)
1. **GitHub Actions macOS runner (recommended):** Claude adds a workflow that exports the Xcode project with Godot, archives and signs it with your App Store Connect API key (stored as GitHub secrets) and uploads it to TestFlight.
2. **Codemagic:** a ready template is in [`docs/ci/codemagic.yaml`](../../../docs/ci/codemagic.yaml) - copy it to the repository root, connect the repo in Codemagic, add your App Store Connect API key and Team ID.
3. **A Mac for an afternoon:** install Xcode 26+, Godot 4.7.2 and its export templates; Project > Export > iOS > Export Project; open `BugsEyeView.xcodeproj`, Product > Archive > Distribute App.
