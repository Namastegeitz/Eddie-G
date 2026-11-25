# Printing on Bambu Lab printers (Bambu Studio)

Every part has been checked and packed for Bambu Studio. Download **`downloads/CYMATIC_ODYSSEY_Bambu_Studio.zip`** (3MF projects) or **`downloads/CYMATIC_ODYSSEY_30_style_kits.zip`** (plain STLs). Both open in Bambu Studio.

## What was checked (`tools/bambu_ready.py`)

| Check | Result |
|---|---|
| Every STL (all 355 looks, 30 style kits, hardware) | watertight, consistently wound, positive volume, sitting on the bed (z = 0), millimetres, binary STL |
| Every 3MF project | written with **lib3mf**, the 3MF Consortium's reference library, then re-read in strict mode. Each mesh reports manifold and oriented, with no warnings. |
| Bed fit | every part fits the A1, P1S, X1C and H2D. Everything except the 200 mm platform fits the **A1 mini**; it gets a 4-quarter version. |

The full results are in `bambu/REPORT.json`. Opening these files in Bambu Studio itself couldn't be tested here (no desktop app in this environment). The 3MF files follow the core 3MF specification that Bambu Studio reads.

## How to open

1. **File → Open Project / Import** (or drag the file onto Bambu Studio).
2. For our 3MF files Bambu Studio may say the file *isn't from Bambu Lab* and offer to **load geometry only**. Choose **Yes**: the parts arrive arranged on the plate with their names. You then pick the printer, filament and process as usual.
3. STLs import directly. Bambu Studio lays them flat on the plate.

## What's in the Bambu zip

| File | What it is |
|---|---|
| `styles/S##_name.3mf` | one plate per style: insert, gobo and dipper foot arranged on a 256 mm plate |
| `styles/S##_name_gobo_2color.3mf` | the gobo as **one object with two parts**: *base* and *lines*. With an AMS, give *base* white or translucent PLA/PETG and *lines* **black**. Black lines block light far better than thick white plastic, so the stencil comes out much sharper. |
| `hardware/plate_00_platform.3mf` | the 200 mm vibration platform (256 mm beds) |
| `hardware/plate_##.3mf` | all other hardware packed onto plates, including 4 foot cups and 8 panel corners |
| `hardware/a1mini_platform_x2.3mf` | **A1 mini:** 2 platform quarters + 2 splice plates. Print it **twice**, then join the 4 quarters with 16 x M3x12 screws and nuts. |

## Recommended settings

| Part | Filament (Bambu) | Process | Notes |
|---|---|---|---|
| Gobo, single colour | Bambu PLA Basic **White** or PETG HF White | 0.20 mm Standard; **100% infill**; walls 2; no supports | print flat; no ironing; the 0.6 mm base should stay translucent |
| Gobo, two colour (AMS) | base: PLA Basic White / PETG Translucent; lines: PLA Basic **Black** | 0.20 mm Standard; 100% infill | flush: purge into infill is fine; prime tower on |
| Rainbow gobo | PETG Translucent (clear) | 0.20 mm; 100% infill; slower outer walls | put it between two polarisers for rainbow colours |
| Boundary insert | **PETG HF** (any colour) | 0.20 mm Standard; walls 3; infill 30% | water-safe; sand the underside flat if it lifts |
| Dipper foot | PETG HF | 0.16 mm Optimal; 100% infill | stem prints upright; add a brim if your plate is cool |
| Platform | PETG HF | 0.20 mm Strength; walls 4; gyroid 40% | stiffness matters; Textured PEI plate |
| Other hardware | PETG HF (or PLA for prototypes) | 0.20 mm Standard | defaults |
| Glow, glitter, metal-filled filaments | - | - | use the **hardened steel nozzle** (standard on X1C; optional on P1S/A1) |

**Plates:** Textured PEI for PETG, Cool Plate or Textured PEI for PLA. Glue stick on a smooth plate with PETG so it releases cleanly.

## Enhanced versions (Blender)

`blender_enhanced/` (built by `tools/blender/cymatic_blender.py enhance-kits`) holds every kit part with:
- softened edges (0.6 mm bevel on inserts, 0.4 mm on feet, 0.8 mm on hardware)
- the **style ID engraved**: on the insert's top ring, and on the gobo's rim

These import into Bambu Studio the same way. See [BLENDER.md](BLENDER.md).
