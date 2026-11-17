#!/usr/bin/env python3
"""Keeps the store-launch checklist in one place and writes everything else
from it:

    LAUNCH/checklist.json      the source: phases > steps (edit this)
    LAUNCH/progress.json       which steps are done (exported from the live page)
    -> LAUNCH/README.md        the full checklist, ✅ next to finished steps
    -> LAUNCH/<store>/README.md  that store's steps
    -> LAUNCH/page/checklist.json, LAUNCH/page/builds.json   data for the live page
    -> BUILDS/README.md status table is left alone; builds.json reads BUILDS/*/BUILD_INFO.json

    python3 tools/launch_docs.py
"""
import json
import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L = ROOT / "LAUNCH"
PAGE_URL_FILE = L / "page" / "URL"
STORE_NAMES = {"all": "All stores", "apple": "Apple App Store", "google": "Google Play", "amazon": "Amazon Appstore",
               "samsung": "Samsung Galaxy Store", "steam": "Steam", "gog": "GOG", "itch": "itch.io",
               "epic": "Epic Games Store", "mac": "Mac distribution", "web": "Web"}
OWNER = {"you": "You", "claude": "Claude", "both": "You + Claude"}
PLATFORM_STORES = {
    "android": "Google Play (.aab), Amazon Appstore, Samsung Galaxy Store (.apk)",
    "ios": "Apple App Store (TestFlight first)",
    "windows": "Steam, GOG, itch.io, Epic, Microsoft Store",
    "macos": "Steam, GOG, itch.io, Epic (after signing + notarizing)",
    "linux": "Steam (and Steam Deck), GOG, itch.io",
    "web": "Beta testers' link, itch.io (playable in browser)",
}


def load():
    cl = json.loads((L / "checklist.json").read_text())
    prog = {}
    if (L / "progress.json").exists():
        prog = json.loads((L / "progress.json").read_text())
    return cl, prog


def builds():
    out = []
    for plat in ["android", "ios", "windows", "macos", "linux", "web"]:
        f = ROOT / "BUILDS" / plat / "BUILD_INFO.json"
        info = json.loads(f.read_text()) if f.exists() else {"platform": plat, "status": "not built", "files": []}
        info["id"] = plat
        info["stores"] = PLATFORM_STORES[plat]
        out.append(info)
    return {"platforms": out, "note": "Each platform has its own folder in apps/CANOPY-CROSSING/BUILDS/. The game files are rebuilt from the source (tools/build_all.sh, or the GitHub Actions workflow 'Canopy Crossing release builds', which also makes Android); they're too big to keep in git."}


def task_md(t, done, level="###"):
    box = "- [x] ✅" if done else "- [ ]"
    chips = [OWNER.get(t.get("owner", "you"), "You")]
    chips += [STORE_NAMES.get(s, s) for s in t.get("stores", []) if s != "all"]
    for k in ("cost", "time"):
        if t.get(k):
            chips.append(t[k])
    if t.get("needs"):
        chips.append("needs " + t["needs"])
    lines = [f"{box} **{t['title']}**  ", f"  _{' · '.join(chips)}_", ""]
    if t.get("why"):
        lines += [f"  **Why:** {t['why']}", ""]
    if t.get("how"):
        lines += ["  **How:**"] + [f"  {i}. {h}" for i, h in enumerate(t["how"], 1)] + [""]
    if t.get("done_when"):
        lines += [f"  **Done when:** {t['done_when']}", ""]
    if t.get("pitfall"):
        lines += [f"  **Watch out:** {t['pitfall']}", ""]
    if done and t.get("next"):
        lines += [f"  **Done ✅** {t['next']}", ""]
    if t.get("links"):
        lines += ["  **Official pages:** " + " · ".join(f"[{l['label']}]({l['url']})" for l in t["links"]), ""]
    return lines


def readme(cl, prog, url):
    tasks = [t for p in cl["phases"] for t in p["tasks"]]
    done = sum(1 for t in tasks if prog.get(t["id"], {}).get("done"))
    pct = round(done / len(tasks) * 100) if tasks else 0
    nxt = next((t for t in tasks if not prog.get(t["id"], {}).get("done")), None)
    today = datetime.date.today().isoformat()
    out = ["# **CANOPY CROSSING: STORE LAUNCH CHECKLIST**", "",
           f"**{done} of {len(tasks)} steps done ({pct}%)** · snapshot {today}", "",
           f"**Live checklist (tick steps, log bugs, see builds):** {url}" if url else "", "",
           "Every step to publish Canopy Crossing on the Apple App Store, Google Play, Amazon, Samsung,",
           "Steam, GOG, itch.io and Epic, in order. A ✅ means the step is done. The live page is the",
           "real-time version: tick a step there and it turns green for everyone, with notes; this",
           "file is a snapshot of it (`python3 tools/launch_docs.py` after exporting the page's",
           "progress refreshes it). Each step says why it matters, how to do it, what \"done\" looks",
           "like, the usual mistakes, and the official page to check.", "",
           f"**Requirements researched:** {cl.get('researched', '')}. Store rules change; each step links",
           "the official page to re-check on the day you do it.", ""]
    if nxt:
        out += [f"> **Next step:** {nxt['title']}  ", f"> {nxt.get('why', '')}", ""]
    out += ["## Folders", "",
            "| Folder | What's there |", "|---|---|",
            "| [`../BUILDS/`](../BUILDS/) | one folder per platform: android, ios, windows, macos, linux, web |"]
    for s in cl.get("stores", []):
        out.append(f"| [`{s['folder']}/`]({s['folder']}/) | {s['label']}: its steps and researched requirements |")
    out += ["| [`shared/`](shared/) | store text, privacy policy, in-app products, content-rating answers, asset sizes |", ""]
    out += ["## Phases", ""]
    for p in cl["phases"]:
        pd = sum(1 for t in p["tasks"] if prog.get(t["id"], {}).get("done"))
        out += [f"- [{p['name']}](#{anchor(p['name'])}): {pd}/{len(p['tasks'])}"]
    out += [""]
    for p in cl["phases"]:
        pd = sum(1 for t in p["tasks"] if prog.get(t["id"], {}).get("done"))
        out += [f"## {p['name']}", "", f"_{pd} of {len(p['tasks'])} done._ {p.get('goal', '')}", ""]
        for t in p["tasks"]:
            out += task_md(t, prog.get(t["id"], {}).get("done"))
    out += ["## Bugs and feedback", "",
            "Log bugs and how the game feels on the live page's **Bugs & feedback** tab (kind, how bad,",
            "device, view, where, steps). Claude reads that list to fix them; set a report to *Fixed* once",
            "you've checked the fix. Testers who aren't on the page can send reports to you to log.", ""]
    return "\n".join(out)


def anchor(name):
    return "".join(c for c in name.lower().replace(" ", "-") if c.isalnum() or c == "-")


def store_readme(s, cl, prog, url):
    key = s["key"]
    out = [f"# **CANOPY CROSSING: {s['label'].upper()}**", "",
           f"Steps for {s['label']} (and the ones every store needs). Live checklist: {url}" if url else f"Steps for {s['label']}.", ""]
    req = L / s["folder"] / "requirements.md"
    if req.exists():
        out += [f"Researched requirements, with sources: [requirements.md](requirements.md)", ""]
    for p in cl["phases"]:
        ts = [t for t in p["tasks"] if key in t.get("stores", []) or "all" in t.get("stores", [])]
        if not ts:
            continue
        out += [f"## {p['name']}", ""]
        for t in ts:
            out += task_md(t, prog.get(t["id"], {}).get("done"))
    return "\n".join(out)


def main():
    cl, prog = load()
    url = PAGE_URL_FILE.read_text().strip() if PAGE_URL_FILE.exists() else ""
    ids = [t["id"] for p in cl["phases"] for t in p["tasks"]]
    assert len(ids) == len(set(ids)), "duplicate step ids"
    (L / "README.md").write_text(readme(cl, prog, url))
    for s in cl.get("stores", []):
        d = L / s["folder"]
        d.mkdir(exist_ok=True)
        (d / "README.md").write_text(store_readme(s, cl, prog, url))
    page = L / "page"
    page.mkdir(exist_ok=True)
    (page / "checklist.json").write_text(json.dumps(cl, indent=1, ensure_ascii=False))
    (page / "builds.json").write_text(json.dumps(builds(), indent=1, ensure_ascii=False))
    done = sum(1 for i in ids if prog.get(i, {}).get("done"))
    print(f"{len(ids)} steps in {len(cl['phases'])} phases, {done} done; wrote LAUNCH/README.md, {len(cl.get('stores', []))} store READMEs, page data")


if __name__ == "__main__":
    main()
