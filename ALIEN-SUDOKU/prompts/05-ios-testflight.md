# 5. iPhone: TestFlight and the App Store

**What it gives you:** Alien Sudoku on your iPhone through TestFlight, and later in the App Store.
iPhones can't install a downloaded app file the way Android phones can. Apple has to sign it.

## Before you send it

1. Join the Apple Developer Program: https://developer.apple.com/programs/ ($99/year).
2. In App Store Connect, go to **Apps → + → New App**: iOS, name "Alien Sudoku",
   bundle id `com.eddieg.aliensudoku` (register it under Certificates, Identifiers & Profiles
   if it isn't offered), SKU `alien-sudoku`.
3. **Users and Access → Integrations → App Store Connect API → +**: role **App Manager**.
   Download the `.p8` key (you only get one download). Note the **Key ID** and **Issuer ID**.
4. Find your **Team ID** (developer.apple.com → Account → Membership).
5. Add GitHub repository secrets (Settings → Secrets and variables → Actions):
   - `APPLE_TEAM_ID`
   - `ASC_KEY_ID`
   - `ASC_ISSUER_ID`
   - `ASC_KEY_P8_BASE64`: the output of `base64 -i AuthKey_XXXX.p8` on a Mac, or
     `[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXX.p8"))` in Windows PowerShell.
6. Step 2 (GitHub Actions) must work, because that is where the Mac build machine comes from.

## Prompt

```
The Apple secrets are in GitHub. Run the Alien Sudoku workflow so the iOS job archives,
signs and uploads to TestFlight, fix anything that fails, and tell me when the build shows
up in App Store Connect. Then give me the App Privacy answers, age rating answers and iPhone
6.9"/6.5" and iPad 13" screenshots for the App Store listing.
```

After the upload: install **TestFlight** from the App Store on your iPhone, accept the
invite email, and install Alien Sudoku.
