# Google Play and other Android stores - requirements

Researched 2026-11-17 from support.google.com/googleplay/android-developer,
developer.android.com and the Godot docs. Check the linked page before acting
on anything that changes often.

## Google Play, zero to production
| # | Step | Who / cost / time | Requirement |
|---|---|---|---|
| 1 | Developer account | You, **US$25 once**, credit/debit card, 18+, choose **Personal** | [get started](https://support.google.com/googleplay/android-developer/answer/6112435) |
| 2 | Identity + payments profile | You: legal name, address, **government ID** (fee not refunded if the ID is invalid) | Your legal name, country and developer email are shown publicly; address only if you sell ([required info](https://support.google.com/googleplay/android-developer/answer/13628312)) |
| 3 | Contact + device checks | You: email/phone codes; sign in to the Play Console app on a real Android 10+ phone | [device verification](https://support.google.com/googleplay/android-developer/answer/14316361) |
| 4 | Trader status (EEA/UK) | You, **by 1 Feb 2027**; a free hobby game is probably non-trader | [trader status](https://support.google.com/googleplay/android-developer/answer/17594752) |
| 5 | Create the app | Name, package `com.aethertek.bugseyeview` (permanent), Game, Free, contact email, accept Play App Signing | [create app](https://support.google.com/googleplay/android-developer/answer/9859152) |
| 6 | Store listing + App content forms | Text and images ready in this folder | below |
| 7 | Internal test (optional) | Up to 100 testers, instant | [tracks](https://support.google.com/googleplay/android-developer/answer/9845334) |
| 8 | **Closed test (required)** | **At least 12 testers opted in for 14 days in a row** (personal accounts made after 13 Nov 2023). Keep their feedback - the application asks for it | [testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465) |
| 9 | Apply for production | Dashboard -> Apply for production; usually <= 7 days | |
| 10 | Production release + review | Up to 7 days or longer | [publish](https://support.google.com/googleplay/android-developer/answer/9859751) |

Realistic minimum: about 3-5 weeks (verification + 14-day test + reviews).

## Technical
- **Target API 36 (Android 16)** for new apps and updates since 31 Aug 2026 ([target API](https://support.google.com/googleplay/android-developer/answer/11926878)). **Done:** the AAB preset now targets 36 (it was 35). Next bump not announced (likely API 37 around Aug 2027).
- Android 16: edge-to-edge always on, predictive back on; games keep orientation locks on large screens (keep `package/app_category = Game`).
- **64-bit:** arm64-v8a included. **16 KB page size:** Godot 4.5+ complies; Play requires it for native code (updates blocked from 1 Feb 2027 if not). Check: `bundletool dump config --bundle=x.aab` shows `PAGE_ALIGNMENT_16K`.
- **AAB required** (APK only for other stores). Size limit 500 MB base module.
- **Play App Signing:** Google holds the app signing key; you keep an **upload key**. Make it once:
  `keytool -genkeypair -v -keystore bugseyeview-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000`
  Godot needs the store password and the key password to be the **same** (letters and numbers). **Keep the file, alias and password safe, with an offline backup; never put them in git.** If lost, Play Console can reset the upload key.
- **versionCode** must go up with every upload (Godot `version/code`).
- Godot 4.7: JDK 17+ (21 works here), Android SDK platform 36 + build-tools 36.1.0 (installed in the cloud session), gradle build template (installed by the export). Release signing: preset Release/Release User/Release Password, or env vars `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`.

## Store listing
- Icon 512x512 PNG; **feature graphic 1024x500** (required); screenshots: 2-8 per device, JPG/PNG; **3+ landscape 16:9 at 1920x1080 or larger** to be eligible for game recommendations. Tablet: 4+, 16:9.
- Title 30, short description 80, full description 4,000. No "#1/Best/Free", no emoji in the short description.
- Optional YouTube trailer (ads off).

## App content forms
- **Privacy policy:** required even if you collect nothing - a public HTTPS page (not a PDF) **and** a link or text inside the game. Draft in `Legal/`.
- **Data safety:** collects **no** data, shares **no** data (saves stay on the device). Make sure the build asks for no INTERNET permission and has no SDKs.
- Ads: **No**. App access: everything available.
- **Content rating (IARC):** cartoon/fantasy violence -> likely ESRB E / E10+, PEGI 7 (your answers decide).
- **Target audience:** choose **13+** (choosing under-13 brings in the Families policy and longer reviews).

## Other Android stores
- **Android developer verification** (all stores): from 30 Sep 2026 certified devices in Brazil, Indonesia, Singapore and Thailand only install apps from verified developers; global in 2027. APKs you sign for other stores must have their package + key registered in Play Console ([verification](https://developer.android.com/developer-verification/guides)).
- **Amazon Appstore:** closed on non-Amazon Android devices on 20 Aug 2025; still live on **Fire tablets and Fire TV (Fire OS)**, APK or AAB.
- **Samsung Galaxy Store:** no fee; needs commercial seller status (individual form available); APK or AAB. ([Samsung](https://developer.samsung.com/galaxy-store/prepare.html))
- **Huawei AppGallery:** HUAWEI ID + identity check; APK or AAB (Huawei App Signing; 150 MB limit). HarmonyOS NEXT devices don't run APKs.
