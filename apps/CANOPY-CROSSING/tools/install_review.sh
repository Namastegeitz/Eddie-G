#!/usr/bin/env bash
# Installs the In-app Review plugin (godot-mobile-plugins/godot-inapp-review,
# MIT, by Cengiz) for the store builds: Google Play's and Apple's own rating
# card (scripts/platform/review_prompt.gd decides when). Run by the release
# workflow after the web build and the plain APK (the plugin needs Gradle on
# Android). Nothing here is committed.
#   tools/install_review.sh [InappReviewPlugin-Multi-vX.Y.zip]
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${INAPP_REVIEW_VERSION:-5.3}"
ZIP="${1:-}"
if [ -z "$ZIP" ]; then
  dir="$(mktemp -d)"
  gh release download "v$VERSION" -R godot-mobile-plugins/godot-inapp-review -p "*-Multi-v$VERSION.zip" -D "$dir"
  ZIP="$(ls "$dir"/*.zip | head -1)"
fi
echo "inapp-review $VERSION: $(basename "$ZIP") $(sha256sum "$ZIP" | cut -d' ' -f1)"
unzip -q -o "$ZIP" -d .
cfg="$(grep -l 'InappReview' addons/*/plugin.cfg | head -1)"
test -n "$cfg" || { echo "In-app Review plugin.cfg not found after unzip" >&2; exit 1; }
python3 - "res://$cfg" <<'PY'
import re, sys
from pathlib import Path
cfg = sys.argv[1]
p = Path("project.godot")
s = p.read_text()
m = re.search(r'^enabled=PackedStringArray\((.*)\)$', s, re.M)
if m:
    items = [x.strip() for x in m.group(1).split(",") if x.strip()]
    if f'"{cfg}"' not in items:
        items.append(f'"{cfg}"')
    s = s[:m.start()] + "enabled=PackedStringArray(" + ", ".join(items) + ")" + s[m.end():]
else:
    s = s.rstrip("\n") + f'\n\n[editor_plugins]\n\nenabled=PackedStringArray("{cfg}")\n'
p.write_text(s)
# the iOS plugin is switched on in the iOS export preset
gdips = sorted(Path("ios/plugins").glob("**/*.gdip")) if Path("ios/plugins").exists() else []
if gdips:
    e = Path("export_presets.cfg")
    t = e.read_text()
    ios = t.index('platform="iOS"')
    opts = t.index("options]", ios) + len("options]")
    for g in gdips:
        key = f"plugins/{g.stem}=true"
        if key not in t:
            t = t[:opts] + "\n" + key + t[opts:]
    e.write_text(t)
print("enabled", cfg, "and", len(gdips), "iOS plugin(s)")
PY
echo "REVIEW PLUGIN OK"
