#!/usr/bin/env bash
# Serves the packaged web build, taps the title screen in headless Chromium
# (as a phone) and checks the screen changed. Software rendering is slow, so
# this takes a few minutes. Needs Playwright (preinstalled in cloud sessions).
#   tools/web_tap_test.sh [build/web_artifact]
set -u
cd "$(dirname "$0")/.."
DIR="${1:-build/web_artifact}"
OUT="${TMPDIR:-/tmp}/csd_webtap"
PORT=8799
python3 -m http.server $PORT -d "$DIR" > /dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null' EXIT
sleep 1
PAGE=$(ls "$DIR"/*.html | head -1 | xargs basename)
node tools/web_tap_test.js "http://localhost:$PORT/$PAGE" "$OUT" || exit 1
python3 - "$OUT" <<'PY'
import sys
from PIL import Image, ImageChops, ImageStat
a = Image.open(sys.argv[1] + '_before.png').convert('RGB')
b = Image.open(sys.argv[1] + '_after.png').convert('RGB')
# The menu panel opens on the left; the title has only the backdrop there.
box = (int(a.width * 0.02), int(a.height * 0.2), int(a.width * 0.5), int(a.height * 0.9))
diff = ImageStat.Stat(ImageChops.difference(a.crop(box), b.crop(box))).mean
score = sum(diff) / 3
print('screen change %.1f' % score)
print('WEB TAP PASSED' if score > 12 else 'WEB TAP FAILED: tapping the title did nothing')
sys.exit(0 if score > 12 else 1)
PY
