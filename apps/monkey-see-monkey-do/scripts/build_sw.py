#!/usr/bin/env python3
"""Regenerates the precache list + version in sw.js from the files in the app.
   python3 scripts/build_sw.py
"""
import hashlib, json, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {'tests', 'scripts', 'docs', 'dist', 'node_modules', '.git'}
SKIP_FILES = {'sw.js', 'README.md', 'RUN.md'}
EXTS = {'.html', '.css', '.js', '.svg', '.png', '.woff2', '.webmanifest', '.txt'}

files = []
for d, dirs, names in os.walk(ROOT):
    dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
    for n in sorted(names):
        if n in SKIP_FILES or os.path.splitext(n)[1] not in EXTS:
            continue
        rel = os.path.relpath(os.path.join(d, n), ROOT).replace(os.sep, '/')
        files.append(rel)

h = hashlib.sha256()
for f in files:
    h.update(f.encode())
    with open(os.path.join(ROOT, f), 'rb') as fh:
        h.update(fh.read())
version = h.hexdigest()[:12]
precache = ['./'] + [f for f in files if f != 'index.html'] + ['index.html']

sw_path = os.path.join(ROOT, 'sw.js')
sw = open(sw_path).read()
block = '// PRECACHE-START (generated, do not edit by hand)\nconst VERSION = %s;\nconst PRECACHE = %s;\n// PRECACHE-END' % (
    json.dumps(version), json.dumps(precache, indent=2))
sw = re.sub(r'// PRECACHE-START.*?// PRECACHE-END', block, sw, flags=re.S)
open(sw_path, 'w').write(sw)
print('sw.js: %d files, version %s' % (len(precache), version))
