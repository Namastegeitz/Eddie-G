# Blender: enhance the STLs and build the chamber

`tools/blender/cymatic_blender.py` is one file that works three ways. It was tested with Blender 5.3 (`bpy` module) and needs Blender 4.2 or newer.

## 1. As an add-on (inside Blender)

1. **Edit → Preferences → Add-ons → Install from Disk** → choose `cymatic_blender.py`, then tick **CYMATIC ODYSSEY**.
2. In the 3D View press **N** and open the **Cymatic** tab.
3. Set **Project folder** to your `apps/cymatic-odyssey` folder and pick a **Style** (S01-S30).
4. Buttons:
   - **Build chamber / Build exploded view**: assembles Model A from the real STLs, with glass, water, acrylic and PETG materials, the light beam and the projected picture on a wall.
   - **Enhance selected**: with a part selected, applies the bevel, engraved text, voxel remesh/smoothing and decimate settings shown above the button.
   - **Export STL for Bambu Studio**: saves the selected part as a binary STL.

## 2. From the command line (batch)

```bash
# one part: bevel 0.6 mm and engrave "S05" on the top face at (0, 63.5)
blender -b -P tools/blender/cymatic_blender.py -- enhance --in styles/S05_metatron/insert_B004_insert_hexagon.stl \
        --out insert_plus.stl --bevel 0.6 --label S05 --label-y 63.5

# every style kit + all hardware -> blender_enhanced/ (with a REPORT.json of before/after mesh checks)
blender -b -P tools/blender/cymatic_blender.py -- enhance-kits --root apps/cymatic-odyssey

# assemble and render the chamber for a style (add --exploded for the exploded view)
blender -b -P tools/blender/cymatic_blender.py -- build --root apps/cymatic-odyssey --style S07 \
        --render chamber_S07.png --blend chamber_S07.blend --samples 64 --res 1600x1200
```

Without the Blender app: `pip install bpy` (Python 3.13), then `python tools/blender/cymatic_blender.py <same arguments>`.

## Enhancement options

| Option | What it does | Good for |
|---|---|---|
| `--bevel mm` | rounds edges sharper than 40 degrees | inserts, feet, hardware: nicer to handle, fewer stress cracks |
| `--label TEXT` (+ `--label-size`, `--label-x/y`) | engraves text 0.6 mm deep into the top face (exact boolean) | style IDs, venue names, gift messages |
| `--remesh mm` | voxel remesh + corrective smooth | an organic, cast look on hardware or sculptural prints |
| `--decimate 0-1` | reduces triangles | lighter files for very dense gobos |
| `--scale-xy mm` | scales the footprint to a size | fit an insert to a measured dish |

Avoid bevels on gobos: their lines are only 0.8 mm wide. The batch command engraves the gobo rim instead.

## What's been generated

- `blender_enhanced/<style>/..._plus.stl`: every style kit part, enhanced and checked watertight
- `blender_enhanced/hardware/..._plus.stl`: every hardware part, bevelled
- `marketing/renders/chamber_S##.png`: an assembled-chamber render per style; `chamber_exploded.png`: the exploded hero shot
- `marketing/renders/chamber_S05.blend`: an editable Blender scene
