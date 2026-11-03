# 3. Real ads (AdMob)

**What it gives you:** ad income from the phone apps. Until then the apps show
Google's test ads, which pay nothing.

## Before you send it

1. Sign in at https://admob.google.com and accept the terms. Add your payment
   and tax info later, once there is income.
2. **Apps → Add app**, twice: "Alien Sudoku" for Android and "Alien Sudoku" for iOS
   ("Is the app listed on a store?" → No, for now). Copy each **App ID**
   (looks like `ca-app-pub-1234567890123456~1234567890`).
3. For each app, **Ad units → Add**:
   - **Banner** (adaptive)
   - **Interstitial**
   - **Rewarded** (reward: 1 "hint")

   That makes 6 ad unit ids (they look like `ca-app-pub-…/…`).
4. **Privacy & messaging**: create a **European regulations (GDPR)** message for both apps,
   and an **IDFA explainer** message for iOS. Publish them.
5. Have your developer website ready for `app-ads.txt` (step 6 can host it).

## Prompt (fill in the ids)

```
Set up real AdMob ads for Alien Sudoku (apps/alien-sudoku):
Android app id: ca-app-pub-...~...
iOS app id: ca-app-pub-...~...
Android banner / interstitial / rewarded: ca-app-pub-.../..., ca-app-pub-.../..., ca-app-pub-.../...
iOS banner / interstitial / rewarded: ca-app-pub-.../..., ca-app-pub-.../..., ca-app-pub-.../...
Publisher id for app-ads.txt: pub-...
Put the app ids in the native projects with tools/set-admob-ids.mjs, give me the exact
GitHub secret names and values to add for the unit ids (don't commit them to the repo),
add the full SKAdNetwork list from Google's iOS guide to Info.plist, create app-ads.txt,
rebuild, and update the docs.
```

Ad unit ids are not secret (they ship inside the app), but keeping them in GitHub
secrets keeps test and real builds separate.
