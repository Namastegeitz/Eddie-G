# iPhone and iPad (App Store): ⛔ Blocked here

## What's here
- Nothing yet. The iOS project is `game/ios` (Capacitor 8, iOS 15+, iPhone and iPad, privacy manifest included).

## How to build it
On a Mac with Xcode 26 or newer:
```bash
cd ALIEN-SUDOKU/game
npm run cap:sync && npx cap open ios      # then Product > Archive > Distribute App
```
No Mac here. The other options are GitHub Actions macOS runners (after Actions is fixed), Codemagic, or renting a Mac. Prompt `05-ios-testflight.md` sets up the cloud route. Note that the App Store Connect API key must have the **Admin** role for cloud signing.

## What the store needs
- Apple Developer Program ($99/year), App Store Connect app record. See **App Store** in the checklist and `store-launch/apple-app-store.md`.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
