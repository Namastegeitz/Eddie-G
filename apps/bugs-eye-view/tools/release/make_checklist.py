#!/usr/bin/env python3
"""Builds the release checklist in two forms from one source.

  BUG'S-EYE VIEW/Checklist/steps.json   the steps (edit this)
  BUG'S-EYE VIEW/Checklist/status.json  which steps are done (synced from the
                                        live tracker's database by Claude)
->
  BUG'S-EYE VIEW/Checklist/tracker.html the live page (published as an artifact)
  BUG'S-EYE VIEW/README.md              the same checklist with green checks

  python3 tools/release/make_checklist.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REL = ROOT / "BUG'S-EYE VIEW"
CHK = REL / "Checklist"
REPO = ("https://github.com/Namastegeitz/Eddie-G/tree/claude/nifty-lamport-bfm2ub/"
        "apps/bugs-eye-view/BUG%27S-EYE%20VIEW")
TRACKER_URL = "TRACKER-URL"
GAME_URL = "https://claude.ai/artifact/Gmpx6M1Qb9WmCn1BY1Qbh4"


def load():
    data = json.loads((CHK / "steps.json").read_text())
    status_path = CHK / "status.json"
    status = json.loads(status_path.read_text()) if status_path.exists() else {"steps": {}}
    return data, status


def tracker(data):
    tpl = (ROOT / "tools/release/tracker_template.html").read_text()
    html = tpl.replace("/*STEPS_JSON*/", json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    html = html.replace("__REPO__", REPO)
    (CHK / "tracker.html").write_text(html)


def rel_link(path):
    # README sits in BUG'S-EYE VIEW/, so strip that prefix for relative links.
    p = path.removeprefix("BUG'S-EYE VIEW/").removeprefix("BUG'S-EYE VIEW")
    return (p or ".").replace(" ", "%20")


def readme(data, status):
    done = {k: v for k, v in status.get("steps", {}).items() if v.get("done")}
    steps = [s for p in data["phases"] for s in p["steps"]]
    n_done = sum(1 for s in steps if s["id"] in done)
    tracker_url = status.get("tracker_url", TRACKER_URL)
    out = []
    w = out.append
    w("# **BUG'S-EYE VIEW**\n")
    w("Everything needed to take Bug's-Eye View from a finished game to live store pages - "
      "builds, store images, listing text, legal pages, research and a step-by-step checklist.\n")
    bar_len = 30
    filled = round(bar_len * n_done / max(len(steps), 1))
    w(f"**Progress: {n_done} of {len(steps)} steps done ({round(100 * n_done / max(len(steps), 1))}%)**  \n")
    w("`" + "█" * filled + "░" * (bar_len - filled) + "`\n")
    w(f"- **Live checklist (tick steps, leave notes, report bugs):** {tracker_url}")
    w(f"- **Play the web build:** {GAME_URL}")
    w(f"- Last synced from the live checklist: {status.get('synced', 'not yet')}\n")
    w("> The live checklist is the real-time version: tick a step there and it turns green on every device. "
      "This README is a snapshot Claude refreshes from it with each update (✅ done, ⬜ to do).\n")

    w("## What's in this folder\n")
    w("| Folder | What it holds |")
    w("|---|---|")
    rows = [
        ("Builds/", "One folder per platform: Windows, macOS, Linux, Web, Android, iOS - each with the build and a README"),
        ("Store Assets/", "Icons, key art, logo, screenshots and every store's image sizes, rendered from the game"),
        ("Store pages/", "One folder per store: what to upload where, in order"),
        ("Listing Text/", "Names, descriptions, keywords and system requirements, checked against each store's limits"),
        ("Legal/", "Privacy policy and the answers for every store's privacy, data and age-rating forms"),
        ("Research/", "What each store requires, how long it takes and what it costs (researched 17 Nov 2026)"),
        ("Checklist/", "The checklist's source (steps.json), its status and the live page"),
        ("Make Desktop Folder.bat", "Copies this whole folder to your Windows Desktop"),
    ]
    for a, b in rows:
        w(f"| [{a}]({rel_link(a)}) | {b} |")
    w("")

    w("## How the feedback loop works\n")
    w("1. **Play** a build from `Builds/` (or the web link above).")
    w("2. **Report** anything odd in the live checklist's *Feedback & bugs* tab: where you were, what happened, what you expected. Minor things count.")
    w("3. **Ask Claude to \"check the tracker\".** Claude reads every report and your step notes, fixes what it can, replies on each report and marks it *Fixing* or *Fixed*.")
    w("4. **Tick steps** as you finish them. The *Next up* card always shows the next step whose earlier steps are done, with how-to and tips.\n")

    w("## The checklist\n")
    for pi, p in enumerate(data["phases"]):
        pd = sum(1 for s in p["steps"] if s["id"] in done)
        mark = "✅" if pd == len(p["steps"]) else "🟡" if pd else "⬜"
        w(f"### {mark} Phase {pi} - {p['name']}  ({pd}/{len(p['steps'])})\n")
        w(f"_{p['goal']}_\n")
        for s in p["steps"]:
            d = done.get(s["id"])
            box = "✅" if d else "⬜"
            meta = " · ".join(x for x in [s.get("who"), s.get("time"), s.get("cost")] if x)
            when = f" - done {d.get('doneAt', '')[:10]}" if d and d.get("doneAt") else ""
            w(f"- {box} **{s['t']}**  \n  <sub>{meta}{when}</sub>")
            if not d:
                for i, h in enumerate(s["how"], 1):
                    w(f"  {i}. {h}")
                if s.get("tip"):
                    w(f"  > **Tip:** {s['tip']}")
            for f in s.get("files", []):
                label = f.removeprefix("BUG'S-EYE VIEW/") or "BUG'S-EYE VIEW"
                w(f"  - 📁 [{label}]({rel_link(f)})")
            for label, url in s.get("links", []):
                w(f"  - 🔗 [{label}]({url})")
            note = status.get("steps", {}).get(s["id"], {}).get("coach")
            if note:
                w(f"  > **Claude:** {note}")
        w("")

    w("## Costs at a glance\n")
    w("| Store | Fee | Time to live (typical) |")
    w("|---|---|---|")
    for row in [
        ("itch.io", "Free", "Same day"),
        ("Google Play", "US$25 once", "3-5 weeks (14-day closed test)"),
        ("Apple App Store", "US$99 a year (+ a Mac or cloud Mac)", "1-2 weeks"),
        ("Steam", "US$100 per game, refunded after $1,000", "4-6 weeks (2-week Coming Soon, 21-day wait)"),
        ("GOG", "Free (curated)", "Weeks to months, if accepted"),
        ("Epic Games Store", "US$100 per game", "2-4 weeks"),
        ("Microsoft Store", "Free", "1-2 weeks"),
    ]:
        w("| " + " | ".join(row) + " |")
    w("")
    w("## Never put these in git\n")
    w("Signing keys and passwords stay on your computer and in your password manager: the Android upload "
      "keystore (`*.keystore`, `*.jks`), Apple certificates (`*.p12`) and API keys (`*.p8`), Steam and store "
      "logins. `.gitignore` already blocks the key files.\n")
    w("_Regenerate this file and the tracker page with `python3 tools/release/make_checklist.py`._")
    (REL / "README.md").write_text("\n".join(out) + "\n")


if __name__ == "__main__":
    d, st = load()
    tracker(d)
    readme(d, st)
    print("checklist:", sum(len(p["steps"]) for p in d["phases"]), "steps")
