#!/usr/bin/env python3
"""Offline test of tools/meshy/generate.py against a local MOCK of the Meshy
API (no network, no key, no real Meshy output). The mock answers the
create/poll calls the way the API documents them and serves
tests/fixtures/formation_fixture.glb (made by the game itself) as the
"model". Checks that the script creates preview + refine tasks with the
low-poly settings, waits for them, downloads the GLB into the slot and
writes the manifest.   python3 tools/meshy/test_pipeline.py
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
        rc = generate.main(["--api-base", "http://127.0.0.1:%d" % srv.server_address[1], "--slot-root", tmp,
                            "--biome", "eerie", "--only", "ridge,shard"])
        slot = os.path.join(tmp, "assets", "biomes", "eerie", "ridge.glb")
        man = json.load(open(os.path.join(tmp, "assets", "biomes", "meshy_manifest.json")))
        checks = [
            ("script succeeded", rc == 0),
            ("4 tasks: preview + refine for 2 formations", len(calls) == 4),
            ("preview asks for a remeshed low-poly triangle mesh", calls[0]["mode"] == "preview" and calls[0]["should_remesh"] is True
             and calls[0]["topology"] == "triangle" and calls[0]["target_polycount"] == 6000),
            ("near-ring formation gets a smaller face budget", calls[2]["target_polycount"] == 2500),
            ("refine textures the preview", calls[1] == {"mode": "refine", "preview_task_id": "task-1", "enable_pbr": True}),
            ("GLB saved in the slot", os.path.exists(slot) and open(slot, "rb").read(4) == b"glTF"),
            ("manifest records both", set(man) == {"eerie/ridge", "eerie/shard"} and man["eerie/ridge"]["preview_task"] == "task-1"),
        ]
        calls.clear()
        rc2 = generate.main(["--api-base", "http://127.0.0.1:%d" % srv.server_address[1], "--slot-root", tmp,
                             "--biome", "eerie", "--only", "ridge"])
        checks.append(("existing slots are kept unless --force", rc2 == 0 and len(calls) == 0))
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
