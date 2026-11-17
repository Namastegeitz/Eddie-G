#!/bin/sh
# Adds Cosmic Saucer Drift (opens in your browser) to your app menu and desktop.
set -e
cd "$(dirname "$0")"
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps" "$HOME/.local/share/applications"
cp cosmic-saucer-drift.png "$HOME/.local/share/icons/hicolor/512x512/apps/cosmic-saucer-drift.png"
cp cosmic-saucer-drift.desktop "$HOME/.local/share/applications/"
DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [ -d "$DESK" ]; then
  cp cosmic-saucer-drift.desktop "$DESK/"
  chmod +x "$DESK/cosmic-saucer-drift.desktop"
  gio set "$DESK/cosmic-saucer-drift.desktop" metadata::trusted true 2>/dev/null || true
fi
echo "Done: Cosmic Saucer Drift is in your app menu and on your desktop."
