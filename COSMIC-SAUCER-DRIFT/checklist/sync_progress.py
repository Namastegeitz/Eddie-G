"""Copy the live page's step statuses into progress.json (then run build.py).
Input: a file with one database document per line, as Claude's db_list returns them:
  {"id": "ws-folder", "data": {"status": "done", "by": "claude", "note": "...", "at": 1794..., "history": [...]}}
Usage: python3 sync_progress.py docs.jsonl"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ids = {s["id"] for s in json.load(open(os.path.join(HERE, "checklist.json")))["steps"]}
progress = {}
for line in open(sys.argv[1]):
    line = line.strip()
    if not line.startswith("{"):
        continue
    doc = json.loads(line)
    if doc.get("id") in ids and isinstance(doc.get("data"), dict):
        d = doc["data"]
        progress[doc["id"]] = {k: d.get(k) for k in ("status", "by", "note", "at", "history") if k in d}
json.dump(progress, open(os.path.join(HERE, "progress.json"), "w"), indent=1)
print("synced", len(progress), "steps;", sum(1 for v in progress.values() if v.get("status") == "done"), "done")
