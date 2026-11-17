# **CANOPY CROSSING: content-rating answers (draft)**

Answers for the age-rating questionnaires (Google Play's IARC questionnaire,
which also gives the ESRB, PEGI, USK, ClassInd and other ratings; Apple's
age-rating questions in App Store Connect; Amazon, Samsung and Microsoft use
IARC too; Steam asks its own "mature content" questions). Written from what
is in the game today (checked in its content files on 2026-11-17). Answer
the real questionnaire honestly on the day; if the game changes, the answers
change.

| Topic | In the game | Answer |
|---|---|---|
| Violence | Cartoon animals get "snapped up" by crocodiles, "bitten" by snakes, "squashed" by elephants or "flattened" by trucks, fall off ledges or into water. No blood, no gore, no bodies left behind: the animal flashes and the run continues or restarts. Real animals, stylised. | Cartoon / fantasy violence, mild, not realistic. No blood. No violence against humans (there are no people on screen). |
| Fear | Crocodiles bursting from water, snakes striking, eagles swooping. | Mild; occasional startling moments (answer "yes" to mild scary scenes if asked). |
| Language | None. | No. |
| Sexual content / nudity | None. | No. |
| Drugs, alcohol, tobacco | None. | No. |
| Gambling | No real-money or simulated gambling. No random paid items (no loot boxes): every product's contents are listed before purchase. Daily rewards are fixed. | No gambling; no loot boxes. |
| In-app purchases | Yes: currency (Amber), animal and map packs, bundles, Remove Ads, a season pass (Expedition Pass). | Yes, digital purchases. On Google Play also declare "In-app purchases"; on Apple they're shown automatically. |
| Ads | Planned: AdMob rewarded videos (opt-in) and between-run ads; none during play. Currently a sandbox. | Declare "contains ads" only if the shipped build shows real ads. |
| User interaction | No chat, no user-generated content, no friends list, no sharing of location. | No interaction between users. |
| Personal info shared | None leaves the device (see privacy-policy.md). | No. |
| Location | Not used. | No. |
| Unrestricted web access | No in-game browser. | No. |
| Medical / health info | None. | No. |
| Contests | None. | No. |

**Expected result** (the questionnaires decide; answer honestly):

- **Google Play / IARC**: ESRB Everyone, PEGI 3 or 7 (7 if the scary moments count), with the
  "In-Game Purchases" descriptor.
- **Apple** (tiers 4+, 9+, 13+, 16+, 18+ since 2025-26): cartoon/fantasy violence that is
  *infrequent* gives **9+**; if being snapped up or squashed (the normal way a run ends) counts
  as *frequent*, it's **13+**. Advertising alone is 4+ globally but **A12 in Brazil**. Making
  deaths non-violent (a puff or a bonk) is the design lever to keep it lower. Answer **No** to
  loot boxes (daily deals show their contents before purchase), and No to the new questions:
  Shared Location and Dating and Relationships (required since 2026-11-16, all apps by
  2027-01-12) and the social-media questions (required since Sept 2026).
- Apple's "Made for Kids" option exists only at 4+/9+ and **can't be undone after approval**.

**Audience.** The game is family-friendly and appeals to children but isn't designed only for
them. Google Play asks for target age groups: choosing under-13 brings the **Families policy**
(certified ad SDKs only, child-directed ads with a G content cap, a neutral age screen, no
personalised ads to children), and choosing 13+ only means the store listing must not
primarily appeal to children, or Google rejects it. Apple has no audience setting beside the
rating and Made for Kids; **don't choose the Kids category** (it bans third-party ads and
analytics without parental gates), never say "for kids" in the listing, and treat the game as
mixed-audience. The amended US COPPA Rule (compliance by 2026-04-22) applies to apps that
attract children: get legal advice before turning on ads. Researched details:
`../apple-app-store/requirements.md` (sections 2.6-2.8) and `../google-play/requirements.md`
(section 2.3).
