# Alien Sudoku on PC and web stores (Steam, itch.io, Microsoft Store, Epic, GOG, web portals)

*Researched November 17, 2026. Paths are written as `game/...` (today: `apps/alien-sudoku/...`).*

> **How this was checked.** This workspace cannot open store websites directly (partner.steamgames.com,
> itch.io, docs.gog.com, dev.epicgames.com, learn.microsoft.com and so on are blocked by the network
> policy), so every fact below was checked through web-search summaries of the official pages listed in
> **Sources**. Where official pages disagree with each other, or only third-party sites had the answer,
> this guide says so. Before you pay or submit anything, open the linked official page and confirm it.
> The same block means uploads (steamcmd, butler, BuildPatchTool) must run on **your own PC**.

---

## 1. Summary

### What it costs and how long it takes

| Store | Up-front cost | Store cut | Time to first release (from today) | Fit for this game | Recommendation |
|---|---|---|---|---|---|
| **itch.io** | $0 | You choose; default 10% (0–100%), plus payment fees | 1–3 days | Good. Web build + desktop builds, fast feedback | **Do first** |
| **Steam** | $100 per game (paid back to you after $1,000 adjusted gross revenue) | 30% (25% above $10M, 20% above $50M) | 5–8 weeks minimum (verification 15–30 days, 21-day wait after paying, 2-week Coming Soon) | Main PC market; AI disclosure is shown on the page | **Main target** |
| **Microsoft Store** | $0 for individuals (since Sep 2025); $99 one-time for companies | 12% on games | 1–3 weeks (ID check, MSIX build on a Windows PC, certification up to 3 business days) | Good, and MSIX gets free signing | **Do second or third** |
| **Epic Games Store** | $100 per product (paid back after $1,000) | 0% on the first $1M net per product per year, then 12% | 3–5 weeks (verification can take 2+ weeks) | Works, but little traffic for small puzzle games | Optional, later |
| **GOG** | $0 to submit | Set in the contract (commonly reported as 70/30; not published) | Unknown; curated, often slow, often no reply | Low odds: small sudoku game with AI-assisted art | Submit after Steam launch, expect a no |
| **Web portals** (CrazyGames, Poki) | $0 | Ad revenue share (splits not published) | CrazyGames Basic Launch in days; Poki is closed beta | Technically perfect (2.4 MB HTML5), but portals need **their** ads and a free game | Only if you want a free, ad-funded web version |

### Big risks for this game (read these first)

1. **The full game is free elsewhere.** Phones are free with ads; the web build (`game/dist`) and the
   single-file `play/AlienSudoku.html` are complete and free; a public playable artifact link exists.
   A paid PC version needs a clear reason to buy (ad-free, complete, keyboard/controller, Steam features)
   and the free web version should probably become a **demo**. Decide this before any store page.
2. **AI disclosure is public on Steam and itch.** The glyph art, themes, music code and probably some text
   were made with Claude's help. Steam prints your disclosure on the store page; itch tags the page
   "AI Generated" and hides it from the "No AI" filter. Disclose honestly anyway: under-disclosing is a
   policy violation, and GOG's audience in particular reacted strongly against generative AI in 2026.
3. **Space photo licenses are unverified.** The 6 images in `game/public/space/` came with the prototype.
   Every store agreement (and Steam's content survey) makes you confirm you own or license all content.
   NASA-made images are public domain; ESA/Webb and ESA/Hubble images are CC BY 4.0 and **require visible
   credit**. The game has no credits screen yet.
4. **No controller support.** Input is mouse, touch and keyboard only. Steam Deck "Verified" needs full
   controller support with controller button prompts; without it expect "Playable" at best.
5. **macOS is blocked.** Steam requires new macOS apps to be notarized. `desktop/package.json` has
   `"identity": null`; there is no Mac here and GitHub Actions jobs don't start. Ship Windows (and maybe
   Linux) first.
6. **No accounts yet.** Steam's 21-day wait starts only when you pay the fee, so the fee is the first
   thing to do if Steam matters.
7. **Electron on Linux/Steam.** Steam's Linux container breaks Electron's setuid sandbox; Electron games
   on Steam usually launch with `--no-sandbox` on Linux. Ship a plain folder build, not the AppImage.

### Current state mapped to the stores

| Thing | State today | Needed for |
|---|---|---|
| Windows x64 build (`desktop/out/win-unpacked`, NSIS, portable) | **OK** (built, 1.0.0, unsigned; unpacked size 311 MB) | Steam, Epic, GOG, itch |
| Linux build | **Needs change**: config is AppImage + deb only, not built yet; Steam needs a folder (`dir` target). Can be built here | Steam (optional), itch, GOG (optional) |
| macOS universal build | **Blocked**: unsigned, needs a Mac + Apple Developer ID + notarization | Steam (optional), itch, GOG (optional) |
| Microsoft Store MSIX | **Needs change**: no `appx` target; MSIX can't be built on Linux, needs a Windows 10/11 PC | Microsoft Store |
| Web build (`game/dist`, 56 files, 2.4 MB) | **Mostly OK**: registers a PWA service worker on the web, which should be off for itch/portal embeds | itch, portals, your site |
| Code signing (Windows) | **Not done** (only matters for direct downloads and the Store EXE path) | itch/site downloads |
| Store text | **Drafted** in `docs/STORE_CHECKLIST.md` §5 (mentions phones; needs a PC version) | All |
| Screenshots | **Needs change**: 3 images in `docs/` at 1990x664 and 1590x1338; stores want 16:9 1920x1080 | All |
| Key art, logo, capsules | **Missing** (only the 1024 px icon and 2732 px splash in `game/assets`) | All |
| Privacy policy | **Template** in `docs/PRIVACY.md`, not hosted | MS Store, Epic, portals, your site |
| Credits/licenses screen | **Missing** | All (CC BY credit, OFL notices) |
| Gamepad input | **Missing** | Steam Deck badge |

---

## 2. Cross-store setup (do once, use everywhere)

### 2.1 Business and payout identity

- **Individual is fine everywhere.** Steam, itch.io, Microsoft (free "individual developer" account), Epic
  (organization type "Individual") and GOG (contract) all accept individuals.
- **Use your legal name.** Steam rejects aliases, DBAs and nicknames; the bank account must be in the same
  name you enter as "Legal Company Name". A brand ("Eddie G") can still be your publisher display name.
- **Tax:** every store runs a US tax interview. As a US person you give W-9 data (SSN, or an **EIN** if you
  are a sole proprietor or LLC). An EIN is free from the IRS in minutes and keeps your SSN off store
  forms. Steam warns that a newly issued TIN can take up to 30 days to validate.
- **EU "trader" status (Digital Services Act).** Epic runs "trader verification"; Apple and others publish a
  trader's address, phone and email on EU store pages. I could not confirm how Steam and Microsoft display
  this, but plan for it: use a business address (PO box / virtual office) and a business phone and email
  you are happy to see in public.
- **Bank:** a US checking account in your legal name (or the LLC's).

### 2.2 Builds each store wants

| Store | Upload format | From this repo |
|---|---|---|
| Steam | Plain folders per OS via SteamPipe depots | `desktop/out/win-unpacked`, `desktop/out/linux-unpacked` (add `dir` target), `Alien Sudoku.app` (notarized) |
| Epic | Plain folder via BuildPatchTool | `desktop/out/win-unpacked` |
| GOG | Plain folder via Build Creator (GUI) or Pipeline Builder (CLI); GOG builds the installers | `win-unpacked` (+ Linux/Mac if offered) |
| Microsoft Store | MSIX/APPX (recommended) **or** a signed EXE/MSI installer at a versioned HTTPS URL | add `appx` target (build on Windows) |
| itch.io | Zip/folder per channel via butler or the web uploader; HTML5 zip for the browser | web zip, `win-unpacked` or portable exe, Linux, Mac zip |
| Portals | HTML5 zip with `index.html` at the root, plus the portal's SDK for money | web zip (portal flavour) |

Do **not** upload the NSIS installer to Steam, Epic or GOG; they install the unpacked folder themselves.

### 2.3 Pricing (no ads on PC)

- Comparable plain sudoku games on Steam sit at **$2.99–$4.99** (Sudoku Pro and Sudoku Mania $4.99;
  Sudoku Jigsaw $2.99; minimal ones $0.99–$1.99), and they discount often.
- **Suggested:** **$3.99 USD** everywhere (Steam, itch, Microsoft, Epic), with Steam's recommended regional
  prices and a **10–20% launch discount** on Steam (Steam allows up to 40% for 7–14 days at launch).
- Make the PC edition the "complete, ad-free" one. Turn the free web version into a demo (for example
  Sector 1 + Daily + Quick Play Easy) that links to the Steam/itch pages from your own site.
- Steam pays the $100 fee back after $1,000 adjusted gross revenue (counted before Valve's cut, after
  refunds and taxes); at $3.99 with cheaper regional prices that is roughly 250–350 sales (rough estimate).
- Don't go free-to-play on PC: there are no PC ads or purchases, and you'd never recoup the Steam fee.

### 2.4 Age ratings (IARC) and suggested answers

IARC ratings are **free**. Microsoft Store (Partner Center) and Epic (publishing tools) run the IARC
questionnaire; you get ESRB, PEGI, USK, ClassInd, ACB and a generic rating at once. Microsoft lets you enter
an existing IARC certificate ID; keep the certificate e-mail. Steam and GOG don't use IARC (Steam uses its
own content survey). Epic treats an unrated product as the highest maturity everywhere, so do get one.
South Korea is not covered by IARC.

| IARC topic | Answer for Alien Sudoku |
|---|---|
| Violence | None. No fighting, no injury, no blood |
| Fear / horror | Honest answer: **mild**. Optional "gnarly" alien sets show cartoon monsters with fangs, many eyes and slime; an alien ship "asks who you are" after a loss. Not realistic, no gore |
| Sexuality / nudity | None |
| Language | None |
| Drugs, alcohol, tobacco | None |
| Gambling / simulated gambling | None |
| Users interact or chat | No. No online play, no chat, no user content |
| Shares location / personal info | No. The typed name stays on the device |
| Digital purchases | None in the PC game (it's a paid app with no in-app purchases) |
| Unrestricted web access | No (external links open in the system browser only) |
| Ads | None on PC |

Expect roughly **ESRB E / PEGI 3 or PEGI 7** (PEGI 7 if the "frightening" answer is yes). Don't
under-answer to get a lower rating; screenshots must match the rating you get.

### 2.5 The AI disclosure (use the same wording on every store)

Steam's January 2026 rewrite of the survey focuses on **player-facing content** made with AI (art, sound,
text, store art) and treats AI coding/efficiency tools as out of scope (this comes from secondary coverage;
Valve's page itself could not be opened here). Proposed text:

> **Pre-generated content:** The alien glyph artwork and the visual themes were created with the help of
> AI tools (Anthropic's Claude) and then selected and edited by the developer. The music and sound effects
> are synthesized live by the game's own code; that code was written with AI assistance, but no AI audio
> model and no AI-generated recordings are used. *[If true:]* Some in-game text and some store artwork
> were drafted with AI assistance and edited by the developer.
>
> **Live-generated content:** None. The game does not use AI while you play. Puzzles come from a
> pre-built, algorithmically checked set, and the Alien Duel rival is a scripted computer opponent.

- In store copy, call the Duel opponent a **"computer rival"**, not an "AI rival", so players don't confuse
  it with generative AI.
- Space photos are not AI; they are licensed photos (once verified).
- Epic and Microsoft have no AI disclosure field that I could find (Epic's CEO publicly opposes AI labels).
  GOG has no published policy for submissions; mention it in the form anyway.

### 2.6 Licenses and credits (blocker for every paid store)

- **Space photos** (`public/space/*.webp`): trace each to its source page. NASA-made images: public domain
  (don't use NASA logos or imply endorsement). **ESA/Webb and ESA/Hubble: CC BY 4.0, must be "clearly and
  visibly credited"** (for example "ESA/Webb, NASA & CSA, ..." exactly as the source gives it); their logos
  are excluded, and ESA/Hubble forbids implying endorsement of a commercial product. Replace anything you
  can't trace.
- **Fonts** (Orbitron, Space Grotesk, Quicksand, Black Ops One, Creepster, Audiowide, Cinzel, Exo 2,
  Fredoka): SIL OFL 1.1 allows commercial use and embedding, but the copyright notice and license must be
  distributed with the font files. Add a `licenses/` folder (or an in-game Licenses screen) to every build.
- **Electron/Chromium** notices: electron-builder already ships `LICENSE.electron.txt` and
  `LICENSES.chromium.html` in `win-unpacked`. Keep them.
- Add an in-game **Credits** screen (Settings → Credits): photo credits, fonts, "Made by Eddie G with AI
  assistance".

### 2.7 Website: privacy policy, support, press kit, app-ads.txt

- Put a small site on a **domain root you control**: a custom domain (about $10–20/year) on Netlify,
  Cloudflare Pages or GitHub Pages, or a GitHub *user* site (`<user>.github.io`).
- A GitHub *project* path such as `namastegeitz.github.io/Eddie-G/` works for the privacy policy but **not
  for app-ads.txt**: AdMob crawls `app-ads.txt` at the root of the developer-website host listed in the
  store. GitHub Pages from a private repo needs a paid plan; Netlify's free plan allows commercial use
  (third-party summaries).
- Pages: `/privacy` (fill in `docs/PRIVACY.md`; it already says desktop and web send no data), a support
  email, `/press`, `/play` (web demo), `/app-ads.txt` (for the phone apps).

### 2.8 Press kit

A `/press` page with: fact sheet (developer, release date, platforms, price, website, contact), short and
long description, feature list, trailer (YouTube + MP4 download), 6–10 screenshots (1920x1080), logo (PNG,
transparent), key art (layered source kept), icon, credits, a one-line honest note about AI assistance,
and one zip with everything. Link it from Steam, itch and your site.

### 2.9 Windows code signing and SmartScreen

| Distribution | Needs your own signature? |
|---|---|
| Steam, Epic, GOG (their clients/installers) | No |
| Microsoft Store **MSIX** | No: Microsoft re-signs it for free |
| Microsoft Store **EXE/MSI** | **Yes**: installer and all PE files signed with a cert chaining to the Microsoft Trusted Root Program; self-signed not accepted |
| itch.io downloads, your website | Recommended, otherwise SmartScreen shows "Windows protected your PC" |

Options (late 2026):

- **Azure Artifact Signing** (renamed from "Trusted Signing"): Basic **$9.99/month** (5,000 signatures),
  Premium $99.99/month. **Individuals are eligible only in the USA and Canada** (organizations: USA, Canada,
  EU, UK). Needs a paid Azure subscription and identity validation. Does **not** give instant SmartScreen
  trust. electron-builder supports it via `win.azureSignOptions` (signing runs on Windows; check the
  electron-builder docs for your version).
- **OV certificate:** Microsoft quotes **$150–300/year** on one page and **$300–500/year** on another. Since
  June 2023 the key must live on certified hardware (token or cloud HSM). Certificates issued on or after
  **March 1, 2026 last at most 460 days** (CA/B Forum ballot CSC-31), so you renew every ~15 months.
- **EV certificate:** Microsoft removed EV's instant SmartScreen bypass in 2024; EV now builds reputation
  like OV. Not worth the extra cost for this.
- Recommendation: **don't buy anything for launch.** Use Steam, MSIX and itch (with a SmartScreen note on
  the page). Add Artifact Signing later if direct downloads matter.

---

## 3. Steam

### 3.1 Summary

- **Cost:** $100 Steam Direct fee per game, non-refundable, paid back in the payment after the game reaches
  $1,000 adjusted gross revenue. Demos are separate App IDs tied to the base game (no separate fee found in
  the docs; confirm in Steamworks).
- **Cut:** 30% up to $10M, 25% from $10M–$50M, 20% above $50M (marginal tiers, unchanged since 2018).
- **Timeline from today (Nov 17, 2026):**

| Step | Time |
|---|---|
| Sign up, pay fee | Day 0 |
| Tax/bank/identity verification | 15–30 days (some pages say 2–7 business days; Spanish page 10–15) |
| Waiting period after paying the fee | **21 days** before you may release (the default onboarding page and Steam Direct page; an older July 2025 revision said 30 days) |
| Store page review | 3–5 business days; submit ≥7 business days before you want it public |
| "Coming Soon" | page must be public **≥ 2 weeks** before release |
| Build review | 1–5 days; plan 7 business days |
| Release date lock | within 14 days of release you can't change the date without asking Valve |

  Earliest realistic release: **early-to-mid January 2027** if you pay this week and nothing stalls
  (holidays slow Valve). With Next Fest February 2027: release after **March 1, 2027**. With Next Fest June
  2027: after **June 21, 2027**.
- **Big risks:** AI disclosure on the page, no controller support (Deck), unverified photo licenses,
  Electron sandbox on Linux, macOS notarization blocked.

### 3.2 Accounts and business setup

1. Steam account with Steam Guard on, and a **phone number**: since Oct 2023 Steam sends an **SMS code**
   before a build can go live on the **default branch** of a released app (and when adding users). Unreleased
   apps and beta branches don't need it. steamcmd can upload and set beta branches, but not set the default
   branch of a released app.
2. `partner.steamgames.com/steamdirect` → legal name, address → sign the distribution agreement.
3. Pay the **$100 fee** (only an admin of the partner account can) → you get an App ID.
4. **Tax interview** (TaxIdentity by Lilaham): 5–10 minutes, cannot be saved halfway; W-9 info for US
   persons; legal name only.
5. **Bank:** routing number, account number, bank address, account in the same legal name.
6. Answer any document requests. Verification 15–30 days.

### 3.3 Technical and build requirements

| Requirement | Game today | Status |
|---|---|---|
| 64-bit Windows build, folder upload | `win-unpacked`, x64, `Alien Sudoku.exe` | **OK** |
| Launch option per OS | none yet | **Needs change** (configure in Steamworks → Installation) |
| SteamPipe depots/builds | none yet | **Needs change** (scripts below) |
| Linux build | AppImage/deb only, not built | **Needs change**: add `dir` target, `executableName`, test |
| macOS: 64-bit **and notarized** (Steam requirement since Oct 2019) | unsigned, `identity: null` | **Blocked** (Mac + Apple Developer ID) |
| Steamworks SDK | not used | **OK** (optional; no DRM required) |
| Steam overlay | not hooked | **OK** (optional) |
| Controller support | none | **Needs change** for a Deck badge |
| Window fits 1280x800 (Deck) | opens 1280x860 | **Needs change** (fullscreen flag / fit to screen) |
| Saves | localStorage in Electron's userData (`%APPDATA%/Alien Sudoku`) | **OK** (survive updates; Steam Cloud optional and not recommended for LevelDB folders) |

**SteamPipe (uploads).** Download the Steamworks SDK (ContentBuilder) from the partner site, or use steamcmd.
Example scripts (`game/desktop/steam/`):

```vdf
"AppBuild"
{
  "AppID" "<APP_ID>"
  "Desc" "Alien Sudoku 1.0.0"
  "ContentRoot" "../out/"
  "BuildOutput" "./output/"
  "SetLive" "beta"            // never "default": default can't be set automatically
  "Depots"
  {
    "<WIN_DEPOT_ID>"   { "FileMapping" { "LocalPath" "win-unpacked/*"   "DepotPath" "." "Recursive" "1" } }
    "<LINUX_DEPOT_ID>" { "FileMapping" { "LocalPath" "linux-unpacked/*" "DepotPath" "." "Recursive" "1" } }
  }
}
```

Upload from your PC: `steamcmd +login <builder_account> +run_app_build <path>/app_build.vdf +quit`, then in
Steamworks → Builds set it live on the beta branch (password-protected) for testing, and later on
**default** for release. "Invalid content configuration" at launch means no build is live on that branch or
the launch option is wrong; "status = 6" during upload usually means wrong App/depot ID, permissions or
`ContentRoot`. Note: Valve now requires a manually created, password-protected `local` branch for local
content-server builds (from Sept 2026); not needed for normal uploads.

**Launch options** (Steamworks → Installation → General):

| OS | Executable | Arguments |
|---|---|---|
| Windows (64-bit) | `Alien Sudoku.exe` | none |
| Linux | `alien-sudoku` (set `linux.executableName`) | `--no-sandbox` (test first) |
| macOS | `Alien Sudoku.app` (bundle preferred) | none |

Linux: choose a **Steam Linux Runtime** under Installation → Linux Runtime (sniper/3.0 is the current
generation; confirm in Steamworks). Electron's setuid `chrome-sandbox` can't work inside Steam's container
or from an AppImage; developers report the app hangs or shows a blank screen until `--no-sandbox` is
passed on the command line (`app.commandLine.appendSwitch('no-sandbox')` in code is reported **not** to
work). The game only loads its own `app://` content and blocks navigation, so the risk is low. If Valve's
Linux test fails, they test the Windows build under Proton instead, but every OS you **list** must launch.
Simplest first release: **Windows only**, tested under Proton on a Deck/Linux PC; add the native Linux
depot after testing.

**Steam overlay / achievements (optional).** Not needed for review. If you want Steam achievements, the
usual route is `steamworks.js` (native module). Its README's renderer integration needs
`contextIsolation: false`/`nodeIntegration: true`, which weakens the game's secure Electron setup; call it
from the main process over IPC instead. The overlay additionally needs `--in-process-gpu
--disable-direct-composition` (community reports). **Important:** if Steam has achievements, **Epic requires
Epic achievements too** (Epic policy for games with achievements on other PC stores). The in-game
achievements alone don't trigger that rule.

**Steam Deck / Steam Machine compatibility review.** Valve reviews games for Deck and the new Steam Machine
under one program. **Verified** = everything works with no configuration: the default controller layout
reaches all content, on-screen prompts use Deck or Xbox button names (no keyboard prompts while a pad is
used), playable frame rate (30 fps at 800p on Deck), and the smallest text is **≥ 9 px tall at 1280x800**.
**Playable** = works but needs user effort (e.g. picking a community controller config or using the
touchscreen). You may request a review for unreleased games after the game passes build review (Technical
Tools → "Steam Hardware Compatibility Review"; not all partners have the link yet); results take about a week
and you get a week to read them before they're public. The badge doesn't affect release eligibility.
For this game: add Gamepad API support, controller glyphs, a fullscreen start on Deck (`SteamDeck=1` env
var), check font sizes at 1280x800, and make the "who are you?" name prompt skippable (Deck users would
need Steam+X for the keyboard).

### 3.4 Store listing and assets (exact specs)

**Store capsules** (sizes raised in Aug 2024; old sizes no longer accepted):

| Asset | Size | Notes |
|---|---|---|
| Header capsule | **920 x 430** | required |
| Small capsule | **462 x 174** | required; 120x45 and 184x69 are generated from it; logo should nearly fill it |
| Main capsule | **1232 x 706** | required; front-page carousel |
| Vertical capsule | **748 x 896** | required |
| Page background | **1438 x 810** | optional; otherwise generated from the last screenshot |
| Screenshots | **≥ 5**, **≥ 1920 x 1080**, 16:9 | real gameplay, no awards/marketing text; mark **≥ 4** as suitable for all ages or they may not show on the front page |
| Trailer | up to 1920x1080, 30/29.97 or 60/59.94 fps, ≥ 5,000 kbps, .mp4/.mov/.wmv, H.264 + AAC preferred | custom thumbnail: a frame of the video, 1920x1080 .jpg/.png |
| Event/announcement cover | **800 x 450** | listed in the asset overview; used for events/news posts |

**Library assets:**

| Asset | Size | Rules |
|---|---|---|
| Library capsule | **600 x 900** | game logo must be legible; 300x450 generated |
| Library header | **920 x 430** | required |
| Library hero | **3840 x 1240** PNG | **no text**; keep key content in the central **860 x 380** safe area; 1920x620 generated |
| Library logo | PNG, **1280 wide and/or 720 tall**, transparent | logotype (+ optional logomark) only; drawn over the hero |

**Icons:**

| Asset | Size |
|---|---|
| App icon (community/client icon) | **184 x 184** .jpg |
| Shortcut icon | **256 x 256 or 512 x 512**, .ico or .png (Steam makes the .ico; alpha becomes black in the app icon) |

**Capsule rules:** base capsules may contain only artwork, the game name and an official subtitle. No review
scores, award names/logos, "On sale", "Wishlist now" or other calls to action. Text about new content goes
only in temporary **Artwork Overrides** (max 14 days per the English page).

**Text and settings (answers for this game):**

- Name: *Alien Sudoku*. Developer/Publisher: *Eddie G*.
- Short description (≤ 300 characters), e.g.: *"Classic Sudoku with glowing alien glyphs instead of numbers.
  Decode 54 transmissions across 6 sectors, keep a daily streak, race a computer rival in Alien Duel, or relax
  in Zen mode, all over real space photography and a synthesized soundtrack."*
- Long description: reuse `docs/STORE_CHECKLIST.md` §5, minus phone/ads wording; add "No ads, no
  account, plays offline".
- Genres: Casual, Indie. Tags (up to 20): Puzzle, Logic, Casual, Relaxing, Sci-fi, Aliens, Space,
  Singleplayer, 2D, Cute, Colorful, Minimalist, Family Friendly.
- Languages: English (interface).
- Features: Single-player; Family Sharing on. Only tick Steam Achievements / Cloud / controller support if
  the build really has them (build review checks this).
- System requirements (suggested; confirm): Windows 10/11 64-bit, dual-core CPU, 4 GB RAM, DirectX 11
  GPU, 500 MB storage. macOS only once notarized (use Electron 45's minimum macOS, believed to be
  macOS 12; check Electron's release notes). Linux: Ubuntu 22.04+ or SteamOS, only once tested.
- Price: see 2.3.

### 3.5 Forms and questionnaires

- **Content survey, mature content:** No to frequent violence or gore, nudity or sexual content, adult-only
  sexual content and general mature content. (The scary aliens are mild cartoon content.)
- **Content survey, AI section:** Pre-Generated **Yes** (text in 2.5), Live-Generated **No**.
- **Rights:** confirm you have rights to all content (after 2.6).
- **Release checklist** in Steamworks: store page, pricing, content survey, build, depots, launch options,
  supported OS, library assets, all green before review.
- **Ratings:** optional on Steam.

### 3.6 Testing

- Beta branch (password-protected) → install through Steam on Windows → play campaign, daily, duel, zen →
  quit and relaunch to confirm saves → uninstall/reinstall.
- Steam Deck or Linux PC: Windows build via Proton; native Linux depot with `--no-sandbox`.
- Generate Steam keys for a few testers (Steamworks → Keys) before release.
- Run `npm run smoke` in `game/desktop` after each build.

### 3.7 Submission and review

1. Store page → "Submit for review" ≥ 7 business days before you want it public (typical 3–5 business days).
2. Publish as **Coming Soon**; keep it public ≥ 2 weeks.
3. Mark the release-candidate build and submit for **build review** (1–5 days). Valve runs the game,
   checks it launches on every listed OS and that listed features exist. It is not QA.
4. Optional: Steam Deck compatibility review (≈ 1 week).
5. When all are green, the 21 days since payment have passed and you're verified: press **Release**
   yourself (approved titles don't auto-release).

Common failures: text or review quotes in capsules; features listed but missing (controller support,
achievements, Cloud); an OS listed that doesn't launch; screenshots that aren't gameplay; build not set live.

### 3.8 Next Fest and wishlists (small indie puzzle game)

- **Next Fest February 2027:** Feb 22–Mar 1, 2027. Registration deadline **Jan 10, 2027 (11:59 pm PST)**;
  the base game's store page must be **public** to register; a public demo must be live when the fest
  starts; the full game must release **after** the fest. Valve suggests submitting the demo + page for
  review by **Jan 18** for the press preview; the English page lists Feb 1 for required items (other
  translations say Feb 8; check). A game can be in **only one** Next Fest.
- **Next Fest June 2027:** June 14–21, 2027. This is the realistic target if you want a fest.
- **Demo:** separate App ID linked to the base game (own depots and builds; optional own page with ≥ 5
  demo screenshots and capsules marked "Demo"). A good demo here: Sector 1 (9 levels) + Daily + Quick
  Play Easy.
- **Wishlists:** put the Coming Soon page up as early as possible; link it from your site, itch page, web
  demo end screen and the phone apps' "More games" spot (allowed on your own channels, not on portals);
  post short GIFs of the glyph grid and Duel race; send keys to sudoku/puzzle YouTubers and Steam curators.
  Keep expectations modest: plain sudoku games are a crowded, low-price niche.
- **Discount rules:** launch discount max 40% for 7–14 days (Valve suggests 10–15%), then no discounts for
  30 days; 30-day cooldown between discounts; seasonal sales are exempt from cooldowns.

### 3.9 After launch

- Patches: upload → beta → default (SMS code). Write a short update event for each patch.
- Re-request the Deck review after input changes.
- Answer reviews, especially early negative ones about AI or price.
- Join seasonal sales after the 30-day window.

---

## 4. itch.io

### 4.1 Summary

Free, fast (same day), and the only store that takes the **web build** and the desktop builds on one page.
Good for a soft launch, a free web demo and early feedback. Revenue is small but the cut is yours to set.

### 4.2 Accounts and business setup

- Free account. **Payment mode:** "Collected by itch.io, paid later" (itch acts as the seller and handles
  VAT/sales tax; payouts on request after review) or "Direct to you" (PayPal; you handle taxes). For a solo
  developer, "Collected by itch.io" is simpler.
- **Tax interview:** W-9; without it itch withholds **30%**.
- **Revenue share:** default **10%** to itch, adjustable **0–100%** (Seller settings → Revenue sharing).
  Payment-processor fees (about 2.9% + $0.30 per transaction) come on top.
- Note: in July 2025 itch.io de-indexed adult content under payment-processor pressure and some payouts were
  delayed by tax-validation holds. That doesn't affect this game's content, but don't count on instant
  payouts.

### 4.3 Technical requirements (HTML5)

| Rule | Game | Status |
|---|---|---|
| Zip with `index.html` (entry point) | `dist/index.html` at the root | **OK** |
| ≤ 1,000 files after extraction | 56 files | **OK** |
| ≤ 500 MB extracted, ≤ 200 MB per file | 2.4 MB | **OK** |
| Path ≤ 240 characters, case-sensitive, UTF-8 | short relative paths | **OK** |
| Relative paths (served from a sub-folder) | `base: './'` | **OK** |
| Service worker | registered on the web build | **Needs change**: add a build flag to skip it for itch/portal embeds |
| Save data | `localStorage` with `alien-sudoku:` prefix | **OK** (itch's HTML games share a domain; the prefix avoids clashes) |

**Embed options:** "Embed in page" with your width/height (use e.g. **1024 x 720**) or "Click to launch in
fullscreen"; tick Fullscreen button and **Mobile friendly** (orientation: any). On phones itch always uses
click-to-launch fullscreen. Test after uploading that saves survive a new upload.

**Desktop uploads and butler:**

```bash
butler login
butler push <web-zip-folder>               <user>/alien-sudoku:html5   --userversion 1.0.0
butler push game/desktop/out/win-unpacked  <user>/alien-sudoku:windows --userversion 1.0.0
butler push game/desktop/out/linux-unpacked <user>/alien-sudoku:linux  --userversion 1.0.0
```

Channel names containing `win`/`windows`, `linux`, `mac`/`osx` set the platform tags (changeable later).
Mark the HTML5 upload "played in the browser" on the Edit game page. Unsigned Windows downloads show
SmartScreen; unsigned Mac zips need "Open Anyway" in System Settings → Privacy & Security. Say this on the page.

### 4.4 Store listing and assets

- **Cover image:** 315:250 ratio; minimum 315x250; **630 x 500** recommended (other shapes get cropped).
- **Screenshots:** no official size; 3–5 at 1920x1080 work well.
- **Trailer:** YouTube/Vimeo link. Optional banner/background via the theme editor.
- **Classification:** Kind of project = HTML (if the web version plays on the page); genre Puzzle; up to
  10 tags (sudoku, puzzle, logic, aliens, space, casual, relaxing, singleplayer, cute, sci-fi).
- **Pricing:** "Paid" with "let people pay more" (pay-what-you-want above a minimum, e.g. $3.99), or
  "$0 or donate" for a free demo page. If the browser version is a demo and downloads are paid, mark the
  browser upload as a demo or use a separate free demo page (check how a paid project shows the embed
  before publishing).

### 4.5 Forms: generative AI disclosure

Edit page → "Generative AI disclosure": **Yes**, tick **Graphics**, **Sound** (the music code was
AI-written), **Code**, and **Text & Dialog** if in-game text was AI-drafted. itch staff's own advice is
"if you have to ask, you should probably tag". The page gets the "AI Generated" tag and is hidden from the
"No AI" browse filter. Disclosure is strictly enforced for asset packs and optional-but-expected for games;
itch also treats mass-produced AI content as spam (not your case).

### 4.6 Testing, review and launch

No review step. Keep the page **Draft** or **Restricted** (secret URL), test the web embed on desktop and a
phone, finish a level, reload, check the save, download and run the Windows build, then make it **Public**
and post a devlog. After launch: devlogs for updates (butler pushes are patched incrementally for itch app
users).

---

## 5. Microsoft Store (Windows)

### 5.1 Summary

- **Account:** **free** for individual developers since Sept 10, 2025 (personal Microsoft account + ID and
  selfie verification); companies still pay **$99** one time.
- **Cut:** **12% for games** (15% for other apps).
- **Certification:** up to 3 business days; first submissions can take longer.
- **Best path for this game: MSIX** via electron-builder's `appx` target. Microsoft signs it (no
  certificate), hosts it, pushes updates, and Store commerce (paid apps) is tied to MSIX. The EXE/MSI path
  needs your own trusted signature, a versioned HTTPS URL, silent install, and has no Store-managed
  updates; community answers say EXE/MSI apps can't be sold for a price through the Store (could not confirm
  on an official page). Alternative: package the hosted PWA as "MSIX or PWA app" (smaller, but it's a web app).

### 5.2 Accounts

Partner Center → Individual → ID + selfie → tax profile (W-9) → payout account → **Apps and games → New
product → MSIX or PWA app** → reserve "Alien Sudoku". Copy **Product identity**: Package/Identity/Name,
Package/Identity/Publisher (`CN=...`) and Publisher display name.

### 5.3 Technical requirements

| Requirement | Game today | Status |
|---|---|---|
| MSIX/APPX package | no `appx` target | **Needs change** |
| Build machine | Linux workspace; electron-builder can't build MSIX on Linux | **Needs a Windows 10/11 PC** with the Windows SDK |
| Identity values match Partner Center | — | set `appx.identityName`, `appx.publisher`, `appx.publisherDisplayName` |
| Package logos | none | add PNGs in `desktop/build/appx/` (StoreLogo, Square44x44Logo, Square150x150Logo, Wide310x150Logo); otherwise you get placeholder art |
| Min Windows version | Electron 45 needs Windows 10+ | **OK** (10.0.17763 is the usual Store minimum) |
| Pass Windows App Certification Kit | not run | **Needs testing** |
| EXE/MSI path only: signed with a Microsoft-trusted CA, versioned HTTPS URL that never changes, silent install (`/S` for NSIS), offline installer, no bundleware | unsigned NSIS | **Needs change** if you choose this path |

Example config (fill in from Partner Center):

```json
"win": { "target": [ {"target":"nsis","arch":["x64"]}, {"target":"portable","arch":["x64"]}, {"target":"appx","arch":["x64"]} ] },
"appx": {
  "identityName": "<Package/Identity/Name>",
  "publisher": "CN=<from Partner Center>",
  "publisherDisplayName": "Eddie G",
  "applicationId": "AlienSudoku",
  "displayName": "Alien Sudoku",
  "languages": ["en-US"]
}
```

### 5.4 Store listing and assets

| Asset | Spec |
|---|---|
| Screenshots | ≥ 1 required, **≥ 4 recommended**, up to 10; desktop **≥ 1366 x 768**, up to 3840 x 2160; real PNG files |
| 2:3 Poster art (main logo for games) | **720 x 1080** or **1440 x 2160** |
| 1:1 Box art | **1080 x 1080** or **2160 x 2160** (used as the main logo if no poster art) |
| App tile icon | **300 x 300** (strongly recommended) |
| 16:9 Super hero art | **1920 x 1080** or **3840 x 2160** (recommended for games with trailers) |
| Trailer thumbnail | **1920 x 1080 PNG** |

Text: description, short description, features (reuse the Steam text). Category **Games → Puzzle & trivia**.
Privacy policy URL and support contact (from your site).

### 5.5 Forms

- **Age ratings:** IARC questionnaire (answers in 2.4). Keep the certificate ID.
- **Pricing and availability:** base price ($3.99), all markets, release "manually" after certification so
  you control the moment.
- **Properties:** game, single-player, no accessibility claims you haven't tested, keyboard and mouse.

### 5.6 Testing, submission, after launch

Run the Windows App Certification Kit on the `.appx`, install it locally (Developer Mode), play a full game,
uninstall. Submit; certification checks security, technical compliance (WACK) and content, up to 3
business days. If stuck after 72 hours, open a free Partner Center support ticket. Updates: new MSIX
submissions with higher versions.

---

## 6. Epic Games Store

### 6.1 Summary

- **Fee:** **$100 per product** (plus local tax), non-refundable, recouped in the payment after the product
  earns $1,000 from EGS purchases.
- **Cut:** since June 1, 2025 developers keep **100% of the first $1M net revenue per product per calendar
  year**, then **88/12**. (Epic First Run: 100% for 6 months but needs PC-store exclusivity; skip it,
  it conflicts with Steam and itch.)
- **Time:** onboarding (trader verification, tax profile, Hyperwallet payout) "might take more than two
  weeks"; then page, build, review (timing not published).
- **Fit:** works technically (upload the Windows folder), but small puzzle games get little traffic there.
  Optional, after Steam.

### 6.2 Accounts

Epic account (18+) → Developer Portal organization (type **Individual**) → accept the **Epic Games Store
Distribution Agreement** → **trader verification** (EU DSA; non-traders' details aren't shown publicly) →
**tax interview** (Personal / Sole proprietor / Single-member LLC; generates a W-9) → activate **Hyperwallet**
payouts → pay the $100 fee.

### 6.3 Requirements

- **Age rating:** IARC via the publishing tools (strongly recommended; unrated = highest maturity in every
  region). Main storefront content must stay at a moderate level whatever the rating.
- **Achievements:** if the game has achievements on another PC store (Steam), you must support Epic
  achievements (EOS) too, demos included. In-game-only achievements don't trigger this.
- **Cross-play:** only for multiplayer games (not applicable).
- **Accuracy:** product content and binary must match the store description; patch notes for major updates.
- **Platforms:** Windows build. The Epic launcher is Windows + macOS (Apple Silicon for the new client); a
  native Linux launcher is only in public preview (late 2026).
- **Refunds** (customer-facing, 2019 policy): within 14 days of purchase and under 2 hours of play.

### 6.4 Build upload

**BuildPatchTool** (CLI; a GUI "BuildPatch Tool Interface" exists): get its own Client ID/Secret from
Product Settings, then `-mode=UploadBinary` with organization, product, artifact, client ID, secret env var,
`-BuildRoot` = `win-unpacked`, cloud dir, build version, `-AppLaunch "Alien Sudoku.exe"`, `-AppArgs ""`.
Then set the binary **active** in Artifacts and add the Windows platform in the portal (self-service orgs
can't label via BPT). Docs mention BPT 1.7.3.1 and 1.8.6; use the newest listed.

### 6.5 Store assets

Epic's Storefront Media Guide defines offer images (general key art and Library images), a logo, the media
carousel (videos, screenshots, key art), up to 12 "About" blocks, 1–6 additional images and social previews.
Exact pixel sizes are shown in the portal; I could not verify them here. Third-party guides list **landscape
key art 2560 x 1440**, **portrait 1200 x 1600**, a wide logo and **≥ 5 screenshots** (unverified).

### 6.6 Review and launch

Submit the offer + binary for review; Epic checks that content and binary match the description. Release
after approval. No AI disclosure field.

---

## 7. GOG

### 7.1 Summary

- **Submit:** free form, about **15 questions**, at `gog.com/submit-your-game` (also `lp.gog.com/submit-your-game/en`).
  GOG reviews games in their final stage or already released and won't give feedback on early builds.
- **Odds:** highly curated; developers report long or no replies and "too niche" rejections. For a small
  sudoku game with AI-assisted art, odds are **low**. GOG's own use of AI images in January 2026 caused a
  backlash from its users, so its audience is sensitive to this.
- **Ownership:** CD Projekt sold GOG to co-founder Michał Kiciński (closed Dec 31, 2025, about $25M); GOG says
  nothing changes for users; I found no change to developer terms.
- **Revenue share:** not published; set in each game's distribution agreement (commonly reported 70/30;
  could not verify).

### 7.2 If accepted: requirements

- **DRM-free:** must run fully offline without GOG Galaxy (GOG QA tests this). The game already is.
- **Builds per OS** (Windows, plus macOS/Linux if you offer them), uploaded with **Build Creator** (GUI) or
  **Pipeline Builder** (CLI, `build-game` with a `project.json`). GOG generates **offline installers** on
  its servers after you publish to the master branch (and for day-1 launch after receiving the release
  candidate).
- **GOG Galaxy SDK:** optional (achievements, cloud saves, overlay).
- **Release candidate** at least **3–5 days** before launch, tested by you on a staging/beta branch via Galaxy.
- **Assets:** made from GOG's templates or asset tool: high-res key art and logo, **layered PSD**,
  screenshots, store descriptions, trailer with the **GOG logo on the end slate**. Your GOG product manager
  handles branding; exact sizes come with the templates (not public).

---

## 8. Web game portals

### 8.1 Does the game fit?

Technically yes: 2.4 MB, 56 files, responsive, offline, no external requests, keyboard + touch, content
well inside PEGI 12. The catch is business: portals pay through **their** ads, so a portal version means a
**free, ad-supported web version** that competes with your paid PC version. Decide that first.

### 8.2 CrazyGames

- **Basic Launch:** no SDK needed, **no ads/monetization**, a 7–21 day test (ends once live ≥ 7 days with
  ≥ 500 plays, or after 21 days).
- **Full Launch:** monetization on; **SDK required**; only SDK ads allowed (no external ads); progress must
  link to a CrazyGames account (their data module) for "Full Implementation"; no other portal's branding.
- **Size:** total ≤ 250 MB, initial download ≤ 50 MB (≤ 20 MB to be eligible for the mobile homepage). This
  game: **OK**.
- **Links:** no cross-promotion; **no app-store links in game**; community links only in the menu and not to
  a playable web version elsewhere. Remove "get it on Steam" type links in the portal build.
- **Money:** ad revenue share; split not published (a 2026 jam's terms reportedly gave developers 60% of ad
  revenue, 70% of in-game purchases; unverified). Payouts reportedly monthly via Tipalti, €100 minimum.
  Exclusivity optional (extra compensation for launch exclusivity reported; unverified).

### 8.3 Poki

- Developer program in **closed beta**; apply via form; every game human-reviewed.
- Prefers **Web Exclusive** deals: on the open web the game lives only on Poki (Steam and mobile stay
  allowed). Term reported as 5 years (third party) or 7 years (Poki's own page); read the contract. A
  non-exclusive category also exists.
- Revenue (Poki docs via search): **100%** of revenue from players you bring directly; **50/50** on Poki
  traffic.
- Conflict: a web-exclusive deal means taking the web build off itch and your own site.

### 8.4 Others

GameDistribution (ad rev-share via its SDK; third-party sources say ~33%+ to developers), Newgrounds (ad
rev-share), Armor Games (curated, one-off sponsorship). Coolmath Games has stricter content rules (younger
audience). None verified officially here.

### 8.5 Technical work for a portal build

The game already has interstitial-between-games and rewarded-for-hint/second-chance logic for AdMob
(`src/platform/ads.js`). A portal adapter behind a build flag can map interstitial → CrazyGames "midgame" /
Poki `commercialBreak`, rewarded → `rewardedBreak`, mute music and pause input during ads, call the portal's
gameplay start/stop events, and skip the service worker. Keep the PC and itch builds ad-free.

### 8.6 Hosting the web build yourself

Host `/play` (the demo or full web build), `/privacy`, `/press` and `/app-ads.txt` on your own domain root
(see 2.7). This is also the "developer website" for the phone apps' store listings.

---

## 9. Recommended order

1. Decide price + free/paid split; verify photo licenses; add credits; put up the website. (Week 1)
2. Pay the Steam fee (starts the 21-day clock) and start Steam, itch and Microsoft accounts. (Week 1)
3. Builds: Linux folder build, gamepad + fullscreen, web embed flag; MSIX on a Windows PC. (Weeks 1–3)
4. Art: key art, capsules, library art, screenshots, trailer, press kit. (Weeks 1–3)
5. itch.io soft launch (web demo + paid downloads). (Week 2–3)
6. Steam store page → Coming Soon; Microsoft Store submission. (Weeks 3–4)
7. Steam build review, Deck review, release (January 2027, or after a Next Fest). Microsoft release.
8. Later: Epic; GOG submission after Steam reviews come in; portals only if you want an ad-funded web version.

---

## 10. Sources (URL and what it confirmed)

**Steam**
- https://partner.steamgames.com/doc/gettingstarted/appfee : $100 fee per app, recouped after $1,000 AGR; only admins can pay.
- https://partner.steamgames.com/steamdirect : Steam Direct; 21-day wait; onboarding 15–30 days.
- https://partner.steamgames.com/doc/gettingstarted/onboarding : 21-day wait between paying the fee and release (a 2025-07-21 revision said 30 days); paperwork 15–30 days.
- https://partner.steamgames.com/doc/gettingstarted/faq : TaxIdentity (Lilaham) interview, legal name only, bank in same name, W-9/W-8, new TIN up to 30 days.
- https://partner.steamgames.com/doc/store/coming_soon : Coming Soon ≥ 2 weeks before release; submit ≥ 7 business days ahead.
- https://partner.steamgames.com/doc/store/releasing : store review 3–5 business days, build review 1–5 days, manual release button.
- https://partner.steamgames.com/doc/store/release_dates : release date locked within 14 days.
- https://partner.steamgames.com/doc/store/review_process : what review checks (launch on every listed OS, listed features exist, not QA, plan 7 business days).
- https://partner.steamgames.com/doc/store/assets : overview, Aug 2024 size change, header 920x430, small 462x174, event cover 800x450, app icon 184x184.
- https://partner.steamgames.com/doc/store/assets/standard : main 1232x706, vertical 748x896, small capsule derivatives, page background 1438x810, ≥ 5 screenshots ≥ 1920x1080, mark ≥ 4 all-ages.
- https://partner.steamgames.com/doc/store/assets/libraryassets : library capsule 600x900, header 920x430, hero 3840x1240 (no text, 860x380 safe area), logo 1280w/720h.
- https://partner.steamgames.com/doc/store/assets/rules and /doc/store/assets/overrides : capsule text rules; overrides 14 days.
- https://partner.steamgames.com/doc/store/assets/community : shortcut icon 256/512 ICO or PNG.
- https://partner.steamgames.com/doc/store/trailer : trailer formats and thumbnail.
- https://partner.steamgames.com/doc/sdk/uploading : steamcmd run_app_build, SetLive can't target default, launch options per OS, local branch rule from Sept 2026.
- https://partner.steamgames.com/doc/store/application/platforms : macOS 64-bit + notarized requirement, overlay entitlements.
- https://partner.steamgames.com/doc/store/application/platforms/linux : Linux runtime per branch, %command%.
- https://partner.steamgames.com/doc/steamhardware/compat : Deck/Steam Machine review: Verified vs Playable, controller rules, 9 px text at 1280x800, request for unreleased games after build review, ~1 week.
- https://partner.steamgames.com/doc/store/pricing , /doc/marketing/discounts : regional pricing, launch discount ≤ 40% for 7–14 days, 30-day rules.
- https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027 and /june_2027 : Next Fest dates and deadlines.
- https://partner.steamgames.com/doc/store/application/demos : demo app rules.
- https://www.helpnetsecurity.com/2023/10/17/steam-sms-confirmation/ : SMS code to set default-branch builds live on released apps.
- https://www.remio.ai/post/steam-ai-disclosure-policy-updated-efficiency-tools-now-exempt and https://finance.biggo.com/news/202601171220_Steam_AI_Disclosure_Update_Focuses_on_Player_Content : January 2026 AI survey rewrite (secondary sources).
- https://github.com/electron/electron/issues/18265 , https://steamcommunity.com/app/221410/discussions/8/3373782977089871287/ , https://log.schemescape.com/posts/game-development/web-game-on-steam-for-linux-2.html : Electron needs `--no-sandbox` under Steam on Linux (community).
- https://github.com/JamesMoulang/electron-steam-notes , https://www.npmjs.com/package/steamworks.js : overlay flags, steamworks.js (community).
- https://beancount.io/sk/blog/2026/07/09/steam-revenue-share-indie-game-developer-bookkeeping-guide : 30/25/20 marginal tiers.
- https://www.dekudeals.com/items/sudoku-pro , https://www.dekudeals.com/items/sudoku-mania , https://club.steam250.com/app/3586880 : price band of Steam sudoku games.

**itch.io**
- https://itch.io/docs/creators/html5 : zip + index.html, 1,000 files, 500 MB, 200 MB per file, 240-char paths, embed and mobile behaviour.
- https://itch.io/docs/creators/getting-started : cover 315:250, 630x500 recommended.
- https://itch.io/docs/creators/payments : 10% default share adjustable 0–100%, processor fees.
- https://itch.io/docs/butler/pushing.html : butler push syntax and channel naming.
- https://itch.io/docs/creators/quality-guidelines and https://itch.io/t/4309690/generative-ai-disclosure-tagging : AI disclosure field (Graphics/Sound/Text/Code), "AI Generated"/"No AI" tags.
- https://www.engadget.com/2305699/itchio-adds-a-filter-for-games-with-gen-ai-disclosures/ : "No AI" filter.
- https://itch.io/t/1158456/html5-local-storage-seems-to-be-shared-between-multiple-games : shared localStorage domain (community).
- https://www.pcgamer.com/gaming-industry/game-development/itch-io-is-actively-reaching-out-to-other-payment-processors-after-pressure-from-credit-card-companies-to-curtail-nsfw-content-and-that-compared-to-valve-it-has-limited-ability-to-push-back/ : 2025 payment-processor events.

**Microsoft**
- https://blogs.windows.com/windowsdeveloper/2025/09/10/free-developer-registration-for-individual-developers-on-microsoft-store/ : free individual registration; ID + selfie; companies $99; 12% games.
- https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msi/app-package-requirements : EXE/MSI rules (trusted signing, versioned URL, silent install, offline installer).
- https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/choose-distribution-path : MSIX vs EXE/MSI; Store commerce tied to MSIX.
- https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/screenshots-and-images : screenshot, poster, box art, hero, tile specs.
- https://learn.microsoft.com/en-us/windows/apps/publish/store-readiness-checklist : real PNGs, WACK.
- https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-certification-process : up to 3 business days.
- https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options : Store re-signs MSIX; Artifact Signing $9.99/mo, individuals USA/Canada only; OV $150–300; EV bypass removed 2024.
- https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation : SmartScreen reputation model.
- https://www.electron.build/docs/appx and https://www.electron.build/docs/msix/ : appx/MSIX target, Windows-only build, identity fields.
- https://devdocs.xbox.com/publishing/game-publishing/concepts/age-ratings : IARC free, questionnaire in Partner Center, reuse certificate IDs.

**Epic**
- https://dev.epicgames.com/docs/epic-games-store/publishing-tools/organization-management/manage-org : $100 per product, recouped after $1,000.
- https://store.epicgames.com/en-US/news/epic-games-store-updates-revenue-share-keep-100-of-the-first-1m-per-product-per-year : 100% of first $1M per product per year from June 1, 2025, then 88/12.
- https://dev.epicgames.com/docs/epic-games-store/store-presence/epic-first-run : First Run needs no prior PC-store release.
- https://dev.epicgames.com/docs/epic-games-store/requirements-guidelines/distribution-requirements/requirements-overview : 18+, agreement, IARC strongly recommended, unrated = highest maturity, review, patch notes.
- https://dev.epicgames.com/docs/epic-games-store/publishing-tools/organization-management/manage-finance : trader verification, tax profile (W-9), Hyperwallet, 2+ weeks.
- https://dev.epicgames.com/docs/epic-games-store/publishing-tools/uploading-binaries : BuildPatchTool usage, set binary active.
- https://dev.epicgames.com/docs/epic-games-store/sales-and-marketing/marketing/storefront-media-guide : offer images, carousel, About blocks.
- https://forums.unrealengine.com/t/achievements-needed-in-demo-if-full-version-includes-it/1153970 : achievements rule (Epic staff on forum).
- https://www.pcgamer.com/epic-games-store-now-allows-refunds-for-any-reason : 14 days / 2 hours refunds (2019).
- https://www.gamingonlinux.com/2023/03/prepare-to-see-a-lot-more-of-epic-online-services-with-epics-new-self-publishing/ : self-publishing requirements; no Linux client then.
- https://www.techradar.com/ai-platforms-assistants/steam-requires-ai-game-disclosures-epics-ceo-says-theyre-meaningless : Epic has no AI disclosure requirement.

**GOG**
- https://lp.gog.com/submit-your-game/en : ~15-question submission form.
- https://support.gog.com/hc/en-us/articles/11382878039197-Releasing-your-game-on-GOG-FAQ : submit near-final or released games; no feedback for early builds.
- https://docs.gog.com/release-flow/ , https://docs.gog.com/quality-assurance/ : RC 3–5 days before launch; QA checks offline/no-DRM.
- https://docs.gog.com/build-delivery/ , https://docs.gog.com/pb-build-game/ , https://docs.gog.com/offline-installers/ : Build Creator / Pipeline Builder; GOG-generated offline installers.
- https://docs.gog.com/basic-game-assets/ : templates, key art + logo, layered PSD, trailer with GOG end slate.
- https://sites.google.com/gog.com/terms-and-conditions/terms-and-conditions : DRM-free definition; share set per agreement.
- https://www.videogameschronicle.com/news/its-going-into-very-good-hands-cd-projekt-is-selling-gog/ : sale to Michał Kiciński.
- https://www.gamingonlinux.com/2026/02/gog-did-an-ama-and-heres-some-highlights-like-how-theyll-continue-using-generative-ai : GOG and generative AI backlash.

**Web portals and hosting**
- https://docs.crazygames.com/requirements/intro/ , /requirements/technical/ , /requirements/quality/ : Basic vs Full Launch, size limits, link and ad rules, account linking.
- https://app.cinevva.com/guides/publish-game-crazygames : 60%/70% jam terms, €100 Tipalti payouts (third party).
- https://sdk.poki.com/ and https://sdk.poki.com/deals.html : closed beta, Web Exclusive vs Non-Exclusive, revenue split.
- https://support.google.com/admob/answer/9363762 : app-ads.txt at the developer-website host root.
- https://docs.github.com/en/pages : GitHub Pages (public repos on free plans).

**Signing and licenses**
- https://cabforum.org/working-groups/code-signing/requirements/ : 460-day max validity from March 1, 2026.
- https://esawebb.org/copyright : ESA/Webb CC BY 4.0, visible credit, logos excluded.
- https://esahubble.org/copyright/ : ESA/Hubble CC BY 4.0, no implied endorsement.
- https://openfontlicense.org/ : SIL OFL terms (license must travel with fonts).

### Could not verify (check before relying on it)

- Steam: exact current AI survey wording (only secondary sources); whether Steam publishes DSA trader
  contact details; whether demos ever need a fee; payment schedule.
- Epic: exact store image sizes and screenshot minimum; review duration; current refund policy wording.
- GOG: revenue share, acceptance rate, response time, store asset sizes.
- Microsoft: whether EXE/MSI apps can be paid in the Store; ID-verification turnaround.
- itch.io: whether a paid HTML project shows the browser embed to non-buyers; payout hold times.
- CrazyGames and Poki revenue splits and exclusivity bonuses; Poki exclusivity length.
- No exact-name "Alien Sudoku" game showed up on Steam, itch or Google Play in a quick search (not a
  trademark search).
