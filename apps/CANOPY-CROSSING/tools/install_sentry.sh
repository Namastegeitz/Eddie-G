#!/usr/bin/env bash
# Installs the official Sentry SDK for Godot (getsentry/sentry-godot, MIT) into
# addons/sentry and sets it up for Canopy Crossing. The release workflow runs
# this when the SENTRY_DSN secret is set; nothing here is committed.
#   SENTRY_DSN=https://<key>@o<org>.ingest.sentry.io/<project> tools/install_sentry.sh [sentry-godot-X.Y.Z.zip]
# Settings written into project.godot (in the build machine's copy only):
#   sentry/options/dsn                 the project's DSN (from SENTRY_DSN)
#   sentry/options/auto_init=false     autoload/crash_report.gd starts Sentry itself,
#                                      and only when Settings > Send crash reports is on
#   sentry/options/send_default_pii=false
# The web build and the plain APK are built before this runs: Sentry needs
# Gradle on Android and GDExtension support on the web, which those two don't use.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${SENTRY_GODOT_VERSION:-2.5.1}"
: "${SENTRY_DSN:?set SENTRY_DSN to the DSN of the Sentry project}"
ZIP="${1:-}"
if [ -z "$ZIP" ]; then
  ZIP="$(mktemp -d)/sentry-godot-$VERSION.zip"
  if command -v gh > /dev/null && [ -n "${GH_TOKEN:-}" ]; then
    gh release download "$VERSION" -R getsentry/sentry-godot -p "sentry-godot-$VERSION.zip" -O "$ZIP"
  else
    curl -fsSL -o "$ZIP" "https://github.com/getsentry/sentry-godot/releases/download/$VERSION/sentry-godot-$VERSION.zip"
  fi
fi
echo "sentry-godot $VERSION: $(sha256sum "$ZIP" | cut -d' ' -f1)"
rm -rf addons/sentry
unzip -q -o "$ZIP" 'addons/sentry/*' -d .
test -f addons/sentry/sentry.gdextension || { echo "addons/sentry/sentry.gdextension missing from the zip" >&2; exit 1; }
python3 - "$SENTRY_DSN" <<'PY'
import re, sys
from pathlib import Path
dsn = sys.argv[1].strip()
p = Path("project.godot")
s = p.read_text()
s = re.sub(r"\n\[sentry\]\n(?:[^\[]*\n)*?(?=\n\[|\Z)", "\n", s)
s = s.rstrip("\n") + f'\n\n[sentry]\n\noptions/auto_init=false\noptions/dsn="{dsn}"\noptions/send_default_pii=false\n'
p.write_text(s)
# the iOS privacy manifest declares what Sentry sends: crash data and other
# diagnostics, not linked to the player, not used for tracking, for App
# Functionality (Godot's purpose flag 2)
p = Path("export_presets.cfg")
s = p.read_text()
ios = s.index('platform="iOS"')
opts = s.index("options]", ios) + len("options]")
end = s.find("\n[preset.", opts)
end = len(s) if end < 0 else end
section = s[opts:end]
lines = []
for kind in ["crash_data", "other_diagnostic_data"]:
    for key, val in [("collected", "true"), ("linked_to_user", "false"), ("used_for_tracking", "false"), ("collection_purposes", "2")]:
        name = f"privacy/collected_data/{kind}/{key}"
        section = re.sub(r"\n" + re.escape(name) + r"=[^\n]*", "", section)
        lines.append(f"{name}={val}")
section = "\n" + "\n".join(lines) + section
p.write_text(s[:opts] + section + s[end:])
PY
echo "SENTRY OK: addons/sentry installed, auto-start off (the game starts it when reports are allowed)"
