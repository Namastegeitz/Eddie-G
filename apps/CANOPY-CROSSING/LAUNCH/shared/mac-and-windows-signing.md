# **CANOPY CROSSING: Mac notarization and Windows code signing**

Researched 2026-11-17 from official pages (some via search extracts, marked); re-check on the day.

## macOS: shipping the .app outside the Mac App Store (Steam, GOG, itch.io, Epic)

- Needs the **Apple Developer Program ($99/year)** and a **Developer ID Application** certificate (not Mac App Distribution, not Apple Development, not ad-hoc).
- Sign every executable inside-out with the **Hardened Runtime** and a **secure timestamp**, submit to the notary service, then **staple** the ticket. Required for Developer ID software on macOS 10.15+. `altool` uploads have been rejected since 1 Nov 2023: use `notarytool` on a Mac, or Apple's **Notary REST API** (JWT from an App Store Connect API key) from Linux.
  (developer.apple.com/documentation/security/notarizing-macos-software-before-distribution · developer.apple.com/documentation/notaryapi)
- **From Linux / GitHub Actions with Godot 4.7**: install **rcodesign** and set its path in Editor Settings; in the macOS export preset set Code Signing = rcodesign with your **Developer ID .p12** and password; **disable the "Debugging" entitlement**; Notarization = rcodesign with the App Store Connect API issuer UUID + key (env vars such as `GODOT_MACOS_NOTARIZATION_API_KEY`, `GODOT_MACOS_NOTARIZATION_API_KEY_ID`); check with `rcodesign notary-log`. Official templates are universal (x86_64 + arm64). (docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
- Steam overlay / any bundled dylibs: disable library validation, allow DYLD environment variables, sign every `.dylib` and `.framework`.
- Package after stapling (zip with `ditto -c -k --keepParent`, or a signed + notarized DMG); never change files after signing.
- **Without notarization**: Apple silicon won't run arm64 code with no signature at all (Godot's ad-hoc signing covers that minimum), and downloaded apps are blocked; **macOS 15 Sequoia removed the Control-click bypass** (users must go to System Settings > Privacy & Security > Open Anyway). **Steam requires notarized macOS apps.**
- Developer ID builds must be re-signed against Apple's new G2 Sub-CA before **2027-02-01** (from the Apple research).

## Windows code signing and SmartScreen

- Steam, GOG, Epic and itch.io don't require Authenticode signing; the Microsoft Store EXE/MSI route does.
- Unsigned or new executables downloaded in a browser (itch.io, direct sales) show "Windows protected your PC" until they build reputation. **EV certificates no longer skip SmartScreen**; reputation builds over time under one signing identity. (learn.microsoft.com/windows/apps/package-and-deploy/smartscreen-reputation)
- From **1 Mar 2026** new code-signing certificates are valid for at most **460 days** (CA/Browser Forum ballot CSC-31).
- **Azure Artifact Signing** (formerly Trusted Signing): about $9.99/month (5,000 signatures), paid Azure subscription; individuals in the USA and Canada, organizations in the USA, Canada, EU and UK **[CONFLICTING: a 2026 blog claims looser rules]**.
- **Godot from Linux**: signing uses **osslsigncode**. **Don't embed the PCK if you sign** (it breaks the signature): the Windows preset currently embeds it (`binary_format/embed_pck=true`), so switch that off for a signed build. Icon/metadata editing uses **rcedit, which needs Wine** on Linux CI; version strings need four parts. (docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)

## Suggested order of work (PC)
1. Strip ads and real-money purchases from the desktop build; fix portrait scaling, font sizes, controller support, offline play; audit Meshy licences.
2. Join the Apple Developer Program and get notarization working in CI; decide on Windows signing (mainly for itch.io and direct downloads).
3. **Steam**: pay the fee and start onboarding early (the waiting clocks start); submit the store page; run a Playtest during Coming Soon; leave review buffers of up to 12 business days; remember the 5-minute playtime rule.
4. **itch.io**: any time; good for early access or a demo.
5. **GOG**: submit the form when nearly finished; if accepted, deliver the RC 3-5 days before launch.
6. **Epic**: onboard early (verification 2+ weeks); achievement and patch parity.
