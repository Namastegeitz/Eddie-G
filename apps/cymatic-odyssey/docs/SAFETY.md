# Safety

Read this before building or running anything. Water, mains power, high voltage and flashing light don't mix well.

## 1. The EZ-100 Tesla coil: keep it dry and separate

Your EZ-100 is a small solid-state "music Tesla coil" (plasma arc speaker). It makes a high-voltage, high-frequency arc (thousands of volts) at the wire tip. It does **not** make useful mechanical vibration. The sound comes from the arc heating the air, not from anything moving.

| Hazard | Why it matters here | Rule |
|---|---|---|
| Water + high voltage | Water and wet surfaces conduct. An arc can track across a damp enclosure or into the liquid. That can shock you, destroy the coil and start a fire. | **Never put the coil in, on, under or next to the water chamber.** Keep it at least 50 cm away, in its own dry bay ([coil_bay_base.stl](../stl/hardware/coil_bay_base.stl)). |
| RF burns | Touching the arc or wire can cause deep RF burns even if it feels like a tingle. | Don't touch the tip while it's running. Switch off before adjusting. |
| Ozone and NOx | Arcs make ozone and nitrogen oxides. In a closed box they build up. | Never seal the coil in an airtight box. Run it in a ventilated space, in short sessions. |
| Fire | Arcs can ignite paper, dust and thin plastic, including PLA prints. | Keep 10 cm of clear air around the tip. Nothing printed touches the arc. |
| Medical implants | Strong RF fields can interfere with pacemakers and other implants. | No one with an implant near it. Post a sign in public settings. |
| Electronics | RF noise can upset the ESP32, the amplifier, phones and cameras. | Keep the coil and its cables away from the chamber electronics. |
| Overheating | Sellers say these units hit thermal protection at max power in music mode. | Medium power, short runs. |

**Business installs:** leave the coil out. An open-arc device in a space the public can reach is a liability you don't need. The water-and-light show stands on its own.

## 2. Electrical (the water chamber)

- **Low voltage only near water.** The chamber runs on a 24 V DC supply (an external "brick" with a UL/ETL listing). No mains wiring inside the enclosure.
- Plug the brick into a **GFCI/RCD-protected outlet**.
- Put the amplifier, LED driver and ESP32 **above or beside** the water, never below it. Add a drip tray under the dish (any spill lands in the tray, not on electronics).
- The exciters sit under the platform. Use an acrylic splash shield between the dish and the exciters, and conformal-coat or tape the exciter terminals.
- Fuse the 24 V line (5 A blade fuse). Use strain relief on every cable.
- Unplug before topping up, emptying or cleaning the dish.

## 3. Light and flicker (photosensitive epilepsy)

Flashing light between about **3 and 60 flashes per second** can trigger seizures in people with photosensitive epilepsy. The most provocative band is around 15-25 Hz. Large, bright, high-contrast or red flashes are the worst.

- The default system uses **steady light**. The moving pattern changes slowly, and the Voyage console keeps visible motion well under 3 Hz.
- **Stroboscopic "slow-motion" effects** (strobing the LED near the water's frequency) can fall right in the danger band. For example, a 30 Hz water wave needs a 30 Hz strobe. Only use strobe effects when the strobe frequency is **at least 70 Hz** (drive 140 Hz or more in Faraday mode), and **never in public spaces**.
- LED drivers must dim with PWM at **20 kHz or more**, or with analog (constant-current) dimming, so there is no invisible flicker either.
- Public venues: post a notice ("light effects in use") and keep the show slow.

## 4. Lasers (if you add any)

Don't, unless you know the rules. In the US, a laser light show device stronger than Class 2 needs an FDA/CDRH variance, and audience scanning is regulated. LEDs do everything this project needs.

## 5. Sound

Exciters at 15-60 Hz are mostly felt, not heard, but higher drive frequencies and square waves get loud. Keep the console volume low and the amplifier gain at the minimum that makes clean patterns. The console's limiter is a backstop, not hearing protection.

## 6. Water

- Distilled water plus **one drop** of dish soap per litre gives the sharpest patterns. Change it weekly.
- Don't add glitter, oils or dyes near the electronics. For colour, use light (gels, RGB LEDs), not dye.
- In homes with small children or pets, keep the chamber closed. The enclosure lid exists for a reason: it's an "enclosed chamber" in the safety sense, not just for looks.
- Glass dishes: borosilicate (Pyrex-type) only, inspected for chips.

## 7. Health claims

See [MARKET.md](MARKET.md#health-and-wellbeing-what-you-can-and-cant-say). Describe this as ambience and relaxation, not treatment.
