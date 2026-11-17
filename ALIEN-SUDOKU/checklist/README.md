# Launch checklist data

The live page (**Launch Control**, https://claude.ai/artifact/LzbsCTPkTUsxyLLCUWCgRM) and the
checklist in `../README.md` are both made from these files:

| File | What it holds |
|---|---|
| `tasks.json` | Every task: phase, store, owner (you / claude / both), steps, tips and watch-outs, links, what it depends on |
| `meta.json` | The seven phases and the stores |
| `progress.json` | Who checked what off and when, exported from the live page |
| `reports.json` (in `../feedback/`) | Bug reports exported from the live page |
| `dashboard.template.html` | The live page; `build.mjs` puts the data in |

```bash
node build.mjs --page /tmp/launch-control.html   # rewrites ../README.md's checklist and builds the page
```

**Syncing:** the live page keeps progress and reports in its own database (collections `progress/<task id>`
and `feedback/<id>`). When you ask Claude to "sync the launch board", Claude reads those collections,
writes `progress.json` and `../feedback/reports.json`, runs `build.mjs`, and commits, so the README's
green checks match the page. When Claude finishes one of its own tasks, it writes `progress/<task id>`
on the live page directly.

**Adding or changing a task:** edit `tasks.json`, run `build.mjs`, and republish the page (ask Claude).
