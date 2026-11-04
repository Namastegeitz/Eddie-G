# Run, test, build

Everything below runs from `apps/monkey-see-monkey-do/`.

## Play it locally

No build step. Serve the folder over HTTP (ES modules don't load from `file://`):

```
python3 -m http.server 8765
```

Open http://localhost:8765. On a phone on the same Wi-Fi, open
`http://<your-computer's-IP>:8765` (offline install needs HTTPS, see below).

Or just open `dist/monkey-see-monkey-do.html`: it's the whole game in one
file and works straight from disk, a USB stick, email or any web host.

## Tests

```
node tests/unit.mjs                      # rules, levels, generator, prices (443 checks)
python3 -m http.server 8765 --bind 127.0.0.1 &
node tests/acceptance.js                 # 25-step play-through in Chromium
```

The acceptance test plays the tutorial and Level 1 by tapping the pad,
makes mistakes on purpose (wrong move, timeout, half a combo), uses the
continue, plays combos, Endless and Free Dance (pad, keys, swipe and tapping
the monkey), buys from the wardrobe, checks settings, How it works, stats,
saving across reloads, and loading offline. Screenshots land in
`tests/output/`. It needs Playwright with Chromium (`npm i -D playwright`
and `npx playwright install chromium` if you don't have them).

## After changing game files

```
python3 scripts/build_sw.py        # refresh the offline cache list + version
node scripts/build_single.mjs      # rebuild dist/ single-file versions (uses esbuild via npx)
node scripts/make_icons.js         # only if assets/icons/icon.svg changed
```

## Install on a phone (offline, full screen)

Host the folder on any HTTPS static host (GitHub Pages, Netlify, Cloudflare
Pages, surge). Open it once on the phone, then:

- **Android (Chrome):** menu > Add to Home screen / Install app.
- **iPhone (Safari):** Share > Add to Home Screen.

After the first visit it plays with no connection. Progress is saved on that
phone only; use Settings > Your data > Copy save code to move it.

GitHub Pages example (publishes this folder to a `gh-pages` branch; only do
this when you want the game public):

```
git subtree push --prefix apps/monkey-see-monkey-do origin gh-pages
```

## Tuning

- Points, stars, bananas, timers, combo windows: `js/rules.js`
- Levels (moves per round, tempo, combos, twists): `js/levels.js`
- Wardrobe items and prices: `js/shop.js`
- Music patterns per stage: `STYLES` in `js/audio.js`

The How it works screen reads these files, so it updates by itself.

## Console helpers

`window.MSMD` exposes the game for poking around, e.g.
`MSMD.game.run.expected` (the routine you must copy) or
`MSMD.Save.addBananas(500, 'testing')`.
