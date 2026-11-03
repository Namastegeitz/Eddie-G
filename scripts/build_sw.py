#!/usr/bin/env python3
"""Regenerate the service worker's PRECACHE list and VERSION.

Run from anywhere:  python3 scripts/build_sw.py
Every app file (html, css, js, images, pdf, manifest) under the app folder is
listed, except development-only files (scripts/, tests/, README, licences of
build tools). VERSION is a hash of all file contents, so any change produces a
new cache and installed apps update on next launch.
"""
import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDE_EXT = {'.html', '.css', '.js', '.png', '.svg', '.webmanifest', '.pdf', '.json', '.txt', '.ico', '.webp', '.jpg'}
EXCLUDE_DIRS = {'scripts', 'tests', 'dist', 'node_modules', '.git', '__pycache__'}
EXCLUDE_FILES = {'sw.js'}


def collect():
    files = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        rel_dir = os.path.relpath(dirpath, ROOT)
        dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDE_DIRS and not d.startswith('.'))
        for fn in sorted(filenames):
            if fn in EXCLUDE_FILES or fn.startswith('.'):
                continue
            if os.path.splitext(fn)[1].lower() not in INCLUDE_EXT:
                continue
            rel = os.path.normpath(os.path.join(rel_dir, fn)).replace(os.sep, '/')
            files.append(rel)
    return sorted(files)


def main():
    files = collect()
    h = hashlib.sha256()
    for f in files:
        h.update(f.encode())
        with open(os.path.join(ROOT, f), 'rb') as fh:
            h.update(fh.read())
    version = h.hexdigest()[:12]
    precache = ['./'] + files
    block = ('// PRECACHE-START (generated — do not edit by hand)\n'
             'const VERSION = ' + json.dumps(version) + ';\n'
             'const PRECACHE = ' + json.dumps(precache, indent=2) + ';\n'
             '// PRECACHE-END')
    sw_path = os.path.join(ROOT, 'sw.js')
    with open(sw_path, encoding='utf-8') as fh:
        sw = fh.read()
    new = re.sub(r'// PRECACHE-START.*?// PRECACHE-END', lambda m: block, sw, flags=re.S)
    if new == sw and version not in sw:
        sys.exit('PRECACHE markers not found in sw.js')
    with open(sw_path, 'w', encoding='utf-8') as fh:
        fh.write(new)
    total = sum(os.path.getsize(os.path.join(ROOT, f)) for f in files)
    print('sw.js: %d files precached (%.1f KB), version %s' % (len(files), total / 1024, version))


if __name__ == '__main__':
    main()
