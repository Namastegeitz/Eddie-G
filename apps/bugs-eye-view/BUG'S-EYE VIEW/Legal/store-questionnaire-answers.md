# Answers for the stores' forms

What to pick on each store's privacy, data and age-rating forms for
Bug's-Eye View as it is today (offline, no accounts, no ads, no purchases,
no analytics, saves only on the device). Re-check these if any of that
changes.

## Google Play - App content
| Form | Answer |
|---|---|
| Privacy policy | The URL of the published privacy policy page (see checklist) |
| Ads | **No**, the app does not contain ads |
| App access | All functionality is available without special access |
| Content rating (IARC) | Category **Game**. Violence: **cartoon / fantasy violence** (insects are swatted, stomped, sprayed; no blood, no humans hurt). No sexual content, language, drugs, gambling, user interaction or sharing of location. Expected result: ESRB E or E10+, PEGI 7 |
| Target audience | **13 and over** (avoids the Families policy) |
| News app | No |
| Data safety | **Does your app collect or share any required user data types? No.** Data is not encrypted in transit (nothing is transmitted). Users can request deletion: not applicable / in-game reset |
| Government app / financial / health | No |

## Apple - App Store Connect
| Form | Answer |
|---|---|
| App Privacy | **"No, we do not collect data from this app"** -> shows *Data Not Collected* |
| Encryption (export compliance) | Uses no non-exempt encryption -> `ITSAppUsesNonExemptEncryption = NO` (Godot writes it into the build's Info.plist) |
| Age rating | Cartoon or Fantasy Violence: **Frequent** -> 13+ (Infrequent would be 9+; bugs get swatted on most failures, so Frequent is the honest answer). Everything else: None / No. Not "Made for Kids" |
| Content rights | Contains no third-party content (all art, sound and code made for the game; Meshy-generated models used under your Meshy plan's terms) |

## Steam
- Content survey: **cartoon violence**, nothing else. Mark at least 4 screenshots "suitable for all ages".
- Steamworks / DRM: none.

## Microsoft Store / Epic
- IARC questionnaire: same answers as Google Play.

## EU trader status (Apple, Google, Epic)
- Free game, no money involved -> usually **non-trader**. If you sell the game or have VAT registration -> **trader** (your address/phone/email are verified and shown in the EU). Decide before you set a price.
