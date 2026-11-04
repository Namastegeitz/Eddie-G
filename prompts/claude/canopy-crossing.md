<!-- Source: Claude doc https://claude.ai/artifact/FE6JJoUKuFcJnjBY9asHTT (copied 2026-11-04) -->

# Canopy Crossing — Game Build Prompt

2026-11-04 · eddie

> Paste everything below into your coding agent (Claude Code, etc.). It is written as a direct brief to the builder. Working title *Canopy Crossing* — rename freely.

## Build goal

You are building **Canopy Crossing**, a mobile-first arcade "crosser" in the lineage of Frogger, reskinned and expanded around a jungle/rainforest theme. The player guides a chosen wild animal across a scrolling stack of hazard lanes — rivers, logging trails, swamp channels, ant highways — hopping one tile at a time and timing each move to avoid being crushed, eaten, or swept away. The twist: the player picks from a roster of up to **50 real jungle animals**, each with a signature movement ability, and every level is a **different real-world rainforest** (Amazon, Congo, Borneo, Daintree, and more) with its own hazards, palette, and wildlife. The game is free to start and monetized with in-app purchases: unlockable animals, downloadable real-world map regions, power-ups, cosmetics, and a rotating season pass.

**Hard requirement:** build it data-driven, so animals, maps, and the store catalog are content files — not code. The roster and map list must grow without touching gameplay logic.

- **Genre:** single-screen / endless arcade crosser
- **Platform:** portrait mobile (iOS + Android) first; also runs on desktop
- **Controls:** one-thumb play — tap-to-hop or directional swipe
- **Tone:** vivid, friendly, lightly educational (real animals, real places)
- **Monetization:** free download; IAP for animals, maps, power-ups, cosmetics, and a season pass; opt-in rewarded ads

## Core gameplay

Move your animal from the bottom of the screen to the safe zone at the top (Journey mode) or survive as long as possible (Endless mode), crossing a stack of moving hazard lanes.

- **Movement:** grid-based, one tile per input. Tap ahead = hop forward; swipe up / down / left / right = hop that way. Discrete snapping, Frogger-style — no free roaming.
- **Lane types:**
- *Trail / ground lanes* — hazards move across (logging trucks, stampeding peccaries, rolling logs). Get hit = fail.
- *Water lanes* (rivers, swamp, flooded channels) — water is deadly unless you ride a floating platform (log, lily pad, caiman back, drifting branch). Platforms carry you sideways and can drift you off-screen.
- *Safe lanes* — banks and grassy strips between hazards to pause and time the next hop.

- **Dynamic hazards & predators:** snakes that strike along a lane, crocodiles that surface, raptors that swoop a column, quicksand tiles, slash-and-burn fire lanes, and tides that rise and fall.
- **Scoring:** +1 per forward row, bonus for reaching the goal, a combo multiplier for continuous forward progress, and collectible fruit / insects that convert to currency. Highest row reached sets the Endless high score.
- **Fail states:** crushed, eaten, drowned, swept off-screen, or (on harder maps) an optional per-move timer runs out.
- **Modes:** *Journey* — fixed levels, each a real region, with a goal and rising difficulty; *Endless* — procedurally stacked lanes, score chase; plus an optional daily challenge.

## The 50 playable animals

Grouped by home region. Each has one **signature ability** that changes how it crosses; **rarity** drives unlock cost and store tier. Five are free starters; the rest unlock with soft currency (Berries) or premium currency (Amber), and many are bundled into their regional pack. Ship abilities as reusable modules so new animals just reference an existing one.

| # | Animal | Home region | Signature ability | Rarity | Unlock |
|---|---|---|---|---|---|
| 1 | Poison Dart Frog | Amazon | Precise reliable hop (baseline) | Common | Free starter |
| 2 | Red-Eyed Tree Frog | Amazon | Double-hop (clears 2 tiles) | Common | Berries |
| 3 | Capybara | Amazon | Floats — safe on one water lane | Rare | Berries |
| 4 | Three-Toed Sloth | Amazon | Slow, but camouflage ignores one predator | Rare | Berries |
| 5 | Toco Toucan | Amazon | Glide hop (longer forward jump) | Rare | Berries |
| 6 | Howler Monkey | Amazon | Vine-swing across a gap | Epic | Amazon pack |
| 7 | Green Anaconda | Amazon | Slithers 2 tiles fast; cannot idle on water | Epic | Amazon pack |
| 8 | Scarlet Macaw | Amazon | Short hover over a lane | Epic | Amazon pack |
| 9 | Jaguar | Amazon | Sprint dash (3-tile burst) | Epic | Amazon pack |
| 10 | Giant Otter | Amazon | Fast and safe in water lanes | Rare | Berries |
| 11 | Harpy Eagle | Amazon | Swoop — skip a lane on cooldown | Legendary | Amber |
| 12 | Capuchin Monkey | Amazon | Grabs collectibles one lane away | Rare | Berries |
| 13 | Western Gorilla | Congo | Smashes one obstacle clear | Epic | Free starter |
| 14 | Okapi | Congo | Steady — resists water-current drift | Rare | Berries |
| 15 | Chimpanzee | Congo | Tool use — temporary one-hit shield | Epic | Congo pack |
| 16 | Forest Elephant | Congo | Cannot be knocked back; slower | Rare | Berries |
| 17 | Mandrill | Congo | Intimidate — nearby predators pause | Epic | Congo pack |
| 18 | African Grey Parrot | Congo | Hover glide | Rare | Berries |
| 19 | Bonobo | Congo | Agile double swing | Rare | Berries |
| 20 | Leopard | Congo | Climbs — skips a ground hazard briefly | Epic | Congo pack |
| 21 | Pangolin | Congo | Rolls into an armored invincible dash | Legendary | Amber |
| 22 | Orangutan | Borneo | Long vine swings over gaps | Epic | Free starter |
| 23 | Proboscis Monkey | Borneo | Big leap over a full water lane | Rare | Berries |
| 24 | Sun Bear | Borneo | Fast climber | Common | Berries |
| 25 | Rhinoceros Hornbill | Borneo | Glide hop | Rare | Berries |
| 26 | Slow Loris | Borneo | Toxic — predators avoid it | Rare | Berries |
| 27 | Colugo (flying lemur) | Borneo | Glides across 2 lanes | Epic | Borneo pack |
| 28 | Binturong | Borneo | Balanced all-rounder | Common | Berries |
| 29 | Wallace's Flying Frog | Borneo | Glide-jump (floats on descent) | Rare | Berries |
| 30 | Sunda Clouded Leopard | Borneo | Stealth — predators miss once | Legendary | Amber |
| 31 | Sumatran Tiger | Sumatra | Sprint dash and swims | Epic | Borneo pack |
| 32 | Southern Cassowary | Daintree | Powerful forward charge (2 tiles) | Epic | Free starter |
| 33 | Tree Kangaroo | Daintree | Huge hop (2–3 tiles) | Rare | Berries |
| 34 | Green Tree Python | Daintree | Slither-climb | Common | Berries |
| 35 | Sugar Glider | Daintree | Glides a lane | Rare | Berries |
| 36 | Platypus | Daintree | Swims safely in water | Rare | Berries |
| 37 | Bird of Paradise | New Guinea | Dazzle — distracts a predator | Epic | Daintree pack |
| 38 | Kookaburra | Daintree | Flight hop | Common | Berries |
| 39 | Short-beaked Echidna | Daintree | Curls — brief invincibility | Rare | Berries |
| 40 | Ring-Tailed Lemur | Madagascar | Nimble multi-hop | Common | Free starter |
| 41 | Aye-Aye | Madagascar | Night vision — reveals hidden hazards | Epic | Madagascar pack |
| 42 | Fossa | Madagascar | Predator sprint | Epic | Madagascar pack |
| 43 | Panther Chameleon | Madagascar | Camouflage — invisible briefly | Legendary | Amber |
| 44 | Tomato Frog | Madagascar | Startle puff — pushes back one hazard | Rare | Berries |
| 45 | Resplendent Quetzal | Costa Rica | Graceful long glide | Legendary | Amber |
| 46 | Spider Monkey | Costa Rica | Chained vine swings | Epic | C. America pack |
| 47 | Kinkajou | Costa Rica | Night climber | Rare | Berries |
| 48 | Coatimundi | Costa Rica | Sniffs out bonus collectibles | Common | Berries |
| 49 | Baird's Tapir | Costa Rica | Plows through brush obstacles | Rare | Berries |
| 50 | Bengal Tiger | Sundarbans | Apex sprint and strong swim | Legendary | Amber |

## Real-world jungle maps

Each Journey level is a real rainforest somewhere on Earth, with its own hazards, palette, music, and native animals. The **Amazon is free** to start; every other region is an unlockable **Map Pack** that also bundles its native animals. A world-map / spinning-globe selector shows which regions are owned, locked, or coming soon.

| Region | Real location | Signature hazards | Look | Access |
|---|---|---|---|---|
| Amazon Basin | Brazil / Peru | Caiman rivers, floating logs, leafcutter-ant highways, falling branches | Emerald canopy, muddy rivers, light shafts | Free (start here) |
| Congo Basin | DR Congo | Swamp channels, forest-elephant trails, river rapids, poacher jeeps | Dense dark green, misty clearings | Map pack |
| Borneo | Malaysia / Indonesia | Logging trucks, blackwater rivers, palm-oil clearings, swinging vines | Steamy lowland, muddy water | Map pack |
| Daintree | Queensland, Australia | Mangrove tides, croc rivers, cassowary territory, cyclone gusts | Ancient ferns, coastal rainforest | Map pack |
| Masoala | Madagascar | Eroded gullies, slash-and-burn fire lanes, fast streams | Red earth, spiny + rainforest mix | Map pack |
| Monteverde | Costa Rica | Low-visibility mist, swaying hanging bridges, rushing creeks | Pale fog, moss, hanging gardens | Map pack |
| Sundarbans | India / Bangladesh | Tidal channels, Bengal-tiger ambush zones, boat traffic | Mangrove maze, brackish water | Map pack |
| Western Ghats | India | Monsoon floods, tea-estate roads, waterfalls | Lush hills, heavy rain | Map pack |
| Bwindi | Uganda | Steep mountain forest, mudslides, narrow ridges | Highland jungle, mist | Map pack |
| New Guinea Highlands | Papua New Guinea | River gorges, rope bridges, sudden downpours | Remote highland forest | Map pack |

Define each map as data: region id, lane-layout generator, hazard set, palette, soundtrack, difficulty curve, and the list of native animals it unlocks. Adding a region is a new data file plus art — no gameplay-code changes.

## Store and monetization

Free to download and play; purchases add variety, flair, and convenience — never a wall. Two currencies drive the economy.

- **Berries** (soft) — earned from runs, daily rewards, and challenges; buy common/rare animals and consumables.
- **Amber** (premium) — bought with real money (occasionally earned); buys legendaries, cosmetics, and converts to Berries.

**In-app purchase catalog** (prices illustrative):

| Item | Type | What it is | Example price |
|---|---|---|---|
| Remove Ads | One-time | Kills interstitials; keeps optional rewarded ads | $2.99 |
| Starter Bundle | One-time | Amber + 3 animals + 1 map, discounted | $4.99 |
| Regional Animal Pack | Unlock | Every animal from one region | $3.99 |
| Map Region Pack | DLC unlock | One real-world map + its hazards + native animals | $2.99 |
| Amber packs | Consumable | 100 / 550 / 1200 / 3000 Amber | $0.99–$19.99 |
| Expedition Pass | Season | 30-day reward track: animals, cosmetics, Berries | $7.99 / season |
| Mega Bundle | One-time | All current maps + animals | $24.99 |

**Power-ups / consumables** (Berries or Amber): Extra Lives, Shield Totem (one-hit block), Vine Grapple (pull forward 2 lanes), Time-Slow (slows hazards briefly), Revive (continue after death), Berry Doubler (24h).

**Cosmetics** (Amber, pure vanity): animal skins (Golden Jaguar, Albino Python), hop trails, idle emotes, goal-zone flags.

**Ads (player-friendly):** opt-in rewarded video for Berries, a revive, or doubled run rewards; a light interstitial between runs (removable). No forced ads mid-run.

**Live ops:** rotating daily deals, weekend 2x Berries, a limited-time "animal of the week," and seasons themed around a featured region.

**Design rule:** every map is beatable with the free starter animals. Purchases are optional depth, not a paywall over fun.

## Player prompts and onboarding

The game guides the player with short, timely prompts — never walls of text, never nagging mid-run.

- **First-launch tutorial:** 3–4 coached prompts over a gentle Amazon lane — "Tap ahead to hop," "Wait for the gap," "Ride the log across the river," "Reach the glowing safe zone." Finger-tap hints, minimal words.
- **Animal-select carousel:** before each run, a swipeable carousel of up to **50 animals**. Each card shows the animal, its region flag, a rarity gem, its signature ability, and a lock/price if not owned. Owned = *Equip*; locked = prompt the store. Filter by region and rarity.
- **Region intro cards:** entering a new map shows a card — region name, a globe spin / map pin to the real location, one or two real facts ("The Amazon holds around 10% of known species on Earth"), and the new hazards to expect. This is the "different part of the world" hook.
- **Contextual store prompts:** surfaced only at natural moments — after a death ("Revive for 1 Amber?"), at a milestone ("You've reached Congo — unlock the Congo pack?"), when low on lives, or when tapping a locked animal.
- **Progress nudges:** daily reward popup, challenge of the day, animal of the week, and season-pass progress. All soft and dismissible.
- **Conservation touch (on-brand, optional):** each animal card can carry a one-line real conservation status ("Vulnerable") — light, educational, and good for marketing.
- **Accessibility:** colorblind-safe hazard markers, left/right-hand toggle, haptics on/off, instant restart.

## Phased build plan (stop and show at each checkpoint)

Build in order. **Finish and show me each phase before starting the next.** Keep everything data-driven so the remaining animals and maps are just new content files.

- **Phase 0 — Setup.** Scaffold the project in the chosen engine, portrait mobile resolution, empty game loop, version control. *Checkpoint: a blank game window runs on device/emulator.*
- **Phase 1 — Core crosser loop.** One animal, one lane-stack, grid hop (tap + swipe), one ground lane and one water lane with riding platforms, collision, fail + restart, score by row. *Checkpoint: I can cross and die on a single screen — show a short clip.*
- **Phase 2 — Animal system (data-driven).** Define the Animal schema (id, name, region, sprite, ability, rarity, unlock); load from a content file; implement 3–4 abilities as reusable modules (double-hop, float, dash, glide); build the select carousel. *Checkpoint: I can pick 3 animals and feel the differences.*
- **Phase 3 — Map / region system (data-driven).** Define the Map schema (region, lane generator, hazard set, palette, music, native animals); build Amazon + one more region from data; world-map selector; Journey and Endless modes. *Checkpoint: two regions that look and play differently.*
- **Phase 4 — Economy and save.** Berries + Amber, earning, persistent save (owned animals/maps, high scores, currency), unlock flow with soft currency. *Checkpoint: earn Berries, unlock an animal, relaunch — still owned.*
- **Phase 5 — Store and IAP scaffold.** Store UI, catalog from a data file, mock purchase flow first, then wire the platform billing SDK behind a flag; map packs as downloadable/unlockable content. *Checkpoint: buy a map pack in sandbox and play it.*
- **Phase 6 — Prompts and onboarding.** Tutorial, region intro cards, contextual store prompts, daily reward, season-pass track. *Checkpoint: a first-timer is guided from launch to first unlock without confusion.*
- **Phase 7 — Art, audio, and juice.** Final sprites/animations, per-region palettes and music, hop/hit/collect feedback, particles, screen shake, menus. *Checkpoint: it feels alive and distinct per region.*
- **Phase 8 — Platform, ads, analytics, ship.** Rewarded + interstitial ads (opt-in), analytics events (runs, deaths, purchases, funnels), store listings, icons, builds for iOS + Android + desktop. *Checkpoint: signed builds, a sandbox purchase, and events firing.*

## Tech, art, and acceptance criteria

- **Recommended stack:** Godot 4 (GDScript) — one codebase exports to iOS, Android, and desktop, which fits the phone-plus-computer goal. Alternative: Phaser 3 + TypeScript for a web build. State the choice before Phase 0.
- **Data-driven mandate:** animals, maps, store catalog, and lane generators live in JSON / resource files, not code. Adding an animal or map = add a file plus assets, with zero gameplay-code changes. This is the hard requirement that makes 50 animals and many maps sustainable.
- **Art direction:** bright, stylized, high-contrast top-down (flat-shaded 2.5D or clean 2D). Readable animal silhouettes. Hazards clearly telegraphed by color and motion. Distinct palette and canopy framing per region. Friendly, not photoreal.
- **Audio:** an ambient rainforest bed and distinct music per region; crisp SFX for hop / splash / collect / fail; light haptics.
- **Controls / UX:** one-thumb portrait, tap-to-hop or directional swipe, left/right-hand toggle, large touch targets, instant restart.

**Definition of done:**

- Runs at 60fps on mid-range phones, portrait
- All content data-driven — a new animal or map is added by file only
- 5 free starter animals + the Amazon map are fully playable with zero purchases; every map is beatable free
- Carousel lists up to 50 animals with clear owned / locked / price states
- Save persists across relaunch; purchases restore
- No forced mid-run ads — all monetization is opt-in or between runs
- Each region has a distinct look, hazard set, and intro card
- Store, currencies, and at least one real map-pack purchase work end to end in sandbox
