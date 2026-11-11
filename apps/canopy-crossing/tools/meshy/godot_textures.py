#!/usr/bin/env python3
"""After Godot first imports the models, switch their extracted textures
(assets/models/*.webp) to Basis Universal: small in the download and kept
GPU-compressed on the phone (lossless or uncompressed textures would make
the web build huge and use a lot of memory). Then re-import:

    godot --headless --path . --import
    python3 tools/meshy/godot_textures.py
    godot --headless --path . --import
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
    # the colour map keeps its detail; the roughness and normal maps (_1, _2
    # in Meshy's order) and all scenery textures are fine at 512 px
    small = not imp.name.split(".")[0].endswith("_0") or imp.name.startswith("scene_")
    new = setting(new, "process/size_limit", "512" if small else "0")
    if new != text:
        imp.write_text(new)
        changed += 1
print(f"{changed} model texture(s) set to Basis Universal")
sys.exit(0)
