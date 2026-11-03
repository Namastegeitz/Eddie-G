#!/usr/bin/env python3
"""Offline test for generate.py against a local fake of the Meshy API.

The fake only mimics the request/response shapes generate.py relies on; it
proves the client's flow (preview -> refine -> download, resume, errors),
not what the real service returns.

  python3 tools/meshy/test_generate.py
"""
from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import shutil
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
KEY = "test-key"
GLB = b"glTF" + b"\x02\x00\x00\x00" + b"\x0c\x00\x00\x00"


class Fake(BaseHTTPRequestHandler):
    tasks: dict = {}
    posts: list = []
    polls_needed = 2

    def log_message(self, *a):
        pass

    def _send(self, code: int, obj=None, raw: bytes | None = None):
        body = raw if raw is not None else json.dumps(obj or {}).encode()
        self.send_response(code)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authed(self) -> bool:
        if self.headers.get("Authorization") != "Bearer " + KEY:
            self._send(401, {"message": "Invalid API key"})
            return False
        return True

    def do_POST(self):
        if not self._authed():
            return
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        Fake.posts.append(body)
        if body["mode"] == "refine" and body["preview_task_id"] not in Fake.tasks:
            return self._send(400, {"message": "unknown preview"})
        tid = f"task{len(Fake.tasks) + 1}"
        Fake.tasks[tid] = {"polls": 0, "mode": body["mode"]}
        self._send(202, {"result": tid})

    def do_GET(self):
        port = self.server.server_address[1]
        if self.path.startswith("/files/"):
            return self._send(200, raw=GLB if self.path.endswith(".glb") else b"\x89PNG")
        if not self._authed():
            return
        tid = self.path.rsplit("/", 1)[-1]
        t = Fake.tasks.get(tid)
        if t is None:
            return self._send(404, {"message": "no task"})
        t["polls"] += 1
        if t["polls"] < Fake.polls_needed:
            return self._send(200, {"id": tid, "status": "IN_PROGRESS", "progress": 50})
        self._send(200, {"id": tid, "status": "SUCCEEDED", "progress": 100,
                         "model_urls": {"glb": f"http://127.0.0.1:{port}/files/{tid}.glb"},
                         "thumbnail_url": f"http://127.0.0.1:{port}/files/{tid}.png"})


def load_generate(base: str, root: Path):
    os.environ["MESHY_API_BASE"] = base
    spec = importlib.util.spec_from_file_location("meshy_generate", HERE / "generate.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.MODELS = root / "models"
    mod.THUMBS = root / "thumbs"
    mod.STATE = root / "state.json"
    mod.save_state.__defaults__ = (mod.STATE,)
    mod.load_state.__defaults__ = (mod.STATE,)
    return mod


def main() -> int:
    server = ThreadingHTTPServer(("127.0.0.1", 0), Fake)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_address[1]}"
    root = Path(tempfile.mkdtemp(prefix="meshy_test_"))
    fails = []

    def check(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)

    try:
        g = load_generate(base, root)
        common = ["--poll", "0.01", "--timeout", "5"]

        os.environ["MESHY_API_KEY"] = KEY
        rc = g.main(["--only", "bug_fly,crumb", *common])
        check(rc == 0, "two models generate end to end")
        check((root / "models/bug_fly.glb").read_bytes()[:4] == b"glTF", "the GLB lands in assets/models/<id>.glb")
        check((root / "thumbs/crumb.png").exists(), "thumbnails are saved")
        modes = sorted(p["mode"] for p in Fake.posts)
        check(modes == ["preview", "preview", "refine", "refine"], "each model is a preview then a texture task")
        pv = next(p for p in Fake.posts if p["mode"] == "preview")
        check("Stylized" in pv["prompt"] and pv["topology"] == "triangle" and "target_polycount" in pv,
              "prompts carry the shared style and the manifest's mesh settings")
        state = json.loads((root / "state.json").read_text())
        check(state["bug_fly"]["done"] and state["crumb"]["textured"], "progress is recorded")

        n = len(Fake.posts)
        rc = g.main(["--only", "bug_fly,crumb", *common])
        check(rc == 0 and len(Fake.posts) == n, "models already on disk are skipped (no credits spent)")

        # Resume: a preview started in an earlier run is not paid for twice.
        state = json.loads((root / "state.json").read_text())
        tid = "task99"
        Fake.tasks[tid] = {"polls": 0, "mode": "preview"}
        state["pet_cat"] = {"preview_id": tid}
        (root / "state.json").write_text(json.dumps(state))
        n = len(Fake.posts)
        rc = g.main(["--only", "pet_cat", *common])
        new = Fake.posts[n:]
        check(rc == 0 and [p["mode"] for p in new] == ["refine"] and new[0]["preview_task_id"] == tid,
              "an interrupted run resumes from its saved preview task")

        rc = g.main(["--only", "pet_dog", "--preview-only", *common])
        check(rc == 0 and Fake.posts[-1]["mode"] == "preview", "--preview-only skips texturing")

        n = len(Fake.posts)
        with contextlib.redirect_stdout(io.StringIO()):
            rc = g.main(["--tier", "3", "--dry-run"])
        check(rc == 0 and len(Fake.posts) == n, "--dry-run sends nothing")

        os.environ["MESHY_API_KEY"] = "wrong"
        rc = g.main(["--only", "robot_vacuum", *common])
        check(rc == 1 and not (root / "models/robot_vacuum.glb").exists(), "a rejected key fails cleanly")

        os.environ.pop("MESHY_API_KEY")
        rc = g.main(["--only", "robot_vacuum", *common])
        check(rc == 2, "no key set: explains where to put it")
    finally:
        server.shutdown()
        shutil.rmtree(root, ignore_errors=True)

    print(f"== meshy client: {11 - len(fails)} passed, {len(fails)} failed ==")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
