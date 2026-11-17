#!/usr/bin/env bash
# Build the store trailer and App Store previews from frames recorded by tests/trailer.tscn.
#   bash tools/make_trailer.sh <frames dir> <output dir>
# Writes: cosmic-saucer-drift-trailer-1080p.mp4 (Steam/YouTube/itch, ~44 s),
#         app-preview-iphone-1920x886.mp4 and app-preview-ipad-1600x1200.mp4 (Apple, 30 s, no cards).
set -euo pipefail
FR="${1:?frames dir}"; OUT="${2:?output dir}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
FONT="$HERE/assets/fonts/DejaVuSans-Bold.ttf"
MUSIC="$HERE/assets/audio/music_race.wav"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
BG="0x090c1a"
# Gameplay with a caption per clip (6 clips x 6 s).
cap() { echo "drawtext=fontfile=$FONT:text='$1':fontsize=54:fontcolor=white:borderw=4:bordercolor=0x000000@0.6:x=(w-text_w)/2:y=h-150:enable='between(t,$2,$3)':alpha='if(lt(t,$2+0.4),(t-$2)/0.4,if(gt(t,$3-0.4),($3-t)/0.4,1))'"; }
CAPS="$(cap 'Race real worlds' 0.3 5.7),$(cap 'Fly the realistic HD Aurora' 6.3 11.7),$(cap 'Race from a 3D cockpit' 12.3 17.7),$(cap '20 power-ups' 18.3 23.7),$(cap 'Drift to boost' 24.3 29.7),$(cap '14 worlds · 42 track layouts' 30.3 35.7)"
ffmpeg -v error -y -framerate 30 -i "$FR/frame_%05d.png" -vf "$CAPS,format=yuv420p" -c:v libx264 -preset slow -crf 18 -r 30 "$TMP/play.mp4"
card() { # $1 title, $2 subtitle, $3 seconds, $4 file
  ffmpeg -v error -y -f lavfi -i "color=c=$BG:s=1920x1080:d=$3:r=30" -vf \
    "drawtext=fontfile=$FONT:text='$1':fontsize=120:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2-60,drawtext=fontfile=$FONT:text='$2':fontsize=46:fontcolor=0x4fd8ff:x=(w-text_w)/2:y=(h/2)+70,fade=in:0:12,fade=out:st=$(echo "$3 - 0.4" | bc):d=0.4,format=yuv420p" \
    -c:v libx264 -preset slow -crf 18 "$4"
}
card "COSMIC SAUCER DRIFT" "Race alien spacecraft across real worlds" 3 "$TMP/title.mp4"
card "COSMIC SAUCER DRIFT" "Free  ·  No ads  ·  Plays offline" 4 "$TMP/end.mp4"
printf "file '%s'\nfile '%s'\nfile '%s'\n" "$TMP/title.mp4" "$TMP/play.mp4" "$TMP/end.mp4" > "$TMP/list.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$TMP/list.txt" -c copy "$TMP/video.mp4"
DUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/video.mp4")"
ffmpeg -v error -y -i "$TMP/video.mp4" -stream_loop -1 -i "$MUSIC" -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k \
  -af "afade=in:st=0:d=1,afade=out:st=$(echo "$DUR - 2" | bc):d=2" -t "$DUR" -movflags +faststart "$OUT/cosmic-saucer-drift-trailer-1080p.mp4"
# Apple app previews: gameplay only, 30 s, 30 fps, exact sizes.
ffmpeg -v error -y -i "$TMP/play.mp4" -stream_loop -1 -i "$MUSIC" -map 0:v -map 1:a -t 30 \
  -vf "crop=1920:886:0:97,format=yuv420p" -c:v libx264 -preset slow -crf 18 -r 30 -c:a aac -b:a 192k \
  -af "afade=out:st=28.5:d=1.5" -movflags +faststart "$OUT/app-preview-iphone-1920x886.mp4"
ffmpeg -v error -y -i "$TMP/play.mp4" -stream_loop -1 -i "$MUSIC" -map 0:v -map 1:a -t 30 \
  -vf "crop=1440:1080:240:0,scale=1600:1200,format=yuv420p" -c:v libx264 -preset slow -crf 18 -r 30 -c:a aac -b:a 192k \
  -af "afade=out:st=28.5:d=1.5" -movflags +faststart "$OUT/app-preview-ipad-1600x1200.mp4"
rm -r "$TMP"
ls -la "$OUT"
