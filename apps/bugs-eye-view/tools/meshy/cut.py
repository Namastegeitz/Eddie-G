#!/usr/bin/env python3
"""Cut parts out of a generated model: drops every triangle whose centre is
inside one of the given boxes (in the model's own coordinates), e.g. the
door Meshy left hanging open on the fridge. Standard library + numpy.

    python3 tools/meshy/cut.py raw/kitchen_fridge.glb out.glb \\
        --box=0.3,9,-9,9,0.24,9 --box=-9,9,-9,9,0.3,9

Each --box=xmin,xmax,ymin,ymax,zmin,zmax (use the = form: values can be negative). The cut indices are appended
to the binary chunk (run the result through gltf-transform optimize, which
prunes the leftovers; see README.md).
"""
import argparse
import json
import struct

import numpy as np

COMP = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    b = open(path, "rb").read()
    assert b[:4] == b"glTF", "not a GLB file"
    jl = struct.unpack("<I", b[12:16])[0]
    js = json.loads(b[20:20 + jl])
    off = 20 + jl
    bl = struct.unpack("<I", b[off:off + 4])[0]
    return js, bytearray(b[off + 8:off + 8 + bl])


def write_glb(path, js, binb):
    jb = json.dumps(js, separators=(",", ":")).encode()
    jb += b" " * (-len(jb) % 4)
    binb = bytes(binb) + b"\0" * (-len(binb) % 4)
    total = 12 + 8 + len(jb) + 8 + len(binb)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<I4s", len(jb), b"JSON") + jb)
        f.write(struct.pack("<I4s", len(binb), b"BIN\0") + binb)


def accessor(js, binb, i):
    a = js["accessors"][i]
    bv = js["bufferViews"][a["bufferView"]]
    n = WIDTH[a["type"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    arr = np.frombuffer(bytes(binb), dtype=COMP[a["componentType"]], count=a["count"] * n, offset=off)
    return arr.reshape(-1, n) if n > 1 else arr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dest")
    ap.add_argument("--box", action="append", required=True)
    args = ap.parse_args()
    boxes = [np.array([float(v) for v in b.split(",")]).reshape(3, 2) for b in args.box]
    js, binb = read_glb(args.src)
    dropped = kept = 0
    for mesh in js["meshes"]:
        for prim in mesh["primitives"]:
            pos = accessor(js, binb, prim["attributes"]["POSITION"]).astype(np.float64)
            idx = accessor(js, binb, prim["indices"]).reshape(-1, 3)
            cen = pos[idx].mean(axis=1)
            cut = np.zeros(len(idx), dtype=bool)
            for bx in boxes:
                cut |= np.all((cen >= bx[:, 0]) & (cen <= bx[:, 1]), axis=1)
            keep = idx[~cut].astype(np.uint32).ravel()
            dropped += int(cut.sum())
            kept += len(idx) - int(cut.sum())
            binb += b"\0" * (-len(binb) % 4)
            js["bufferViews"].append({"buffer": 0, "byteOffset": len(binb), "byteLength": keep.nbytes,
                                      "target": 34963})
            binb += keep.tobytes()
            a = js["accessors"][prim["indices"]]
            a.update({"bufferView": len(js["bufferViews"]) - 1, "byteOffset": 0, "componentType": 5125,
                      "count": int(keep.size)})
            a.pop("min", None)
            a.pop("max", None)
    js["buffers"][0]["byteLength"] = len(binb) + (-len(binb) % 4)
    write_glb(args.dest, js, binb)
    print(f"cut {dropped} triangles, kept {kept}")


if __name__ == "__main__":
    main()
