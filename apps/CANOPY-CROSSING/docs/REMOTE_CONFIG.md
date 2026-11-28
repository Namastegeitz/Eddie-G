# **CANOPY CROSSING: REMOTE SWITCHES AND UPDATE PROMPTS**

Change how the released game behaves without a store update, using a small
file on the project's GitHub Pages site (no extra service, free).

- **The file:** `content/remote_config.json`. The game ships with it, and the
  beta workflow (*Actions > Canopy Crossing beta (web + Android)*) publishes
  it to `https://namastegeitz.github.io/eddie-g/canopy-crossing/config.json`
  (project setting `canopy/remote_config/url`). GitHub Pages must be switched
  on once: repository *Settings > Pages > Source: GitHub Actions*.
- **When the game reads it:** at start-up, in the background (6 s time-out, two
  retries). Play never waits for it. The last good copy is kept on the device
  for offline starts. Until a copy arrives, the shipped values apply. The web
  version keeps the shipped values (its pages can't reach other sites).

## Switches (`flags`, all `true` in the shipped file)

| Switch | Turned off |
|---|---|
| `first_person` | No eye button; the canopy roof is lifted so those rows play from above |
| `silly_faces` | Animals never pull faces |
| `hd_terrain` | The earlier, plainer ground, water and foliage (lighter on old phones) |
| `review_prompt` | Never asks for a store rating |
| `crash_reports` | No crash reports are sent, whatever the player's setting |
| `between_run_ads` | No ads between runs (reward videos the player chooses stay) |

A switch only turns an existing feature off or back on. Never use it to
reveal something new: App Review guideline 2.5.19 forbids hidden or dormant
features. Mention the switches in the App Review notes.

## Update prompts

- `latest_build`: if the player's build is older, the home screen shows
  **Update available** once (Update / Later).
- `min_build`: if the player's build is older, the home screen shows
  **Update needed**, and play waits until they update (only when a store link
  for their platform is set; otherwise it's the gentle version).
- `update_message`: optional text for either card.
- `store_urls`: `android` (Google Play, filled in), `ios` (fill in once the
  App Store page exists: `https://apps.apple.com/app/id<number>`), `default`.

The build number is the commit count of the release build (see
`.github/workflows/canopy-crossing-release.yml`); Settings shows nothing new,
but crash reports and Play Console show it.

## Example: switch first person off after a bad crash report

1. Edit `content/remote_config.json`: `"first_person": false`.
2. Commit, push, run the beta workflow.
3. Players get it on their next launch. Fix the bug, release the fix, set the
   switch back to `true`, and set `latest_build` to the fixed build.
