#!/usr/bin/env python3
"""Sets the game's version everywhere it lives, and raises every build number by one.

  python3 tools/bump_version.py 1.0.1            # set version 1.0.1, build numbers +1
  python3 tools/bump_version.py 1.0.1 --dry-run  # show what would change, change nothing
  python3 tools/bump_version.py --show           # print the current values

Changes project.godot (application/config/version) and export_presets.cfg:
Android + Android AAB (version/name, version/code), iOS and macOS
(application/short_version, application/version) and Windows
(file_version, product_version). Google Play and the App Store refuse an
upload whose build number isn't higher than the last one, so every
store upload needs a run of this script (same version, or a new one).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, ".."))
PROJECT = os.path.join(GAME, "project.godot")
PRESETS = os.path.join(GAME, "export_presets.cfg")


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def show():
    s = read(PROJECT)
    print("project.godot  version", re.search(r'^config/version="([^"]*)"', s, re.M).group(1))
    p = read(PRESETS)
    for m in re.finditer(r'^\[preset\.(\d+)\]\n\nname="([^"]+)"', p, re.M):
        head = "[preset.%s.options]\n" % m.group(1)
        i = p.index(head)
        j = p.find("\n[preset.", i + 1)
        block = p[i:j if j > 0 else len(p)]
        vals = re.findall(r'^(version/(?:name|code)|application/(?:short_version|version|file_version|product_version))=(.*)$', block, re.M)
        if vals:
            print("%-16s %s" % (m.group(2), "  ".join("%s=%s" % v for v in vals)))


def bump(version, dry):
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        sys.exit("version must look like 1.2.3")
    changes = []
    s = read(PROJECT)
    s2 = re.sub(r'^config/version="[^"]*"', 'config/version="%s"' % version, s, flags=re.M)
    changes.append(("project.godot", "config/version", version))
    p = read(PRESETS)

    def code(m):
        n = int(m.group(2)) + 1
        changes.append(("export_presets.cfg", m.group(1), str(n)))
        return "%s=%d" % (m.group(1), n)

    def quoted_code(m):
        n = int(m.group(2)) + 1
        changes.append(("export_presets.cfg", m.group(1), str(n)))
        return '%s="%d"' % (m.group(1), n)

    p2 = re.sub(r'^(version/code)=(\d+)$', code, p, flags=re.M)
    p2 = re.sub(r'^(application/version)="(\d+)"$', quoted_code, p2, flags=re.M)
    p2 = re.sub(r'^version/name="[^"]*"$', 'version/name="%s"' % version, p2, flags=re.M)
    p2 = re.sub(r'^application/short_version="[^"]*"$', 'application/short_version="%s"' % version, p2, flags=re.M)
    p2 = re.sub(r'^application/(file_version|product_version)="[^"]*"$',
                lambda m: 'application/%s="%s.0"' % (m.group(1), version), p2, flags=re.M)
    changes.append(("export_presets.cfg", "version names", version))
    for c in changes:
        print("%-20s %-24s -> %s" % c)
    if dry:
        print("(dry run: nothing written)")
        return
    with open(PROJECT, "w", encoding="utf-8") as f:
        f.write(s2)
    with open(PRESETS, "w", encoding="utf-8") as f:
        f.write(p2)
    print("written. Add a CHANGELOG.md entry and commit.")


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        sys.exit(__doc__)
    if args[0] == "--show":
        show()
    else:
        bump(args[0], "--dry-run" in args)
