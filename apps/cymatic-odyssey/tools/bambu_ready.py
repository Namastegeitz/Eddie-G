#!/usr/bin/env python3
"""Make every part Bambu Studio-ready and prove it with the official 3MF library.

    python3 tools/bambu_ready.py

1. Checks/repairs every STL: one watertight, consistently-wound shell set, positive volume,
   resting on z = 0, mm units, binary STL; reports which Bambu beds each part fits.
2. Writes plate-ready 3MF projects with lib3mf (3MF Consortium reference library):
     bambu/styles/S##_name.3mf           gobo + insert + foot arranged on a 256 mm plate
     bambu/styles/S##_name_gobo_2color.3mf  gobo as two parts (base + lines) for AMS colours
     bambu/hardware/plate_##.3mf          hardware packed onto 250 mm plates
     bambu/hardware/a1mini_platform.3mf   4 quarters + 4 splice plates for the A1 mini
3. Re-reads every 3MF with lib3mf, checks each mesh is manifold and oriented, and
   writes bambu/REPORT.json + downloads/CYMATIC_ODYSSEY_Bambu_Studio.zip.
"""
from __future__ import annotations

import json
import sys
import zipfile
from pathlib import Path

import numpy as np
import trimesh
import lib3mf

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
from odyssey import build, catalog  # noqa: E402

BEDS = {"A1 mini": (180, 180, 180), "A1": (256, 256, 256), "P1S / X1C": (256, 256, 256), "H2D": (325, 320, 325)}
W = lib3mf.get_wrapper()


# ---------------------------------------------------------------- STL check / repair
def check_fix(path: Path):
    m = trimesh.load(path, force="mesh", process=True)
    issues = []
    if not m.is_winding_consistent:
        trimesh.repair.fix_winding(m); issues.append("fixed winding")
    if m.volume < 0:
        m.invert(); issues.append("inverted normals")
    # note: sliver (near-zero-area) triangles are kept - removing them would open holes;
    # slicers handle slivers fine
    zmin = m.bounds[0][2]
    if abs(zmin) > 1e-6:
        m.apply_translation((0, 0, -zmin)); issues.append(f"moved to bed (z {zmin:+.3f})")
    ok = bool(m.is_watertight and m.is_winding_consistent and m.volume > 0)
    if issues:
        # rewrite as binary STL with a header that doesn't start with 'solid'
        data = m.export(file_type="stl")
        path.write_bytes(b"CYMATIC ODYSSEY (bambu-ready)".ljust(80, b" ") + data[80:])
    ext = m.extents
    fits = [b for b, (x, y, z) in BEDS.items() if (ext[0] <= x - 4 and ext[1] <= y - 4 or ext[1] <= x - 4 and ext[0] <= y - 4) and ext[2] <= z]
    return m, dict(file=str(path.relative_to(ROOT)), watertight=bool(m.is_watertight), oriented=bool(m.is_winding_consistent),
                   volume_cm3=round(float(m.volume) / 1000, 2), size_mm=[round(float(v), 1) for v in ext],
                   triangles=int(len(m.faces)), fixed=issues, fits=fits, ok=ok)


# ---------------------------------------------------------------- 3MF writing with lib3mf
def _mesh_object(model, mesh: trimesh.Trimesh, name):
    obj = model.AddMeshObject()
    obj.SetName(name)
    V = np.asarray(mesh.vertices, dtype=float)
    F = np.asarray(mesh.faces, dtype=int)
    verts = []
    for x, y, z in V:
        p = lib3mf.Position(); p.Coordinates[0] = x; p.Coordinates[1] = y; p.Coordinates[2] = z
        verts.append(p)
    tris = []
    for a, b, c in F:
        t = lib3mf.Triangle(); t.Indices[0] = int(a); t.Indices[1] = int(b); t.Indices[2] = int(c)
        tris.append(t)
    obj.SetGeometry(verts, tris)
    return obj


def _centered(mesh):
    m = mesh.copy()
    b = m.bounds
    m.apply_translation((-(b[0][0] + b[1][0]) / 2, -(b[0][1] + b[1][1]) / 2, -b[0][2]))
    return m


def write_3mf(path: Path, items, title, description, components=None):
    """items: list of (name, trimesh, (x, y)) placed on the plate (plate origin bottom-left).
    components: optional list of (object_name, [(part_name, trimesh), ...], (x, y)) -> one
    object made of several parts (Bambu assigns a filament per part)."""
    model = W.CreateModel()
    model.SetUnit(lib3mf.ModelUnit.MilliMeter)
    md = model.GetMetaDataGroup()
    for k, v in (("Title", title), ("Designer", "CYMATIC ODYSSEY"), ("Description", description),
                 ("Application", "CYMATIC ODYSSEY generator (lib3mf)")):
        md.AddMetaData("", k, v, "string", False)
    for name, mesh, (x, y) in items:
        obj = _mesh_object(model, _centered(mesh), name)
        model.AddBuildItem(obj, W.GetTranslationTransform(float(x), float(y), 0.0))
    for oname, parts, (x, y) in components or []:
        comp = model.AddComponentsObject()
        comp.SetName(oname)
        # keep parts' relative placement: centre on the first part's footprint
        b = parts[0][1].bounds
        off = (-(b[0][0] + b[1][0]) / 2, -(b[0][1] + b[1][1]) / 2, 0)
        for pname, mesh in parts:
            pm = mesh.copy(); pm.apply_translation(off)
            mo = _mesh_object(model, pm, pname)
            comp.AddComponent(mo, W.GetIdentityTransform())
        model.AddBuildItem(comp, W.GetTranslationTransform(float(x), float(y), 0.0))
    path.parent.mkdir(parents=True, exist_ok=True)
    model.QueryWriter("3mf").WriteToFile(str(path))


def verify_3mf(path: Path):
    model = W.CreateModel()
    r = model.QueryReader("3mf")
    r.SetStrictModeActive(True)
    r.ReadFromFile(str(path))
    warnings = [r.GetWarning(i)[1] for i in range(r.GetWarningCount())]
    meshes = model.GetMeshObjects()
    n, bad, tris = 0, [], 0
    while meshes.MoveNext():
        mo = meshes.GetCurrentMeshObject()
        n += 1
        tris += mo.GetTriangleCount()
        if not mo.IsManifoldAndOriented():
            bad.append(mo.GetName())
    items = model.GetBuildItems()
    nb = 0
    while items.MoveNext():
        nb += 1
    return dict(file=str(path.relative_to(ROOT)), meshes=n, build_items=nb, triangles=tris,
                not_manifold=bad, warnings=warnings, ok=not bad and not warnings)


def shelf_pack(parts, W_=250.0, gap=6.0):
    """parts: list of (name, mesh). Returns plates: list of [(name, mesh, (x, y))]."""
    plates, cur, x, y, row_h = [], [], gap, gap, 0.0
    for name, mesh in sorted(parts, key=lambda p: -p[1].extents[1]):
        w, h = mesh.extents[0], mesh.extents[1]
        if x + w > W_:
            x, y, row_h = gap, y + row_h + gap, 0.0
        if y + h > W_:
            plates.append(cur); cur, x, y, row_h = [], gap, gap, 0.0
        cur.append((name, mesh, (x + w / 2, y + h / 2)))
        x += w + gap; row_h = max(row_h, h)
    if cur:
        plates.append(cur)
    return plates


def main():
    report = {"stl": [], "3mf": []}
    # 1. every STL
    files = sorted(set((ROOT / "stl").rglob("*.stl")) | set((ROOT / "styles").rglob("*.stl")))
    meshes = {}
    for f in files:
        m, r = check_fix(f)
        meshes[f] = m
        report["stl"].append(r)
    bad = [r for r in report["stl"] if not r["ok"]]
    print(f"STL checked: {len(files)}, problems: {len(bad)}, repaired: {sum(1 for r in report['stl'] if r['fixed'])}")
    # 2. style plates
    styles = json.loads((ROOT / "catalog/styles.json").read_text())
    ents = {e["name"]: e for e in catalog.entries()}
    spec = build.Spec()
    out = ROOT / "bambu"
    for s in styles:
        folder = ROOT / s["folder"]
        stl = {p.name.split("_")[0]: p for p in folder.glob("*.stl")}
        items = []
        slots = {"insert": (77, 77), "gobo": (194, 194), "dipper": (226, 30)}
        for role in ("insert", "gobo", "dipper"):
            if role in stl:
                label = {"gobo": s["gobo"], "insert": s["insert"], "dipper": s["dipper"]}[role]
                items.append((f"{s['id']} {role} - {label}", meshes[stl[role]], slots[role]))
        slug = Path(s["folder"]).name
        p = out / "styles" / f"{slug}.3mf"
        write_3mf(p, items, f"{s['id']} {s['name']}", f"CYMATIC ODYSSEY style {s['id']} {s['name']}: gobo in white PLA/PETG, insert and foot in PETG.")
        report["3mf"].append(verify_3mf(p))
        base, top = build.gobo_parts(ents[s["gobo"]]["fn"](), spec)
        tm = lambda man: trimesh.Trimesh(np.asarray(man.to_mesh().vert_properties)[:, :3], np.asarray(man.to_mesh().tri_verts), process=True)
        p2 = out / "styles" / f"{slug}_gobo_2color.3mf"
        write_3mf(p2, [], f"{s['id']} gobo two-colour", "Assign white/translucent filament to 'base' and black to 'lines' (AMS).",
                  components=[(f"{s['id']} gobo - {s['gobo']}", [("base (white or translucent)", tm(base)), ("lines (black)", tm(top))], (128, 128))])
        report["3mf"].append(verify_3mf(p2))
        print("style", s["id"], "ok")
    # 3. hardware plates
    hw = {f.stem: meshes[f] for f in files if f.parent.name == "hardware"}
    full = [(k, m) for k, m in hw.items() if k not in ("platform_quarter_a1mini", "platform_splice_plate", "platform_4x_exciter")]
    extra = [("platform_foot_cup", hw["platform_foot_cup"])] * 3 + [("panel_corner", hw["panel_corner"])] * 7
    plates = shelf_pack(full + extra)
    write_3mf(out / "hardware" / "plate_00_platform.3mf", [("platform_4x_exciter", hw["platform_4x_exciter"], (128, 128))],
              "Platform (256 mm beds)", "Vibration platform, PETG, 4 walls, 40% gyroid.")
    report["3mf"].append(verify_3mf(out / "hardware" / "plate_00_platform.3mf"))
    for i, pl in enumerate(plates, 1):
        p = out / "hardware" / f"plate_{i:02d}.3mf"
        write_3mf(p, pl, f"Hardware plate {i}", "CYMATIC ODYSSEY hardware, PETG.")
        report["3mf"].append(verify_3mf(p))
    q, sp = hw["platform_quarter_a1mini"], hw["platform_splice_plate"]
    a1 = [("platform quarter 1", q, (55, 55)), ("platform quarter 2", q, (125, 125))]
    write_3mf(out / "hardware" / "a1mini_platform_x2.3mf", a1 + [("splice plate", sp, (140, 30)), ("splice plate", sp, (30, 140))],
              "A1 mini platform (print twice)", "Two quarters + two splice plates per plate; print this plate twice.")
    report["3mf"].append(verify_3mf(out / "hardware" / "a1mini_platform_x2.3mf"))
    bad3 = [r for r in report["3mf"] if not r["ok"]]
    print(f"3MF written and re-read: {len(report['3mf'])}, problems: {len(bad3)}")
    (out / "REPORT.json").write_text(json.dumps(report, indent=1))
    z = ROOT / "downloads/CYMATIC_ODYSSEY_Bambu_Studio.zip"
    with zipfile.ZipFile(z, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for f in sorted(out.rglob("*")):
            if f.is_file():
                zf.write(f, f"bambu/{f.relative_to(out)}")
        zf.write(ROOT / "docs/BAMBU_STUDIO.md", "bambu/README_BAMBU_STUDIO.md") if (ROOT / "docs/BAMBU_STUDIO.md").exists() else None
    print("zip", z.stat().st_size // 1024, "KB")
    return 1 if bad or bad3 else 0


if __name__ == "__main__":
    sys.exit(main())
