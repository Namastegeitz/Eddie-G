# 4. Google Play release

**What it gives you:** Alien Sudoku on the Play Store.

## Before you send it

1. Create a Google Play developer account at https://play.google.com/console ($25 one time,
   ID verification can take a few days).
2. Host the privacy policy (`apps/alien-sudoku/docs/PRIVACY.md`, fill in your name and
   email). Step 6 can host it for you.
3. Steps 1 and 3 done: the app builds, and you have real ad ids.
4. Decide who keeps the **upload key**. Claude can generate it, but you must store the file and passwords
   somewhere safe (a password manager). If you lose it, Google can reset it,
   but that takes days.
5. Note: new personal accounts must run a **closed test with 12+ testers for 14 days**
   before they can publish to everyone.

## Prompt

```
Prepare the Alien Sudoku Google Play release (apps/alien-sudoku, id com.eddieg.aliensudoku).
Generate an upload keystore, tell me how to store it and which GitHub secrets to add
(ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD),
build the signed release AAB, and give me: the AAB file, phone screenshots (1080x1920) of the
menu, campaign, play and win screens, a 512x512 icon and a 1024x500 feature graphic, plus the
store listing text and Data safety answers from docs/STORE_CHECKLIST.md.
My privacy policy URL is: https://...
```
