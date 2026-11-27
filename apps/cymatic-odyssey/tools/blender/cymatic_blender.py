"""CYMATIC ODYSSEY for Blender (4.2+ / 5.x).

Use it three ways:

1. Add-on: Edit > Preferences > Add-ons > Install from Disk > this file. A "Cymatic" tab appears in the
   3D View sidebar (N): import a style kit, enhance the selected part, build the chamber, export for Bambu.

2. Command line (Blender app):
     blender -b -P cymatic_blender.py -- enhance --in insert.stl --out insert_plus.stl --bevel 0.6 --label S05
     blender -b -P cymatic_blender.py -- enhance-kits --root apps/cymatic-odyssey
     blender -b -P cymatic_blender.py -- build --root apps/cymatic-odyssey --style S05 --render out.png --blend chamber.blend

3. Python with the bpy module (pip install bpy):  python cymatic_blender.py build --root ... (same arguments)

Enhancements: edge bevel (softer, stronger prints), engraved style label (insert top / gobo rim),
voxel remesh + smoothing (organic finish), decimate (lighter files), scale-to-dish (fit a measured dish).
Build: the full Model A chamber assembled from the real STLs with glass, water, acrylic and PETG
materials, a light beam, and a Cycles render (assembled or exploded).
"""
from __future__ import annotations

bl_info = {
    "name": "CYMATIC ODYSSEY",
    "author": "CYMATIC ODYSSEY",
    "version": (1, 0, 0),
    "blender": (4, 2, 0),
    "location": "View3D > Sidebar > Cymatic",
    "description": "Enhance CYMATIC ODYSSEY STLs and build the water-light chamber",
    "category": "Import-Export",
}

import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

# ------------------------------------------------------------------ basics

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_stl(path, name=None):
    before = set(bpy.data.objects)
    bpy.ops.wm.stl_import(filepath=str(path))
    obj = [o for o in bpy.data.objects if o not in before][0]
    if name:
        obj.name = name
    return obj


def export_stl(obj, path):
    for o in list(bpy.context.scene.objects):
        if o is not None and o != obj:
            o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.stl_export(filepath=str(path), export_selected_objects=True, ascii_format=False, apply_modifiers=True)


def bake(obj):
    """Apply all modifiers without operator context (works headless)."""
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(obj.evaluated_get(dg))
    obj.modifiers.clear()
    old = obj.data
    obj.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)
    return obj


def boolean_solver():
    items = [e.identifier for e in bpy.types.BooleanModifier.bl_rna.properties["solver"].enum_items]
    return "MANIFOLD" if "MANIFOLD" in items else "EXACT"


def text_mesh(body, size, depth, align="CENTER"):
    cu = bpy.data.curves.new("label", type="FONT")
    cu.body = body
    cu.size = size
    cu.extrude = depth / 2
    cu.align_x = align
    cu.align_y = "CENTER"
    t = bpy.data.objects.new("label", cu)
    bpy.context.scene.collection.objects.link(t)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(t.evaluated_get(dg))
    m = bpy.data.objects.new("label_mesh", me)
    bpy.context.scene.collection.objects.link(m)
    bpy.data.objects.remove(t)
    return m


def mesh_stats(obj):
    bm = bmesh.new(); bm.from_mesh(obj.data)
    non_manifold = sum(1 for e in bm.edges if not e.is_manifold)
    vol = bm.calc_volume(signed=True)
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    bm.free()
    d = obj.dimensions
    return {"triangles": tris, "non_manifold_edges": non_manifold, "volume_cm3": round(vol / 1000, 2),
            "size_mm": [round(d.x, 1), round(d.y, 1), round(d.z, 1)]}

# ------------------------------------------------------------------ enhancements

def bevel(obj, width=0.6, segments=2, angle_deg=40):
    m = obj.modifiers.new("bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle_deg)
    m.harden_normals = False
    return bake(obj)


def _clean_manifold(obj_or_mesh, dist=1e-4):
    me = obj_or_mesh.data if hasattr(obj_or_mesh, "data") else obj_or_mesh
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dist)
    bmesh.ops.dissolve_degenerate(bm, dist=dist, edges=bm.edges)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()


def _non_manifold(obj):
    bm = bmesh.new(); bm.from_mesh(obj.data)
    n = sum(1 for e in bm.edges if not e.is_manifold)
    bm.free()
    return n


def engrave(obj, text, size=6.0, depth=0.6, at=(0, 0), top=True, rotate_deg=0.0):
    """Cut text into the top (or bottom) face of a flat part. Self-checking: tries the EXACT
    solver, then MANIFOLD with a cleaned text mesh; if the result still isn't manifold the
    part is left unlabelled (obj["label_skipped"] = True) rather than exporting a broken mesh."""
    z = obj.bound_box
    zmax = max(v[2] for v in z) if top else min(v[2] for v in z)
    original = obj.data.copy()
    for solver in ("EXACT", boolean_solver()):
        lab = text_mesh(text, size, depth * 2)
        _clean_manifold(lab)
        lab.location = (at[0], at[1], zmax)
        lab.rotation_euler[2] = math.radians(rotate_deg)
        bpy.context.view_layer.update()
        m = obj.modifiers.new("engrave", "BOOLEAN")
        m.operation = "DIFFERENCE"
        m.solver = solver
        m.object = lab
        bake(obj)
        bpy.data.objects.remove(lab)
        if _non_manifold(obj) == 0:
            return obj
        obj.data = original.copy()
    obj["label_skipped"] = True
    return obj


def smooth_remesh(obj, voxel=0.25, smooth_iters=6):
    r = obj.modifiers.new("remesh", "REMESH")
    r.mode = "VOXEL"
    r.voxel_size = voxel
    s = obj.modifiers.new("smooth", "CORRECTIVE_SMOOTH")
    s.iterations = smooth_iters
    return bake(obj)


def decimate(obj, ratio=0.5):
    d = obj.modifiers.new("decimate", "DECIMATE")
    d.ratio = ratio
    return bake(obj)


def scale_to(obj, target_xy):
    d = obj.dimensions
    s = target_xy / max(d.x, d.y)
    obj.scale = (s, s, 1.0)
    bpy.context.view_layer.update()
    obj.data.transform(obj.matrix_basis)
    obj.matrix_basis.identity()
    return obj


def enhance_file(src, dst, bevel_w=0.0, label="", label_at=(0, 0), label_size=6.0, remesh=0.0, decimate_ratio=0.0, scale_xy=0.0):
    clear_scene()
    o = import_stl(src, Path(src).stem)
    before = mesh_stats(o)
    if scale_xy:
        scale_to(o, scale_xy)
    if remesh:
        smooth_remesh(o, remesh)
    if bevel_w:
        bevel(o, bevel_w)
    if label:
        engrave(o, label, size=label_size, at=label_at)
    if decimate_ratio:
        decimate(o, decimate_ratio)
    after = mesh_stats(o)
    export_stl(o, dst)
    return {"in": str(src), "out": str(dst), "before": before, "after": after, "label_skipped": bool(o.get("label_skipped", False))}


def enhance_kits(root):
    """For every style kit: bevel + engrave the insert, engrave the gobo rim, bevel the foot."""
    root = Path(root)
    styles = json.loads((root / "catalog/styles.json").read_text())
    report = []
    for s in styles:
        folder = root / s["folder"]
        out = root / "blender_enhanced" / folder.name
        for f in sorted(folder.glob("*.stl")):
            role = f.name.split("_")[0]
            if role == "insert":
                r = enhance_file(f, out / f.name.replace(".stl", "_plus.stl"), bevel_w=0.6, label=s["id"], label_at=(0, 63.5), label_size=6.0)
            elif role == "gobo":
                r = enhance_file(f, out / f.name.replace(".stl", "_plus.stl"), label=s["id"], label_at=(0, -53.0), label_size=2.6)
            else:
                r = enhance_file(f, out / f.name.replace(".stl", "_plus.stl"), bevel_w=0.4)
            r["style"] = s["id"]; r["role"] = role
            report.append(r)
            print(s["id"], role, r["after"], flush=True)
    for f in sorted((root / "stl/hardware").glob("*.stl")):
        r = enhance_file(f, root / "blender_enhanced/hardware" / f.name.replace(".stl", "_plus.stl"), bevel_w=0.8)
        r["role"] = "hardware"; report.append(r)
        print("hardware", f.name, r["after"], flush=True)
    (root / "blender_enhanced/REPORT.json").write_text(json.dumps(report, indent=1))
    return report

# ------------------------------------------------------------------ materials

def mat(name, color, rough=0.4, transmission=0.0, ior=1.45, alpha=1.0, metallic=0.0, emission=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    b.inputs["IOR"].default_value = ior
    for key in ("Transmission Weight", "Transmission"):
        if key in b.inputs:
            b.inputs[key].default_value = transmission
            break
    b.inputs["Alpha"].default_value = alpha
    if emission is not None:
        for key in ("Emission Color", "Emission"):
            if key in b.inputs:
                b.inputs[key].default_value = (*emission, 1)
                break
        b.inputs["Emission Strength"].default_value = strength
    return m


def glow_mat(name, color, strength, image=None, alpha=1.0):
    """Emission mixed with transparency (light beams) or an emissive image (the projected wall)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*color, 1)
    em.inputs["Strength"].default_value = strength
    if image:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(image))
        nt.links.new(tex.outputs["Color"], em.inputs["Color"])
    if alpha < 1.0:
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        mix.inputs[0].default_value = alpha
        nt.links.new(tr.outputs[0], mix.inputs[1]); nt.links.new(em.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
    else:
        nt.links.new(em.outputs[0], out.inputs["Surface"])
    return m


def assign(obj, m):
    obj.data.materials.clear()
    obj.data.materials.append(m)
    return obj


def cylinder(name, r, h, z0, verts=96, x=0.0, y=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=(x, y, z0 + h / 2))
    o = bpy.context.active_object; o.name = name
    return o


def box(name, sx, sy, sz, loc):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object; o.name = name; o.scale = (sx, sy, sz)
    return o


def place(obj, x=0, y=0, z=0, rx=0, ry=0, rz=0, center_xy=True):
    bpy.context.view_layer.update()
    bb = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    if center_xy:
        cx = (min(v.x for v in bb) + max(v.x for v in bb)) / 2
        cy = (min(v.y for v in bb) + max(v.y for v in bb)) / 2
        obj.data.transform(__import__("mathutils").Matrix.Translation((-cx, -cy, -min(v.z for v in bb))))
    obj.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    obj.location = (x, y, z)
    return obj

# ------------------------------------------------------------------ chamber assembly

# which assembly step adds each part (object base name -> step)
STAGES = {
    "LED cradle": 1, "heatsink": 1, "LED": 1, "amplifier": 1, "base": 1,
    "gobo carrier": 2, "gobo": 2, "light beam": 2,
    "exciter": 3, "foot cup": 3, "platform": 3, "support post": 3,
    "glass dish": 4, "insert": 4, "water": 4,
    "dipper speaker": 5, "dipper arm": 5, "dipper foot": 5,
    "M5 rod": 6, "lens ring": 6, "lens": 6, "mirror holder": 6, "mirror": 6, "wall picture": 6, "projected beam": 6,
    "acrylic": 7,
}


def build_chamber(root, style_id="S05", exploded=False, render=None, blend=None, samples=48, res=(1280, 960), stage=0):
    root = Path(root)
    clear_scene()
    sc = bpy.context.scene
    styles = {s["id"]: s for s in json.loads((root / "catalog/styles.json").read_text())}
    s = styles[style_id]
    kit = root / s["folder"]
    hw = root / "stl/hardware"
    e = 60.0 if exploded else 0.0

    petg_blue = mat("PETG blue", (0.15, 0.45, 0.9), 0.35)
    petg_orange = mat("PETG orange", (0.95, 0.45, 0.12), 0.4)
    pla_white = mat("PLA white", (0.92, 0.92, 0.88), 0.5)
    glass = mat("borosilicate", (0.95, 0.97, 1.0), 0.02, transmission=1.0, ior=1.47)
    water = mat("water", (0.85, 0.93, 1.0), 0.01, transmission=1.0, ior=1.33)
    acrylic = mat("acrylic", (0.9, 0.95, 1.0), 0.0, transmission=1.0, ior=1.49, alpha=0.025)
    mirror = mat("mirror", (0.95, 0.95, 0.95), 0.02, metallic=1.0)
    dark = mat("electronics", (0.05, 0.05, 0.07), 0.6)
    steel = mat("steel", (0.6, 0.6, 0.62), 0.3, metallic=1.0)
    ledm = mat("LED", (1, 0.95, 0.85), 0.3, emission=(1, 0.95, 0.85), strength=40)
    pal = s["pal"]
    hexc = lambda h: tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    beam = glow_mat("beam", hexc(pal[1]), 0.8, alpha=0.035)

    def stl(path, name, m):
        return assign(import_stl(path, name), m)

    # light source
    cradle = place(stl(hw / "led_cradle.stl", "LED cradle", petg_orange), z=0 - e * 1.5)
    cylinder("heatsink", 20, 20, 8 - e * 1.5, 32); bpy.context.active_object.data.materials.append(steel)
    led = cylinder("LED", 4, 2, 28 - e * 1.5, 24); assign(led, ledm)
    # gobo + carrier
    carrier = place(stl(hw / "gobo_carrier.stl", "gobo carrier", petg_orange), z=200 - e * 0.5)
    gobo_f = next(kit.glob("gobo_*.stl"))
    gobo = place(stl(gobo_f, "gobo", pla_white), z=202 - e * 0.5)
    # platform + exciters + feet
    plat = place(stl(hw / "platform_4x_exciter.stl", "platform", petg_blue), z=214)
    for sx in (1, -1):
        for sy in (1, -1):
            ex = cylinder("exciter", 22, 18, 196 - e * 0.25, 48, x=70 * sx, y=70 * sy); assign(ex, dark)
            cup = place(stl(hw / "platform_foot_cup.stl", "foot cup", petg_orange), x=92 * sx, y=92 * sy, z=206 - e * 0.25)
            post = cylinder("support post", 7, 206, -e * 0.25, 32, x=92 * sx, y=92 * sy); assign(post, steel)
    # dish, insert, water
    dish = cylinder("glass dish", 75, 25, 218.2 + e * 0.5, 128); assign(dish, glass)
    ins = place(stl(next(kit.glob("insert_*.stl")), "insert", petg_blue), z=221.2 + e * 1.0)
    wat = cylinder("water", 71, 5, 221.2 + e * 0.5, 128); assign(wat, water)
    # dipper
    if s["dipper"]:
        spk = cylinder("dipper speaker", 38, 30, 240 + e, 64, x=125); assign(spk, dark)
        arm = place(stl(hw / "dipper_arm.stl", "dipper arm", petg_orange), x=70, z=272 + e)
        foot = place(stl(next(kit.glob("dipper_*.stl")), "dipper foot", petg_orange), x=15, z=224 + e * 1.2)
    # lens + mirror
    lr = place(stl(hw / "lens_ring_80mm.stl", "lens ring", petg_orange), z=360 + e * 1.6)
    lens = cylinder("lens", 40, 4, 362 + e * 1.6, 96); assign(lens, glass)
    for sx in (1, -1):
        rod = cylinder("M5 rod", 2.5, 200, 230, 16, x=58 * sx, y=0); assign(rod, steel)
    mh = place(stl(hw / "mirror_holder_45.stl", "mirror holder", petg_orange), z=410 + e * 2.2)
    mir = box("mirror", 100, 100, 3, (0, 0, 452 + e * 2.2)); mir.rotation_euler = (math.radians(-45), 0, 0); assign(mir, mirror)
    # the wall the chamber projects onto, showing this style's simulated picture
    wall_img = root / s["folder"] / "wall_preview.png"
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 900, 470))
    wall = bpy.context.active_object; wall.name = "wall picture"; wall.scale = (520, 520, 1); wall.rotation_euler = (math.radians(90), 0, 0)
    assign(wall, glow_mat("wall", (1, 1, 1), 1.6, image=wall_img if wall_img.exists() else None))
    bpy.ops.mesh.primitive_cone_add(vertices=64, radius1=40, radius2=250, depth=850, location=(0, 470, 455 + e * 2.2))
    throw = bpy.context.active_object; throw.name = "projected beam"; throw.rotation_euler = (math.radians(-90), 0, 0); assign(throw, beam)
    # enclosure (acrylic) + base electronics
    if not exploded:
        for (sx, sy, sz, loc) in ((300, 3, 480, (0, -150, 240)), (3, 300, 480, (-150, 0, 240))):
            p = box("acrylic", sx, sy, sz, loc); assign(p, acrylic)
        fl = box("base", 300, 300, 6, (0, 0, -3)); assign(fl, dark)
    amp = box("amplifier", 70, 50, 20, (95, -95, 10 - e * 1.5)); assign(amp, dark)
    # light cone (visual)
    bpy.ops.mesh.primitive_cone_add(vertices=64, radius1=6, radius2=60, depth=190, location=(0, 0, 30 + 95 - e * 0.5))
    cone = bpy.context.active_object; cone.name = "light beam"; assign(cone, beam)
    # assembly steps: keep parts up to `stage`, highlight the parts added in that step
    if stage:
        hi = mat("new in this step", (1.0, 0.72, 0.18), 0.35, emission=(1.0, 0.6, 0.1), strength=0.6)
        for o in list(bpy.data.objects):
            if o.type != "MESH":
                continue
            st = next((n for pre, n in STAGES.items() if o.name.split(".")[0] == pre), 0)
            if st > stage:
                bpy.data.objects.remove(o)
            elif st == stage and o.name.split(".")[0] not in ("light beam", "projected beam", "wall picture", "water", "glass dish", "lens", "acrylic"):
                assign(o, hi)
    # lights + camera + world
    bpy.ops.object.light_add(type="SPOT", location=(0, 0, 30))
    sp = bpy.context.active_object; sp.data.energy = 2.5e6; sp.data.spot_size = math.radians(40); sp.rotation_euler = (0, 0, 0)
    bpy.ops.object.light_add(type="AREA", location=(400, -500, 700))
    ar = bpy.context.active_object; ar.data.energy = 1.6e7; ar.data.size = 600
    ar.rotation_euler = (math.radians(50), 0, math.radians(35))
    bpy.ops.object.light_add(type="AREA", location=(-600, 300, 300))
    a2 = bpy.context.active_object; a2.data.energy = 1.2e7; a2.data.size = 500; a2.rotation_euler = (math.radians(70), 0, math.radians(-120))
    cam_d = 1500 if not exploded else 1750
    if stage and stage < 6:
        cam_d = 950
    bpy.ops.object.camera_add(location=(cam_d * 0.80, -cam_d * 0.60, 520 + (150 if exploded else 0)))
    cam = bpy.context.active_object
    tgt = bpy.data.objects.new("target", None); sc.collection.objects.link(tgt); tgt.location = (0, 300, 330 if not exploded else 340)
    if stage and stage < 6:
        tgt.location = (0, 0, 200)
    c = cam.constraints.new("TRACK_TO"); c.target = tgt; c.track_axis = "TRACK_NEGATIVE_Z"; c.up_axis = "UP_Y"
    cam.data.lens = 35 if not (stage and stage < 6) else 52
    cam.data.clip_end = 10000
    sc.camera = cam
    world = bpy.data.worlds.new("world"); sc.world = world; world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.012, 0.014, 0.03, 1)
    sc.unit_settings.system = "METRIC"; sc.unit_settings.scale_length = 0.001
    if blend:
        Path(blend).parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(blend).resolve()))
    if render:
        sc.render.engine = "CYCLES"
        sc.cycles.device = "CPU"
        sc.cycles.samples = samples
        try:
            sc.cycles.use_denoising = True
        except Exception:
            pass
        sc.render.resolution_x, sc.render.resolution_y = res
        sc.render.film_transparent = False
        sc.view_settings.view_transform = "AgX" if "AgX" in [i.identifier for i in sc.view_settings.bl_rna.properties["view_transform"].enum_items] else "Filmic"
        sc.render.filepath = str(Path(render).resolve())
        bpy.ops.render.render(write_still=True)
    return sc

# ------------------------------------------------------------------ add-on UI

class CYMATIC_PT_panel(bpy.types.Panel):
    bl_label = "CYMATIC ODYSSEY"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Cymatic"

    def draw(self, context):
        p = context.scene.cymatic
        col = self.layout.column(align=True)
        col.prop(p, "root"); col.prop(p, "style")
        col.operator("cymatic.build", text="Build chamber").exploded = False
        col.operator("cymatic.build", text="Build exploded view").exploded = True
        col.separator()
        col.label(text="Enhance selected part")
        col.prop(p, "bevel"); col.prop(p, "label"); col.prop(p, "label_size"); col.prop(p, "remesh"); col.prop(p, "decimate")
        col.operator("cymatic.enhance")
        col.operator("cymatic.export_bambu")


class CymaticProps(bpy.types.PropertyGroup):
    root: bpy.props.StringProperty(name="Project folder", subtype="DIR_PATH")
    style: bpy.props.StringProperty(name="Style", default="S05")
    bevel: bpy.props.FloatProperty(name="Bevel mm", default=0.6, min=0)
    label: bpy.props.StringProperty(name="Engrave text", default="")
    label_size: bpy.props.FloatProperty(name="Text mm", default=6.0, min=1)
    remesh: bpy.props.FloatProperty(name="Voxel remesh mm (0=off)", default=0.0, min=0)
    decimate: bpy.props.FloatProperty(name="Decimate ratio (0=off)", default=0.0, min=0, max=1)


class CYMATIC_OT_build(bpy.types.Operator):
    bl_idname = "cymatic.build"; bl_label = "Build chamber"
    exploded: bpy.props.BoolProperty(default=False)

    def execute(self, context):
        p = context.scene.cymatic
        build_chamber(bpy.path.abspath(p.root), p.style, self.exploded)
        return {"FINISHED"}


class CYMATIC_OT_enhance(bpy.types.Operator):
    bl_idname = "cymatic.enhance"; bl_label = "Enhance selected"

    def execute(self, context):
        p = context.scene.cymatic
        o = context.active_object
        if p.remesh:
            smooth_remesh(o, p.remesh)
        if p.bevel:
            bevel(o, p.bevel)
        if p.label:
            engrave(o, p.label, size=p.label_size)
        if p.decimate:
            decimate(o, p.decimate)
        self.report({"INFO"}, str(mesh_stats(o)))
        return {"FINISHED"}


class CYMATIC_OT_export(bpy.types.Operator):
    bl_idname = "cymatic.export_bambu"; bl_label = "Export STL for Bambu Studio"
    filepath: bpy.props.StringProperty(subtype="FILE_PATH")

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self); return {"RUNNING_MODAL"}

    def execute(self, context):
        export_stl(context.active_object, self.filepath if self.filepath.endswith(".stl") else self.filepath + ".stl")
        return {"FINISHED"}


CLASSES = (CymaticProps, CYMATIC_PT_panel, CYMATIC_OT_build, CYMATIC_OT_enhance, CYMATIC_OT_export)


def register():
    for c in CLASSES:
        bpy.utils.register_class(c)
    bpy.types.Scene.cymatic = bpy.props.PointerProperty(type=CymaticProps)


def unregister():
    del bpy.types.Scene.cymatic
    for c in reversed(CLASSES):
        bpy.utils.unregister_class(c)

# ------------------------------------------------------------------ CLI

def cli(argv):
    import argparse
    ap = argparse.ArgumentParser(prog="cymatic_blender")
    sub = ap.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("enhance")
    e.add_argument("--in", dest="src", required=True); e.add_argument("--out", required=True)
    e.add_argument("--bevel", type=float, default=0.0); e.add_argument("--label", default="")
    e.add_argument("--label-size", type=float, default=6.0); e.add_argument("--label-x", type=float, default=0.0)
    e.add_argument("--label-y", type=float, default=0.0); e.add_argument("--remesh", type=float, default=0.0)
    e.add_argument("--decimate", type=float, default=0.0); e.add_argument("--scale-xy", type=float, default=0.0)
    k = sub.add_parser("enhance-kits"); k.add_argument("--root", required=True)
    b = sub.add_parser("build")
    b.add_argument("--root", required=True); b.add_argument("--style", default="S05"); b.add_argument("--exploded", action="store_true")
    b.add_argument("--render"); b.add_argument("--blend"); b.add_argument("--samples", type=int, default=48)
    b.add_argument("--res", default="1280x960")
    b.add_argument("--stage", type=int, default=0, help="1-7: render one assembly step, new parts highlighted")
    a = ap.parse_args(argv)
    if a.cmd == "enhance":
        print(json.dumps(enhance_file(a.src, a.out, a.bevel, a.label, (a.label_x, a.label_y), a.label_size, a.remesh, a.decimate, a.scale_xy), indent=1))
    elif a.cmd == "enhance-kits":
        enhance_kits(a.root)
    else:
        w, h = (int(v) for v in a.res.split("x"))
        build_chamber(a.root, a.style, a.exploded, a.render, a.blend, a.samples, (w, h), a.stage)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if argv:
        cli(argv)
    else:
        register()
