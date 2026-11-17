# **CANOPY CROSSING: BUILDS**

Every platform has its own folder. Each holds that platform's game file(s),
a `README.md` (what it is, which stores take it, how to test it, what's left
before a store will accept it) and a `BUILD_INFO.json` (version, build
number, git commit, file sizes and SHA-256 checksums).

| Folder | What's in it | Stores | Made on |
|---|---|---|---|
| [`android/`](android/) | `.apk` (install on phones) + `.aab` (Google Play upload) | Google Play, Amazon Appstore, Samsung Galaxy Store | GitHub Actions (needs the Android SDK) |
| [`ios/`](ios/) | Xcode project (zip); `.ipa` once archived on a Mac | Apple App Store (TestFlight first) | Linux exports the project; a Mac archives it |
| [`windows/`](windows/) | `CanopyCrossing-Windows-x86_64.zip` (one `.exe`) | Steam, GOG, itch.io, Epic, Microsoft Store | Linux / GitHub Actions |
| [`macos/`](macos/) | `CanopyCrossing-macOS.zip` (universal `.app`) | Steam, GOG, itch.io, Epic, (Mac App Store) | Linux / GitHub Actions; signing + notarizing needs Apple |
| [`linux/`](linux/) | `CanopyCrossing-Linux-x86_64.zip` (one file) | Steam (+ Steam Deck), GOG, itch.io | Linux / GitHub Actions |
| [`web/`](web/) | the web version + `CanopyCrossing-Web.zip` | itch.io (HTML5), the beta testers' link | Linux / GitHub Actions |

## Make the builds

```bash
tools/build_all.sh                     # every platform this machine can build
tools/build_all.sh windows macos      # just these
python3 tools/set_version.py 1.0.0 2   # set the version + build number everywhere first
```

Or on GitHub: **Actions > Canopy Crossing release builds > Run workflow**
(`.github/workflows/canopy-crossing-release.yml`). It builds all six,
including Android, and offers each platform as its own download. Push a tag
like `canopy-release-v1.0.0` to also get a draft GitHub Release with every
file attached.

The game files themselves are not kept in git (each is 65-150 MB; GitHub
refuses files over 100 MB). Only the README.md and BUILD_INFO.json in each
folder are committed; the files are rebuilt from the source any time.
