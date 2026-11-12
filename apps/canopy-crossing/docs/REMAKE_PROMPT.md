You are a senior game director, technical artist and gameplay engineer. Remake my mobile game CANOPY CROSSING from this spec at the highest visual quality you can reach, keeping the gameplay exactly as described. It is an original game: do not copy characters, art, music or levels from any existing game.

=== 1. QUALITY BAR ===
- Look: a living nature documentary, photoreal with a touch of charm, readable at a glance. Every animal and creature is a fully rigged, animated 3D model (never a static statue) with fur, feather or scale shading, wet eyes that blink and track, and a facial rig (see section 8).
- Resolution: native up to 4K on desktop, device-native on phones (render scale 0.75-1.0 with temporal upscaling such as FSR2 / MetalFX where available). All UI is vector or SDF so it stays crisp at any resolution.
- Textures: author PBR at 4K (albedo, normal, roughness/metal, AO, height). Ship 2K for hero animals, 1K for props on high-end phones, 512 on low-end, GPU-compressed (ASTC on phones, BC7 on desktop) with streaming.
- Lighting: physically based, ACES or AgX tonemapping, real-time global illumination on high-end (baked lightmaps + light probes on phones), soft cascaded shadows, contact shadows, SSAO, screen-space reflections on water, volumetric fog and god rays under the canopy, gentle bloom. Depth of field only in cinematics. No motion blur in gameplay.
- Vegetation: dense layered rainforest (buttress-rooted giants, strangler figs, lianas, epiphytes, palms, tree ferns, bamboo, heliconias, monsteras, ferns), wind animation (trunk sway, branch bend, leaf flutter), leaf translucency, grass that bends where animals step.
- Water: flowing rivers with flow maps, foam around logs and rocks, refraction, caustics, ripples and splashes; waterfalls with spray and mist.
- Frame rate: 60 fps on recent phones (iPhone 12 / Pixel 6 class), 30 fps floor on older phones on Low, 120 fps option where supported. Graphics settings Low / Medium / High / Ultra.

=== 2. PLATFORMS AND TECH ===
- iOS, Android (portrait phones 9:16 to 9:21, plus tablets) and Web (WebGL2 or WebGPU; Web may default to Medium).
- Pick an engine that can hit this bar on phones (for example Unity URP/HDRP, Unreal 5 mobile, or Godot 4 Forward+/Mobile). Say which and why before building.
- Data-driven: animals, jungles, hazards, lane generators, store, seasons and all text live in JSON content files. Adding an animal or a jungle = adding a file.
- A deterministic fixed-step simulation on the grid, separate from rendering, so a path-finding bot can play every level in automated tests.

=== 3. CORE GAMEPLAY (KEEP EXACTLY) ===
- You are an animal crossing a jungle one tile per hop on a grid 9 columns wide; the level scrolls as you advance. Swipe or tap to hop up, left, right or back. Hop timing is the same everywhere.
- Rows are: safe banks (grass), roads (ground movers: herds and vehicles), rivers (ride platforms: logs, rafts, lily pads, canoes, boats, caiman backs; stepping stones; bridges), and terrain tiles that block a tile (mossy boulders, roots, brush).
- Water rule: falling in the water restarts the run from the start of the level (no life lost, no revive). Every other hazard costs a life. Lives by tier: Easy 5, Medium 3, Hard and Expert as tuned.
- You ride whatever you stand on. Hops along a moving log keep pace with it; landing just short of a log's end still lands on it; vehicle hit edges are a touch forgiving.
- Jumps follow the ground: a quick low skip across a road, a real leap onto a log, lily pad or waterfall stone, each surface with its own landing sound and a small camera dip.
- A mover brushing past you = "Close call!" (+2 points).
- Canopy zones: stretches of dense canopy hide the rows from above; a pulsing eye button switches to first person to see under them. Each zone shows a title card with its scene name.
- Berries to collect along the trail (some only visible to foraging abilities). Reach the goal row to win; results card with stars, berries and unlocks.

=== 4. TWO VIEWS, BOTH FULLY PLAYABLE ===
- Bird's-eye: top-down 3/4 camera, clear silhouettes, optional colour-blind hazard markers.
- First person: at the chosen animal's eye height, wide FOV that adapts to the screen (wider left-right and upward), eye rides on what you stand on (up on a log, low on a lily pad, lower when swimming), landing dips, head bob.
- Live mini-map in a corner in both views: zoomed rows around you with traffic and creatures moving in real time, canopy patches, waterfall ledges, goal, and a gauge for the whole level. Tap to enlarge; can be turned off in Settings.

=== 5. THE 22 JUNGLES (globe order, 10 levels each = 220 levels) ===
1 Amazon Basin (Brazil/Peru) - free | 2 Congo Basin (DR Congo) | 3 Borneo (Malaysia/Indonesia) | 4 Daintree (Queensland, Australia) | 5 Masoala (Madagascar) | 6 Monteverde (Costa Rica) | 7 Sundarbans (India/Bangladesh) | 8 Western Ghats (India) | 9 Bwindi (Uganda) | 10 New Guinea Highlands | 11 Atlantic Forest (Serra do Mar, Brazil) | 12 Xishuangbanna (Yunnan, China) | 13 Taman Negara (Malaysia) | 14 Sinharaja (Sri Lanka) | 15 Yasuni (Ecuador) | 16 Choco (Pacific Colombia) | 17 Tai Forest (Cote d'Ivoire) | 18 Palawan (Philippines) | 19 Maya Forest (Peten, Guatemala) | 20 Khao Sok (Thailand) | 21 Cardamom Mountains (Cambodia) | 22 El Yunque (Puerto Rico)
- Clearing a jungle's 10th level opens the next one for free (map packs still sell that region's animals).
- Difficulty tiers: jungles 1-2 Easy, 3-5 Medium, 6-10 Hard, 11-22 Expert. Inside a jungle, levels get longer and harder from 1 to 10; the first jungles bring in their hazards level by level. Level lengths: Easy 25-60 rows, Medium 40-100, Hard 50-120, Expert longer.
- Each jungle: 4 themed first-person canopy scenes (for example buttress-root cathedral, misty waterfall gorge, temple ruins, mangrove tunnels), its own wildlife along the trail, landmarks (Maya temple and stelae, karst towers, waterfall cliffs), waterfall ledges in later levels (water pours over all but a dry path of stones), and its own atmosphere (mist, rain, light shafts).
- Every road is a trade route: wheel ruts, a grassy hump between them, gravel shoulders, potholes; crates of fruit, coffee and cacao sacks, barrels, banana bunches, market stalls with striped awnings, signposts ("PORT 3 km"). Vehicles always face and drive the way they are moving.

=== 6. HAZARDS (by behaviour) ===
- Movers on roads: tour jeeps, 4WDs, logging, banana, rubber, tea, oil and rosewood trucks, palm-oil tractors, zebu carts, mule trains, tricycle taxis, scooters; elephant herds, forest buffalo, gaur, peccaries, wild boar, red river hogs, dholes, cassowaries, mongooses, water monitors, pygmy hippos, land-crab marches, giant red soldier ants carrying wedges of cheese, rolling logs and boulders, swinging vines, KANGAROO MOBS (Daintree, New Guinea; bounding in high arcs) and STROLLING GIRAFFES (Congo, Tai, Bwindi; slow, very tall, swinging their necks).
- River platforms: floating, rapids, tidal and blackwater logs, drifting branches, bamboo and mangrove rafts, dugout canoes, longboats, longtail boats, bangka outriggers, lily pads, caiman backs (dive under now and then), stepping stones, rope and hanging bridges.
- Surfacers (crocodiles and caimans burst up from the water and snap), strikers (vipers, pythons, cobras, a tiger ambush from the bank), swoopers (harpy, crowned and sea eagles dive at you), fallers (branches, fruit), gaps (gullies, ridges, sinkholes, waterfall ledges), lane effects (quicksand, swamp mud, mudslides, slash-and-burn fire, mangrove tides, monsoon floods), weather events (monsoon rain, cyclone gusts that push you).
- Every hazard telegraphs clearly before it acts (ripples before a croc, rustling grass before a snake, a shadow before an eagle).

=== 7. THE 50 PLAYABLE ANIMALS ===
Each has a rarity (common, rare, epic, legendary), a home region, a special ability, skins, and full animations (idle, hop, land, ride, swim, fall, hurt, celebrate). Free starters: Poison Dart Frog, Orangutan, Ring-Tailed Lemur, Southern Cassowary, Western Gorilla. Abilities upgrade to level 5 with Berries (120 / 260 / 480 / 800).
Amazon: Poison Dart Frog (precise hop), Red-Eyed Tree Frog (double hop), Capybara (float), Giant Otter (swimmer), Green Anaconda (slither), Capuchin Monkey (long reach), Howler Monkey (vine swing), Jaguar (sprint dash), Harpy Eagle (swoop), Scarlet Macaw (hover), Toco Toucan (glide), Three-Toed Sloth (camouflage).
Congo: Western Gorilla (smash), Chimpanzee (tool shield), Bonobo (double swing), Mandrill (intimidate), Okapi (steady), Forest Elephant (unstoppable), Leopard (climb), Pangolin (armored roll), African Grey Parrot (hover glide).
Borneo: Orangutan (long swing), Proboscis Monkey (river leap), Binturong (all-rounder), Sun Bear (fast climb), Slow Loris (toxic), Colugo (long glide), Rhinoceros Hornbill (glide), Wallace's Flying Frog (parachute glide), Sumatran Tiger (dash and swim), Sunda Clouded Leopard (stealth).
Daintree: Southern Cassowary (charge), Tree Kangaroo (huge hop), Green Tree Python (slither-climb), Sugar Glider (glide), Platypus (swimmer), Kookaburra (flight hop), Short-beaked Echidna (curl up).
Masoala: Ring-Tailed Lemur (multi-hop), Aye-Aye (night vision), Fossa (predator sprint), Panther Chameleon (vanish), Tomato Frog (startle puff).
Monteverde: Resplendent Quetzal (long glide), Spider Monkey (chain swing), Kinkajou (night climb), Coatimundi (sniff out), Baird's Tapir (plow).
New Guinea: Bird of Paradise (dazzle). Sundarbans: Bengal Tiger (apex sprint).
The equipped animal turns and breathes in 3D on the home and animal screens.

=== 8. LIVING WILDLIFE AND PERSONALITY ===
- Ambient life: flocks of scarlet and blue-and-gold macaws crossing the sky over open rows; honeybees working the fruit at market stalls; perched birds, frogs, crabs, butterflies, lizards and beetles on the banks (each jungle its own list); everything reacts a little to you passing.
- SILLY-FACE GLANCES (on most maps): every so often, at random (roughly every 8-20 seconds, never two nearby animals at once), an animal on screen - a hazard animal (giraffe, kangaroo, elephant, boar, croc, monkey...), roadside wildlife, or a bird on a branch - turns its head to look straight at you, pulls a silly face for about 1-1.5 seconds, then snaps back to normal and carries on. Faces: crossed eyes, tongue out, puffed cheeks, ears flopping, eyebrows wiggling, a wink, a goofy grin, a raspberry; 4-6 variations per species, matched to its anatomy (a giraffe's long purple tongue, a croc's toothy grin, a kangaroo's ear wiggle, a frog's puffed throat). In first person it looks right into your eyes; in bird's-eye it looks up at the camera. It must never change the animal's path, speed or timing, and never hide a hazard. On by default in most jungles (a per-jungle switch keeps a few serious ones calm); a Settings toggle turns it off. Your own animal does it now and then on the home screen too.
- This needs a facial rig on every animal model (blend shapes or face bones): eye look-at, blink, cross-eye, brows, jaw and mouth, tongue, cheeks, ears.

=== 9. MODES, ECONOMY, SCREENS ===
- Modes: Journey (the 220 levels), Endless (procedural, the jungle creeps up behind you; canopy zones every 26-40 rows), Daily Challenge (same seed for everyone, rotates through jungles).
- Economy: Berries (earned) and Amber (premium). Store: map packs, regional animal packs, Amber packs, Starter and Mega bundles, Remove Ads, power-ups, cosmetics (skins, hop trails, emotes, goal flags), a 30-tier Expedition Pass with seasons themed on a region, daily deals, weekend 2x Berries, animal of the week, daily reward.
- Screens: home (equipped animal in 3D, Journey / Endless / Daily, Animals, Store, Pass, Settings, Watch film), 3D globe world map (jungles as pins, tier chips, stars per level, "New here"), animal select carousel with skills, store, pass, settings (graphics level, view, mini-map, music style, sound, haptics, left/right hand, colour-blind markers, reduce motion, silly faces on/off).
- Onboarding: coached tutorial in the Amazon, region intro cards, contextual prompts (revive, milestone, last life, locked animal).
- Accessibility: colour-blind markers, left/right-hand layout, haptics toggle, reduce motion, instant restart.

=== 10. AUDIO ===
- Calm music for every jungle and the menu, about a minute each, looping seamlessly: soft pads, a sparse melody on the jungle's own instrument, gentle kalimba arpeggio, light percussion. Each song is tuned to 528 Hz or 963 Hz (alternating along the globe): every note a pure ratio of that tone, which hums softly underneath. A "Classic" style option with livelier songs.
- 3D spatial jungle ambience (insects, frogs, birds, rain, rivers, waterfalls), per-surface footsteps and landings, animal calls, engine sounds that pass by with Doppler, satisfying UI sounds and haptics.

=== 11. IN-GAME FILM: "THE BEE AND THE GIRAFFE" (about 30 s, home > Watch, Skip button) ===
1. A jungle trade road: a jeep and a logging truck hauling goods drive past (facing the way they go), a giraffe ambles by the road, kangaroos bound along it, macaws fly overhead. Title "CANOPY CROSSING".
2. Scarlet macaws fly overhead; the camera tilts down to a honeybee working a red hibiscus, then zooms right in as time slows to about 12x slow motion: veined see-through wings beating slowly, compound eyes, fuzz, pollen.
3. The bee lifts off; the camera rides alongside as it climbs and zips right past a giraffe's eye (close-up: eyelashes, the eye tracking the bee).
4. The annoyed giraffe rears back and swings its neck down at a kangaroo grazing below; in slow motion the kangaroo leaps clear, missed by a whisker.
5. The kangaroo bounds off down the road with its mob; end card "Giraffes - Kangaroos - Macaws, now on the trade roads".
Letterboxed in landscape, framed for portrait phones too, with music and a bee buzz that drops in pitch in slow motion. Also export it as a 1080p (and 4K) MP4 trailer.

=== 12. PERFORMANCE BUDGETS ===
- Phones on High: at most about 150 draw calls and 400k visible triangles; LODs on every model (3-4 levels plus impostors for distant trees); GPU instancing for vegetation and props; occlusion culling; build the rows ahead a little each frame and reuse objects so hopping never stalls.
- Download: base app small (under 150 MB), jungles as downloadable content packs; texture and mesh compression throughout.
- Memory under 1.5 GB on phones; no frame over 33 ms during play.

=== 13. ASSETS ===
- Hero animals and creatures: sculpted or AI-generated then retopologised, UV'd, rigged with face rigs, animated (walk, run, hop, idle, special, silly faces), and checked side by side for consistent scale and style.
- Name every asset and its source; only use assets we have the rights to ship commercially.

=== 14. HOW TO DELIVER ===
Work in milestones; at the end of each, give me the code and files, what changed, and how to check it:
M0 engine choice, architecture, style frames for 3 jungles, 3 animals and the first-person view.
M1 grid simulation and rules, path-finding bot, automated tests.
M2 bird's-eye view. M3 first person and mini-map.
M4 vertical slice: the Amazon at full quality, 10 levels, 5 starter animals.
M5 all 22 jungles and their hazards. M6 all 50 animals with abilities, skins and silly faces.
M7 UI, economy, store, pass, onboarding. M8 music and sound. M9 the film. M10 optimisation, store builds for iOS, Android and Web.
Acceptance tests: the bot beats all 220 levels with the free Poison Dart Frog; every hazard kind is tested; adding an animal or a jungle by file works; first person draws a correct picture in every scene; 60 fps on the target phones; the water rule restarts the run; clearing a jungle opens the next; silly faces never change hazard timing.
Ask me before changing any gameplay rule.
