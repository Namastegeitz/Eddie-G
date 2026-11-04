# Monkey See, Monkey Do: add-on and next-build prompts (Claude Code)

Copy one prompt at a time into a Claude Code session on this repo. Each is
self-contained. They build on the game as it is now (`apps/monkey-see-monkey-do`,
vanilla JS + three.js, no build step).

Rules for every prompt (paste once at the top of a session, or keep in a `CLAUDE.md`):

```
You're working on Monkey See, Monkey Do in apps/monkey-see-monkey-do (vanilla JS
modules + three.js r180, no bundler).
- Numbers players see (points, bananas, prices, timers) live in js/rules.js,
  js/levels.js or js/shop.js, never hard-coded in UI. The How it works screen
  (renderHelp in js/ui.js) must describe any new rule.
- No real-money purchases, ads, tracking or network calls unless the prompt
  says so, and anything that leaves the device is opt-in and explained in How it works.
- Keep tests green: node tests/unit.mjs and node tests/acceptance.js (serve the
  folder on 127.0.0.1:8765 first). Add checks for every new feature.
- After changing files: python3 scripts/build_sw.py and node scripts/build_single.mjs.
- Phone first: test at 390x844 and 375x667 and in landscape.
```

---

## Transparency and friendliness

### 1. Replay review: see exactly what happened

```
After each round (and on every mistake card), add "Review" that shows the routine
as a timeline: each move the monkey did on its beat, and each tap you made, with
its grade and how many ms early/late it was. Colour + icon per move, a beat grid,
and a plain-English summary ("You were 60 ms late on average; your Right Leg taps
were the latest"). Keep the last 10 reviews in the save so Stats can open them.
Add a "Practice this routine" button that replays it at 70% speed with no lives.
```

### 2. Daily Dance (fair, no pressure)

```
Add a Daily Dance mode: one routine per day from a seed made from the date, so
everyone gets the same dance. 5 rounds, unlimited tries, best score kept. Show
the seed and the date on screen. A streak counter that never punishes missing a
day (show "days played" rather than a breaking streak). Small banana reward
(set in rules.js, shown in How it works). Works offline.
```

### 3. Choreographer: make and share routines

```
In Free Dance add "Record": the next taps (up to 16, combos allowed) become a
routine at the current tempo. Save up to 20 routines locally, name them, play
them like a level (3 lives, normal scoring, no bananas), and share them as a short
code (base32 of tempo + moves, with a checksum). "Play a code" on the title
screen loads one. Validate codes with a clear error. Add codes to How it works.
```

### 4. Accessibility pack

```
Add Settings > Accessibility:
- Big buttons layout (2 columns x 3 rows, 30% taller), and a left-handed mirror.
- Colour themes for the six moves: default, colour-blind safe (Okabe-Ito), high contrast.
- One-switch mode: the pad highlights each button in turn; any key, tap or switch
  press chooses the highlighted one. Scan speed slider. Timer turns off automatically.
- Screen-reader narration of the routine during Watch ("Left arm, then right leg...").
- Vibration "notes": a different short pattern per move on phones that support it.
Check each option at 390x844 in the acceptance test.
```

### 5. Grown-up panel (play time and breaks)

```
Add a PIN-protected "Grown-ups" page under Settings: daily play-time today and
this week, an optional soft time limit (gentle "time for a break" card with the
monkey yawning, never mid-round), lock Settings > Your data, and force Relaxed
timer. Store the PIN hashed. Explain all of it in How it works.
```

### 6. Achievements sticker book

```
Add a sticker book (30 stickers) with every requirement visible from the start
(no hidden achievements) and a progress bar for each: e.g. clear World 1, 3-star
any boss, 50 Perfects, Endless 15 rounds, try every Flair, a 25-move streak.
Stickers are only for fun (no bananas). Data-driven list in a new js/stickers.js.
```

## More game

### 7. World 4: Snowy Peaks + new twists

```
Add World 4 "Snowy Peaks" (levels 31-40, a snowy stage with falling snow and an
ice-blue pad) and two twists, each introduced on its own level with a card:
- Echo: the monkey shows the routine, then a parrot repeats the first half; you
  copy the whole thing.
- Spotlight: the stage goes dark and only the moving limb is lit (captions and
  notes still play, so it stays fair; Assist mode turns it off).
Tempo 130-150, 8-12 moves. Unlock by clearing level 30. Update the level table,
unit tests and How it works.
```

### 8. Two-player Copycat Battle

```
Add a pass-and-play mode for 2-4 players on one device. Player 1 taps one move;
the monkey dances it; the phone passes to Player 2, who copies it and adds one;
and so on (the classic memory duel). A miss knocks a player out; last one standing
wins. Big "Pass to Player N" screens so nobody sees the previous player's turn.
```

### 9. Real music and a monkey voice

```
Replace the generated grooves with four short loopable tracks (one per stage,
OGG + M4A, under 400 KB each), keep the synth as a fallback when files fail to
load, keep the beat clock exact (tempo metadata per track), and add a recorded
"ooh-ooh!" set for cheer/oops. List the sources and licences in README.md and How it works.
```

## Other builds

### 10. Put it online (GitHub Pages) with an install QR

```
Publish apps/monkey-see-monkey-do to GitHub Pages from a gh-pages branch with a
script (scripts/publish_pages.sh) that runs the tests, rebuilds sw.js and pushes.
Add a "Play on another device" QR on the title screen's Stats page pointing at the
live URL. Ask me before running the publish step.
```

### 11. Android app (Google Play)

```
Wrap the game for Android with Capacitor (or a Trusted Web Activity once it is on
HTTPS). Splash screen, adaptive icon from assets/icons/icon.svg, portrait lock,
keep-screen-on while playing, haptics via the Capacitor plugin. Build a debug APK
in this session, write the release steps (keystore, AAB, Data safety form: "no
data collected") in docs/STORE.md.
```

### 12. iPhone app (App Store)

```
Add an iOS target with Capacitor. Generate the Xcode project, icons and launch
screen, and write docs/STORE.md steps for signing (Mac or Codemagic), the App
Privacy label ("Data Not Collected") and TestFlight. Make sure audio starts after
the first tap and respects the silent switch setting.
```

### 13. Opt-in online leaderboard (Supabase)

```
Add an optional, off-by-default Endless leaderboard using Supabase: anonymous
nickname (no email), best rounds + score + run code only, row-level security,
rate-limited insert via an edge function that replays the run code to check the
score is possible. A clear consent card before the first upload, and "Delete my
scores" in Settings > Your data. Document every field sent in How it works.
```

### 14. Spanish and Portuguese

```
Move every player-facing string into js/i18n/en.js and add es.js and pt.js
(Portugal Portuguese). Language picker in Settings, defaulting to the device
language. Move names, How it works tables and results must all translate; numbers
come from rules.js as before. Add an acceptance step per language.
```
