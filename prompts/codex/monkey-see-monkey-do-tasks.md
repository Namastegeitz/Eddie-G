# Monkey See, Monkey Do: small Codex tasks

Each is a small, self-contained change in `apps/monkey-see-monkey-do`. Run
`node tests/unit.mjs` after each (and `node tests/acceptance.js` with the folder
served on 127.0.0.1:8765 if UI changed).

1. **Mute button in the HUD.** Add a speaker icon next to the pause button that
   toggles music and effects to 0 and back (remember the old volumes in the save).
2. **Per-move vibration patterns.** In `js/game.js` `echo()`, vibrate with a
   different short pattern per move id when Settings > Vibration is on.
3. **Level card "Show me again".** In the level intro card, a button that makes the
   monkey demonstrate each new move once more.
4. **Keyboard level select.** Arrow keys move focus around `#level-grid`; Enter opens
   the level.
5. **Save-merge unit test.** Test that a save missing new keys (e.g. no `ledger`)
   loads with defaults and keeps old progress (`js/save.js` `merge`).
6. **Banana ledger filter.** In Stats > Banana history, chips to show All / Earned / Spent.
7. **Wardrobe "Randomise" button.** Picks a random owned item per slot and equips it.
8. **Results share text.** A "Copy result" button that copies e.g.
   "Monkey See, Monkey Do · Level 7 · 3 stars · 2,450 points" to the clipboard.
9. **Endless milestone toast.** Every 5 rounds, a toast "+10 bananas at the end" so
   the reward is visible when earned.
10. **Unit test for timer table.** Check every level's timer in How it works equals
    `timeLimit()` for all three timer modes and three speeds.
