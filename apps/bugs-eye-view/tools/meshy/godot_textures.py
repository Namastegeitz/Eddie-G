#!/usr/bin/env python3
"""After Godot first imports the models, switch the textures it extracted
from them (assets/models/*.webp) to Basis Universal: small in the download
and kept GPU-compressed on a phone (lossless textures would make the web
build much bigger and use a lot of memory). Every map is capped at 512 px:
plenty on a phone, and the web build's game data has to stay under the
20 MiB a published file can be (a 1024 px colour map is ~540 KB, 512 px
~135 KB). Then re-import:

    godot --headless --path . --import
    python3 tools/meshy/godot_textures.py
    godot --headless --path . --import

The models themselves are made phone-sized first (see README.md: textures
resized to WebP with gltf-transform; the full downloads stay in raw/).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent


def setting(text: str, key: str, value: str) -> str:
    if re.search(rf"^{re.escape(key)}=", text, flags=re.M):
        return re.sub(rf"^{re.escape(key)}=.*$", f"{key}={value}", text, flags=re.M)
    return text.replace("[params]\n", f"[params]\n\n{key}={value}\n", 1)


changed = 0
for imp in sorted((ROOT / "assets" / "models").glob("*.webp.import")):
    text = imp.read_text()
    new = setting(text, "compress/mode", "4")                 # Basis Universal
    new = setting(new, "compress/rdo_quality_loss", "2.0")    # much smaller, barely visible
    new = setting(new, "process/size_limit", "512")
    if new != text:
        imp.write_text(new)
        changed += 1
print(f"{changed} model texture(s) set to Basis Universal")
sys.exit(0)
