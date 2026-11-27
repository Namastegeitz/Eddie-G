#!/usr/bin/env bash
# Makes "Cymatic Light Chamber" on your Desktop with the manual, print files, gobo library, show videos
# and the Android app (about 280 MB). Safe to run again: it only downloads what's missing.
#   curl -fsSL https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/files/get-desktop-folder.sh | bash
set -euo pipefail
SITE="${SITE:-https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber}"
DEST="$HOME/Desktop/Cymatic Light Chamber"
mkdir -p "$DEST/1 Start here"
echo "Making: $DEST"
curl -fsSL "$SITE/files/manifest.txt" | while IFS=$'\t' read -r path folder; do
  [ -z "$path" ] && continue
  mkdir -p "$DEST/$folder"
  out="$DEST/$folder/$(basename "$path")"
  if [ -s "$out" ]; then echo "  have  $folder/$(basename "$path")"; continue; fi
  echo "  get   $folder/$(basename "$path")"
  curl -fSL --retry 3 -o "$out.part" "$SITE/files/$path" && mv "$out.part" "$out"
done
curl -fsSL -o "$DEST/1 Start here/Start here.html" "$SITE/files/start-here.html"
echo "Done. Open \"1 Start here/Start here.html\" in the folder on your Desktop."
