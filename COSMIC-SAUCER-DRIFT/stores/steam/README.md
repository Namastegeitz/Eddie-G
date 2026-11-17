# **COSMIC SAUCER DRIFT** · Steam

**Cost:** $100 per game (paid back only after $1,000 revenue, so a free game never gets it
back). **Time:** at least 30 days from paying the fee. Pay it early: the wait runs alongside
everything else.

## Already done (on this computer)
- Windows, Linux and macOS builds → [`../../builds/`](../../builds/) (macOS still unsigned)
- Full gamepad, keyboard and mouse support; runs at 1280×800 (Steam Deck size)
- Store text to adapt → `game/docs/STORE_LISTING.md`
- 7 screenshots at 1920×1080 → [`../screenshots/1920x1080/`](../screenshots/1920x1080/)
- Trailer, 1920×1080, 30 fps, with music → [`../trailer/`](../trailer/)

## Missing
- [ ] Steamworks account: identity, tax interview, bank (15–30 days in total)
- [ ] Store assets at Steam's sizes (Claude can render them from the game)
- [ ] Content survey: answers in [`../AGE_RATINGS.md`](../AGE_RATINGS.md), AI disclosure ready in [`AI_DISCLOSURE.md`](AI_DISCLOSURE.md)
- [ ] steamcmd upload: blocked on this computer (download host not allowed); works from
      any PC with the Steamworks SDK

## Requirements today
| Item | Rule |
|---|---|
| Waiting period | 30 days after paying the fee before release |
| Coming Soon page | Public **≥14 days** before release |
| Store page review | 3–5 business days (plan 7) |
| Build review | 3–5 business days (plan 7; backlogs reported in 2026) |
| Store capsules | Header 920×430 · Small 462×174 · Main 1232×706 · Vertical 748×896 |
| Library | Capsule 600×900 · Hero 3840×1240 · Logo 1280 wide and/or 720 tall (transparent) · Header 920×430 |
| Optional | Page background 1438×810 |
| Screenshots | ≥5, ≥1920×1080, 16:9, real gameplay |
| Ratings | No ESRB/PEGI needed; the content survey creates Germany/Indonesia ratings |
| Steamworks API | Not required (only the SDK's upload tool) |
| Steam Deck | Optional review; native Linux build tested first; check text readability at 1280×800 |
| Next Fest (optional) | Feb 2027: register by 10 Jan · Jun 2027: register by 25 Apr. Needs an unreleased game with a demo |

## Steps
1. Join Steamworks, pay $100, finish identity/tax/bank.
2. Create the app as **Free** (or paid; free → paid is generally not allowed later).
3. Fill the store page, content survey and system requirements (Windows 10+, OpenGL 3.3 / Vulkan GPU).
4. Submit the store page → go **Coming Soon** (≥14 days).
5. Upload Windows, Linux and macOS depots with steamcmd → submit the build for review.
6. Release once 30 days have passed since the fee.

Sources: https://partner.steamgames.com/doc/gettingstarted/appfee ·
https://partner.steamgames.com/steamdirect · https://partner.steamgames.com/doc/gettingstarted/onboarding ·
https://partner.steamgames.com/doc/store/review_process · https://partner.steamgames.com/doc/store/assets ·
https://partner.steamgames.com/doc/store/trailer · https://partner.steamgames.com/doc/gettingstarted/contentsurvey ·
https://partner.steamgames.com/doc/sdk/uploading · https://partner.steamgames.com/doc/steamhardware/compat ·
https://partner.steamgames.com/doc/store/freetoplay
