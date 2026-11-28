# **WINDOWS** build

| | |
|---|---|
| File | `BugsEyeView-windows.zip` (47 MB) |
| Version | 1.0.0 (build 1), exported 28 Nov 2026 |
| Runs on | Windows 10/11, 64-bit, OpenGL 3.3 graphics |
| Stores | Steam, GOG, Epic, Microsoft Store (as MSIX), itch.io |

## Play it
1. Unzip, then double-click `BugsEyeView.exe` (one file - the game data is inside).
2. Windows SmartScreen may say *Windows protected your PC*: click **More info > Run anyway**. That appears for any unsigned game; a code-signing certificate removes it (optional, see Research).

Saves go to `%APPDATA%\BugsEyeView`.

## For the stores
- **Steam / Epic / GOG:** upload the unzipped `BugsEyeView.exe` as the Windows depot/build.
- **Microsoft Store:** wrap it as MSIX (checklist phase 8).
