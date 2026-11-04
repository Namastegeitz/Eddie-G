#!/usr/bin/env bash
# Render the game under Xvfb with Godot's movie writer and keep the last
# frame (or all frames with KEEP_ALL=1).
#   tools/capture.sh out.png <frames> [WxH] -- <game user args...>
# e.g. tools/capture.sh /tmp/home.png 40 720x1280 -- --skip-tutorial --screen=home
set -e
cd "$(dirname "$0")/.."
OUT="$1"; FRAMES="$2"; RES="${3:-720x1280}"
shift 3; [ "$1" = "--" ] && shift
TMP="$(mktemp -d)"
W="${RES%x*}"; H="${RES#*x}"
timeout 300 xvfb-run -a -s "-screen 0 $((W+64))x$((H+64))x24" "${GODOT:-godot}" --path . --rendering-driver opengl3 \
  --resolution "$RES" --write-movie "$TMP/f.png" --fixed-fps 30 --quit-after "$FRAMES" -- "$@" > "$TMP/log.txt" 2>&1 || true
grep -E "SCRIPT ERROR|^ERROR" "$TMP/log.txt" | grep -v "resources still in use" | head -20 || true
if [ "${KEEP_ALL:-0}" = "1" ]; then
  mkdir -p "$OUT"; cp "$TMP"/f*.png "$OUT"/
else
  LAST="$(ls "$TMP"/f*.png | tail -1)"; cp "$LAST" "$OUT"
fi
rm -rf "$TMP"
