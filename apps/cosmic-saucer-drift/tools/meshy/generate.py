#!/usr/bin/env python3
"""Generate the biome rock formations with Meshy and drop them into the
game's import slots.

For every formation in content/biomes.json that has a "prompt" and a "mesh"
slot (res://assets/biomes/<biome>/<id>.glb) this:
  1. creates a Meshy Text-to-3D *preview* task (untextured mesh, remeshed to a
     low-poly triangle mesh: should_remesh + topology + target_polycount),
  2. *refines* it (textures, PBR) only for formations that keep the model's
     own materials ("material": "asset"); formations painted with the biome
     palette ("material": "biome", the default) skip it: their textures would
     never show and only bloat the download (about 6 MB each),
  3. downloads the GLB into the slot and records the task in
     assets/biomes/meshy_manifest.json.
Then open/import the project (godot --headless --path . --import): Godot
imports each GLB with mesh LODs, and the game uses it instead of the
procedural recipe (scripts/track/biome_builder.gd). Check the result with
tools/content_report.tscn.

Needs an API key in MESHY_API_KEY and network access to api.meshy.ai and
the asset host Meshy returns download links on (assets.meshy.ai).
Standard library only.

Credits are spent carefully: a run first prints its plan and estimated
cost and spends NOTHING unless --yes is given. It refuses to go over
--max-credits (default 60, three models) and never lets the account drop
below --keep credits (default 1000). Estimates use the rates measured on
this account: 20 credits per model (preview), 10 per texture pass.

Usage:
  MESHY_API_KEY=... python3 tools/meshy/generate.py [--biome eerie] [--only ridge,cone]
      [--polycount 4000] [--ai-model latest] [--no-texture] [--dry-run] [--force]
      [--yes] [--max-credits 60] [--keep 1000]
  --api-base lets the pipeline run against a local mock (tests).
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.abspath(os.path.join(HERE, "..", ".."))
BIOMES = os.path.join(PROJECT, "content", "biomes.json")
MANIFEST = os.path.join(PROJECT, "assets", "biomes", "meshy_manifest.json")

# Credits per task (Meshy pricing; measured on this account: 8 previews + 1
# refine = 170). Lite models cost 5 per preview.
COST_PREVIEW = 20
COST_PREVIEW_LITE = 5
COST_REFINE = 10
LITE_MODELS = ("meshy-6-lite", "meshy-t2", "meshy-t2.5")
CRAFT = os.path.join(PROJECT, "content", "craft_hd.json")

# Per-ring default face budgets: horizon ridges are seen big, near rocks small.
RING_POLY = {"far": 6000, "mid": 4000, "near": 2500}


def res_to_path(res, root=PROJECT):
    if not res.startswith("res://"):
        raise ValueError("mesh slot must be a res:// path: " + res)
    return os.path.join(root, res[len("res://"):])


class Meshy:
    def __init__(self, key, base, verbose=True):
        self.key = key
        self.base = base.rstrip("/")
        self.verbose = verbose

    def _req(self, method, path, body=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method)
        req.add_header("Authorization", "Bearer " + self.key)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        for attempt in range(5):
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    return json.loads(r.read().decode() or "{}")
            except urllib.error.HTTPError as e:
                msg = e.read().decode(errors="replace")[:300]
                if e.code in (429, 500, 502, 503, 504) and attempt < 4:
                    time.sleep(2 ** attempt * 2)
                    continue
                raise RuntimeError("%s %s -> HTTP %d: %s" % (method, path, e.code, msg))
            except urllib.error.URLError as e:
                if attempt < 4:
                    time.sleep(2 ** attempt * 2)
                    continue
                raise RuntimeError("%s %s -> %s" % (method, path, e.reason))

    def balance(self):
        return int(self._req("GET", "/openapi/v1/balance").get("balance", 0))

    def create(self, body):
        return self._req("POST", "/openapi/v2/text-to-3d", body)["result"]

    def wait(self, task_id, poll=5.0, timeout=1800):
        t0 = time.time()
        last = -1
        while True:
            t = self._req("GET", "/openapi/v2/text-to-3d/" + task_id)
            st = t.get("status", "")
            if st == "SUCCEEDED":
                return t
            if st in ("FAILED", "CANCELED", "EXPIRED"):
                raise RuntimeError("task %s %s: %s" % (task_id, st, t.get("task_error", {})))
            pr = int(t.get("progress", 0))
            if self.verbose and pr != last:
                print("    %s %s %d%%" % (task_id[:8], st, pr), flush=True)
                last = pr
            if time.time() - t0 > timeout:
                raise RuntimeError("task %s timed out" % task_id)
            time.sleep(poll)


def download(url, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".part"
    with urllib.request.urlopen(url, timeout=300) as r, open(tmp, "wb") as f:
        while True:
            chunk = r.read(1 << 16)
            if not chunk:
                break
            f.write(chunk)
    with open(tmp, "rb") as f:
        if f.read(4) != b"glTF":
            os.remove(tmp)
            raise RuntimeError("download is not a GLB: " + url)
    os.replace(tmp, dest)


def refetch(a, jobs, manifest_path):
    """Download finished models again by task id: costs nothing. Meshy keeps
    task results for a limited time, so do this soon after a fresh clone."""
    try:
        with open(manifest_path) as f:
            manifest = json.load(f)
    except (OSError, ValueError):
        print("no manifest at " + manifest_path)
        return 1
    key = os.environ.get("MESHY_API_KEY", "")
    if not key and not a.dry_run:
        print("MESHY_API_KEY is not set")
        return 2
    api = Meshy(key, a.api_base)
    failed = 0
    for b, fm in jobs:
        name = fm["id"] if a.source == "craft" else "%s/%s" % (b["id"], fm["id"])
        entry = manifest.get(name)
        slot = res_to_path(fm["mesh"], a.slot_root)
        if not entry or not entry.get("final_task"):
            continue
        if os.path.exists(slot) and not a.force:
            print("%-18s already here" % name)
            continue
        if a.dry_run:
            print("%-18s GET task %s -> %s" % (name, entry["final_task"], slot))
            continue
        try:
            t = api._req("GET", "/openapi/v2/text-to-3d/" + entry["final_task"])
            url = t.get("model_urls", {}).get("glb", "")
            if not url:
                raise RuntimeError("the task has no GLB any more (results expire)")
            download(url, slot)
            print("%-18s fetched (%d KB)" % (name, os.path.getsize(slot) // 1024))
        except Exception as e:
            failed += 1
            print("%-18s FAILED: %s" % (name, e))
    return 1 if failed else 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--biome", default="", help="only this biome id")
    ap.add_argument("--only", default="", help="comma-separated formation ids")
    ap.add_argument("--polycount", type=int, default=0, help="target faces (default by ring: far 6000, mid 4000, near 2500)")
    ap.add_argument("--ai-model", default="latest")
    ap.add_argument("--art-style", default="realistic")
    ap.add_argument("--no-texture", action="store_true", help="never run the refine (texturing) step")
    ap.add_argument("--texture", action="store_true", help="always refine, even for biome-painted formations")
    ap.add_argument("--force", action="store_true", help="regenerate even if the slot already has a GLB")
    ap.add_argument("--dry-run", action="store_true", help="print the requests, call nothing")
    ap.add_argument("--api-base", default=os.environ.get("MESHY_API_BASE", "https://api.meshy.ai"))
    ap.add_argument("--biomes-file", default=BIOMES, help="biome data (default content/biomes.json)")
    ap.add_argument("--source", default="biomes", choices=["biomes", "craft"],
                    help="biomes: rock formations; craft: HD spacecraft exteriors and cockpits (content/craft_hd.json)")
    ap.add_argument("--craft-file", default=CRAFT)
    ap.add_argument("--slot-root", default=PROJECT, help="where res:// slots live (tests point this elsewhere)")
    ap.add_argument("--yes", action="store_true", help="actually spend credits (without it the run only shows its plan and cost)")
    ap.add_argument("--max-credits", type=int, default=60, help="refuse runs estimated above this (default 60 = three models)")
    ap.add_argument("--keep", type=int, default=1000, help="never let the account drop below this many credits (default 1000)")
    ap.add_argument("--refetch", action="store_true",
                    help="free: download the GLBs again from the task ids in the manifest (raw craft GLBs are not in git)")
    a = ap.parse_args(argv)
    only = set(x for x in a.only.split(",") if x)
    jobs = []
    if a.source == "craft":
        # Each HD craft has two slots: "model" (exterior) and "cockpit"
        # (first-person interior). --only takes a craft id (both parts) or
        # "id/model", "id/cockpit". Both keep their own textures.
        manifest_path = os.path.join(a.slot_root, "assets", "craft", "meshy_manifest.json")
        with open(a.craft_file) as f:
            craft = json.load(f)["saucers"]
        for c in craft:
            for part in ("model", "cockpit"):
                spec = dict(c.get(part, {}))
                if not spec.get("prompt") or not spec.get("mesh"):
                    continue
                spec["id"] = "%s/%s" % (c["id"], part)
                spec.setdefault("material", "asset")
                if only and c["id"] not in only and spec["id"] not in only:
                    continue
                jobs.append(({"id": "craft"}, spec))
    else:
        manifest_path = os.path.join(a.slot_root, "assets", "biomes", "meshy_manifest.json")
        with open(a.biomes_file) as f:
            biomes = json.load(f)["biomes"]
        for b in biomes:
            if a.biome and b["id"] != a.biome:
                continue
            for fm in b["formations"]:
                if only and fm["id"] not in only:
                    continue
                if not fm.get("prompt") or not fm.get("mesh"):
                    continue
                jobs.append((b, fm))
    if not jobs:
        print("nothing to generate")
        return 0
    if a.refetch:
        return refetch(a, jobs, manifest_path)

    # Plan: which slots would be (re)made, and what it would cost.
    def is_textured(fm):
        return a.texture or (not a.no_texture and fm.get("material", "biome") == "asset")
    todo = [(b, fm) for b, fm in jobs if a.force or not os.path.exists(res_to_path(fm["mesh"], a.slot_root))]
    preview_cost = COST_PREVIEW_LITE if a.ai_model in LITE_MODELS else COST_PREVIEW
    estimate = sum(preview_cost + (COST_REFINE if is_textured(fm) else 0) for b, fm in todo)
    print("Plan: %d model(s), about %d credits (budget %d, keep %d in the account)." % (len(todo), estimate, a.max_credits, a.keep))
    if todo and estimate > a.max_credits and not a.dry_run:
        print("Over budget: nothing was spent. Narrow it with --only, or raise --max-credits on purpose.")
        return 3

    key = os.environ.get("MESHY_API_KEY", "")
    if not key and not a.dry_run:
        print("MESHY_API_KEY is not set (and api.meshy.ai must be reachable). Use --dry-run to see the requests.")
        return 2
    api = Meshy(key, a.api_base)
    start_balance = None
    if todo and not a.dry_run:
        start_balance = api.balance()
        print("Account balance: %d credits." % start_balance)
        if start_balance - estimate < a.keep:
            print("That would leave fewer than %d credits: nothing was spent. Use --keep to change the reserve." % a.keep)
            return 4
        if not a.yes:
            print("Nothing was spent. Re-run with --yes to generate.")
            return 0
    manifest = {}
    if os.path.exists(manifest_path):
        with open(manifest_path) as f:
            manifest = json.load(f)

    failed = 0
    mine = 0   # credits this run's own tasks cost, at Meshy's prices
    for b, fm in jobs:
        slot = res_to_path(fm["mesh"], a.slot_root)
        name = fm["id"] if a.source == "craft" else "%s/%s" % (b["id"], fm["id"])
        if os.path.exists(slot) and not a.force:
            print("%-18s already in its slot (use --force to redo)" % name)
            continue
        poly = a.polycount or int(fm.get("polycount", RING_POLY.get(fm.get("ring", "near"), 3000)))
        preview = {
            "mode": "preview",
            "prompt": fm["prompt"][:600],
            "art_style": a.art_style,
            "ai_model": a.ai_model,
            "should_remesh": True,
            "topology": "triangle",
            "target_polycount": poly,
            "symmetry_mode": fm.get("symmetry", "off"),
        }
        textured = is_textured(fm)
        print("%-18s %d faces%s  %s" % (name, poly, ", textured" if textured else "", fm["prompt"][:70] + "..."))
        if a.dry_run:
            print("    POST /openapi/v2/text-to-3d " + json.dumps(preview))
            if textured:
                print("    POST /openapi/v2/text-to-3d " + json.dumps({"mode": "refine", "preview_task_id": "<preview id>", "enable_pbr": True}))
            print("    -> " + slot)
            continue
        job_cost = preview_cost + (COST_REFINE if textured else 0)
        if start_balance is not None and len(jobs) > 1:
            # Something else may be using the same account at the same time:
            # look again before each model so the reserve still holds.
            try:
                now = api.balance()
            except RuntimeError:
                now = None
            if now is not None and now - job_cost < a.keep:
                print("    stopped: the balance is %d and the reserve is %d, so nothing more was spent." % (now, a.keep))
                break
        try:
            pid = api.create(preview)
            mine += preview_cost
            task = api.wait(pid)
            final_id = pid
            if textured:
                rid = api.create({"mode": "refine", "preview_task_id": pid, "enable_pbr": True})
                mine += COST_REFINE
                task = api.wait(rid)
                final_id = rid
            url = task.get("model_urls", {}).get("glb", "")
            if not url:
                raise RuntimeError("no GLB in the task result")
            download(url, slot)
            manifest[name] = {"slot": fm["mesh"], "prompt": fm["prompt"], "target_polycount": poly,
                              "preview_task": pid, "final_task": final_id, "textured": textured,
                              "ai_model": a.ai_model, "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
            os.makedirs(os.path.dirname(manifest_path), exist_ok=True)
            with open(manifest_path, "w") as f:
                json.dump(manifest, f, indent=2)
            print("    saved %s (%d KB)" % (fm["mesh"], os.path.getsize(slot) // 1024))
        except Exception as e:  # keep going with the other formations
            failed += 1
            print("    FAILED: %s" % e)
    if start_balance is not None:
        try:
            end = api.balance()
            print("Credits spent by this run: %d." % mine)
            note = ""
            if start_balance - end != mine:
                note = " (the difference is other use of this Meshy account at the same time)"
            print("Account balance: %d -> %d, %d less%s." % (start_balance, end, start_balance - end, note))
        except RuntimeError:
            pass
    if not a.dry_run:
        print("Done. Now import: godot --headless --path . --import ; then check: godot --headless --path . res://tools/content_report.tscn")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
