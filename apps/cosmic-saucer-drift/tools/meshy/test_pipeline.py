#!/usr/bin/env python3
"""Offline test of tools/meshy/generate.py against a local MOCK of the Meshy
API (no network, no key, no real Meshy output). The mock answers the
create/poll calls the way the API documents them and serves
tests/fixtures/formation_fixture.glb (made by the game itself) as the
"model". Checks the credit guard (plan only without --yes, budget cap,
reserve), that only "asset" formations get a texture pass, the low-poly
settings, polling, the download into the slot and the manifest.
    python3 tools/meshy/test_pipeline.py
"""
import http.server
import json
import os
import shutil
import sys
import tempfile
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import generate  # noqa: E402

FIXTURE = os.path.join(PROJECT, "tests", "fixtures", "formation_fixture.glb")
calls = []


class Mock(http.server.BaseHTTPRequestHandler):
    polls = {}
    balance = 1300

    def log_message(self, *a):
        pass

    def _json(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.headers.get("Authorization") != "Bearer test-key":
            return self._json({"message": "bad key"}, 401)
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        calls.append(body)
        tid = "task-%d" % len(calls)
        Mock.polls[tid] = 0
        self._json({"result": tid})

    def do_GET(self):
        if self.path == "/openapi/v1/balance":
            return self._json({"balance": Mock.balance})
        if self.path.startswith("/files/"):
            data = open(FIXTURE, "rb").read()
            self.send_response(200)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        tid = self.path.rsplit("/", 1)[-1]
        Mock.polls[tid] = Mock.polls.get(tid, 0) + 1
        if Mock.polls[tid] < 2:
            return self._json({"id": tid, "status": "IN_PROGRESS", "progress": 50})
        port = self.server.server_address[1]
        self._json({"id": tid, "status": "SUCCEEDED", "progress": 100,
                    "model_urls": {"glb": "http://127.0.0.1:%d/files/%s.glb" % (port, tid)}})


def main():
    assert os.path.exists(FIXTURE), "run tools/make_fixture_glb.tscn first"
    srv = http.server.HTTPServer(("127.0.0.1", 0), Mock)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    tmp = tempfile.mkdtemp(prefix="meshy_test_")
    ok = True
    try:
        os.environ["MESHY_API_KEY"] = "test-key"
        orig_wait = generate.Meshy.wait
        generate.Meshy.wait = lambda self, tid, poll=0.05, timeout=30: orig_wait(self, tid, 0.05, 30)
        base = ["--api-base", "http://127.0.0.1:%d" % srv.server_address[1], "--slot-root", tmp]
        checks = []
        # 1. Without --yes nothing is spent.
        rc = generate.main(base + ["--biome", "eerie", "--only", "ridge,shard"])
        checks.append(("plan only: no --yes, no credits spent", rc == 0 and len(calls) == 0))
        # 2. Over the budget: refused before any call.
        rc = generate.main(base + ["--biome", "eerie", "--only", "ridge,shard", "--yes", "--max-credits", "30"])
        checks.append(("over budget: refused, nothing spent", rc == 3 and len(calls) == 0))
        # 3. Would dip into the reserve: refused.
        rc = generate.main(base + ["--biome", "eerie", "--only", "ridge,shard", "--yes", "--keep", "1290"])
        checks.append(("reserve kept: refused, nothing spent", rc == 4 and len(calls) == 0))
        # 4. A real (mock) run: biome-painted formations get no texture pass.
        rc = generate.main(base + ["--biome", "eerie", "--only", "ridge,shard", "--yes"])
        slot = os.path.join(tmp, "assets", "biomes", "eerie", "ridge.glb")
        man = json.load(open(os.path.join(tmp, "assets", "biomes", "meshy_manifest.json")))
        checks += [
            ("generated with --yes", rc == 0),
            ("2 tasks: one untextured preview per formation", len(calls) == 2 and all(c["mode"] == "preview" for c in calls)),
            ("preview asks for a remeshed low-poly triangle mesh", calls[0]["should_remesh"] is True
             and calls[0]["topology"] == "triangle" and calls[0]["target_polycount"] == 6000),
            ("near-ring formation gets a smaller face budget", calls[1]["target_polycount"] == 2500),
            ("GLB saved in the slot", os.path.exists(slot) and open(slot, "rb").read(4) == b"glTF"),
            ("manifest records both, untextured", set(man) == {"eerie/ridge", "eerie/shard"} and not man["eerie/ridge"]["textured"]),
        ]
        # 5. Existing slots are kept unless --force.
        calls.clear()
        rc = generate.main(base + ["--biome", "eerie", "--only", "ridge", "--yes"])
        checks.append(("existing slots are kept unless --force", rc == 0 and len(calls) == 0))
        # 6. A formation that keeps its own materials gets the texture pass.
        bio = json.load(open(generate.BIOMES))
        bio["biomes"][0]["formations"][1]["material"] = "asset"
        bfile = os.path.join(tmp, "biomes_asset.json")
        json.dump(bio, open(bfile, "w"))
        calls.clear()
        rc = generate.main(base + ["--biomes-file", bfile, "--biome", "eerie", "--only", "cone", "--yes"])
        checks.append(("asset formation: preview + refine", rc == 0 and len(calls) == 2 and calls[1].get("mode") == "refine"
                       and calls[1].get("preview_task_id", "").startswith("task-")))
        for name, good in checks:
            print(("PASS " if good else "FAIL ") + name)
            ok = ok and good
    finally:
        srv.shutdown()
        shutil.rmtree(tmp, ignore_errors=True)
    print("MESHY PIPELINE TEST %s" % ("OK" if ok else "FAILED"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
