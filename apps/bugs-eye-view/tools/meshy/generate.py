#!/usr/bin/env python3
"""Generate the game's 3D models with Meshy (text to 3D).

Reads tools/meshy/assets.json, runs a Meshy preview task and then a refine
(texturing) task for each model, and saves the result as
assets/models/<id>.glb. The game picks those files up automatically: every
SkinAnchor whose model_id matches swaps its placeholder for the model.

Needs only the Python standard library and a Meshy API key in the
MESHY_API_KEY environment variable (never put the key in this repo).

  python3 tools/meshy/generate.py --list            # what's done / pending
  python3 tools/meshy/generate.py --dry-run --tier 1 # show requests, no network
  python3 tools/meshy/generate.py --tier 1           # bugs and threats first
  python3 tools/meshy/generate.py --only bug_fly,pet_cat
  python3 tools/meshy/generate.py                    # everything still missing

Progress is saved in tools/meshy/state.json after every step, so an
interrupted run picks up where it left off (Meshy tasks keep running on
their side). Re-run with --force to regenerate models that already exist.
"""
from __future__ import annotations

import argparse
import json
import os
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
        req.add_header("User-Agent", "bugs-eye-view-meshy/1.0")
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
            req = urllib.request.Request(url, headers={"User-Agent": "bugs-eye-view-meshy/1.0"})
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
    s = state.setdefault(aid, {})
    dest = MODELS / f"{aid}.glb"

    if not s.get("preview_id"):
        body = preview_body(asset, manifest)
        s["preview_id"] = request("POST", API_BASE + ENDPOINT, key, body)["result"]
        s["prompt"] = body["prompt"]
        save_state(state)
        log(f"{aid}: preview started ({s['preview_id']})")
    preview = wait_task(s["preview_id"], key, aid + " preview", args.poll, args.timeout)

    final = preview
    if not args.preview_only:
        if not s.get("refine_id"):
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
    s["done"] = True
    s["bytes"] = size
    s["textured"] = not args.preview_only
    save_state(state)
    return f"{aid}: saved assets/models/{aid}.glb ({size / 1_048_576:.1f} MB)"


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
    return assets


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--only", help="comma-separated model ids")
    ap.add_argument("--tier", type=int, action="append", help="1 bugs/threats, 2 cover/props, 3 furniture (repeatable)")
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
            print(f"tier {a.get('tier', '?')}  {a['id']:<22} {mark}")
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

    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        print("MESHY_API_KEY is not set. Add your Meshy API key as an environment variable "
              "(see tools/meshy/README.md); don't paste it into files in this repo.", file=sys.stderr)
        return 2

    failures = []
    with ThreadPoolExecutor(max_workers=max(1, args.parallel)) as pool:
        futures = {pool.submit(run_asset, a, manifest, state, key, args): a["id"] for a in todo}
        for fut, aid in futures.items():
            try:
                log(fut.result())
            except MeshyError as e:
                failures.append(aid)
                log(f"{aid}: FAILED - {e}")
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
