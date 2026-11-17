# **CANOPY CROSSING: macOS build**

**Stores:** Steam, GOG, itch.io, Epic Games Store (and the Mac App Store, which works like the iOS one).

`CanopyCrossing-macOS.zip` holds `Canopy Crossing.app`, universal (Apple
silicon + Intel); see `BUILD_INFO.json` for the version.

**Not signed or notarized yet.** macOS blocks apps from unknown developers:
to test, right-click the app > Open > Open. Before shipping it outside the
Mac App Store it must be signed with a *Developer ID* certificate and
notarized by Apple (needs the Apple Developer Program, USD 99/year, and a
Mac or `rcodesign` + App Store Connect API key). Steam and GOG both expect
a notarized .app.

See `../../LAUNCH/steam/` and `../../LAUNCH/gog/`.
