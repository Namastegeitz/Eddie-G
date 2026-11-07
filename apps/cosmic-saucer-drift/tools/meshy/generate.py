#!/usr/bin/env python3
"""Generate the biome rock formations with Meshy and drop them into the
game's import slots.

For every formation in content/biomes.json that has a "prompt" and a "mesh"
slot (res://assets/biomes/<biome>/<id>.glb) this:
  1. creates a Meshy Text-to-3D *preview* task (untextured mesh, remeshed to a
     low-poly triangle mesh: should_remesh + topology + target_polycount),
  2. optionally *refines* it (textures, PBR) unless --no-texture,
  3. downloads the GLB into the slot and records the task in
     assets/biomes/meshy_manifest.json.
Then open/import the project (godot --headless --path . --import): Godot
imports each GLB with mesh LODs, and the game uses it instead of the
procedural recipe (scripts/track/biome_builder.gd). Check the result with
tools/content_report.tscn.

Needs an API key in MESHY_API_KEY and network access to api.meshy.ai and
the asset host Meshy returns download links on (assets.meshy.ai).
Standard library only.

Usage:
  MESHY_API_KEY=... python3 tools/meshy/generate.py [--biome eerie] [--only ridge,cone]
      [--polycount 4000] [--ai-model latest] [--no-texture] [--dry-run] [--force]
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


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--biome", default="", help="only this biome id")
    ap.add_argument("--only", default="", help="comma-separated formation ids")
    ap.add_argument("--polycount", type=int, default=0, help="target faces (default by ring: far 6000, mid 4000, near 2500)")
    ap.add_argument("--ai-model", default="latest")
    ap.add_argument("--art-style", default="realistic")
    ap.add_argument("--no-texture", action="store_true", help="skip the refine (texturing) step")
    ap.add_argument("--force", action="store_true", help="regenerate even if the slot already has a GLB")
    ap.add_argument("--dry-run", action="store_true", help="print the requests, call nothing")
    ap.add_argument("--api-base", default=os.environ.get("MESHY_API_BASE", "https://api.meshy.ai"))
    ap.add_argument("--biomes-file", default=BIOMES, help="biome data (default content/biomes.json)")
    ap.add_argument("--slot-root", default=PROJECT, help="where res:// slots live (tests point this elsewhere)")
    a = ap.parse_args(argv)
    manifest_path = os.path.join(a.slot_root, "assets", "biomes", "meshy_manifest.json")

    with open(a.biomes_file) as f:
        biomes = json.load(f)["biomes"]
    only = set(x for x in a.only.split(",") if x)
    jobs = []
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

    key = os.environ.get("MESHY_API_KEY", "")
    if not key and not a.dry_run:
        print("MESHY_API_KEY is not set (and api.meshy.ai must be reachable). Use --dry-run to see the requests.")
        return 2
    api = Meshy(key, a.api_base)
    manifest = {}
    if os.path.exists(manifest_path):
        with open(manifest_path) as f:
            manifest = json.load(f)

    failed = 0
    for b, fm in jobs:
        slot = res_to_path(fm["mesh"], a.slot_root)
        name = "%s/%s" % (b["id"], fm["id"])
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
            "symmetry_mode": "off",
        }
        print("%-18s %d faces  %s" % (name, poly, fm["prompt"][:70] + "..."))
        if a.dry_run:
            print("    POST /openapi/v2/text-to-3d " + json.dumps(preview))
            if not a.no_texture:
                print("    POST /openapi/v2/text-to-3d " + json.dumps({"mode": "refine", "preview_task_id": "<preview id>", "enable_pbr": True}))
            print("    -> " + slot)
            continue
        try:
            pid = api.create(preview)
            task = api.wait(pid)
            final_id = pid
            if not a.no_texture:
                rid = api.create({"mode": "refine", "preview_task_id": pid, "enable_pbr": True})
                task = api.wait(rid)
                final_id = rid
            url = task.get("model_urls", {}).get("glb", "")
            if not url:
                raise RuntimeError("no GLB in the task result")
            download(url, slot)
            manifest[name] = {"slot": fm["mesh"], "prompt": fm["prompt"], "target_polycount": poly,
                              "preview_task": pid, "final_task": final_id, "textured": not a.no_texture,
                              "ai_model": a.ai_model, "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
            os.makedirs(os.path.dirname(manifest_path), exist_ok=True)
            with open(manifest_path, "w") as f:
                json.dump(manifest, f, indent=2)
            print("    saved %s (%d KB)" % (fm["mesh"], os.path.getsize(slot) // 1024))
        except Exception as e:  # keep going with the other formations
            failed += 1
            print("    FAILED: %s" % e)
    if not a.dry_run:
        print("Done. Now import: godot --headless --path . --import ; then check: godot --headless --path . res://tools/content_report.tscn")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
