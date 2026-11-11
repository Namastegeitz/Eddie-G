#!/usr/bin/env python3
"""Generate Canopy Crossing's 3D models with Meshy (text to 3D).

Reads tools/meshy/assets.json, runs a Meshy preview task and then a refine
(texturing) task for each model, downloads the GLB to tools/meshy/raw/,
and writes a phone-friendly copy to assets/models/<id>.glb (textures
resized and stored as WebP with gltf-transform). The game picks those files
up automatically (see scripts/view/models_3d.gd and scenery_3d.gd).

Credit budgets: assets.json "budgets" caps what each group ("fauna",
"scenery") may spend, using "costs" per task. Spending is recorded in
state.json before each task is sent, and the live Meshy balance is checked
too, so a run never goes over budget, even across restarts.

The API key comes from MESHY_API_KEY, or, in a Claude Code cloud session
whose environment saves the key as a network secret for api.meshy.ai, from
the session's proxy (leave MESHY_API_KEY unset). Never put the key in this
repo.

  python3 tools/meshy/generate.py --list             # what's done / pending, spend so far
  python3 tools/meshy/generate.py --balance          # credits left on the account
  python3 tools/meshy/generate.py --dry-run --group fauna
  python3 tools/meshy/generate.py --only fauna_soldier_ant
  python3 tools/meshy/generate.py --group fauna      # everything still missing in a group
  python3 tools/meshy/generate.py --optimize-only    # redo the phone-friendly copies

Progress is saved in tools/meshy/state.json after every step, so an
interrupted run picks up where it left off (Meshy tasks keep running on
their side). Re-run with --force to regenerate models that already exist.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent.parent
MANIFEST = HERE / "assets.json"
STATE = HERE / "state.json"
MODELS = PROJECT / "assets" / "models"
THUMBS = HERE / "thumbnails"
RAW = HERE / "raw"
GLTF_TRANSFORM = "@gltf-transform/cli@4.5.1"
TEXTURE_SIZE = {"fauna": 1024, "scenery": 512}
SIMPLIFY = {"fauna": 0.6, "scenery": 0.5}   # share of triangles kept (phones draw many at once)

API_BASE = os.environ.get("MESHY_API_BASE", "https://api.meshy.ai").rstrip("/")
ENDPOINT = "/openapi/v2/text-to-3d"
DONE = "SUCCEEDED"
FAILED = {"FAILED", "CANCELED", "EXPIRED"}
PREVIEW_KEYS = ("ai_model", "art_style", "topology", "target_polycount", "should_remesh", "symmetry_mode")

_lock = threading.Lock()


class MeshyError(RuntimeError):
    pass


def log(msg: str) -> None:
    with _lock:
        print(msg, flush=True)


# --- state -------------------------------------------------------------------

def load_state(path: Path = STATE) -> dict:
    if path.exists():
        return json.loads(path.read_text())
    return {}


def save_state(state: dict, path: Path = STATE) -> None:
    with _lock:
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
        tmp.replace(path)


# --- HTTP --------------------------------------------------------------------

def request(method: str, url: str, key: str, body: dict | None = None, retries: int = 5) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    for attempt in range(retries):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", "Bearer " + key)
        req.add_header("Accept", "application/json")
        req.add_header("User-Agent", "canopy-crossing-meshy/1.0")
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read() or b"{}")
        except urllib.error.HTTPError as e:
            text = e.read().decode(errors="replace")[:500]
            if e.code == 401:
                raise MeshyError("Meshy rejected the API key (401). Check MESHY_API_KEY.") from None
            if e.code == 402:
                raise MeshyError("Meshy says the account is out of credits (402).") from None
            if e.code == 429 or e.code >= 500:
                wait = 2 ** attempt * 5
                log(f"  Meshy busy ({e.code}), retrying in {wait}s")
                time.sleep(wait)
                continue
            raise MeshyError(f"Meshy {method} {url} -> {e.code}: {text}") from None
        except urllib.error.URLError as e:
            wait = 2 ** attempt * 5
            log(f"  network error ({e.reason}), retrying in {wait}s")
            time.sleep(wait)
    raise MeshyError(f"Meshy {method} {url} kept failing after {retries} tries")


def download(url: str, dest: Path, retries: int = 4) -> int:
    dest.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "canopy-crossing-meshy/1.0"})
            with urllib.request.urlopen(req, timeout=300) as r:
                blob = r.read()
            tmp = dest.with_suffix(dest.suffix + ".part")
            tmp.write_bytes(blob)
            tmp.replace(dest)
            return len(blob)
        except (urllib.error.URLError, TimeoutError) as e:
            wait = 2 ** attempt * 3
            log(f"  download failed ({e}), retrying in {wait}s")
            time.sleep(wait)
    raise MeshyError(f"could not download {url}")


# --- budget ------------------------------------------------------------------

def balance(key: str) -> int:
    return int(request("GET", f"{API_BASE}/openapi/v1/balance", key).get("balance", 0))


def charge(state: dict, manifest: dict, group: str, step: str, key: str, label: str) -> None:
    """Records a task's cost against its group's budget before it is sent;
    refuses if that would go over the budget or over the live balance."""
    cost = int(manifest.get("costs", {}).get(step, 0))
    budget = int(manifest.get("budgets", {}).get(group, 10 ** 9))
    with _lock:
        spent = state.setdefault("_spent", {})
        if int(spent.get(group, 0)) + cost > budget:
            raise BudgetError(f"{label}: {step} would take '{group}' to {int(spent.get(group, 0)) + cost} of its {budget} credits")
        live = balance(key)
        if live < cost:
            raise BudgetError(f"{label}: only {live} credits left on the account, {step} needs {cost}")
        spent[group] = int(spent.get(group, 0)) + cost
        state.setdefault("_log", []).append({"asset": label, "step": step, "cost": cost, "balance_before": live, "t": int(time.time())})
    save_state(state)


class BudgetError(MeshyError):
    pass


def optimize(aid: str, group: str) -> int:
    """Phone-friendly copy: textures resized (1024 px for animals, 512 for
    scenery) and stored as WebP; meshes welded, pruned and simplified
    (SIMPLIFY). Returns bytes."""
    src = RAW / f"{aid}.glb"
    dest = MODELS / f"{aid}.glb"
    MODELS.mkdir(parents=True, exist_ok=True)
    size = TEXTURE_SIZE.get(group, 1024)
    cmd = ["npx", "-y", GLTF_TRANSFORM, "optimize", str(src), str(dest), "--compress", "false",
           "--texture-compress", "webp", "--texture-size", str(size), "--simplify", "true",
           "--simplify-ratio", str(SIMPLIFY.get(group, 0.6)), "--simplify-error", "0.002",
           "--instance", "false", "--palette", "false", "--flatten", "false", "--join", "false"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 or not dest.exists():
        raise MeshyError(f"{aid}: gltf-transform failed: {r.stderr[-400:]}")
    return dest.stat().st_size


# --- jobs --------------------------------------------------------------------

def preview_body(asset: dict, manifest: dict) -> dict:
    d = manifest.get("defaults", {})
    prompt = asset["prompt"].strip()
    style = manifest.get("style", "").strip()
    if style:
        prompt = prompt + " " + style
    body = {"mode": "preview", "prompt": prompt}
    for k in PREVIEW_KEYS:
        v = asset.get(k, d.get(k))
        if v is not None:
            body[k] = v
    return body


def refine_body(asset: dict, manifest: dict, preview_id: str) -> dict:
    d = manifest.get("defaults", {})
    body = {"mode": "refine", "preview_task_id": preview_id}
    pbr = asset.get("enable_pbr", d.get("enable_pbr"))
    if pbr is not None:
        body["enable_pbr"] = pbr
    if asset.get("texture_prompt"):
        body["texture_prompt"] = asset["texture_prompt"]
    return body


def wait_task(task_id: str, key: str, label: str, poll: float, timeout: float) -> dict:
    start = time.time()
    last = -1
    while True:
        t = request("GET", f"{API_BASE}{ENDPOINT}/{task_id}", key)
        status = t.get("status")
        if status == DONE:
            return t
        if status in FAILED:
            err = (t.get("task_error") or {}).get("message", "")
            raise MeshyError(f"{label}: task {task_id} {status} {err}".strip())
        pct = int(t.get("progress") or 0)
        if pct != last:
            log(f"  {label}: {status} {pct}%")
            last = pct
        if time.time() - start > timeout:
            raise MeshyError(f"{label}: task {task_id} still {status} after {int(timeout)}s; re-run to resume")
        time.sleep(poll)


def run_asset(asset: dict, manifest: dict, state: dict, key: str, args) -> str:
    aid = asset["id"]
    group = asset.get("group", "fauna")
    s = state.setdefault(aid, {})
    dest = RAW / f"{aid}.glb"

    if not s.get("preview_id"):
        body = preview_body(asset, manifest)
        charge(state, manifest, group, "preview", key, aid)
        s["preview_id"] = request("POST", API_BASE + ENDPOINT, key, body)["result"]
        s["prompt"] = body["prompt"]
        save_state(state)
        log(f"{aid}: preview started ({s['preview_id']})")
    preview = wait_task(s["preview_id"], key, aid + " preview", args.poll, args.timeout)

    final = preview
    if not args.preview_only:
        if not s.get("refine_id"):
            charge(state, manifest, group, "refine", key, aid)
            s["refine_id"] = request("POST", API_BASE + ENDPOINT, key,
                                     refine_body(asset, manifest, s["preview_id"]))["result"]
            save_state(state)
            log(f"{aid}: texturing started ({s['refine_id']})")
        final = wait_task(s["refine_id"], key, aid + " texture", args.poll, args.timeout)

    url = (final.get("model_urls") or {}).get("glb")
    if not url:
        raise MeshyError(f"{aid}: finished but returned no GLB link")
    size = download(url, dest)
    with dest.open("rb") as f:
        if f.read(4) != b"glTF":
            dest.unlink()
            raise MeshyError(f"{aid}: download is not a GLB file")
    if final.get("thumbnail_url"):
        try:
            download(final["thumbnail_url"], THUMBS / f"{aid}.png")
        except MeshyError:
            pass
    small = optimize(aid, group)
    s["done"] = True
    s["bytes"] = size
    s["bytes_optimized"] = small
    s["textured"] = not args.preview_only
    save_state(state)
    return f"{aid}: saved assets/models/{aid}.glb ({size / 1_048_576:.1f} MB from Meshy, {small / 1_048_576:.2f} MB in the game)"


# --- CLI ---------------------------------------------------------------------

def select(manifest: dict, args) -> list[dict]:
    assets = manifest["assets"]
    if args.only:
        wanted = [x.strip() for x in args.only.split(",") if x.strip()]
        known = {a["id"] for a in assets}
        unknown = [w for w in wanted if w not in known]
        if unknown:
            raise SystemExit("unknown id(s): " + ", ".join(unknown))
        assets = [a for a in assets if a["id"] in wanted]
    if args.tier:
        assets = [a for a in assets if a.get("tier") in args.tier]
    if args.group:
        assets = [a for a in assets if a.get("group") in args.group]
    return assets


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--only", help="comma-separated model ids")
    ap.add_argument("--tier", type=int, action="append", help="1 first, 2, 3 (repeatable)")
    ap.add_argument("--group", action="append", help="fauna or scenery (repeatable)")
    ap.add_argument("--balance", action="store_true", help="print the account's credits and stop")
    ap.add_argument("--optimize-only", action="store_true", help="rebuild assets/models from tools/meshy/raw")
    ap.add_argument("--force", action="store_true", help="regenerate models that already exist")
    ap.add_argument("--preview-only", action="store_true", help="untextured preview meshes only (cheaper)")
    ap.add_argument("--dry-run", action="store_true", help="print the requests; no network, no key needed")
    ap.add_argument("--list", action="store_true", help="show which models exist")
    ap.add_argument("--parallel", type=int, default=2, help="models generated at once (default 2)")
    ap.add_argument("--poll", type=float, default=10.0, help="seconds between status checks")
    ap.add_argument("--timeout", type=float, default=1800.0, help="give up waiting on one task after this many seconds")
    args = ap.parse_args(argv)

    manifest = json.loads(MANIFEST.read_text())
    assets = select(manifest, args)
    state = load_state()

    if args.list:
        for a in assets:
            have = (MODELS / f"{a['id']}.glb").exists()
            s = state.get(a["id"], {})
            mark = "done" if have else ("in progress" if s.get("preview_id") else "-")
            print(f"{a.get('group', '?'):<8} tier {a.get('tier', '?')}  {a['id']:<26} {mark}")
        for g, b in manifest.get("budgets", {}).items():
            print(f"{g}: spent {state.get('_spent', {}).get(g, 0)} of {b} credits")
        return 0
    if args.optimize_only:
        for a in assets:
            if (RAW / f"{a['id']}.glb").exists():
                print(a["id"], optimize(a["id"], a.get("group", "fauna")), "bytes")
        return 0

    if args.balance:
        print(request("GET", f"{API_BASE}/openapi/v1/balance", os.environ.get("MESHY_API_KEY", "").strip() or "set-by-proxy"))
        return 0
    todo = [a for a in assets if args.force or not (MODELS / f"{a['id']}.glb").exists()]
    if args.force:
        for a in todo:
            state.pop(a["id"], None)
    print(f"{len(todo)} model(s) to generate, {len(assets) - len(todo)} already present")
    if args.dry_run:
        for a in todo:
            print(json.dumps({"id": a["id"], "preview": preview_body(a, manifest),
                              "refine": None if args.preview_only else refine_body(a, manifest, "<preview id>")}))
        return 0
    if not todo:
        return 0

    # With no MESHY_API_KEY, a placeholder goes out: a cloud session's proxy
    # swaps in the key saved for api.meshy.ai (anywhere else Meshy answers 401).
    key = os.environ.get("MESHY_API_KEY", "").strip() or "set-by-proxy"

    failures = []
    with ThreadPoolExecutor(max_workers=max(1, args.parallel)) as pool:
        futures = {pool.submit(run_asset, a, manifest, state, key, args): a["id"] for a in todo}
        for fut, aid in futures.items():
            try:
                log(fut.result())
            except MeshyError as e:
                failures.append(aid)
                log(f"{aid}: FAILED - {e}")
                if isinstance(e, BudgetError):
                    continue
                if "API key" in str(e) or "credits" in str(e):
                    pool.shutdown(cancel_futures=True)
                    break
    if failures:
        print(f"{len(failures)} failed: {', '.join(failures)}. Re-run to retry; finished models are kept.")
        return 1
    print("All done. Open the project in Godot (or run `godot --headless --path . --import`) to import the models.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
