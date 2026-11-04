#!/usr/bin/env python3
"""Packages build/web (Godot's Web export) for hosts that cap file size at
15 MB and only serve common web file types (e.g. a claude.ai artifact):
splits index.wasm into three parts, renames index.pck to a served
extension, and copies the custom page that stitches them back together.

    godot --headless --path . --export-release "Web" build/web/index.html
    python3 tools/web_artifact/package.py build/web build/web_artifact

Then publish build/web_artifact/canopy-crossing.html with the other files
in that folder alongside it. Any static host also works with build/web as-is.
"""
import json, os, re, shutil, subprocess, sys, time

src, dst = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
os.makedirs(dst, exist_ok=True)
for f in ["index.js", "index.audio.worklet.js", "index.audio.position.worklet.js", "index.png"]:
    shutil.copy(os.path.join(src, f), dst)
shutil.copy(os.path.join(src, "index.pck"), os.path.join(dst, "index-gamedata.wasm"))
wasm = open(os.path.join(src, "index.wasm"), "rb").read()
size = -(-len(wasm) // 3)
for i in range(3):
    open(os.path.join(dst, "index.part%d.wasm" % i), "wb").write(wasm[i * size:(i + 1) * size])
page = open(os.path.join(here, "canopy-crossing.html")).read()
sizes = {"index.pck": os.path.getsize(os.path.join(src, "index.pck")), "index.wasm": len(wasm)}
page = re.sub(r'"fileSizes":\{[^}]*\}', '"fileSizes":' + json.dumps(sizes, separators=(",", ":")), page)
page = re.sub(r'const SIZES = \{[^}]*\};', 'const SIZES = ' + json.dumps(sizes, separators=(",", ":")) + ';', page)
try:
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=here, capture_output=True, text=True).stdout.strip()
except OSError:
    commit = ""
stamp = time.strftime("%Y-%m-%d") + (" - " + commit if commit else "")
page = page.replace('<div id="build">Build dev</div>', '<div id="build">Build ' + stamp + '</div>')
open(os.path.join(dst, "canopy-crossing.html"), "w").write(page)
print("packaged into", dst)
