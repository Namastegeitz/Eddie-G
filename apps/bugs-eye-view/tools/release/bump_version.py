#!/usr/bin/env python3
"""Sets the version (semantic, e.g. 1.0.1) and build number everywhere it
lives: project.godot (config/version, config/build_number) and every export
preset (Android version code/name, iOS and macOS version/build, Windows file
and product version). Every store upload needs a higher build number.

  python3 tools/release/bump_version.py 1.0.1          # build number + 1
  python3 tools/release/bump_version.py 1.0.1 57       # exact build number
  python3 tools/release/bump_version.py --show
"""
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJ, PRESETS = ROOT / "project.godot", ROOT / "export_presets.cfg"


def current() -> tuple[str, int]:
    s = PROJ.read_text()
    v = re.search(r'^config/version="([^"]*)"', s, re.M).group(1)
    b = re.search(r'^config/build_number=(\d+)', s, re.M)
    return v, int(b.group(1)) if b else 1


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] == "--show":
        print("%s (build %d)" % current())
        return 0
    version = sys.argv[1]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        sys.exit("version must look like 1.0.1")
    build = int(sys.argv[2]) if len(sys.argv) > 2 else current()[1] + 1
    s = PROJ.read_text()
    s = re.sub(r'^config/version="[^"]*"', f'config/version="{version}"', s, flags=re.M)
    s = re.sub(r'^config/build_number=\d+', f'config/build_number={build}', s, flags=re.M)
    PROJ.write_text(s)
    p = PRESETS.read_text()
    four = version + ".0"
    for pat, val in [
        (r'^version/code=\d+', f'version/code={build}'),
        (r'^version/name="[^"]*"', f'version/name="{version}"'),
        (r'^application/short_version="[^"]*"', f'application/short_version="{version}"'),
        (r'^application/version="[^"]*"', f'application/version="{build}"'),
        (r'^application/file_version="[^"]*"', f'application/file_version="{four}"'),
        (r'^application/product_version="[^"]*"', f'application/product_version="{four}"'),
    ]:
        p = re.sub(pat, val, p, flags=re.M)
    PRESETS.write_text(p)
    print(f"version {version}, build {build}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
