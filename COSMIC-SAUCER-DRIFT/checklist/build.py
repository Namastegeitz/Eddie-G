"""Build the live checklist page and the project README from checklist.json.

  python3 make_checklist.py   # after editing the steps
  python3 build.py            # writes page/index.html and ../README.md

progress.json is the last known state of every step (Claude refreshes it from the live
page's database when syncing). page_url.txt holds the live page's link."""
import json, os, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
data = json.load(open(os.path.join(HERE, "checklist.json")))
prog_path = os.path.join(HERE, "progress.json")
if os.path.exists(prog_path):
    progress = json.load(open(prog_path))
else:
    progress = {}
for s in data["steps"]:
    if s["id"] not in progress and s["initial"] == "done":
        progress[s["id"]] = {"status": "done", "by": "claude", "note": s.get("evidence", ""), "at": 0, "history": []}
json.dump(progress, open(prog_path, "w"), indent=1)

def esc(x):
    return json.dumps(x, ensure_ascii=False).replace("</", "<\\/")

tpl = open(os.path.join(HERE, "page", "template.html")).read()
page = tpl.replace("__CHECKLIST_JSON__", esc(data)).replace("__PROGRESS_JSON__", esc(progress))
open(os.path.join(HERE, "page", "index.html"), "w").write(page)

url_file = os.path.join(HERE, "page_url.txt")
page_url = open(url_file).read().strip() if os.path.exists(url_file) else ""
GAME_URL = "https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY"

MARK = {"done": "✅", "doing": "🔄", "blocked": "⛔", "todo": "⬜"}
WHO = {"you": "You", "claude": "Claude", "both": "Together"}
steps = data["steps"]
st = lambda i: progress.get(i, {}).get("status", "todo")
done = sum(1 for s in steps if st(s["id"]) == "done")
lines = []
A = lines.append
A("# **COSMIC SAUCER DRIFT**")
A("")
A("Everything for the game in one folder: the Godot project, every build, a kit for each store,")
A("and the launch checklist. Store rules researched **%s**." % data["researched"])
A("")
A("| | |")
A("|---|---|")
A("| ▶ **Live checklist** (tick steps, report bugs, log play sessions) | %s |" % (page_url or "link appears after the first publish"))
A("| 🎮 **Play the game in a browser** | %s |" % GAME_URL)
A("| 📁 [`game/`](game/) | The Godot 4.7 project (source, docs, tests, tools) |")
A("| 📦 [`builds/`](builds/) | One folder per build: web, Android APK, Play bundle, iOS Xcode, Windows, macOS, Linux |")
A("| 🏪 [`stores/`](stores/) | One kit per store: rules, sizes, costs, what's done, what's missing, sources |")
A("| ✅ [`checklist/`](checklist/) | The checklist data and the page it builds |")
A("| 📝 [`prompts/`](prompts/) | The original game brief and the next-feature prompts |")
A("")
A("## Progress: %d of %d steps done" % (done, len(steps)))
A("")
bar = round(done * 20 / len(steps))
A("`" + "█" * bar + "░" * (20 - bar) + "` %d%%" % round(done * 100 / len(steps)))
A("")
A("✅ done · 🔄 doing · ⛔ blocked · ⬜ to do. Ticks you make on the live page are copied here when Claude syncs.")
A("Snapshot: %s." % datetime.date.today().isoformat())
A("")
for i, p in enumerate(data["phases"], 1):
    ps = [s for s in steps if s["phase"] == p["id"]]
    pd = sum(1 for s in ps if st(s["id"]) == "done")
    A("### Phase %d · %s (%d/%d)" % (i, p["name"], pd, len(ps)))
    A("")
    A("_%s_" % p["goal"])
    A("")
    for s in ps:
        extra = []
        if s["cost"]:
            extra.append(s["cost"])
        if s["time"]:
            extra.append(s["time"])
        stores = "all stores" if len(s["stores"]) >= len(data["stores"]) else ", ".join(data["stores"][k] for k in s["stores"])
        title = s["title"] if not s["link"] else "[%s](%s)" % (s["title"], s["link"].split("COSMIC-SAUCER-DRIFT/", 1)[-1] or ".")
        A("- %s **%s**: %s · %s%s" % (MARK.get(st(s["id"]), "⬜"), WHO[s["who"]], title, stores, (" · " + " · ".join(extra)) if extra else ""))
    A("")
A("## How the live checklist works")
A("")
A("- Tick the circle next to a step and it turns into a green check. The tick is saved, and every")
A("  device with the page open updates within seconds.")
A("- Each step tells you how to do it, why it matters, what to watch out for, what it unlocks next,")
A("  and what's already on the computer.")
A("- Notes on a step, **bug reports** and **play-session logs** are stored with the page. Claude reads them")
A("  (\"check the checklist\" in the chat), fixes bugs, marks them Fixed, and ticks its own steps.")
A("- The page is private to you. To let testers report bugs there, share it from its page on claude.ai.")
open(os.path.join(ROOT, "README.md"), "w").write("\n".join(lines) + "\n")
print("page:", os.path.getsize(os.path.join(HERE, "page", "index.html")) // 1024, "KB; README:", done, "/", len(steps), "done")
