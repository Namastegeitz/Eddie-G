# Build specs: the CYMATIC ODYSSEY chamber

A sealed, low-voltage box. A shallow glass dish of water sits on a vibrating platform. A point-like LED shines up through it from behind, and a lens throws the moving water's caustics onto any wall. Printed **gobos** (light stencils) put geometry into the beam, **boundary inserts** set the shape of the water's "drum", and **dipper feet** launch shaped waves.

> Prices are rough US retail as of late 2026 and are only for budgeting. Check part datasheets before you buy, especially exciter mounting sizes.

## 1. What your EZ-100 does in this system

| Question | Answer |
|---|---|
| Can it vibrate the water? | **No.** It's a plasma-arc speaker. The sound comes from the arc heating the air, so there's no moving surface to couple into water. |
| Can it be inside the water chamber? | **No.** See [SAFETY.md](SAFETY.md#1-the-ez-100-tesla-coil-keep-it-dry-and-separate). |
| Can it be part of the show? | **Yes, as a separate "Storm Bay" accent** at least 50 cm from the water, on [coil_bay_base.stl](../stl/hardware/coil_bay_base.stl). In **Pulse** mode (1-3 bursts per second) its arc can crack in time with each ring leaving the dipper: lightning launching the waves. |
| How do I sync it? | Your unit has Bluetooth (the music-note switch position). Use a **dual-link Bluetooth transmitter** (one source, two receivers: amp + coil), or a 3.5 mm splitter if your board has an AUX input. Sellers note these coils sound best with square-wave tones, so set the console waveform to *square* for the coil's channel. |

Your own test (flashlight through a glass dispenser onto the door) already shows the basic effect: water and glass bend light into bright lines. The build below makes that sharp, controllable and geometric.

## 2. System at a glance

```
            wall / ceiling  <-------------------------------+
                                                          |
   +------------- enclosure (acrylic, lid) ---------------+|
   |      [45 deg first-surface mirror]  ------------------+
   |               ^                                      |
   |       [projection lens 80 mm, f~100]  (lens ring)    |
   |               ^   caustic plane ~5-15 cm above water |
   |   ~~~~~~~ water 3-6 mm in 145 mm glass dish ~~~~~~~  |  <- boundary insert drops in here
   |   [platform]  4 x exciter underneath  [platform]     |  <- or: dipper foot on an arm from a 3" speaker
   |               [gobo carrier + gobo]                  |
   |               ^                                      |
   |          [LED 10 W single die] on heatsink (cradle)  |
   |   drip tray        amp  |  LED driver  |  ESP32      |  <- electronics beside/above the tray, 24 V only
   +------------------------------------------------------+
        24 V DC brick (GFCI outlet)    audio in: Bluetooth / AUX from the Voyage console
```

### Two drive modes

| | **Faraday (platform)** | **Dipper (foot)** |
|---|---|---|
| What moves | The whole dish, up and down | A small foot touching the surface |
| Water answers at | **half** the drive frequency | the drive frequency |
| Looks | standing squares, hexagons, 12-fold quasicrystals, wall-shaped modes | rings pulsing outward, interference lace, shaped wavefronts |
| Hardware | [platform_4x_exciter.stl](../stl/hardware/platform_4x_exciter.stl) + 4 x Dayton DAEX32EP-4 + 4 x [foot cups](../stl/hardware/platform_foot_cup.stl) | 3-4" full-range speaker + [dipper_arm.stl](../stl/hardware/dipper_arm.stl) + a [dipper foot](../downloads/dippers.zip) |
| Shake needed | about 0.1-0.6 g at 40-80 Hz, about 25 micrometres stroke ([PHYSICS_TABLES.md](PHYSICS_TABLES.md#2-how-hard-to-shake-faraday-onset-depth-5-mm)) | a fraction of a millimetre |

Build both. A switch on the amp output picks the platform or the speaker.

### Optical layouts

| | **A. Compact chamber (above)** | **B. Overhead projector** | **C. Shadow cast (your test)** |
|---|---|---|---|
| How | LED below, lens + mirror above | Put the platform and dish on an old overhead projector's glass | Light through the dish, wall 0.5-1.5 m away, no lens |
| Brightness | good in a dim room | very bright (the classic 1960s liquid light-show tool) | dim, soft |
| Sharpness | sharp (lens images the caustic plane) | sharp (refocus the head slightly up) | blurry, big |
| Cost | about $40 in optics | $20-60 used | $0 |
| Note | most "product-like" | the halogen stage warms the water; prefer LED projectors or short sessions | fine for testing |

**Why a lens:** each ripple acts like a tiny lens with a focal length of roughly 5-15 cm (it gets shorter for bigger, finer waves). The sharpest caustic web sits on a plane a little above the water. A projection lens images *that plane* onto the wall: magnification is about wall distance / lens focal length, so a 100 mm lens at 2 m gives about 20x. The 112 mm water area becomes a picture about 2.2 m wide.

**Why a point source:** a large light source blurs the caustics. Use a single small LED die (2-3 mm) rather than a big COB or a frosted bulb. Your flashlight works for the same reason.

## 3. Specifications

| Item | Spec |
|---|---|
| Enclosure | about 300 x 300 x 420 mm, 3-5 mm clear/smoked acrylic with a lid, printed corners ([panel_corner.stl](../stl/hardware/panel_corner.stl)), drip tray under the dish |
| Vessel | borosilicate glass Petri dish, 150 mm OD x 25 mm (inside diameter about 145 mm; **measure yours** and run `generate.py --dish-id <mm>`) |
| Water | distilled water + 1 drop of dish soap per litre, 3-6 mm deep (about 50-100 mL) |
| Faraday drivers | 4 x Dayton Audio DAEX32EP-4 "Thruster" 32 mm exciter, 4 ohm, 40 W RMS each; two per amp channel in series (8 ohm per channel) |
| Dipper driver | 3-4" full-range speaker, 4-8 ohm, 15-25 W; dipper foot on the printed arm |
| Amplifier | TPA3116D2 2 x 50 W class-D board (with Bluetooth if you want wireless), 24 V |
| Drive range | 8-200 Hz, one or two tones, steady / pulsed / swelling (Voyage console) |
| Main light | 10 W single-die white LED on a 20 mm star (e.g. Luminus SST-40 or Cree XP-L class, about 1000-1300 lm), 40 x 40 mm heatsink, constant-current driver with PWM at 20 kHz or more |
| Colour (optional) | 3 x 3 W colour LEDs (red, green, blue) about 15 mm apart = "chromatic parallax"; or an RGBW star; ESP32 running WLED (free firmware, audio-reactive) |
| Spectrum (optional) | holographic diffraction-grating film (500 or 1000 lines/mm) after the lens; or a glass prism; or polariser + cellophane + polariser |
| Lens | 80 mm diameter, about 100 mm focal length (magnifier or Fresnel), on [lens_ring_80mm.stl](../stl/hardware/lens_ring_80mm.stl) + 3 x M5 rods |
| Mirror | 100 x 100 mm first-surface (front-silvered) mirror, [mirror_holder_45.stl](../stl/hardware/mirror_holder_45.stl) |
| Power | 24 V / 5 A UL/ETL-listed brick, 5 A inline fuse, GFCI outlet. Typical draw 25-40 W |
| Image on wall | 1-3 m wide at 2-4 m throw (Layout A); larger with an overhead projector |
| Control | Voyage console (`console/index.html`, any browser, no install) over Bluetooth/AUX; optional webcam + `tools/mode_mapper.py` for auto-mapping |

## 4. Bill of materials (Layout A, both drive modes)

| Qty | Part | ~US$ |
|---|---|---|
| 4 | Dayton Audio DAEX32EP-4 exciter | 70-90 |
| 1 | 3-4" full-range speaker (dipper) | 10-20 |
| 1 | TPA3116D2 2 x 50 W amp board (Bluetooth version optional) | 15-30 |
| 1 | 24 V 5 A power brick + inline fuse + DC jack | 20-30 |
| 1 | 10 W single-die LED on 20 mm star + 40 mm heatsink + CC driver | 20-35 |
| 1 | ESP32 dev board + 3 colour LEDs / RGBW star (optional) | 10-20 |
| 1 | Borosilicate Petri dish 150 mm | 10-20 |
| 1 | 80 mm lens, f about 100 mm | 10-25 |
| 1 | 100 x 100 mm first-surface mirror | 15-25 |
| 4 | 25 mm Sorbothane hemispheres (platform feet) | 15-25 |
| 1 | Acrylic sheet set for the enclosure + drip tray | 40-70 |
| 1 | Diffraction-grating film / polariser sheet (optional) | 10-15 |
| - | M3/M5 hardware, 3 x M5 threaded rod, wire, DPDT switch, cable ties | 15 |
| 1-2 kg | PETG (inserts, platform, hardware) + white PLA/PETG (gobos) | 25-45 |
| | **Total** | **about $300-450** |

Tesla coil not included (you have it; it's optional and stays outside the chamber).

## 5. Printed parts and settings

| Part | Files | Material | Settings |
|---|---|---|---|
| Gobos (306) | [downloads/gobos_*.zip](../downloads/) (STL + SVG) | **white** PLA or PETG | 0.2 mm layers, 100% infill, flat on the bed, no supports. The 0.6 mm base lets light through; the 2.4 mm raised lines block it (lithophane principle). |
| Gobos, sharper option | the same SVGs | laser-printer transparency film, or a laser cutter (black card) | 110 mm circles; film is the sharpest and cheapest; tint with colour gels |
| Boundary inserts (37) | [stl/inserts/](../stl/inserts/) | PETG (water-safe) | 3 walls, 30% infill; sand the underside flat. Three slots at the bottom let water equalise. |
| Dipper feet (12) | [stl/dippers/](../stl/dippers/) | PETG or resin | 100% infill; the stem fits the arm's 6.2 mm bore |
| Platform | [platform_4x_exciter.stl](../stl/hardware/platform_4x_exciter.stl) | PETG | 200 x 200 mm, needs a 220 mm bed. 4 walls, 40% gyroid: **stiffness matters** (a floppy platform makes muddy patterns). Laser-cut 5 mm acrylic is even better. |
| Everything else | [stl/hardware/](../stl/hardware/) | PETG | defaults |

Change any size (dish, gobo diameter, line width, insert height) in `tools/odyssey/build.py` (`Spec`) and regenerate. Every file rebuilds in about a minute.

## 6. Assembly

1. **Enclosure.** Cut the panels, join them with the printed corners, and fit a drip tray at dish level. Leave a front window (or open front) for the mirror's beam, and a vented back panel.
2. **Light.** LED star on its heatsink in the [LED cradle](../stl/hardware/led_cradle.stl), centred under the dish position, about 150-250 mm below it. Driver and ESP32 to the side, never below the dish.
3. **Platform.** Bond the 4 exciters to the rings on the underside using their adhesive pads (all wired the **same polarity**). Set the platform on 4 Sorbothane hemispheres in the [foot cups](../stl/hardware/platform_foot_cup.stl) so it floats.
   **Wiring for automatic light shows (recommended):** exciters 1+2 in series and 3+4 in series (8 ohm each), then the two pairs in parallel (4 ohm) on the amp's **LEFT** channel. The dipper speaker goes on the **RIGHT** channel. In the console choose *Wiring: Split*; the shows then switch between whole-dish (Faraday) and dipper drive by themselves.
   *Alternative:* the same signal on both channels with a DPDT switch box (console *Wiring: Both*).
4. **Dish.** Put the dish in the platform recess and level it with a bubble level (shim the feet). Add the [gobo carrier](../stl/hardware/gobo_carrier.stl) under the aperture.
5. **Dipper.** Mount the small speaker facing up on a bridge beside the dish (on the fixed frame, not the moving platform). Glue the [dipper arm](../stl/hardware/dipper_arm.stl) pad to its dust cap, slide a foot's stem through the far end so the foot just kisses the water, and lock it with the M3 set screw. Wire it to the amp's right channel (see step 3).
6. **Optics.** Three M5 rods up from the platform frame (not the moving platform), with the [lens ring](../stl/hardware/lens_ring_80mm.stl) about 10-20 cm above the water and the [45 degree mirror](../stl/hardware/mirror_holder_45.stl) above that. Focus by moving the lens until the lines are crisp on the wall.
7. **Spectrum.** Tape the grating film or polariser sandwich just after the lens.
8. **Storm Bay (optional).** EZ-100 on its base at least 50 cm away, outside the enclosure, in a ventilated spot.

## 7. First light and calibration

1. Fill with 5 mm of distilled water + a drop of soap. Dim the room.
2. Open `console/index.html`, press **Start audio** with the volume at 10%, and pick **Faraday, 40 Hz**. Raise the volume slowly until squares appear and stop just above that point. That's the sharpest regime.
3. Try **5:4** (12-fold) and **3:2** (hexagons). Press **Log what I see** whenever the wall looks great: the console builds your own pattern atlas.
4. Optional automation: point a webcam at the wall and run `python3 tools/mode_mapper.py --start 20 --stop 120 --step 0.5`. It sweeps, photographs, recognises each pattern ([pattern_analyzer.py](../tools/pattern_analyzer.py)) and writes `atlas.csv`. Import that into the console.
5. Swap inserts: the triangle, pentagon and stadium change the look completely at low frequencies (15-35 Hz). See the mode table in [PHYSICS_TABLES.md](PHYSICS_TABLES.md).

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| Patterns lopsided / drifting to one side | Level the dish; check all exciters share the same polarity |
| Nothing appears | More volume (onset rises with frequency); try 30-50 Hz first |
| Chaos and droplets | Too much drive: back off until the pattern locks |
| Blurry wall image | Refocus the lens; use a smaller LED die; move the wall further away |
| Dull colours | Use colour LEDs (light), not dyed water; add the grating film |
| Water stains / film | Distilled water, change weekly, wipe the dish |
