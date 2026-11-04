# Monkey See, Monkey Do: build prompt (Claude Code)

The prompt the game in `apps/monkey-see-monkey-do/` was built from. The
original document stopped mid-sentence in "Economy & Customization"; the
section after it records what was filled in, so a rebuild matches.

---

Build this from start to finish. Prompt me add ons and other builds to enable full transparency and user friendly gaming.

# Game Design Document & Prompt: Monkey See, Monkey Do game

## Overview
Develop a casual, highly engaging mobile puzzle-rhythm game titled **"Monkey See, Monkey Do"**. The player watches an expressive, charismatic 3D monkey character perform a sequence of dance moves using its limbs, then must replicate the sequence from memory by tapping or swiping the correct body parts in the exact order.

## Core Gameplay Mechanics
1. **The Watch Phase (Call):**
   - The monkey character executes a sequence of dance animations (e.g., Left Arm up, Right Leg kick, Head bob, Left Leg stomp).
   - Clear visual cues and/or musical beats highlight each movement so the player can easily track the pattern ("Simon Says" style memory loop).
2. **The Response Phase (Response):**
   - The UI displays intuitive touch controls (on-screen buttons or directional gestures representing the monkey's limbs: Left Arm, Right Arm, Left Leg, Right Leg, and optionally a Torso/Dance flair button).
   - The player must tap/swipe the limbs in the correct sequence within a countdown timer.
3. **Success & Failure States:**
   - **Success:** The monkey performs the full routine successfully, accompanied by cheering, coin rewards, and a smooth transition to the next, longer sequence.
   - **Failure:** If the player inputs an incorrect limb or runs out of time, the monkey reacts with a funny, endearing "oops" animation, and the player loses a life or has to retry the level.

## Progression & Difficulty
- **Level Scaling:**
   - Level 1-3: 2 to 3-step sequences, slow tempo.
   - Level 4-10: 4 to 6-step sequences, introduces faster tempos and simultaneous movements (e.g., waving both arms or bouncing).
   - Infinite/Endless Mode: Sequences grow indefinitely until a mistake is made, tracking high scores.
- **Economy & Customization:** Players earn bananas/coins

---

## What was filled in (decisions made during the build)

- **Platform:** a web game (three.js) that installs to the home screen and
  plays offline (PWA), plus a one-file HTML build. Plays on any phone, tablet
  or computer from a link. Native store builds are a follow-up prompt.
- **Moves:** Left Arm, Right Arm, Left Leg, Right Leg, Head Bob, Flair. Each
  has a colour, an icon, a fixed pad position, a key and its own note.
  "Left" = left of the screen by default (mirror); a setting switches names
  to the monkey's own sides.
- **Inputs:** pad buttons, tapping the monkey's body, swiping on the stage,
  keyboard.
- **Simultaneous moves:** four combos (both arms, both legs/jump, two
  cross combos), both taps within 320 ms.
- **Lives:** 3 per level; a mistake replays the same routine.
- **Levels:** 30 across 3 worlds; levels 1-10 follow the brief exactly;
  worlds 2-3 add build-up, speed-up and backwards twists.
- **Rhythm:** timing grades (Perfect/Great/Good) add points and the third
  star but never decide whether a move counts.
- **Economy:** bananas only from play (per move, per star, first clear,
  Endless rounds and milestones). Spent on a wardrobe (furs, hats, glasses,
  neckwear, Flair dance styles, stages), "Watch again" (5) and one continue
  per try (15). No real money anywhere.
- **Transparency:** a How it works screen generated from the rule files,
  itemised rewards, a banana ledger, routine codes, mistake cards, local-only
  saves with view/copy/reset.
