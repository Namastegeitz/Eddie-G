#!/usr/bin/env python3
"""Synthesises Canopy Crossing's audio from data: one music loop per region
(from each map file's "music" block: tempo, root, scale, lead instrument,
drums, drone), a rainforest ambience bed, a menu theme and the SFX set.
Writes OGG Vorbis through ffmpeg.

Calm songs (the default music): a slow, soft piece per region and for the
menu, tuned to 528 Hz or 963 Hz (the region's "music.hz"). Every note is a
pure (just-intonation) ratio of that tone, with a quiet drone on the tone
itself, so the whole song sits on it. Pads, a sparse melody on the region's
instrument, a gentle arpeggio, light percussion and reverb; seamless loop.

    python3 tools/gen_audio.py            # everything
    python3 tools/gen_audio.py --maps     # only region music (after adding a map)
    python3 tools/gen_audio.py --calm     # only the calm songs
    python3 tools/gen_audio.py --check    # check the calm songs' tuning (decodes the OGGs)

A new region gets music by adding its map file and re-running this, or by
pointing its "music.file" at a recorded track.
"""
import glob, json, math, os, subprocess, sys, tempfile, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SR = 22050
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8,
        "A": 9, "A#": 10, "Bb": 10, "B": 11}
SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10], "lydian": [0, 2, 4, 6, 7, 9, 11], "phrygian_dominant": [0, 1, 4, 5, 7, 8, 10],
    "pentatonic_major": [0, 2, 4, 7, 9], "pentatonic_minor": [0, 3, 5, 7, 10],
}


# just-intonation ratios of each scale, from its tonic
JUST = {
    "major": [1, 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8],
    "minor": [1, 9 / 8, 6 / 5, 4 / 3, 3 / 2, 8 / 5, 9 / 5],
    "dorian": [1, 9 / 8, 6 / 5, 4 / 3, 3 / 2, 5 / 3, 9 / 5],
    "mixolydian": [1, 9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 9 / 5],
    "lydian": [1, 9 / 8, 5 / 4, 45 / 32, 3 / 2, 5 / 3, 15 / 8],
    "phrygian_dominant": [1, 16 / 15, 5 / 4, 4 / 3, 3 / 2, 8 / 5, 9 / 5],
    "pentatonic_major": [1, 9 / 8, 5 / 4, 3 / 2, 5 / 3],
    "pentatonic_minor": [1, 6 / 5, 4 / 3, 3 / 2, 9 / 5],
}
MAJ = [1, 5 / 4, 3 / 2]
MIN = [1, 6 / 5, 3 / 2]
# two four-chord progressions per family (chord root ratio, triad), for the
# first and second half of a calm song
PROG = {
    "major": ([(1, MAJ), (5 / 3, MIN), (4 / 3, MAJ), (1, MAJ)], [(1, MAJ), (4 / 3, MAJ), (5 / 3, MIN), (3 / 2, MAJ)]),
    "mixolydian": ([(1, MAJ), (16 / 9, MAJ), (4 / 3, MAJ), (1, MAJ)], [(1, MAJ), (4 / 3, MAJ), (16 / 9, MAJ), (1, MAJ)]),
    "minor": ([(1, MIN), (8 / 5, MAJ), (6 / 5, MAJ), (9 / 5, MAJ)], [(1, MIN), (4 / 3, MIN), (8 / 5, MAJ), (9 / 5, MAJ)]),
    "dorian": ([(1, MIN), (4 / 3, MAJ), (1, MIN), (9 / 5, MAJ)], [(1, MIN), (6 / 5, MAJ), (4 / 3, MAJ), (1, MIN)]),
    "phrygian_dominant": ([(1, MAJ), (16 / 15, MAJ), (1, MAJ), (4 / 3, MIN)], [(1, MAJ), (8 / 5, MAJ), (16 / 15, MAJ), (1, MAJ)]),
}
FAMILY = {"major": "major", "lydian": "major", "pentatonic_major": "major", "mixolydian": "mixolydian",
          "minor": "minor", "pentatonic_minor": "minor", "dorian": "dorian", "phrygian_dominant": "phrygian_dominant"}


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env(n, a=0.005, d=0.3, sustain=0.0, curve=4.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(a, 1e-4))
    dec = np.exp(-curve * np.maximum(0, t - a) / max(d, 1e-4))
    return e * (sustain + (1 - sustain) * dec)


def sine(f, n, phase=0.0):
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t + phase)


def karplus(f, n, bright=0.5, rng=None):
    rng = rng or np.random.default_rng(1)
    p = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, p)
    out = np.zeros(n)
    idx = 0
    damp = 0.996 - (1 - bright) * 0.01
    for i in range(n):
        out[i] = buf[idx]
        nxt = (idx + 1) % p
        buf[idx] = damp * 0.5 * (buf[idx] + buf[nxt])
        idx = nxt
    return out


def noise(n, rng, color="white"):
    w = rng.uniform(-1, 1, n)
    if color == "brown":
        b = np.cumsum(w)
        b -= np.convolve(b, np.ones(400) / 400, mode="same")
        return b / (np.max(np.abs(b)) + 1e-9)
    if color == "pink":
        return np.convolve(w, np.ones(6) / 6, mode="same")
    return w


def lowpass(x, cutoff):
    a = math.exp(-2 * math.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


# ------------------------------------------------------------------ instruments

def inst(name, f, dur, rng):
    n = int(dur * SR)
    if name == "marimba":
        return (sine(f, n) + 0.25 * sine(f * 4.0, n) * env(n, 0.001, 0.05)) * env(n, 0.002, 0.35)
    if name == "kalimba":
        return (sine(f, n) + 0.35 * sine(f * 5.4, n) * env(n, 0.001, 0.04) + 0.15 * sine(f * 2.0, n)) * env(n, 0.002, 0.6)
    if name == "gamelan":
        s = sine(f, n) + 0.5 * sine(f * 2.76, n) + 0.3 * sine(f * 5.4, n) + 0.4 * sine(f * 1.007, n)
        return s * env(n, 0.003, 1.2, curve=3.0) * 0.6
    if name in ("pluck", "valiha"):
        return karplus(f, n, 0.8 if name == "valiha" else 0.5, rng) * 0.9
    if name == "sitar":
        k = karplus(f, n, 0.9, rng)
        return np.tanh(k * 2.5) * 0.6
    if name in ("flute", "bansuri", "bamboo_flute"):
        t = np.arange(n) / SR
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.0 * t) * np.minimum(1, t * 3)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        s = np.sin(ph) + 0.15 * np.sin(2 * ph) + 0.05 * noise(n, rng) * (1.4 if name == "bamboo_flute" else 1.0)
        return s * env(n, 0.06, 0.8, sustain=0.6, curve=2.0) * 0.7
    return sine(f, n) * env(n, 0.005, 0.3)


def drum(kind, rng, accent=1.0):
    if kind == "shaker":
        n = int(0.06 * SR)
        return highpass(noise(n, rng), 3000) * env(n, 0.002, 0.03) * 0.35 * accent
    if kind in ("toms", "log_drum"):
        n = int(0.4 * SR)
        f0 = 130 if kind == "toms" else 210
        t = np.arange(n) / SR
        f = f0 * (1 + 0.6 * np.exp(-t * 30))
        s = np.sin(2 * np.pi * np.cumsum(f) / SR)
        if kind == "log_drum":
            s += 0.5 * np.sin(2 * np.pi * np.cumsum(f * 2.3) / SR)
        return s * env(n, 0.002, 0.18) * 0.8 * accent
    if kind == "tabla":
        n = int(0.35 * SR)
        t = np.arange(n) / SR
        f = 300 * (1 + 0.25 * np.exp(-t * 12))
        return (np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * noise(n, rng) * env(n, 0.001, 0.01)) * env(n, 0.001, 0.15) * 0.6 * accent
    if kind == "gong":
        n = int(1.2 * SR)
        return (sine(98, n) + 0.6 * sine(98 * 2.3, n) + 0.3 * sine(98 * 3.1, n)) * env(n, 0.01, 1.0, curve=3) * 0.35 * accent
    if kind == "clap":
        n = int(0.12 * SR)
        return highpass(noise(n, rng), 1200) * env(n, 0.001, 0.06) * 0.4 * accent
    if kind == "soft":
        n = int(0.3 * SR)
        return sine(90, n) * env(n, 0.005, 0.15) * 0.4 * accent
    n = int(0.3 * SR)
    return sine(100, n) * env(n, 0.005, 0.2) * 0.5


def add(buf, x, at):
    i = int(at * SR)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(x))
    buf[i:j] += x[: j - i]


def render_music(m, seed):
    rng = np.random.default_rng(seed)
    tempo = float(m.get("tempo", 100))
    beat = 60.0 / tempo
    bars = 8
    length = bars * 4 * beat
    tail = 2.0
    buf = np.zeros(int((length + tail) * SR))
    root = 48 + NOTE.get(m.get("root", "C"), 0)
    scale = SCALES.get(m.get("scale", "major"), SCALES["major"])
    lead = m.get("lead", "marimba")
    drums = m.get("drums", "shaker")
    minorish = 3 in scale[:3] or scale == SCALES["pentatonic_minor"]
    prog = [0, 5, 3, 4] if minorish else [0, 4, 5, 3]
    prog = [p % len(scale) for p in prog]

    def deg(d, octave=0):
        return root + 12 * octave + scale[d % len(scale)] + 12 * (d // len(scale))

    for bar in range(bars):
        chord = prog[bar % 4]
        t0 = bar * 4 * beat
        # bass
        for b in (0, 2):
            add(buf, inst("pluck", midi_hz(deg(chord) - 12), beat * 1.8, rng) * 0.5, t0 + b * beat)
        # pad / drone
        if m.get("drone"):
            n = int(4 * beat * SR)
            add(buf, (sine(midi_hz(root - 12), n) + 0.5 * sine(midi_hz(root - 5), n)) * 0.08 * env(n, 0.5, 4.0, sustain=0.8, curve=1), t0)
        else:
            for d in (0, 2, 4):
                n = int(4 * beat * SR)
                add(buf, sine(midi_hz(deg(chord + d, 1)), n) * 0.035 * env(n, 0.3, 3.0, sustain=0.5, curve=1.5), t0)
        # drums
        steps = 8
        for st in range(steps):
            tt = t0 + st * beat / 2
            if drums == "shaker":
                add(buf, drum("shaker", rng, 1.0 if st % 2 == 0 else 0.6), tt)
                if st in (0, 5):
                    add(buf, drum("soft", rng), tt)
            elif drums in ("toms", "log_drum", "tabla"):
                if st in (0, 3, 6) or (st == 7 and bar % 2):
                    add(buf, drum(drums, rng, 1.0 if st == 0 else 0.7), tt)
                if st % 2 == 1:
                    add(buf, drum("shaker", rng, 0.4), tt)
            elif drums == "gong":
                if st == 0 and bar % 2 == 0:
                    add(buf, drum("gong", rng), tt)
                if st % 2 == 0:
                    add(buf, drum("shaker", rng, 0.4), tt)
            elif drums == "clap":
                if st in (2, 6):
                    add(buf, drum("clap", rng), tt)
                add(buf, drum("shaker", rng, 0.35), tt)
            else:
                if st in (0, 4):
                    add(buf, drum("soft", rng), tt)
        # melody: a 2-bar motif repeated with variation
        motif_rng = np.random.default_rng(seed * 7 + (bar // 2) % 2)
        pos = 0.0
        while pos < 4 * beat - 1e-6:
            step = motif_rng.choice([0.5, 0.5, 1.0, 1.0, 1.5]) * beat
            if lead in ("flute", "bansuri", "bamboo_flute"):
                step = motif_rng.choice([1.0, 1.5, 2.0]) * beat
            if motif_rng.random() < 0.8:
                d = chord + int(motif_rng.choice([0, 2, 4, 1, 3, 5, 7]))
                add(buf, inst(lead, midi_hz(deg(d, 1 if lead != "gamelan" else 1)), min(step * 1.6, 2.0), rng) * 0.32, t0 + pos)
            pos += step
    # wrap the tail into the start for a seamless loop
    n_loop = int(length * SR)
    out = buf[:n_loop].copy()
    out[: len(buf) - n_loop] += buf[n_loop:]
    out = np.tanh(out * 1.2)
    return out / (np.max(np.abs(out)) + 1e-9) * 0.85


def render_ambience(seed=5, seconds=24.0):
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    bed = lowpass(noise(n, rng, "pink"), 900) * 0.25
    t = np.arange(n) / SR
    insects = sine(4200, n) * (0.5 + 0.5 * np.sin(2 * np.pi * 37 * t)) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.13 * t)) * 0.04
    bed += insects
    for i in range(14):
        at = rng.uniform(0, seconds - 1.0)
        dur = rng.uniform(0.15, 0.5)
        m = int(dur * SR)
        tt = np.arange(m) / SR
        f0 = rng.uniform(1800, 3600)
        f = f0 * (1 + rng.uniform(-0.4, 0.4) * tt / dur)
        call = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(m, 0.02, dur * 0.6) * rng.uniform(0.05, 0.12)
        reps = int(rng.integers(1, 4))
        for r in range(reps):
            add(bed, call, at + r * dur * 1.3)
    # seamless loop: crossfade the last second into the first
    fade = SR
    bed[:fade] = bed[:fade] * np.linspace(0, 1, fade) + bed[-fade:] * np.linspace(1, 0, fade)
    bed = bed[:-fade]
    return bed / (np.max(np.abs(bed)) + 1e-9) * 0.6


# ------------------------------------------------------------------ sfx

def mix(*xs):
    n = max(len(x) for x in xs if not np.isscalar(x))
    out = np.zeros(n)
    for x in xs:
        if np.isscalar(x):
            continue
        out[: len(x)] += x
    return out


def sfx(name, rng):
    def tone(f0, f1, dur, shape="sine", a=0.003, d=None):
        n = int(dur * SR)
        t = np.arange(n) / SR
        f = f0 * (f1 / f0) ** (t / dur)
        ph = 2 * np.pi * np.cumsum(f) / SR
        s = np.sin(ph) if shape == "sine" else np.sign(np.sin(ph)) * 0.6
        return s * env(n, a, d or dur * 0.5)

    if name == "hop":
        return tone(420, 760, 0.09) * 0.6
    if name == "land":
        return tone(180, 90, 0.08) * 0.6
    if name == "splash":
        n = int(0.5 * SR)
        x = lowpass(noise(n, rng), 2500) * env(n, 0.005, 0.25)
        return mix(x * 1.6, tone(500, 200, 0.2) * 0.2)
    if name == "collect":
        return np.concatenate([tone(1320, 1320, 0.07), tone(1760, 1760, 0.18)]) * 0.5
    if name == "combo":
        return np.concatenate([tone(880, 880, 0.06), tone(1175, 1175, 0.06), tone(1568, 1568, 0.16)]) * 0.4
    if name == "crush":
        n = int(0.35 * SR)
        return mix(tone(140, 50, 0.35) * 0.9, lowpass(noise(n, rng), 1500) * env(n, 0.001, 0.1) * 0.8)
    if name == "chomp":
        n = int(0.15 * SR)
        return np.concatenate([highpass(noise(n, rng), 800) * env(n, 0.001, 0.04), tone(300, 120, 0.15) * 0.6])
    if name == "burn":
        n = int(0.6 * SR)
        return highpass(noise(n, rng), 400) * env(n, 0.05, 0.3) * 0.6
    if name == "fall":
        return tone(900, 150, 0.6, d=0.6) * 0.5
    if name == "goal":
        notes = [523, 659, 784, 1047]
        return np.concatenate([tone(f, f, 0.12 if i < 3 else 0.5) for i, f in enumerate(notes)]) * 0.5
    if name == "tap":
        return tone(900, 700, 0.04) * 0.35
    if name in ("unlock", "results"):
        notes = [784, 988, 1175, 1568] if name == "unlock" else [523, 784, 659, 1047]
        return np.concatenate([inst("kalimba", f, 0.16, rng)[: int(0.16 * SR)] for f in notes[:-1]] + [inst("kalimba", notes[-1], 0.7, rng)]) * 0.6
    if name == "fail_jingle":
        return np.concatenate([inst("marimba", f, 0.2, rng) for f in (523, 466, 392)] + [inst("marimba", 330, 0.6, rng)]) * 0.5
    if name == "purchase":
        return np.concatenate([tone(1568, 1568, 0.08), tone(2093, 2093, 0.25)]) * 0.45
    if name == "shield":
        return tone(300, 900, 0.18) * 0.5
    if name in ("ability", "whoosh"):
        n = int(0.3 * SR)
        x = highpass(noise(n, rng), 800) * env(n, 0.08, 0.15)
        return mix(x * 0.6, tone(400, 1200, 0.3) * 0.25 if name == "ability" else 0)
    if name == "wind":
        n = int(0.9 * SR)
        return lowpass(noise(n, rng), 700) * env(n, 0.3, 0.5, curve=2) * 1.2
    if name == "mud":
        return tone(120, 60, 0.4) * 0.6
    if name == "bump":
        return tone(200, 150, 0.06) * 0.5
    if name == "respawn":
        return np.concatenate([tone(f, f, 0.08) for f in (659, 784, 988, 1319)]) * 0.35
    if name == "smash":
        n = int(0.4 * SR)
        return mix(lowpass(noise(n, rng), 2000) * env(n, 0.001, 0.12) * 1.2, tone(110, 60, 0.3) * 0.5)
    if name == "equip":
        return tone(600, 1200, 0.1) * 0.4
    if name == "swipe":
        n = int(0.15 * SR)
        return highpass(noise(n, rng), 2000) * env(n, 0.03, 0.06) * 0.4
    if name == "intro":
        return np.concatenate([inst("gamelan", f, 0.25, rng) for f in (392, 523)] + [inst("gamelan", 659, 0.9, rng)]) * 0.4
    return tone(440, 440, 0.1)


SFX_NAMES = ["hop", "land", "splash", "collect", "combo", "crush", "chomp", "burn", "fall", "goal", "tap", "unlock", "results",
             "fail_jingle", "purchase", "shield", "ability", "whoosh", "wind", "mud", "bump", "respawn", "smash", "equip", "swipe", "intro"]


# ------------------------------------------------------------------ calm songs

def _comb(x, d, g):
    y = x.copy()
    for i in range(d, len(x), d):
        j = min(len(x), i + d)
        y[i:j] += g * y[i - d:j - d]
    return y


def _allpass(x, d, g):
    y = np.zeros_like(x)
    y[:d] = -g * x[:d]
    for i in range(d, len(x), d):
        j = min(len(x), i + d)
        y[i:j] = -g * x[i:j] + x[i - d:j - d] + g * y[i - d:j - d]
    return y


def reverb(x, wet=0.32, size=1.0):
    # only the mids and highs go into the room: low notes and the drone stay
    # dry, so the room's own resonances never ring off-tune under the song
    xin = highpass(x, 260)
    combs = [int(v * size) for v in (558, 594, 638, 678, 712)]
    w = sum(_comb(xin, d, 0.84) for d in combs) / len(combs)
    w = lowpass(w, 3200)
    for d in (278, 222, 170):
        w = _allpass(w, d, 0.5)
    return x * (1 - wet) + w * wet * 1.6


def pad_tone(f, n):
    # a pair a hair either side of the note: a slow shimmer, centred on it
    t = np.arange(n) / SR
    a = np.sin(2 * np.pi * f * (1 + 0.0006) * t) + np.sin(2 * np.pi * f * (1 - 0.0006) * t)
    return 0.5 * a + 0.12 * np.sin(2 * np.pi * 2 * f * t)


def heartbeat(f, vol):
    """A soft, round low thump at f (the song's fifth below its floor)."""
    n = int(1.1 * SR)
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t) * env(n, 0.025, 0.7, curve=3.0) * vol * 0.5


def bowl(f, vol):
    """A singing bowl struck on the tone: harmonic partials, long ring."""
    n = int(5.0 * SR)
    t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * 2 * f * t) + 0.35 * np.sin(2 * np.pi * 3 * f * t) * env(n, 0.005, 1.5)
    return s * env(n, 0.01, 4.0, curve=2.2) * vol * 0.3


def calm_inst(name, f, dur, rng):
    n = int(dur * SR)
    t = np.arange(n) / SR
    if name in ("marimba", "soft_mallet"):
        return (np.sin(2 * np.pi * f * t) + 0.12 * np.sin(2 * np.pi * 4 * f * t) * env(n, 0.002, 0.04)) * env(n, 0.012, 1.1, curve=3.2)
    if name == "kalimba":
        return (np.sin(2 * np.pi * f * t) + 0.18 * np.sin(2 * np.pi * 5.4 * f * t) * env(n, 0.001, 0.05)) * env(n, 0.004, 1.3, curve=3.0)
    if name == "gamelan":
        s = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2.76 * f * t) * env(n, 0.002, 0.8) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
        return s * env(n, 0.006, 2.4, curve=2.6) * 0.7
    if name in ("pluck", "valiha", "sitar"):
        # a harp-like pluck from exact harmonics (a delay-line string would
        # round its pitch to whole samples and drift off the tone)
        out = np.zeros(n)
        for h, amp in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.06)):
            if f * h < SR / 2:
                out += amp * np.sin(2 * np.pi * f * h * t) * env(n, 0.003, 1.6 / h ** 0.7, curve=3)
        if name == "sitar":
            out += 0.15 * np.sin(2 * np.pi * f * 2 * t) * env(n, 0.05, 1.2, curve=2)   # a soft buzz of the octave
        return out * 0.55
    if name in ("flute", "bansuri", "bamboo_flute"):
        vib = 1 + 0.004 * np.sin(2 * np.pi * 4.6 * t) * np.minimum(1, t * 1.5)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        breath = lowpass(noise(n, rng), 2500) * 0.04
        return (np.sin(ph) + 0.1 * np.sin(2 * ph) + breath) * env(n, 0.18, 1.5, sustain=0.55, curve=1.6) * 0.65
    return np.sin(2 * np.pi * f * t) * env(n, 0.01, 1.0, curve=3)


def render_calm(m, seed, hz):
    """A slow, soft loop on `hz`: every pitch is hz x a just ratio x 2^k."""
    rng = np.random.default_rng(seed)
    tempo = float(np.clip(float(m.get("tempo", 96)) * 0.66, 58, 76))
    bars = 16
    base = float(hz)
    while base >= 220.0:
        base /= 2.0           # 528 -> 132, 963 -> 120.375: the song's floor
    # Loop length: a whole number of the floor tone's cycles that is also a
    # whole number of samples, so the drone runs on across the loop point
    # without a click (the tempo moves by a hair to fit).
    from fractions import Fraction
    fb_ = Fraction(base).limit_denominator(1000)
    unit = Fraction(1, 1) / fb_          # one cycle of the floor tone, in seconds
    k = 1
    while (unit * k * SR).denominator != 1:
        k += 1
    step_s = float(unit * k)
    length = round(bars * 4 * 60.0 / tempo / step_s) * step_s
    beat = length / (bars * 4)
    tail = 5.0
    buf = np.zeros(int(round((length + tail) * SR)))
    scale_name = m.get("scale", "pentatonic_major")
    scale = JUST.get(scale_name, JUST["pentatonic_major"])
    prog_a, prog_b = PROG[FAMILY.get(scale_name, "major")]
    lead = m.get("lead", "kalimba")
    drums = m.get("drums", "soft")
    # the scale over three octaves for the melody, centred on the tone itself
    mel_notes = sorted(set(base * 4 * r * 2 ** o for o in (-1, 0, 1) for r in scale))
    mel_notes = [f for f in mel_notes if base * 2.6 <= f <= base * 10.5]
    home = min(range(len(mel_notes)), key=lambda i: abs(mel_notes[i] - base * 4))
    mel_rng = np.random.default_rng(seed * 13 + 5)
    motifs = []
    for _ in range(2):
        idx = home + int(mel_rng.integers(-2, 3))
        motif = []
        pos = 0.0
        while pos < 8 * beat - 1e-6:
            step = float(mel_rng.choice([1.0, 1.5, 2.0, 2.0, 3.0])) * beat
            rest = mel_rng.random() < 0.28
            motif.append((pos, None if rest else idx, step))
            idx = int(np.clip(idx + int(mel_rng.choice([-2, -1, -1, 0, 1, 1, 2])), 0, len(mel_notes) - 1))
            pos += step
        motifs.append(motif)
    for bar in range(bars):
        half = bar // 8
        prog = prog_a if half == 0 else prog_b
        root_r, triad = prog[bar % 4]
        t0 = bar * 4 * beat
        chord = [root_r * r for r in triad]
        # bass: the chord root, low and round, once a bar (twice in the second half)
        fb = base * root_r
        while fb > base * 1.5:
            fb /= 2.0
        for b in ((0,) if half == 0 else (0, 2)):
            n = int(beat * 3.6 * SR)
            add(buf, np.sin(2 * np.pi * fb * np.arange(n) / SR) * env(n, 0.04, 2.4, curve=2.4) * 0.34, t0 + b * beat)
        # pad: the chord around the octave above the floor, slow swell
        n = int((4 * beat + 2.5) * SR)
        pad = np.zeros(n)
        for r in chord:
            f = base * 2 * r
            while f > base * 4.2:
                f /= 2.0
            pad += pad_tone(f, n)
        e = env(n, 1.4, 4 * beat + 1.0, sustain=0.75, curve=1.2)
        e *= np.clip((n - np.arange(n)) / (2.5 * SR), 0, 1)
        add(buf, pad * e * 0.05, t0)
        # melody: a two-bar motif, played in bars 3-8 and 11-16 with a rest
        # every fourth bar so it breathes
        if bar % 8 >= 2 and bar % 4 != 3:
            motif = motifs[half]
            off = (bar % 2) * 4 * beat
            for pos, idx, step in motif:
                if idx is None or not (off <= pos < off + 4 * beat):
                    continue
                f = mel_notes[idx]
                vol = 0.2 if lead not in ("flute", "bansuri", "bamboo_flute") else 0.16
                add(buf, calm_inst(lead, f, min(step * 1.8, 3.2), rng) * vol, t0 + pos - off)
        # arpeggio in the second half: soft kalimba on the chord, rising and falling
        if half == 1:
            tones = []
            for r in chord + [chord[0] * 2]:
                f = base * 4 * r
                while f > base * 9:
                    f /= 2.0
                tones.append(f)
            pattern = [0, 1, 2, 3, 2, 1, 0, 2]
            for k, pi in enumerate(pattern):
                add(buf, calm_inst("kalimba", tones[pi], 1.4, rng) * 0.075, t0 + k * beat / 2)
        # percussion: barely there, and pitched on the tone too
        if drums in ("shaker", "clap"):
            for st in range(4):
                add(buf, drum("shaker", rng, 0.28 if st % 2 == 0 else 0.16), t0 + st * beat + beat * 0.5)
        elif drums in ("toms", "log_drum", "tabla"):
            add(buf, heartbeat(base * 0.75, 0.55), t0)
            add(buf, heartbeat(base * 0.75, 0.3), t0 + 1.5 * beat)
        elif drums == "gong" and bar % 4 == 0:
            add(buf, bowl(base, 0.5), t0)
    wet = lowpass(reverb(buf, 0.34), 7000)
    n_loop = int(round(length * SR))
    out = wet[:n_loop].copy()
    out[: len(wet) - n_loop] += wet[n_loop:]
    # the tone itself, quietly underneath, breathing slowly, with its octaves
    # below: whole cycles over the loop, so it never breaks
    tt = np.arange(n_loop) / SR
    breathe = 0.75 + 0.25 * np.sin(2 * np.pi * tt / (length / 4))
    drone = 0.022 * np.sin(2 * np.pi * float(hz) * tt) + 0.04 * np.sin(2 * np.pi * base * tt) + 0.03 * np.sin(2 * np.pi * base * 2 * tt)
    out += drone * breathe
    out = np.tanh(out * 1.1)
    # level: a little quieter than the classic songs (about -20 dBFS), never over 0.8
    rms = np.sqrt(np.mean(out ** 2)) + 1e-9
    return out * min(0.1 / rms, 0.8 / (np.max(np.abs(out)) + 1e-9))


CALM_MENU = {"tempo": 100, "scale": "pentatonic_major", "lead": "kalimba", "drums": "soft"}
CALM_DIR = os.path.join(MUSIC_DIR, "calm")


def calm_songs():
    """(name, settings, hz, output path) for every calm song."""
    out = [("menu", CALM_MENU, 528, os.path.join(CALM_DIR, "menu.ogg"))]
    for f in sorted(glob.glob(os.path.join(ROOT, "content", "maps", "*.json"))):
        m = json.load(open(f))
        mus = m.get("music")
        if not mus or m.get("status", "available") != "available" or not mus.get("calm_file"):
            continue
        out.append((m["id"], mus, int(mus.get("hz", 528)), os.path.join(ROOT, mus["calm_file"].replace("res://", ""))))
    return out


def check_tuning():
    """Decodes each calm song and checks its strongest pitches all sit on its
    tone: each of the 12 loudest spectral peaks must be within 0.6 Hz (or
    0.15%) of hz x a just ratio of its scale x a power of two."""
    bad = 0
    for name, mus, hz, path in calm_songs():
        raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-f", "s16le", "-ac", "1", "-ar", str(SR), "-"],
                             capture_output=True, check=True).stdout
        x = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
        spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
        freqs = np.fft.rfftfreq(len(x), 1.0 / SR)
        band = (freqs > 60) & (freqs < 2400)
        sp = np.where(band, spec, 0)
        peaks = []
        for i in np.argsort(sp)[::-1]:
            if len(peaks) >= 12:
                break
            if all(abs(freqs[i] - p) > 3.0 for p in peaks):
                # refine with the neighbouring bins
                a, b, c = sp[i - 1], sp[i], sp[i + 1]
                d = 0.5 * (a - c) / (a - 2 * b + c) if (a - 2 * b + c) != 0 else 0.0
                peaks.append(freqs[i] + d * (freqs[1] - freqs[0]))
        scale_name = mus.get("scale", "pentatonic_major")
        ratios = list(JUST.get(scale_name, JUST["major"]))
        for prog in PROG[FAMILY.get(scale_name, "major")]:
            for root_r, triad in prog:
                ratios += [root_r * r for r in triad]
        ratios.append(3 / 4)   # the heartbeat
        grid = [hz * r * 2 ** k for r in ratios for k in range(-5, 3)]
        off = [p for p in peaks if min(abs(p - g) for g in grid) > max(0.6, p * 0.0015)]
        tone_bin = np.argmin(abs(freqs - hz))
        has_tone = sp[tone_bin - 2:tone_bin + 3].max() > 0.05 * sp.max()
        ok = not off and has_tone
        bad += 0 if ok else 1
        print("%-16s %3d Hz  %s  peaks %s%s" % (name, hz, "ok " if ok else "BAD", ", ".join("%.1f" % p for p in sorted(peaks)[:8]),
                                             ("  off-tune: " + ", ".join("%.1f" % p for p in off)) if off else ""))
    print("calm tuning check: %d songs, %d bad" % (len(calm_songs()), bad))
    return bad == 0


def write_ogg(path, x, quality=3):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.clip(x, -1, 1)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
    os.remove(wav_path)


def main():
    if "--check" in sys.argv:
        sys.exit(0 if check_tuning() else 1)
    if "--calm" in sys.argv or "--maps" not in sys.argv:
        for name, mus, hz, path in calm_songs():
            seed = sum(ord(c) for c in name) * 31 + int(hz)
            write_ogg(path, render_calm(mus, seed, hz), 2)
            print("calm", name, hz, "Hz", os.path.relpath(path, ROOT))
        if "--calm" in sys.argv:
            return
    only_maps = "--maps" in sys.argv
    for f in sorted(glob.glob(os.path.join(ROOT, "content", "maps", "*.json"))):
        m = json.load(open(f))
        mus = m.get("music")
        if not mus or m.get("status", "available") != "available":
            continue
        out = os.path.join(ROOT, mus["file"].replace("res://", ""))
        seed = sum(ord(c) for c in m["id"]) * 31
        write_ogg(out, render_music(mus, seed))
        print("music", os.path.relpath(out, ROOT))
    if only_maps:
        return
    write_ogg(os.path.join(MUSIC_DIR, "menu.ogg"), render_music({"tempo": 92, "root": "F", "scale": "pentatonic_major", "lead": "marimba", "drums": "shaker"}, 77))
    write_ogg(os.path.join(MUSIC_DIR, "ambience.ogg"), render_ambience())
    rng = np.random.default_rng(3)
    for n in SFX_NAMES:
        write_ogg(os.path.join(SFX_DIR, n + ".ogg"), sfx(n, rng), 4)
    print("sfx", len(SFX_NAMES))


if __name__ == "__main__":
    main()
