#!/bin/bash
# Renders "The Bee and the Giraffe" (scripts/ui/film_screen.gd) to an MP4:
#   tools/render_film.sh [WxH] [out.mp4]
# Defaults: 1920x1080 into build/film/bee_and_giraffe.mp4 (about 15 minutes
# on a software GPU). Needs xvfb-run and ffmpeg.
set -e
cd "$(dirname "$0")/.."
RES=${1:-1920x1080}
OUT=${2:-build/film/bee_and_giraffe.mp4}
W=${RES%x*}; H=${RES#*x}
TMP=$(mktemp -d)
mkdir -p "$(dirname "$OUT")"
printf '[display]\n\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "$W" "$H" > override.cfg
trap 'rm -f override.cfg; rm -rf "$TMP"' EXIT
xvfb-run -a -s "-screen 0 $((W+64))x$((H+64))x24" godot --path . --rendering-driver opengl3 \
  --resolution "$RES" --write-movie "$TMP/film.avi" --fixed-fps 30 res://tools/render_film.tscn > "$TMP/log.txt" 2>&1 || true
grep -E "SCRIPT ERROR" "$TMP/log.txt" | head -5 || true
[ -s "$TMP/film.avi" ] || { echo "no frames written"; tail -20 "$TMP/log.txt"; exit 1; }
ffmpeg -y -loglevel error -i "$TMP/film.avi" -c:v libx264 -preset slow -crf 26 -pix_fmt yuv420p \
  -c:a aac -b:a 160k -movflags +faststart "$OUT"
LEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
python3 -c "import sys; sys.exit(0 if float('$LEN') > 26.5 else 1)" || { echo "film too short: $LEN s"; exit 1; }
echo "FILM OK $OUT ($(du -h "$OUT" | cut -f1), ${LEN%.*} s)"
