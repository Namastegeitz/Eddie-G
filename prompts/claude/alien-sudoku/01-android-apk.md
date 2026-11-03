# 1. Android APK

**What it gives you:** Alien Sudoku installed on your Android phone like any
app, with ads (Google's test ads until step 3).

**Why it is waiting:** building an APK needs the Android SDK, which downloads
from `dl.google.com`. The cloud environment's network policy blocks that host,
and GitHub Actions (which could build it instead) can't start jobs yet (step 2).

## Before you send it (pick one)

- **Option A: allow the host (quickest).** In the Claude Code cloud session, open the
  environment menu in the title bar → **Edit** → **Network access**. Add
  `dl.google.com` under **Allowed domains** and leave **Allow package managers** ticked.
  Then start a **new** session on this repo so the setting applies.
  Docs: https://code.claude.com/docs/en/cloud-environments#network-access
- **Option B: GitHub Actions works again** (step 2). The workflow builds the APK by itself.

## Prompt

```
Build the Alien Sudoku Android app (apps/alien-sudoku) now that dl.google.com is allowed.
Install the Android command-line tools, platform 36 and build-tools with sdkmanager, then:
npm ci, npm run build, npx cap sync android, and ./gradlew assembleDebug in android/
(-PversionName=1.0.0). Check the APK with aapt2/apksigner, copy it to
apps/alien-sudoku/dist/android/AlienSudoku-1.0.0-debug.apk (commit it if under 100 MB),
send me the file, and update RUN.md and STATUS.md. Work on my Claude branch and push.
```

## Installing it on your phone

Open the APK on the phone (from the file Claude sends, or from GitHub). Allow
"Install unknown apps" for your browser or Files app when Android asks, then tap Install.
