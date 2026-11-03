# Alien Sudoku launch board

The game is built and playable. The steps below are waiting on something only
you can do: an account, a payment, an id, or a settings change. When a step's
"Before you send it" list is done, open that file and send its prompt to Claude
(Claude Code on this repo).

| # | Step | What you need first | Status |
|---|---|---|---|
| – | Play in a browser (phone or computer) | nothing | **Done**: https://claude.ai/artifact/NdYUzQJYiAGjCra9nF7MHn |
| – | Desktop apps (Windows, Mac, Linux) | nothing | **Done**: built in the cloud session and sent as files; rebuild with `desktop/` (RUN.md) |
| 1 | [Android APK on your phone](01-android-apk.md) | Allow `dl.google.com` in the cloud environment, **or** fix step 2 | Waiting |
| 2 | [Automatic builds (GitHub Actions)](02-github-actions.md) | Fix the GitHub account so Actions jobs can start (billing / spending limit) | Waiting |
| 3 | [Real ads (AdMob)](03-admob.md) | AdMob account, 2 apps, 6 ad units | Waiting |
| 4 | [Google Play release](04-google-play.md) | Play Console account ($25), privacy policy URL, steps 1 + 3 | Waiting |
| 5 | [iPhone / App Store (TestFlight)](05-ios-testflight.md) | Apple Developer account ($99/yr), App Store Connect API key, step 2 | Waiting |
| 6 | [Public website + installable web app](06-public-website.md) | Pick a host and give access (GitHub Pages, surge, Netlify) | Waiting |
| 7 | [Signed desktop installers](07-desktop-signing.md) (optional) | Code-signing certificates | Optional |

Suggested order: 1 (play on your phone soon) → 2 → 3 → 4 and 5 → 6.
