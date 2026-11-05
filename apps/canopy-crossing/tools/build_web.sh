#!/usr/bin/env bash
# Builds the web version, packages it for a claude.ai artifact, and checks
# it in a phone-sized touch browser (tools/web_artifact/smoke.js): it must
# load, a finger tap on the eye button must switch to first person and show
# a 3D scene without hopping, and a second tap must switch back. Any failure
# stops here, so a broken first-person view never ships.
#   tools/build_web.sh            # -> build/web (any static host), build/web_artifact (claude.ai)
# Needs: Godot 4.7.2 with web export templates, python3, node + playwright.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
rm -rf build/web build/web_artifact
mkdir -p build/web
echo "== export"
if ! timeout 900 "$GODOT" --headless --path . --export-release "Web" build/web/index.html > /tmp/cc_web_export.log 2>&1; then
  tail -20 /tmp/cc_web_export.log; echo "web export failed"; exit 1
fi
echo "== package"
python3 tools/web_artifact/package.py build/web build/web_artifact
echo "== smoke test (phone browser, touch)"
mkdir -p build/web_smoke
node tools/web_artifact/smoke.js build/web_artifact canopy-crossing.html build/web_smoke
echo "WEB BUILD OK: build/web_artifact (screenshots in build/web_smoke)"
