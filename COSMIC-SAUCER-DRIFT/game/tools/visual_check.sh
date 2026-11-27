#!/usr/bin/env bash
# Visual regression check: key menu screens at 3 screen sizes (phone portrait
# 720x1280, landscape 1280x720, tablet 2048x1536) compared with the approved
# images in tests/visual_baseline/ (stored at half size). The menus have a
# moving 3D backdrop, so small differences are normal (about 1% of pixels
# between two identical runs); a screen fails above 5% changed pixels.
# Needs xvfb-run and Python with Pillow.
#   tools/visual_check.sh             compare with the baseline
#   tools/visual_check.sh --approve   make the current look the new baseline
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
SCREENS="${SCREENS:-home,settings,howto,credits,quick}"
out="$(mktemp -d)"
trap 'rm -rf "${out:?}"' EXIT
shoot() {  # resolution, extra args...
  local res="$1"; shift
  timeout 300 xvfb-run -a -s "-screen 0 2100x2100x24" "$GODOT" --path . --rendering-driver opengl3 \
    --resolution "$res" res://tests/menu_shots.tscn -- "$out" "$SCREENS" "$@" 2>&1 | grep -c "^saved" >/dev/null
}
shoot 1280x720 x
shoot 720x1280 portrait size=720x1280
shoot 2048x1536 x size=2048x1536 tag=tablet
if [ "${1:-}" = "--approve" ]; then
  python3 tools/visual_diff.py --approve "$out" tests/visual_baseline
else
  python3 tools/visual_diff.py "$out" tests/visual_baseline
fi
