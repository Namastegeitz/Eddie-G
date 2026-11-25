#!/usr/bin/env python3
"""Single source for Voyages (signal programs) and Themes (holidays & observances).

    python3 tools/content.py   -> catalog/content.json, docs/VOYAGES.md, docs/THEMES.md,
                                  and injects the data into console/index.html
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# step: seconds, drive Hz, second-tone ratio [p,q] or None, mix of tone B, pulse Hz (tone bursts),
#       breathe Hz (slow swell), mode, gobo, palette (3 light colours), narration
def S(t, f, ratio=None, mix=0.0, pulse=0.0, breathe=0.0, mode="faraday", gobo="none", pal=None, text=""):
    return dict(t=t, f=f, ratio=ratio, mix=mix, pulse=pulse, breathe=breathe, mode=mode, gobo=gobo,
                pal=pal or ["#7fd4ff", "#ffe9b0", "#b48cff"], text=text)


DEEP = ["#2b6cff", "#7fd4ff", "#b48cff"]
GOLD = ["#ffd27a", "#ff9f43", "#fff3d6"]
NEB = ["#ff5fa2", "#7a5cff", "#36e2ff"]
AUR = ["#36ffb0", "#2bd1ff", "#9b6bff"]
EMB = ["#ff6b3d", "#ffb347", "#ffe3a3"]

VOYAGES = [
    dict(id="departure", name="Departure: Earth Orbit", mood="calm opening, 6 min", steps=[
        S(60, 18, mode="dipper", pulse=0.5, breathe=0.1, pal=DEEP, text="Single drops of sound. Rings leave the centre like a launch countdown."),
        S(60, 24, mode="dipper", pulse=1.0, pal=DEEP, gobo="rings", text="Pulse quickens; concentric rings stack into an orbit map."),
        S(90, 36, pal=DEEP, text="Whole-dish drive: the first standing squares lock in."),
        S(90, 30, breathe=0.1, pal=AUR, text="Breathe with the swell - 6 breaths a minute."),
        S(60, 20, mode="dipper", pulse=0.25, pal=DEEP, text="Leaving orbit."),
    ]),
    dict(id="saturn", name="Saturn's Hexagon", mood="bold, geometric, 5 min", steps=[
        S(60, 40, ratio=[3, 2], mix=0.5, pal=GOLD, gobo="ngon:6", text="Two tones in 2:3 - the water prefers hexagons."),
        S(90, 48, ratio=[3, 2], mix=0.6, pal=GOLD, gobo="hex", text="A hexagonal jet stream, like the one Cassini filmed at Saturn's pole."),
        S(60, 56, ratio=[3, 2], mix=0.4, breathe=0.05, pal=EMB, text="Storm bands tighten."),
        S(90, 44, ratio=[2, 1], mix=0.5, pal=GOLD, gobo="star:6", text="Octave pair: triangles appear inside the hexagons."),
    ]),
    dict(id="quasicrystal", name="Quasicrystal Nebula", mood="mysterious, 7 min", steps=[
        S(90, 40, ratio=[5, 4], mix=0.6, pal=NEB, text="4:5 forcing - the 12-fold quasipattern Edwards & Fauve found in 1993. Order without repetition."),
        S(90, 42, ratio=[7, 6], mix=0.55, pal=NEB, gobo="flower", text="6:7 - superlattices: hexagons nested in hexagons."),
        S(90, 52, ratio=[5, 4], mix=0.7, breathe=0.07, pal=AUR, text="The nebula drifts; phase slips make the pattern rotate."),
        S(60, 60, pal=NEB, text="Single tone again: back to squares, the ground state of water."),
        S(90, 45, ratio=[5, 4], mix=0.6, pal=NEB, gobo="star:12", text="Return to twelve-fold."),
    ]),
    dict(id="pulsar", name="Pulsar", mood="energetic, 4 min", steps=[
        S(40, 30, mode="dipper", pulse=1.4, pal=["#ffffff", "#7fd4ff", "#ff5fa2"], text="A spinning neutron star: one ring per beat."),
        S(60, 40, mode="dipper", pulse=2.0, pal=["#ffffff", "#36e2ff", "#7a5cff"], gobo="radial", text="Two beats a second - rings collide with their echoes off the wall."),
        S(60, 50, mode="dipper", pulse=2.5, pal=NEB, text="Faster - interference lace."),
        S(80, 34, mode="dipper", pulse=0.8, breathe=0.1, pal=DEEP, text="Spin down."),
    ]),
    dict(id="venus", name="Venus Pentagram", mood="romantic, 5 min", steps=[
        S(90, 22, mode="dipper", pulse=0.6, pal=["#ff7aa8", "#ffd1dc", "#ffb347"], gobo="star:5", text="Earth and Venus line up five times in eight years, tracing a five-petalled rose. Use the pentagon insert."),
        S(90, 32, pal=["#ff7aa8", "#ffd1dc", "#b48cff"], gobo="ngon:5", text="Faraday drive inside a pentagon: the wall shape bends the squares into five-fold arcs."),
        S(90, 26, breathe=0.08, pal=["#ff7aa8", "#ffe9b0", "#ff9f43"], text="Slow swell."),
    ]),
    dict(id="hyperbolic", name="Hyperbolic Drift", mood="trippy, 6 min", steps=[
        S(60, 70, pal=AUR, gobo="hex", text="High drive: fine squares, tiles shrinking to the edge like an Escher circle."),
        S(120, 70, ratio=[7, 6], mix=0.3, breathe=0.05, pal=AUR, text="Slow beating between tones makes the lattice breathe in and out."),
        S(90, 90, pal=NEB, text="Finer still."),
        S(90, 55, ratio=[5, 4], mix=0.5, pal=AUR, text="Fold into twelve."),
    ]),
    dict(id="mandala", name="Inner Mandala", mood="introspective, 10 min", steps=[
        S(120, 20, mode="dipper", pulse=0.1, breathe=0.1, pal=GOLD, gobo="flower", text="Breathe in as the swell rises, out as it falls (6 per minute)."),
        S(120, 26, breathe=0.1, pal=GOLD, gobo="flower", text="Squares under the Flower of Life."),
        S(120, 33, ratio=[3, 2], mix=0.35, breathe=0.1, pal=EMB, gobo="star:8", text="Hexagons under an eight-point star."),
        S(120, 24, mode="dipper", pulse=0.1, breathe=0.083, pal=GOLD, gobo="rings", text="Slower: 5 breaths a minute."),
        S(120, 18, mode="dipper", pulse=0.05, breathe=0.083, pal=["#ffe9b0", "#ffd27a", "#ffffff"], text="Stillness. Let the last ring reach the wall."),
    ]),
    dict(id="golden", name="Golden Spiral Descent", mood="flowing, 5 min", steps=[
        S(45, 89, pal=GOLD, text="Frequencies fall by the golden ratio: 89..."),
        S(45, 55, pal=GOLD, text="55..."),
        S(45, 34, pal=EMB, text="34..."),
        S(45, 21, mode="dipper", pulse=0.618, pal=EMB, text="21, pulsing at 0.618 Hz..."),
        S(60, 13, mode="dipper", pulse=0.382, breathe=0.1, pal=GOLD, gobo="star:5", text="13. Fibonacci all the way down."),
    ]),
    dict(id="e8", name="E8 Singularity", mood="intense build, 5 min", steps=[
        S(40, 30, pal=DEEP, text="Low and wide."),
        S(40, 45, ratio=[5, 4], mix=0.4, pal=DEEP, text="Second tone enters."),
        S(40, 60, ratio=[5, 4], mix=0.6, pal=NEB, gobo="star:12", text="Density rises."),
        S(40, 80, ratio=[7, 6], mix=0.6, pal=NEB, gobo="radial", text="Thirty-fold E8 shadow on the gobo."),
        S(60, 100, ratio=[5, 4], mix=0.7, pal=["#ffffff", "#ff5fa2", "#36e2ff"], text="Peak: finest lattice the water can hold."),
        S(60, 24, mode="dipper", pulse=0.3, breathe=0.1, pal=DEEP, text="Release."),
    ]),
    dict(id="aurora", name="Aurora Ribbons", mood="dreamy, 6 min", steps=[
        S(90, 16, breathe=0.06, pal=AUR, text="Long slow waves - ribbons of green light."),
        S(90, 19, ratio=[2, 1], mix=0.3, breathe=0.06, pal=AUR, text="Ribbons fold."),
        S(90, 24, pal=["#36ffb0", "#ff5fa2", "#2bd1ff"], text="A pink curtain appears."),
        S(90, 14, mode="dipper", pulse=0.2, pal=AUR, text="Fade to night."),
    ]),
    dict(id="home", name="Return Home", mood="closing, 3 min", steps=[
        S(60, 28, pal=DEEP, text="Squares - the simplest standing wave."),
        S(60, 20, mode="dipper", pulse=0.5, pal=GOLD, gobo="rings", text="Rings."),
        S(60, 12, mode="dipper", pulse=0.2, breathe=0.1, pal=["#fff3d6", "#ffd27a", "#ffffff"], text="Splashdown."),
    ]),
]

# ------------------------------------------------------------------ themes
def T(id, name, when, palette, voyage, gobos, insert, mood, venues, line):
    return dict(id=id, name=name, when=when, palette=palette, voyage=voyage, gobos=gobos, insert=insert,
                mood=mood, venues=venues, line=line)


THEMES = [
    T("newyear", "New Year's Day", "Jan 1", ["#ffd27a", "#ffffff", "#b48cff"], "departure", ["Sunburst 36", "Golden spiral & Fibonacci squares"], "Insert circle (reference)", "fresh start, countdown rings", "bars, hotels, homes", "Ring in the year with light that ripples from the centre."),
    T("mlk", "Martin Luther King Jr. Day", "3rd Mon Jan", ["#ffffff", "#ffd27a", "#7fd4ff"], "mandala", ["Borromean rings", "Seed of Life"], "Insert circle (reference)", "reflection, unity", "schools, libraries, lobbies", "Unity made visible: three rings that only hold together as one."),
    T("lunar", "Lunar New Year", "late Jan-Feb (lunar)", ["#ff3d3d", "#ffd27a", "#ff9f43"], "saturn", ["Hankin 4.8.8 at 67.5 deg", "Petal mandala 12"], "Insert octagon", "prosperity, lanterns", "restaurants, retail windows", "Red and gold lattices that bloom like lanterns."),
    T("blackhistory", "Black History Month (US)", "February", ["#ffd27a", "#36ffb0", "#ff3d3d"], "mandala", ["Hankin 3.6.3.6 at 60 deg", "Sierpinski triangle"], "Insert hexagon", "heritage, pattern traditions", "museums, schools, offices", "Celebrates mathematical pattern traditions such as fractal design in African architecture (Eglash, 'African Fractals', 1999)."),
    T("valentine", "Valentine's Day", "Feb 14", ["#ff7aa8", "#ffd1dc", "#ff3d6b"], "venus", ["Cardioid", "Cardioid from circles", "Times table x2"], "Insert heart", "romance", "restaurants, date nights, spas", "Light-drawn hearts: the cardioid appears out of pure arithmetic."),
    T("pi", "Pi Day", "Mar 14", ["#7fd4ff", "#ffe9b0", "#ffffff"], "golden", ["Mystic rose K24", "Ford circles", "Apollonian gasket"], "Insert circle (reference)", "math joy", "schools, science centres, cafes", "3.14 reasons to love circles."),
    T("stpatrick", "St. Patrick's Day", "Mar 17", ["#36ff6b", "#ffd27a", "#ffffff"], "aurora", ["Superformula Clover 3", "Borromean rings"], "Insert superformula starfish", "festive green", "pubs, bars", "Shamrock-green ripples on every wall."),
    T("equinox_spring", "Spring Equinox / Nowruz", "~Mar 20", ["#36ffb0", "#ffd1dc", "#ffe9b0"], "golden", ["Sunflower phyllotaxis", "Petal mandala 16", "Fractal plant (L-system)"], "Insert wavy 8", "renewal, growth", "spas, garden centres, homes", "Day and night in balance; growth spirals in light."),
    T("holi", "Holi", "Phalguna full moon (Mar)", ["#ff3dd2", "#36e2ff", "#ffd23d"], "pulsar", ["Petal mandala 12", "Rose 7/1"], "Insert circle (reference)", "colour play", "community halls, events", "Three coloured lights, overlapping into every colour at once."),
    T("yuri", "Yuri's Night / Int'l Day of Human Space Flight", "Apr 12", ["#2b6cff", "#ffffff", "#ff5fa2"], "departure", ["Geocentric Mars", "Cosmic dance Earth-Mars"], "Insert circle (reference)", "space party", "planetariums, bars, schools", "Celebrate the first human in space with real orbital art."),
    T("earth", "Earth Day", "Apr 22", ["#36ffb0", "#2b6cff", "#ffe9b0"], "aurora", ["Sunflower phyllotaxis", "Water mode J6 ring 3"], "Insert circle (reference)", "nature, water", "offices, schools, retail", "Water and light only - a show with nothing to throw away."),
    T("easter", "Easter", "spring (varies)", ["#ffd1dc", "#c8f7c5", "#fff3b0"], "mandala", ["Vesica Piscis", "Flower of Life"], "Insert ellipse 1.5:1", "renewal, pastel", "churches, homes, brunch venues", "Soft pastel light, egg-shaped ripples."),
    T("passover", "Passover", "Nisan 15 (Mar-Apr)", ["#7fd4ff", "#ffffff", "#ffd27a"], "mandala", ["Hexagram (Star of David)", "Hankin 6.6.6 at 60 deg"], "Insert hexagon", "reflection, freedom", "homes, community centres", "Six-pointed geometry in calm blue and gold."),
    T("ramadan", "Ramadan / Eid al-Fitr", "lunar (varies)", ["#36e2ff", "#ffd27a", "#7a5cff"], "mandala", ["Hankin 4.6.12 at 60 deg", "Quasicrystal girih 5-fold at 72 deg", "Octagram {8/3}"], "Insert octagon", "night, lanterns, star patterns", "mosques' community halls, restaurants, homes", "Girih star patterns, the art tradition that anticipated quasicrystals by 500 years (Lu & Steinhardt, Science 2007)."),
    T("mayday", "Cinco de Mayo", "May 5", ["#36ff6b", "#ffffff", "#ff3d3d"], "pulsar", ["Petal mandala 16", "Sunburst 36"], "Insert wavy 12", "fiesta", "restaurants, bars", "Papel-picado colours, pulsing to the music."),
    T("mentalhealth", "Mental Health Awareness Month (US)", "May", ["#36ffb0", "#7fd4ff", "#ffffff"], "mandala", ["Seed of Life", "Pulse rings (J0)"], "Insert circle (reference)", "calm, breathing", "clinics' waiting rooms, offices, schools", "A breathing guide on the wall: swell in, swell out, 6 breaths a minute."),
    T("mothers", "Mother's Day (US)", "2nd Sun May", ["#ff7aa8", "#ffe9b0", "#b48cff"], "venus", ["Rose 5/1", "Petal mandala 8"], "Insert wavy 5", "gentle, floral", "restaurants, spas, homes", "Flowers drawn in light that never wilt."),
    T("memorial", "Memorial Day (US)", "last Mon May", ["#ffffff", "#2b6cff", "#ff3d3d"], "home", ["Pentagram", "Concentric rings"], "Insert pentagon", "remembrance, quiet", "civic spaces", "Quiet rings of remembrance."),
    T("pride", "Pride Month", "June", ["#ff3d3d", "#ffd23d", "#2b6cff"], "pulsar", ["Rose 7/1", "Petal mandala 12", "Times table x21"], "Insert circle (reference)", "joy, spectrum", "bars, retail, offices", "The whole spectrum, split by water and a diffraction film."),
    T("juneteenth", "Juneteenth", "Jun 19", ["#ff3d3d", "#36ff6b", "#ffd27a"], "departure", ["Sunburst 36", "Star polygon pentagram" if False else "Pentagram"], "Insert star {5/2}", "freedom, celebration", "community centres, museums", "A star of freedom rising out of rippling light."),
    T("fathers", "Father's Day (US)", "3rd Sun Jun", ["#2b6cff", "#ffe9b0", "#36e2ff"], "saturn", ["Truncated icosahedron", "Tiling 4.8.8"], "Insert square", "bold, playful", "bars, homes", "Geometry for the dad who has everything (except a hexagon storm)."),
    T("solstice_summer", "Summer Solstice / Int'l Day of Yoga", "~Jun 21", ["#ffd27a", "#ff9f43", "#fff3d6"], "golden", ["Sunburst 36", "Golden spiral & Fibonacci squares"], "Insert wavy 12", "sun, energy", "yoga studios, spas, rooftops", "Longest day: a sun of light on the studio wall."),
    T("july4", "Independence Day (US)", "Jul 4", ["#ff3d3d", "#ffffff", "#2b6cff"], "pulsar", ["Pentagram", "Sunburst 36", "Two-source interference"], "Insert star {5/2}", "fireworks", "bars, backyards, events", "Indoor fireworks: rings bursting in red, white and blue."),
    T("moon", "Moon Landing Day", "Jul 20", ["#ffffff", "#7fd4ff", "#b0b0c0"], "departure", ["Geocentric Venus", "Concentric rings"], "Insert circle (reference)", "space history", "planetariums, schools", "One small step, one ring at a time."),
    T("perseids", "Perseid Meteor Shower", "~Aug 12", ["#7a5cff", "#36e2ff", "#ffffff"], "aurora", ["Galaxy arms", "Archimedean spiral x3"], "Insert circle (reference)", "night sky", "rooftops, camps, bars", "Streaks of light across a midnight-blue wall."),
    T("labor", "Labor Day (US)", "1st Mon Sep", ["#2b6cff", "#ffd27a", "#ffffff"], "home", ["Tiling 6.6.6", "Hankin 6.6.6 at 60 deg"], "Insert hexagon", "honeycomb, teamwork", "offices, union halls", "The honeycomb: the strongest shape is built by many."),
    T("midautumn", "Mid-Autumn Festival", "Aug 15 lunar (Sep-Oct)", ["#ffd27a", "#ff9f43", "#ffffff"], "venus", ["Concentric rings", "Water mode J0 ring 4"], "Insert circle (reference)", "full moon, family", "restaurants, homes", "A full moon on the water, rippling."),
    T("diwali", "Diwali", "Kartika new moon (Oct-Nov)", ["#ffd27a", "#ff6b3d", "#ff3dd2"], "mandala", ["Nine-triangle yantra (simplified)", "Petal mandala 16", "Rose 8/1"], "Insert wavy 8", "festival of lights", "homes, restaurants, temples' halls", "Rangoli-inspired light mandalas."),
    T("spaceweek", "World Space Week", "Oct 4-10", ["#2b6cff", "#ff5fa2", "#36e2ff"], "quasicrystal", ["Cosmic dance Venus-Earth", "600-cell", "E8 root polytope"], "Insert circle (reference)", "science", "schools, museums, planetariums", "A week-long voyage through real orbits and higher dimensions."),
    T("halloween", "Halloween", "Oct 31", ["#ff7a00", "#7a5cff", "#36ff6b"], "hyperbolic", ["Hyperbolic {7,3}", "Julia set - Douady rabbit", "Heighway dragon"], "Insert Bunimovich stadium", "spooky, chaotic", "bars, haunted houses, homes", "Chaotic billiards and Julia sets: geometry that refuses to sit still."),
    T("diadelosmuertos", "Dia de los Muertos", "Nov 1-2", ["#ff7a00", "#ff3dd2", "#ffd23d"], "venus", ["Petal mandala 12", "Rose 5/2"], "Insert wavy 6", "marigolds, memory", "restaurants, community centres", "Marigold rosettes in light."),
    T("veterans", "Veterans Day / Remembrance Day", "Nov 11", ["#ff3d3d", "#ffffff", "#2b6cff"], "home", ["Pentagram", "Concentric rings"], "Insert pentagon", "honour, quiet", "civic spaces, offices", "Steady light, slow rings, a minute of stillness."),
    T("thanksgiving", "Thanksgiving (US)", "4th Thu Nov", ["#ff9f43", "#ffd27a", "#b5651d"], "golden", ["Sunflower phyllotaxis", "Golden spiral & Fibonacci squares"], "Insert wavy 8", "harvest, gratitude", "restaurants, homes", "Harvest spirals - the sunflower's golden angle."),
    T("hanukkah", "Hanukkah", "Kislev 25 (Nov-Dec)", ["#2b6cff", "#ffffff", "#7fd4ff"], "mandala", ["Hexagram (Star of David)", "Hankin 3.12.12 at 60 deg"], "Insert hexagon", "light, eight nights", "homes, community centres", "Eight nights, eight voyages, blue and white light."),
    T("solstice_winter", "Winter Solstice / World Meditation Day", "~Dec 21", ["#7fd4ff", "#ffffff", "#b48cff"], "mandala", ["Koch snowflake L5", "Water mode J6 ring 3"], "Insert Koch snowflake", "stillness, snow", "spas, yoga studios, homes", "Longest night: a slow snowflake meditation."),
    T("christmas", "Christmas", "Dec 25", ["#ff3d3d", "#36ff6b", "#ffd27a"], "aurora", ["Koch snowflake L3", "Hexagram (Star of David)" if False else "Octagram {8/3}", "Fractal plant (L-system)"], "Insert Koch snowflake", "festive, warm", "retail windows, restaurants, homes", "Snowflakes and stars that dance to carols."),
    T("kwanzaa", "Kwanzaa", "Dec 26-Jan 1", ["#ff3d3d", "#36ff6b", "#ffd27a"], "mandala", ["Heptagram {7/2}", "Heptagon nest"], "Insert heptagon", "seven principles", "community centres, homes", "Seven-fold geometry for seven principles."),
    T("nye", "New Year's Eve", "Dec 31", ["#ffd27a", "#ffffff", "#ff5fa2"], "e8", ["E8 root polytope", "Sunburst 36"], "Insert circle (reference)", "countdown, peak", "bars, clubs, events", "Count down with E8: 240 points of light at midnight."),
    T("birthday", "Birthdays (any day)", "any", ["#ff5fa2", "#ffd27a", "#36e2ff"], "pulsar", ["Rose 6/1", "Spirograph R7 r3 d2"], "Insert circle (reference)", "party", "homes, party venues", "A light show named after the guest of honour."),
    T("wedding", "Weddings & anniversaries", "any", ["#ffffff", "#ffd27a", "#ffd1dc"], "venus", ["Vesica Piscis", "Torus knot (2,3)"], "Insert ellipse 1.5:1", "union", "venues, hotels", "Two circles becoming one: the vesica piscis."),
]



# ------------------------------------------------------------------ 15 intertwined 10-minute shows
# Each show = opening (60 s) + 5 core styles (84 s each) + a guest style borrowed from another show (60 s)
# + a bridge (60 s) that turns into the NEXT show's opening, so all 15 chain into one 150-minute loop.
SHOW_PLAN = [
    ("genesis", "Genesis", "first light, slow awakening", "S01", ["S06", "S28", "S16", "S24", "S05"]),
    ("solarwinds", "Solar Winds", "warm, energetic", "S30", ["S17", "S20", "S22", "S12", "S15"]),
    ("saturn", "Saturn Rising", "bold, geometric", "S02", ["S21", "S11", "S12", "S26", "S09"]),
    ("venusmars", "Venus & Mars", "romantic, orbital", "S07", ["S24", "S28", "S06", "S23", "S17"]),
    ("quasicrystal", "Quasicrystal Dreams", "mysterious, never repeating", "S03", ["S04", "S27", "S10", "S12", "S29"]),
    ("sacred", "Sacred Geometry", "centred, devotional", "S05", ["S06", "S25", "S12", "S11", "S21"]),
    ("fractal", "Fractal Forest", "organic, self-similar", "S16", ["S13", "S15", "S14", "S28", "S24"]),
    ("hyperbolic", "Hyperbolic Deep", "infinite, trippy", "S08", ["S23", "S26", "S10", "S29", "S14"]),
    ("ocean", "Ocean of Waves", "pure physics, flowing", "S19", ["S20", "S21", "S18", "S22", "S01"]),
    ("aurora", "Aurora Borealis", "dreamy, shimmering", "S29", ["S17", "S04", "S08", "S30", "S13"]),
    ("nightgarden", "Night Garden", "lantern-lit star patterns", "S11", ["S12", "S25", "S05", "S03", "S02"]),
    ("fourthd", "Fourth Dimension", "hypnotic, higher-dimensional", "S26", ["S10", "S27", "S09", "S08", "S03"]),
    ("golden", "Golden Ratio", "harmonic, spiralling", "S24", ["S16", "S07", "S04", "S27", "S30"]),
    ("silence", "Inner Silence", "meditative, breath-paced", "S28", ["S06", "S13", "S19", "S05", "S01"]),
    ("supernova", "Supernova", "intense build and release", "S09", ["S02", "S12", "S26", "S27", "S10"]),
]


def build_shows():
    from styles import STYLES
    st = {x["id"]: x for x in STYLES}
    n = len(SHOW_PLAN)
    shows = []
    for i, (sid, name, mood, opening, core) in enumerate(SHOW_PLAN):
        nxt = SHOW_PLAN[(i + 1) % n]
        guest_show = SHOW_PLAN[(i + 6) % n]
        steps = []

        def step(style_id, t, role, text, fmul=1.0, breathe=None):
            x = st[style_id]
            steps.append(dict(t=t, f=round(x["f"] * fmul, 1), ratio=x["ratio"], mix=0.55 if x["ratio"] else 0.0,
                              pulse=x["pulse"], breathe=x["breathe"] if breathe is None else breathe, mode=x["mode"],
                              gobo="tex:" + style_id, pal=x["pal"], style=style_id, role=role, text=text))
        step(opening, 60, "opening", f"{name}: {st[opening]['name']}. {st[opening]['how']}", 0.92, 0.1)
        for k, c in enumerate(core):
            step(c, 84, "core", f"{st[c]['name']}. {st[c]['how']}", (1.0, 1.04, 0.97, 1.06, 1.0)[k])
        gs = next(c for c in [guest_show[3]] + guest_show[4] if c not in [opening] + core + [nxt[3]])
        step(gs, 60, "guest", f"Guest from {guest_show[1]}: {st[gs]['name']}.")
        step(nxt[3], 60, "bridge", f"Bridge: the light turns toward {nxt[1]}.", 0.92, 0.1)
        assert sum(s["t"] for s in steps) == 600
        shows.append(dict(id=sid, name=name, mood=mood, minutes=10, next=nxt[0], guest_from=guest_show[0],
                          insert=st[opening]["insert"], steps=steps))
    return shows


def build_assets(STYLES):
    import base64, io
    from PIL import Image
    from odyssey import catalog
    from render_wall import _gobo_mask
    ents = {e["name"]: e for e in catalog.entries()}
    out = {}
    for x in STYLES:
        folder = next((ROOT / "styles").glob(x["id"] + "_*"))
        th = Image.open(folder / "wall_preview.png").convert("RGB").resize((180, 180), Image.LANCZOS)
        b = io.BytesIO(); th.save(b, "JPEG", quality=78)
        m = (_gobo_mask(ents[x["gobo"]]["fn"](), 384) * 255).astype("uint8")
        b2 = io.BytesIO(); Image.fromarray(m).save(b2, "PNG", optimize=True)
        out[x["id"]] = dict(thumb="data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode(),
                            mask="data:image/png;base64," + base64.b64encode(b2.getvalue()).decode())
    return out


def main():
    from odyssey import catalog  # noqa
    names = {e["name"] for e in catalog.entries()}
    bad = [(t["id"], g) for t in THEMES for g in t["gobos"] + [t["insert"]] if g not in names]
    assert not bad, bad
    vids = {v["id"] for v in VOYAGES}
    assert all(t["voyage"] in vids for t in THEMES)
    from styles import STYLES
    SHOWS = build_shows()
    data = dict(voyages=VOYAGES, themes=THEMES, shows=SHOWS,
                styles=[{k: v for k, v in x.items()} for x in STYLES])
    (ROOT / "catalog").mkdir(exist_ok=True)
    (ROOT / "catalog/content.json").write_text(json.dumps(data, indent=1))
    # docs
    md = ["# Voyages", "", "Signal programs for the Voyage console. Each step sets the drive frequency, an optional second tone "
          "(ratio p:q), tone-burst pulsing, a slow 'breathing' swell, the drive mode, a suggested gobo and three light colours.", ""]
    for v in VOYAGES:
        md += [f"## {v['name']}", "", f"*{v['mood']}*", "", "| # | sec | mode | drive Hz | 2nd tone | pulse Hz | breathe Hz | narration |", "|---|---|---|---|---|---|---|---|"]
        for i, s in enumerate(v["steps"], 1):
            rt = f"{s['ratio'][0]}:{s['ratio'][1]} ({s['f'] * s['ratio'][0] / s['ratio'][1]:.1f} Hz, mix {s['mix']})" if s["ratio"] else "-"
            md.append(f"| {i} | {s['t']} | {s['mode']} | {s['f']} | {rt} | {s['pulse'] or '-'} | {s['breathe'] or '-'} | {s['text']} |")
        md.append("")
    (ROOT / "docs/VOYAGES.md").write_text("\n".join(md))
    md = ["# Themes for holidays and observances", "", "Each theme = light colours + a voyage + gobos + a boundary insert + a one-line pitch. "
          "Names in the gobo/insert columns match `catalog/geometry_catalog.csv`. Dates that move (lunar, 'third Monday') are given as rules.", "",
          "| When | Theme | Colours | Voyage | Gobos | Insert | Venues | Pitch |", "|---|---|---|---|---|---|---|---|"]
    vname = {v["id"]: v["name"] for v in VOYAGES}
    for t in THEMES:
        sw = " ".join(f"`{c}`" for c in t["palette"])
        md.append(f"| {t['when']} | **{t['name']}** ({t['mood']}) | {sw} | {vname[t['voyage']]} | {'; '.join(t['gobos'])} | {t['insert']} | {t['venues']} | {t['line']} |")
    (ROOT / "docs/THEMES.md").write_text("\n".join(md) + "\n")
    sn = {x["id"]: x["name"] for x in STYLES}
    md = ["# 15 light shows (10 minutes each, intertwined)", "",
          "Every show ends with a 60-second bridge that becomes the next show's opening, and each borrows a guest "
          "style from the show six places ahead. Play one, or press *Continuous* in the console to run all 15 "
          "(150 minutes) as one loop. Drive mode switches automatically when the platform is on the left amp "
          "channel and the dipper speaker on the right (see BUILD_SPECS). Gobo and insert swaps are optional cues.", ""]
    for sh in SHOWS:
        md += [f"## {sh['name']}", "", f"*{sh['mood']}* - insert for the whole show: **{sh['insert']}** - next: {next(x['name'] for x in SHOWS if x['id'] == sh['next'])}", "",
               "| time | role | style | mode | drive Hz | 2nd tone | pulse | breathe |", "|---|---|---|---|---|---|---|---|"]
        t = 0
        for x in sh["steps"]:
            rt = f"{x['ratio'][0]}:{x['ratio'][1]}" if x["ratio"] else "-"
            md.append(f"| {t // 60}:{t % 60:02d} | {x['role']} | {x['style']} {sn[x['style']]} | {x['mode']} | {x['f']} | {rt} | {x['pulse'] or '-'} | {x['breathe'] or '-'} |")
            t += x["t"]
        md.append("")
    (ROOT / "docs/SHOWS.md").write_text("\n".join(md))
    # inject into console (data + style thumbnails + gobo masks)
    html = ROOT / "console/index.html"
    if html.exists():
        assets = build_assets(STYLES)
        s = html.read_text()
        s = re.sub(r"/\*CONTENT\*/.*?/\*END\*/", lambda m: "/*CONTENT*/" + json.dumps(data) + "/*END*/", s, flags=re.S)
        s = re.sub(r"/\*ASSETS\*/.*?/\*END2\*/", lambda m: "/*ASSETS*/" + json.dumps(assets) + "/*END2*/", s, flags=re.S)
        html.write_text(s)
    print("voyages", len(VOYAGES), "themes", len(THEMES))


if __name__ == "__main__":
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    main()
