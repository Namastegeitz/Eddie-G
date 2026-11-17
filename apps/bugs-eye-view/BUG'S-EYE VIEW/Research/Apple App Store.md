# Apple App Store (iPhone / iPad) - requirements

Researched 2026-11-17 from developer.apple.com and the Godot docs. Things that
change often (Xcode versions, screenshot sizes, fees) - check the linked page
before you act on them.

## Decide first
- **Seller name.** Enrolling as an *individual* lists your personal legal name
  as the seller (not "Aethertek"). To show "Aethertek" you need a registered
  company (LLC/Ltd) plus a free D-U-N-S number; Apple does not accept a DBA /
  trade name. ([enrollment](https://developer.apple.com/support/enrollment/))
- **An iPhone or iPad** is needed for identity verification (Apple Developer
  app) and to test with TestFlight (guideline 2.1 expects on-device testing).
- **Xcode version.** Uploads must be built with **Xcode 26 or later** (since
  28 Apr 2026). Apple warns apps built with the iOS 27 SDK won't launch unless
  they use the UIScene life cycle
  ([TN3187](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle));
  **checked 17 Nov 2026:** the Xcode project Godot 4.7.2 exports for this game
  already has a `UIApplicationSceneManifest` (UIScene life cycle). Build with
  Xcode 26.x anyway until a test on Xcode 27 shows it launching.

## Phases, zero to live
| # | Step | Who | Cost | Time | Requirement |
|---|---|---|---|---|---|
| 1 | Apple Account with two-factor sign-in, your legal name | You | Free | Minutes | [enroll](https://developer.apple.com/programs/enroll/) |
| 2 | Apple Developer Program + ID check in the Apple Developer app | You | US$99 / year | Individual: ~1-2 days (contact Apple after 24 h). Company: D-U-N-S up to ~1 week + vetting | [identity](https://developer.apple.com/help/account/membership/identity-verification/) |
| 3 | Agreements, tax, banking | You | Free | < 1 h + bank check | Free app: Program License Agreement only. Paid: Paid Apps Agreement + bank + W-9 / W-8BEN. [Small Business Program](https://developer.apple.com/app-store/small-business-program/) = 15% commission |
| 4 | EU Digital Services Act trader status | You | Free | Minutes-days | Must be declared even if not selling in the EU. A free hobby app may be "non-trader"; selling makes you a trader (address/phone/email verified and shown in the EU). No status = removed from EU stores. ([DSA](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)) |
| 5 | Register App ID `com.aethertek.bugseyeview` (no capabilities) | You (browser) | Free | Minutes | Must match the build; can't change after the first upload |
| 6 | Apple Distribution certificate + App Store provisioning profile | You, or CI with an App Store Connect API key | Free | ~30 min | CSR can be made with OpenSSL on Windows ([CSR](https://developer.apple.com/help/account/certificates/create-a-certificate-signing-request)) |
| 7 | App record in App Store Connect (name, SKU, language, bundle id) | You | Free | Minutes | Name 2-30 chars |
| 8 | Export preset, icons, privacy policy page, screenshots, CI workflow | **Prepared in this folder** | Free | - | see below |
| 9 | Build: Godot export -> Xcode archive -> .ipa | CI on macOS | see "Without a Mac" | ~10-25 min / build | Xcode 26+ |
| 10 | Upload (Transporter / altool / API / Xcode Cloud) | CI | Free | processing email | [upload](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds) |
| 11 | TestFlight | You | Free | internal: instant; external: first build reviewed (~1 day) | 100 internal / 10,000 external testers; builds expire after 90 days |
| 12 | Listing, App Privacy, age rating, price | You (text drafted here) | Free | Hours | below |
| 13 | Submit for review | You | Free | 50% < 24 h, 90% < 48 h ([App Review](https://developer.apple.com/distribute/app-review/)) | |
| 14 | Release (manual / automatic / scheduled) | You | Free | Immediate | |

## Technical
- **SDK:** Xcode 26+ / iOS 26 SDK (since 28 Apr 2026); minimum deployment target iOS 13+ (since 9 Sep 2026) ([upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)).
- **arm64** only.
- **Icon:** 1024x1024, square, full-bleed, **opaque** (no transparency) -> `Store Assets/Icons/app-icon-1024.png`. Godot options `icons/app_store_1024x1024`, `icons/icon_1024x1024`.
- **Privacy manifest:** Godot's iOS exporter writes PrivacyInfo.xcprivacy from its `privacy/*` options - tracking **off**, collected data **none**, required-reason APIs: **checked in this game's export** - Godot pre-fills file timestamps, system boot time and disk space; if Apple's ITMS-91053 email after upload names another one (for example user defaults, CA92.1), add it in the preset.
- **Encryption:** `ITSAppUsesNonExemptEncryption = NO` - **checked:** Godot 4.7.2 writes it into Info.plist by itself; the game makes no network calls.
- **Orientation:** landscape works best on iPhone; iPhone + iPad means 13" iPad screenshots are required.
- **Godot:** "You must export for iOS from a computer running macOS with Xcode installed" ([docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)). Needs the 10-character **Team ID** (the preset still has the placeholder `ABCDE12345`). Increase `application/version` with every upload.

## Without a Mac (you work on Windows)
| Option | Cost (check) | Notes |
|---|---|---|
| **Codemagic** | 500 free macOS minutes/month, then ~$0.095/min ([pricing](https://docs.codemagic.io/billing/pricing/)) | Easiest: its App Store Connect API integration makes the certificate/profile and uploads to TestFlight |
| **GitHub Actions macOS runner** | Free for public repos; ~$0.06/min private | Install Godot 4.7.2 + templates, pick Xcode 26.x, import the .p12, upload with an API key |
| Xcode Cloud | 25 h/month included | Needs a Mac once to set up; awkward for Godot |
| Scaleway Mac mini | ~EUR 5.30 / day (24 h minimum) | A real Mac for a day if you need Xcode's screens |

## Listing
- **Screenshots** ([spec](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)), 1-10 per size, JPG/PNG, no transparency: iPhone **6.3"** 2622x1206 (now the required size) and **6.9"** 2868x1320 (upload both); **iPad 13"** 2752x2064 if iPad is supported. Ready in `Store Assets/Screenshots/`.
- Text limits: name 30, subtitle 30, keywords 100 bytes, description 4,000, promotional text 170.
- Required: copyright ("2026 Aethertek"), **support URL** with real contact info, **privacy policy URL** (required for every app) - and a privacy link **inside the game** too (guideline 5.1.1).
- **App Privacy:** "No, we do not collect data from this app" -> "Data Not Collected".
- **Age rating** (tiers 4+/9+/13+/16+/18+ since 24 Jul 2025): cartoon or fantasy violence *Infrequent* -> 9+, *Frequent* -> 13+. Bugs getting swatted on every failure suggests answering **Frequent** (13+). Don't pick "Made for Kids".
- Category: Games -> Action (+ Adventure).

## Review gotchas
2.1 completeness (crashes, placeholder art, dead links) is the most common rejection; 4.2 minimum functionality; screenshots must show the real game; touch controls must work without a controller; Apple may test an iPhone app on an iPad.
