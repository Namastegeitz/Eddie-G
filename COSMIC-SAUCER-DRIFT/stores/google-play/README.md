# **COSMIC SAUCER DRIFT** · Google Play

Researched 17 Nov 2026 against Google's own pages (sources at the bottom).
**Cost:** US$25 once. **Time:** at least ~17 days, realistically 3–5 weeks, because
new personal accounts must run a 14-day closed test first.

## Already done (on this computer)
- Store text: name, short and full description, tags, content answers → [`../../game/docs/STORE_LISTING.md`](../../game/docs/STORE_LISTING.md)
- Icon 512×512 32-bit PNG → `game/docs/store/play_icon_512.png` (fixed to 32-bit on 17 Nov)
- Feature graphic 1024×500 → `game/docs/store/feature_graphic_1024x500.png`
- 14 landscape screenshots at 1280×720 → `game/docs/store/` (valid; see the 1080p note below)
- Privacy policy text → `game/docs/privacy-policy.html` (needs a public link)
- Export preset "Android AAB": Gradle build, **target SDK 36** (raised 17 Nov), min SDK 24,
  arm64-v8a + armeabi-v7a, category Game, no internet permission, back button handled
- Test APK for your phone → [`../../builds/android-apk-debug/`](../../builds/android-apk-debug/)

## Missing
- [ ] The signed **AAB**: needs your upload key + Android SDK platform 36 → [`../../builds/android-aab-release/`](../../builds/android-aab-release/)
- [ ] A public URL for the privacy policy
- [ ] 1920×1080 screenshots (needed only for Play's game promotion slots; Claude can render them)
- [ ] Safe-area check on notched phones (Android 16 forces edge-to-edge)

## Requirements today
| Item | Rule | For this game |
|---|---|---|
| Account | $25; legal name, address, ID; email + phone codes; Play Console app on an Android 10+ phone | Personal account is fine; no D-U-N-S needed |
| **Testing rule** | Personal accounts made after 13 Nov 2023: closed test with **≥12 testers opted in for 14 days in a row**, then "Apply for production" (decision usually ≤7 days) | Invite 15–20 so drop-outs don't sink you; ask them to really play |
| Format | Android App Bundle (AAB) | "Android AAB" preset |
| Target API | New apps and updates: **API 36** since 31 Aug 2026 (extension to 1 Nov has passed) | Done in the preset |
| 16 KB pages | Apps targeting 35+ must support 16 KB memory pages; updates without it blocked from 1 Feb 2027 | Godot 4.5+ templates are aligned (unverified); check in Play's App bundle explorer after upload |
| 64-bit | arm64-v8a required when 32-bit is included | On |
| Signing | Play App Signing; you keep the **upload key** (Google can reset a lost one) | Create once, back it up twice |
| Data safety | Required even for apps collecting nothing → "No data collected" | Answers in STORE_LISTING.md |
| Content rating | IARC questionnaire (free) | Cartoon/fantasy violence, no blood → likely PEGI 3–7 / ESRB E–E10+ |
| Target audience | Pick ages | 13+ keeps you out of the Families policy (cartoon art can still draw scrutiny) |
| Listing | Name 30, short 80, full 4000 chars; icon 512 (32-bit PNG, ≤1 MB); feature graphic 1024×500 (no alpha); 2–8 screenshots, 320–3840 px, ≤2:1 | All present |
| Promotion | ≥3 landscape 16:9 screenshots at ≥1920×1080 | Optional; render at 1080p |
| Android 16 | Edge-to-edge can't be turned off; predictive back | Keep HUD in the safe area; test Back on an Android 16 phone |

## Steps
1. Open a personal Play Console account ($25), verify ID, email, phone and device.
2. Create the upload key on your PC; export the signed AAB (or allow `dl.google.com` here and give Claude the key).
3. Host the privacy policy; fill every *App content* form (answers ready).
4. Create the app → internal test → closed test; invite 15–20 testers.
5. Keep ≥12 testers opted in for 14 days; fix what the pre-launch report and testers find.
6. Apply for production → release (review: hours to 7 days).

## Sources
- Target API: https://developer.android.com/google/play/requirements/target-sdk
- 16 KB pages: https://developer.android.com/guide/practices/page-sizes
- Testing rule: https://support.google.com/googleplay/android-developer/answer/14151465
- Account verification: https://support.google.com/googleplay/android-developer/answer/13634081
- Data safety / privacy policy: https://support.google.com/googleplay/android-developer/answer/10787469
- Content rating: https://support.google.com/googleplay/android-developer/answer/188189
- Target audience / Families: https://support.google.com/googleplay/android-developer/answer/9867159
- Listing graphics: https://support.google.com/googleplay/android-developer/answer/9866151
- App signing: https://developer.android.com/studio/publish/app-signing
- Godot export on Android: https://developer.android.com/games/engines/godot/godot-export
- Android 16 behaviour changes: https://developer.android.com/about/versions/16/behavior-changes-16
