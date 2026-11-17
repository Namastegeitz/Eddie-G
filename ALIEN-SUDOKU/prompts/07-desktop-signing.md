# 7. Signed desktop installers (optional)

**What it gives you:** no "Windows protected your PC" or "app is damaged" warnings.
The unsigned builds work fine for you and friends.

- **Windows:** without signing, click **More info → Run anyway**.
- **Mac:** without signing, run `xattr -cr "/Applications/Alien Sudoku.app"` once, or
  right-click the app → **Open**.

## Before you send it

- **Windows:** buy an Authenticode code-signing certificate (OV or EV) from a
  certificate authority, or set up Azure Trusted Signing. Export it as `.pfx` with a password.
- **Mac:** Apple Developer account (step 5). Create a **Developer ID Application**
  certificate and export it as `.p12`. Also create an app-specific password for your Apple ID.
- Add GitHub secrets:
  - `WIN_CSC_LINK`: base64 of the `.pfx`
  - `WIN_CSC_KEY_PASSWORD`
  - `MAC_CSC_LINK`: base64 of the `.p12`
  - `MAC_CSC_KEY_PASSWORD`
  - `APPLE_ID`
  - `APPLE_APP_SPECIFIC_PASSWORD`

## Prompt

```
Turn on code signing for the Alien Sudoku desktop builds: Windows with WIN_CSC_LINK /
WIN_CSC_KEY_PASSWORD and macOS with Developer ID signing + notarization (MAC_CSC_LINK,
MAC_CSC_KEY_PASSWORD, APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID). Update
desktop/package.json and the workflow, run it, and confirm the installers are signed.
```
