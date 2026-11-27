#!/usr/bin/env python3
"""Generate every CYMATIC ODYSSEY part.

    python3 tools/generate.py                 # everything (STL + SVG + previews + catalog)
    python3 tools/generate.py --preview-only  # just the line previews and catalog
    python3 tools/generate.py --family fractals --jobs 4
    python3 tools/generate.py --dish-id 142   # re-fit the boundary inserts to your dish

Outputs (relative to apps/cymatic-odyssey/):
    stl/gobos/<family>/G###_name.stl     light stencils (lithophane-style, white PLA/PETG)
    svg/gobos/<family>/G###_name.svg     same artwork for transparency film / laser cutting
    stl/inserts/B###_name.stl            boundary inserts for the glass dish
    stl/dippers/D###_name.stl            dipper feet (wave sources)
    stl/hardware/*.stl                   platform, arm, LED cradle, mirror holder, ...
    catalog/geometry_catalog.json|csv    the full log
    docs/GEOMETRY_CATALOG.md             human-readable log with previews
    previews/<family>.png                contact sheets
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import time
import traceback
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))

from odyssey import catalog, build  # noqa: E402


def slug(s):
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")[:60]


def thumb(design, path, part):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.collections import LineCollection
    d = design.normalised(1.0)
    fig = plt.figure(figsize=(2, 2), dpi=110)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_facecolor("#05060d"); fig.patch.set_facecolor("#05060d")
    if part in ("insert", "dipper") and d.region is not None:
        from shapely.geometry import Point
        geoms = getattr(d.region, "geoms", [d.region])
        if part == "insert":
            ax.add_patch(plt.Circle((0, 0), 1.25, color="#2a2f45"))
        for g in geoms:
            ax.fill(*g.exterior.xy, color="#7fd4ff")
            for h in g.interiors:
                ax.fill(*h.xy, color="#2a2f45")
        lim = 1.3
    else:
        segs = [ln for ln in d.lines if len(ln) > 1]
        lw = 0.6 * design.weight
        ax.add_collection(LineCollection(segs, colors="#ffe9b0", linewidths=lw))
        for f in d.fills:
            for g in getattr(f, "geoms", [f]):
                ax.fill(*g.exterior.xy, color="#ffe9b0")
                for h in g.interiors:
                    ax.fill(*h.xy, color="#05060d")
        lim = 1.05
    ax.set_xlim(-lim, lim); ax.set_ylim(-lim, lim); ax.set_aspect("equal"); ax.axis("off")
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, facecolor=fig.get_facecolor())
    plt.close(fig)


def job(args):
    e, opts = args
    t0 = time.time()
    spec = build.Spec(dish_id=opts["dish_id"])
    res = {"id": e["id"], "ok": True}
    try:
        design = e["fn"]()
        name = f"{e['id']}_{slug(e['name'])}"
        if e["part"] == "gobo":
            rel_stl = Path("stl/gobos") / e["family"] / f"{name}.stl"
            rel_svg = Path("svg/gobos") / e["family"] / f"{name}.svg"
        elif e["part"] == "insert":
            rel_stl = Path("stl/inserts") / f"{name}.stl"; rel_svg = None
        else:
            rel_stl = Path("stl/dippers") / f"{name}.stl"; rel_svg = None
        rel_png = Path("previews/items") / f"{name}.png"
        thumb(design, ROOT / rel_png, e["part"])
        res["preview"] = str(rel_png)
        if not opts["preview_only"]:
            if e["part"] == "gobo":
                man, rings = build.gobo(design, spec)
                build.svg_from_rings(rings, ROOT / rel_svg, spec.gobo_d)
                res["svg"] = str(rel_svg)
            elif e["part"] == "insert":
                man, _ = build.insert(design, spec)
            else:
                man, _ = build.dipper(design, spec)
            res["triangles"] = build.save_stl(man, ROOT / rel_stl)
            res["stl"] = str(rel_stl)
            res["volume_cm3"] = round(man.volume() / 1000, 2)
            bb = man.bounding_box()
            res["size_mm"] = [round(bb[3] - bb[0], 1), round(bb[4] - bb[1], 1), round(bb[5] - bb[2], 1)]
    except Exception as ex:  # keep going, report at the end
        res["ok"] = False
        res["error"] = f"{type(ex).__name__}: {ex}"
        res["trace"] = traceback.format_exc()
    res["seconds"] = round(time.time() - t0, 2)
    return res


def contact_sheets(results, entries):
    from PIL import Image, ImageDraw
    by = {}
    for e in entries:
        r = results.get(e["id"])
        if r and r.get("ok"):
            by.setdefault(e["family"], []).append((e, r))
    for fam, items in by.items():
        cols = 6
        rows = (len(items) + cols - 1) // cols
        W, Hh = 220, 250
        sheet = Image.new("RGB", (cols * W, rows * Hh), (5, 6, 13))
        dr = ImageDraw.Draw(sheet)
        for k, (e, r) in enumerate(items):
            im = Image.open(ROOT / r["preview"]).convert("RGB").resize((W, W))
            x, y = (k % cols) * W, (k // cols) * Hh
            sheet.paste(im, (x, y))
            dr.text((x + 6, y + W + 6), f"{e['id']} {e['name']}"[:34], fill=(220, 220, 235))
        out = ROOT / "previews" / f"{fam}.png"
        sheet.save(out, optimize=True)


def write_catalog(entries, results):
    rows = []
    for e in entries:
        r = results.get(e["id"], {})
        fam = catalog.FAMILIES[e["family"]]
        rows.append(dict(id=e["id"], name=e["name"], part=e["part"], family=e["family"], family_title=fam["title"],
                         math=e["math"], symmetry=e["symmetry"], look=fam["look"], references=fam["ref"],
                         stl=r.get("stl", ""), svg=r.get("svg", ""), preview=r.get("preview", ""),
                         triangles=r.get("triangles", ""), size_mm=r.get("size_mm", ""), ok=r.get("ok", False)))
    (ROOT / "catalog").mkdir(exist_ok=True)
    (ROOT / "catalog/geometry_catalog.json").write_text(json.dumps(rows, indent=1))
    with open(ROOT / "catalog/geometry_catalog.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    # markdown
    md = ["# Geometry catalog", "",
          f"{len(rows)} printable looks, generated by `tools/generate.py`. Every entry lists the maths that draws it "
          "and where the shape comes from. IDs: **G** = gobo (light stencil), **B** = boundary insert, **D** = dipper foot.", "",
          "Previews: `previews/<family>.png` (contact sheets) and `previews/items/`.", ""]
    md.append("| Family | Count | Contact sheet |")
    md.append("|---|---|---|")
    fams = []
    for e in entries:
        if e["family"] not in fams:
            fams.append(e["family"])
    for fam in fams:
        n = sum(1 for e in entries if e["family"] == fam)
        md.append(f"| [{catalog.FAMILIES[fam]['title']}](#{slug(catalog.FAMILIES[fam]['title']).replace('_', '-')}) | {n} | [sheet](../previews/{fam}.png) |")
    for fam in fams:
        info = catalog.FAMILIES[fam]
        md += ["", f"## {info['title']}", "", f"**Look:** {info['look']}", "", f"**Sources:** {info['ref']}", "",
               f"![{fam}](../previews/{fam}.png)", "", "| ID | Name | Maths | Symmetry | File |", "|---|---|---|---|---|"]
        for r in rows:
            if r["family"] == fam:
                if r["part"] == "gobo":
                    link = f"[gobos_{fam}.zip](../downloads/gobos_{fam}.zip) `{Path(r['stl']).name}`" if r["stl"] else ""
                else:
                    link = f"[stl](../{r['stl']})" if r["stl"] else ""
                md.append(f"| {r['id']} | {r['name']} | {r['math'].replace('|', '/')} | {r['symmetry']} | {link} |")
    hw = ["", "## Hardware parts", "", "| File | What it is |", "|---|---|"]
    for k, (_, desc) in build.HARDWARE.items():
        hw.append(f"| [stl/hardware/{k}.stl](../stl/hardware/{k}.stl) | {desc} |")
    md += hw
    (ROOT / "docs").mkdir(exist_ok=True)
    (ROOT / "docs/GEOMETRY_CATALOG.md").write_text("\n".join(md) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview-only", action="store_true")
    ap.add_argument("--family")
    ap.add_argument("--ids", help="comma-separated ids")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--dish-id", type=float, default=145.0)
    ap.add_argument("--no-hardware", action="store_true")
    ap.add_argument("--no-package", action="store_true", help="don't rebuild downloads/*.zip (CI smoke runs)")
    a = ap.parse_args()
    entries = catalog.entries()
    todo = [e for e in entries if (not a.family or e["family"] == a.family) and (not a.ids or e["id"] in a.ids.split(","))]
    opts = dict(preview_only=a.preview_only, dish_id=a.dish_id)
    results = {}
    old = ROOT / "catalog/geometry_catalog.json"
    if old.exists() and (a.family or a.ids):
        for r in json.loads(old.read_text()):
            results[r["id"]] = dict(ok=r["ok"], stl=r["stl"], svg=r["svg"], preview=r["preview"], triangles=r["triangles"], size_mm=r["size_mm"])
    t0 = time.time()
    # lambdas don't pickle: send ids, rebuild entries in the worker
    with ProcessPoolExecutor(a.jobs) as ex:
        for r in ex.map(_job_by_id, [(e["id"], opts) for e in todo]):
            results[r["id"]] = r
            flag = "ok " if r["ok"] else "ERR"
            print(f"{flag} {r['id']} {r.get('stl', r.get('preview', ''))} {r.get('triangles', '')} {r['seconds']}s"
                  + ("" if r["ok"] else "  " + r["error"]), flush=True)
    if not a.preview_only and not a.no_hardware and not a.ids and not a.family:
        for k, (fn, _) in build.HARDWARE.items():
            n = build.save_stl(fn(), ROOT / "stl/hardware" / f"{k}.stl")
            print("ok  hardware", k, n)
    contact_sheets(results, entries)
    write_catalog(entries, results)
    if not a.preview_only and not a.no_package:
        package()
    bad = [r for r in results.values() if not r.get("ok")]
    print(f"done: {len(results) - len(bad)} ok, {len(bad)} failed, {time.time() - t0:.0f}s")
    for r in bad:
        print(r["id"], r.get("error"))
    return 1 if bad else 0


def package():
    """downloads/: one zip per gobo family (STL + SVG), plus inserts, dippers, hardware."""
    import zipfile
    out = ROOT / "downloads"
    out.mkdir(exist_ok=True)
    groups = {}
    for d in sorted((ROOT / "stl/gobos").iterdir()):
        groups[f"gobos_{d.name}.zip"] = list(d.glob("*.stl")) + list((ROOT / "svg/gobos" / d.name).glob("*.svg"))
    for k in ("inserts", "dippers", "hardware"):
        groups[f"{k}.zip"] = list((ROOT / "stl" / k).glob("*.stl"))
    for name, files in groups.items():
        with zipfile.ZipFile(out / name, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for f in sorted(files):
                z.write(f, f"{f.suffix[1:]}/{f.name}")
    print("packaged", len(groups), "zips")


def _job_by_id(args):
    eid, opts = args
    e = next(x for x in catalog.entries() if x["id"] == eid)
    return job((e, opts))


if __name__ == "__main__":
    sys.exit(main())
