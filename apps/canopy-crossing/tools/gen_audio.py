#!/usr/bin/env python3
"""Synthesises Canopy Crossing's audio from data: one music loop per region
(from each map file's "music" block: tempo, root, scale, lead instrument,
drums, drone), a rainforest ambience bed, a menu theme and the SFX set.
Writes OGG Vorbis through ffmpeg.

    python3 tools/gen_audio.py            # everything
    python3 tools/gen_audio.py --maps     # only region music (after adding a map)

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
