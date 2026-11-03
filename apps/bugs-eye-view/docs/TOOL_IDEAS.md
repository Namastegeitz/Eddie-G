# Tool ideas for building Bug's-Eye View

Tools worth adding as the game grows, roughly in the order they'd pay off.
"Prompt" points to a ready-made prompt in `prompts/claude/bugs-eye-view-next.md`
(C1-C10) or `prompts/codex/bugs-eye-view-tasks.md` (X1-X10).

## Already in the project

| Tool | What it does |
|---|---|
| `tools/build_all.tscn` | Generates every level, actor scene and tuning file from code |
| `tools/run_tests.sh` | Import, warnings-as-errors, smoke test + phase audit in the project and an exported build, Meshy client test |
| `tools/meshy/generate.py` | Turns the 84 prompts in `assets.json` into 3D models that drop into the game's model slots |
| `tools/generate_assets.py` | Synthesizes placeholder sounds, music and icons |
| `tools/web_artifact/package.py` | Splits the web build for hosts with a per-file size limit |

## Build and ship

- **CI on GitHub Actions** - run the tests on every push, build Web + Android
  + desktop, publish the web build automatically. Catches breakage from a
  phone session before you notice it. *Prompt C9.*
- **Codemagic for iOS** - already sketched in `docs/ci/codemagic.yaml`; turn it
  on once you have the Apple developer account.
- **Store screenshot renderer** - the xvfb + OpenGL render trick used to check
  the shelters can stage exact store-size shots of every room. *Prompt C10.*
- **Size budget check** - fail the build if the web download goes over a set
  size (generated models and sounds will grow it).

## Art and audio

- **Meshy** (set up, waiting on your key) - models for every bug, threat, food,
  gem, piece of cover and furniture. *Prompt C1.*
- **Model turntable viewer** - a scene that spins each generated model next
  to its placeholder so you can approve or re-prompt it from your phone.
- **AI sound effects** (e.g. ElevenLabs sound effects) - same manifest pattern
  as Meshy, for footsteps, swatter, purr, gem chime. *Prompt C8.*
- **Music stems** - a calm, a searching and a chase layer that crossfade with
  the alarm gauge (the game already tracks a tension level for the heartbeat).

## Design and balance

- **Debug overlay** - sight cones, hearing rings, live visibility/noise/scent,
  alarm internals, light levels, pet paths. The fastest way to tune stealth.
  *Prompt C6.*
- **Playtest bot + balance report** - plays every room hundreds of times
  headless and tells you which crumbs nobody reaches, which hazard kills most,
  and what to change. *Prompt C7.*
- **Balance sheet export** - dump every `.tres` number (bug stats, threat
  senses, item effects, scoring) to one CSV you can edit in a spreadsheet and
  import back.
- **Layout from a sketch** - describe a room in JSON (furniture, cover, crumbs,
  food, gems, routes) and generate the level, so new rooms are quick to block
  out. *Prompt C3 starts this.*
- **Heatmap** - record where the player gets spotted and where they die, draw
  it over a top-down map of the room.

## Debugging and QA

- **Replay recorder** - record inputs + seed for a run so a bug you hit on your
  phone can be replayed exactly here.
- **Crash and error reporting** - send script errors from test builds to a
  log you can read (Sentry has a Godot SDK).
- **Performance HUD** - FPS, draw calls, physics time on device, toggled from
  the pause menu, to check the phone budget on real hardware.

## For players

- **Gem Shrine** - spend found gems on permanent perks. *Prompt C2.*
- **Skins** - cosmetic bug variants bought with colony crumbs. *Prompt C5.*
- **Daily challenge** - a seeded room/time/bug each day with a shared
  leaderboard.
- **Accessibility options** - colour-blind safe alarm/threat colours,
  hold-vs-toggle for squeeze and sprint, bigger touch buttons.
