#!/usr/bin/env python3
"""Sets the game's version in every place the stores read it, so they never
disagree: project.godot, and the Android, iOS, Windows and macOS export
presets.

    python3 tools/set_version.py 1.0.0 1      # version name, build number
    python3 tools/set_version.py              # show what's set now

The build number must go up with every upload to Google Play or App Store
Connect (Play: versionCode; Apple: CFBundleVersion)."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def show() -> None:
    proj = (ROOT / "project.godot").read_text()
    pre = (ROOT / "export_presets.cfg").read_text()
    print("project:", re.search(r'config/version="([^"]*)"', proj).group(1))
    for key in ["version/name", "version/code", "application/short_version", "application/version",
                "application/file_version", "application/product_version"]:
        vals = sorted(set(re.findall(r'^' + re.escape(key) + r'="?([^"\n]*)"?$', pre, re.M)))
        print(f"{key}: {', '.join(vals)}")


def main() -> None:
    if len(sys.argv) < 3:
        show()
        return
    name, build = sys.argv[1], int(sys.argv[2])
    if not re.fullmatch(r"\d+\.\d+\.\d+", name):
        sys.exit("version must look like 1.2.3")
    win = name + ".0"
    p = ROOT / "project.godot"
    p.write_text(re.sub(r'config/version="[^"]*"', f'config/version="{name}"', p.read_text()))
    p = ROOT / "export_presets.cfg"
    s = p.read_text()
    s = re.sub(r'^version/name="[^"]*"', f'version/name="{name}"', s, flags=re.M)
    s = re.sub(r'^version/code=\d+', f'version/code={build}', s, flags=re.M)
    s = re.sub(r'^application/short_version="[^"]*"', f'application/short_version="{name}"', s, flags=re.M)
    s = re.sub(r'^application/version="[^"]*"', f'application/version="{build}"', s, flags=re.M)
    s = re.sub(r'^application/file_version="[^"]*"', f'application/file_version="{win}"', s, flags=re.M)
    s = re.sub(r'^application/product_version="[^"]*"', f'application/product_version="{win}"', s, flags=re.M)
    p.write_text(s)
    show()


if __name__ == "__main__":
    main()
