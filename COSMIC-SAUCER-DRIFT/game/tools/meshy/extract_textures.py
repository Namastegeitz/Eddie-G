#!/usr/bin/env python3
"""Pull the PBR textures out of a Meshy GLB, shrink them for the game, and
save them next to the slot as JPEGs:
  <slot>_albedo.jpg   base colour
  <slot>_orm.jpg      glTF metallic-roughness (G = roughness, B = metallic)
  <slot>_normal.jpg   tangent-space normal map
Godot imports them as lossy WebP with mipmaps (see fix_imports() below), so a
whole craft costs well under a megabyte on disk.

  python3 -I tools/meshy/extract_textures.py [--craft-file content/craft_hd.json] [--only id,...]
Sizes: exterior 1024 px (normal 1024, ORM 512); cockpit 2048 (normal 1024,
ORM 512), since you see the cockpit up close. Needs Pillow.
"""
import argparse
import glob
import io
import json
import os
import re
import struct
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.abspath(os.path.join(HERE, "..", ".."))
SIZES = {"model": {"albedo": 1024, "normal": 1024, "orm": 512},
         "cockpit": {"albedo": 2048, "normal": 1024, "orm": 512}}


def read_glb(path):
    b = open(path, "rb").read()
    magic, _ver, _len = struct.unpack("<4sII", b[:12])
    if magic != b"glTF":
        raise ValueError("not a GLB: " + path)
    clen, _ctype = struct.unpack("<II", b[12:20])
    gltf = json.loads(b[20:20 + clen])
    off = 20 + clen
    blen, _btype = struct.unpack("<II", b[off:off + 8])
    return gltf, b[off + 8:off + 8 + blen]


def image_bytes(gltf, binary, tex_index):
    img = gltf["images"][gltf["textures"][tex_index]["source"]]
    bv = gltf["bufferViews"][img["bufferView"]]
    start = bv.get("byteOffset", 0)
    return binary[start:start + bv["byteLength"]]


def extract(slot_path, part, quiet=False):
    gltf, binary = read_glb(slot_path)
    mat = gltf["materials"][0]
    pbr = mat.get("pbrMetallicRoughness", {})
    maps = {"albedo": pbr.get("baseColorTexture"), "orm": pbr.get("metallicRoughnessTexture"),
            "normal": mat.get("normalTexture")}
    base = os.path.splitext(slot_path)[0]
    out = {}
    for kind, ref in maps.items():
        if not ref:
            continue
        im = Image.open(io.BytesIO(image_bytes(gltf, binary, ref["index"])))
        im = im.convert("RGB")
        size = SIZES[part][kind]
        if max(im.size) > size:
            im = im.resize((size, size) if im.size[0] == im.size[1] else
                           (size, int(im.size[1] * size / im.size[0])), Image.LANCZOS)
        dst = "%s_%s.jpg" % (base, kind)
        im.save(dst, "JPEG", quality=92, optimize=True)
        out[kind] = dst
        if not quiet:
            print("  %s %s %dx%d %d KB" % (os.path.basename(dst), kind, im.size[0], im.size[1], os.path.getsize(dst) // 1024))
    return out


def glb_skip_images(glb):
    """The game never uses the GLB's own images (it uses the downsized maps
    above), so tell Godot's importer to discard them instead of extracting
    multi-megabyte copies next to the GLB, and remove any it already made."""
    imp = glb + ".import"
    if os.path.exists(imp):
        txt = open(imp).read()
        if "gltf/embedded_image_handling=" in txt:
            txt = re.sub(r"gltf/embedded_image_handling=\d", "gltf/embedded_image_handling=0", txt)
        else:
            txt = txt.replace("[params]\n", "[params]\n\ngltf/embedded_image_handling=0\n", 1)
    else:
        txt = '[remap]\n\nimporter="scene"\n\n[params]\n\ngltf/embedded_image_handling=0\n'
    open(imp, "w").write(txt)
    base = os.path.splitext(glb)[0]
    gone = 0
    for f in glob.glob(base + "_[0-9]*.*"):
        if re.search(r"_\d+\.(jpg|png|jpeg|webp)(\.import)?$", f):
            os.remove(f)
            gone += 1
    return gone


def fix_imports(paths):
    """After Godot has imported the JPEGs once: switch them to lossy WebP
    with mipmaps (and mark normal maps), so a reimport makes small files."""
    changed = 0
    for p in paths:
        imp = p + ".import"
        if not os.path.exists(imp):
            continue
        txt = open(imp).read()
        new = txt
        def setp(t, key, val):
            lines = t.split("\n")
            for i, l in enumerate(lines):
                if l.startswith(key + "="):
                    lines[i] = "%s=%s" % (key, val)
                    return "\n".join(lines)
            return t.replace("[params]\n", "[params]\n\n%s=%s\n" % (key, val), 1)
        new = setp(new, "compress/mode", "1")
        new = setp(new, "compress/lossy_quality", "0.82")
        new = setp(new, "mipmaps/generate", "true")
        new = setp(new, "compress/normal_map", "1" if p.endswith("_normal.jpg") else "2")
        if new != txt:
            open(imp, "w").write(new)
            changed += 1
    return changed


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--craft-file", default=os.path.join(PROJECT, "content", "craft_hd.json"))
    ap.add_argument("--only", default="")
    ap.add_argument("--fix-imports", action="store_true", help="switch already-imported textures to lossy WebP")
    ap.add_argument("--slot", default="", help="one GLB (exterior sizes), e.g. for a side-by-side test")
    a = ap.parse_args(argv)
    if a.slot:
        out = extract(a.slot, "model")
        glb_skip_images(a.slot)
        if a.fix_imports:
            print("import settings updated: %d" % fix_imports(list(out.values())))
        return 0
    only = set(x for x in a.only.split(",") if x)
    craft = json.load(open(a.craft_file))["saucers"]
    done = []
    for c in craft:
        if only and c["id"] not in only:
            continue
        for part in ("model", "cockpit"):
            res = c.get(part, {}).get("mesh", "")
            path = os.path.join(PROJECT, res[len("res://"):]) if res.startswith("res://") else ""
            if not path or not os.path.exists(path):
                continue
            if a.fix_imports:
                base = os.path.splitext(path)[0]
                done += [base + "_%s.jpg" % k for k in ("albedo", "orm", "normal")]
                continue
            print("%s/%s" % (c["id"], part))
            done += list(extract(path, part).values())
            glb_skip_images(path)
    if a.fix_imports:
        print("import settings updated: %d" % fix_imports(done))
    return 0


if __name__ == "__main__":
    sys.exit(main())
