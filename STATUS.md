# Status

## Bug's-Eye View (`apps/bugs-eye-view`)
- Built end to end from `prompts/claude/bugs-eye-view.md` (all 6 phases, all 16 add-ons).
- Godot 4.7.2 project: 3 bugs, 3 rooms with boss chases, perception-based stealth,
  escalation chain, daily routines, colony upgrades, menus, touch/keyboard/gamepad.
- Tests: `tools/run_tests.sh` - 120-check smoke test + 248-check phase audit + offline
  Meshy client test pass in the project and in an exported build; zero GDScript warnings
  and engine errors.
- Updates after the build: alarm gauge (threats only investigate until it's full), slower
  and less sharp-eyed humans/pets, fly escape moves (loop, dive, cling, jink, glide),
  20 new places to hide (11 shelters, 7 sight blockers, 2 tall-grass patches), then bigger
  rooms (kitchen 170x125, living room 180x100, backyard 194x164) with 7 more hiding spots,
  full human bodies (faces, hands, outfits, knee-bending legs), detailed jointed bugs with a
  walk cycle, 6 bug foods and 6 crumb gems with effects. 84 model slots.
- Phase-by-phase audit (all 6 phases) done; fixes it found: human feet were never solid,
  props didn't stun via feet, cereal-box domino layout, spider facing/normal errors, fog strength.
- Android debug APK committed at `apps/bugs-eye-view/dist/android/bugseyeview-debug.apk`.
- Builds made in the cloud session: Android debug APK, Windows, macOS, Linux, Web,
  iOS Xcode project (not committed; rebuild with the commands in RUN.md).
- Playable web build published as a private Claude artifact:
  https://claude.ai/artifact/Gmpx6M1Qb9WmCn1BY1Qbh4
- Meshy: `apps/bugs-eye-view/tools/meshy/generate.py` + `assets.json` (84 prompts) are ready
  but not run yet. The cloud session couldn't reach api.meshy.ai; to run it here, allow
  api.meshy.ai and assets.meshy.ai in the environment's network settings and add
  MESHY_API_KEY as an environment variable, or run it on the PC.
- Next: generate the Meshy models (tier 1 first), real audio, Google Play AAB (needs Android SDK locally), iOS signing via a
  Mac or Codemagic (`docs/ci/codemagic.yaml`), playtesting and tuning.

## NeuroForge (not in this repo)
- Source on the Windows PC: `C:\Users\edwar\Desktop\AI and ALL\Aethertek\content poster\neuroforge`
- Live web: https://neuroforged.surge.sh and https://neuroforge.surge.sh
- App Store launch board was at step 1 of 22 (surge sign-in).
- Next: push the source to a private GitHub repo so cloud/phone sessions can read it.

## Prompts
- `prompts/claude/bugs-eye-view.md` - v2 with the stealth/interactivity add-ons.
- `prompts/claude/bugs-eye-view-next.md` - 10 prompts for the next features (Meshy run,
  Gem Shrine, Bathroom level, living humans, skins, debug overlay, playtest bot, sound, CI,
  store kit).
- `prompts/codex/bugs-eye-view-tasks.md` - 10 small Codex tasks.
- Tool ideas: `apps/bugs-eye-view/docs/TOOL_IDEAS.md`.
- Next: collect the rest of the new prompt set (Claude + Codex) into `prompts/`.
