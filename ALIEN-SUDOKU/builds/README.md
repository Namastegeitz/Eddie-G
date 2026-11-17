# Builds

One folder per platform. Each folder's README says what's built, how to rebuild it, and what its store needs.

| Folder | Status |
|---|---|
| [web](web/README.md) | ✅ Built Web (browser) |
| [itch-io](itch-io/README.md) | ✅ Built itch.io (and other HTML5 stores) |
| [android](android/README.md) | ⛔ Blocked here Android (Google Play) |
| [ios](ios/README.md) | ⛔ Blocked here iPhone and iPad (App Store) |
| [windows](windows/README.md) | ✅ Built (unsigned) Windows |
| [macos](macos/README.md) | ✅ Built (unsigned) macOS |
| [linux](linux/README.md) | ✅ Built Linux |
| [steam](steam/README.md) | ⬜ Not started Steam |
| [gog](gog/README.md) | ⬜ Not started GOG |
| [microsoft-store](microsoft-store/README.md) | ⬜ Not started Microsoft Store |
| [epic](epic/README.md) | ⬜ Optional Epic Games Store |

Large builds (desktop, about 100 MB each) sit in each folder's `files/`, which git ignores. The web builds are small and are committed.
