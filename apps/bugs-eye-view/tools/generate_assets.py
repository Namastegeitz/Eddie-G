#!/usr/bin/env python3
"""Generates Bug's-Eye View placeholder assets: procedural SFX/music (.wav,
with loop points for looping sounds) and app icons + splash (.png/.ico).

Run from the project root:  python3 tools/generate_assets.py
Replace any file in assets/ with real art/audio of the same name to reskin
the game without touching code.
"""
import math, os, struct, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX = os.path.join(ROOT, "assets", "sfx")
ICONS = os.path.join(ROOT, "assets", "icons")
RATE = 22050
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(RATE * dur)) / RATE


def env(n, attack=0.005, release=0.1, dur=None):
    t = np.arange(n) / RATE
    dur = dur or n / RATE
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    r = np.clip((dur - t) / max(release, 1e-4), 0, 1)
    return a * r


def noise(n):
    return rng.uniform(-1, 1, n)


def lowpass(x, cutoff):
    # one-pole low-pass
    a = math.exp(-2 * math.pi * cutoff / RATE)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def tone(freq, dur, kind="sine"):
    t = t_axis(dur)
    if callable(freq):
        phase = 2 * math.pi * np.cumsum(freq(t)) / RATE
    else:
        phase = 2 * math.pi * freq * t
    if kind == "square":
        return np.sign(np.sin(phase))
    if kind == "saw":
        return 2 * ((phase / (2 * math.pi)) % 1.0) - 1
    if kind == "tri":
        return 2 * np.abs(2 * ((phase / (2 * math.pi)) % 1.0) - 1) - 1
    return np.sin(phase)


def normalize(x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def write(name, x, loop=False, peak=0.85):
    x = normalize(np.asarray(x, dtype=np.float64), peak)
    if loop:  # short crossfade so the loop point is seamless
        f = min(int(RATE * 0.02), len(x) // 4)
        x[:f] = x[:f] * np.linspace(0, 1, f) + x[-f:] * np.linspace(1, 0, f)
        x = x[:-f]
    data = (x * 32767).astype("<i2").tobytes()
    path = os.path.join(SFX, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    if loop:  # append a RIFF 'smpl' chunk so Godot imports it as a loop
        frames = len(data) // 2
        smpl = struct.pack("<9I", 0, 0, int(1e9 / RATE), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, frames - 1, 0, 0)
        with open(path, "r+b") as f:
            f.seek(0, 2)
            f.write(b"smpl" + struct.pack("<I", len(smpl)) + smpl)
            size = f.tell() - 8
            f.seek(4)
            f.write(struct.pack("<I", size))


def formant_voice(dur, base, vowels, gain=1.0):
    """Very rough muffled 'giant voice': pulse train through vowel-ish filters."""
    t = t_axis(dur)
    pitch = base * (1 + 0.08 * np.sin(2 * math.pi * 3 * t))
    src = tone(lambda tt: base * (1 + 0.08 * np.sin(2 * math.pi * 3 * tt)), dur, "saw")
    out = np.zeros_like(src)
    seg = len(src) // len(vowels)
    for i, (f1, f2) in enumerate(vowels):
        s = src[i * seg:(i + 1) * seg]
        band = lowpass(s, f1) * 0.7 + lowpass(highpass(s, f2 * 0.7), f2) * 0.4
        out[i * seg:i * seg + len(band)] = band
    return lowpass(out, 900) * env(len(out), 0.03, 0.12) * gain


def build_sfx():
    os.makedirs(SFX, exist_ok=True)
    n = lambda d: int(RATE * d)
    write("crunch", highpass(noise(n(0.09)), 1500) * env(n(0.09), 0.001, 0.07) +
          0.5 * highpass(noise(n(0.09)), 3000) * (t_axis(0.09) > 0.04))
    write("golden", sum(tone(f, 0.5) * env(n(0.5), 0.005, 0.4) * (t_axis(0.5) > d)
                        for f, d in [(880, 0), (1108, 0.08), (1318, 0.16), (1760, 0.24)]))
    write("goal_open", tone(lambda t: 300 + 500 * t, 0.6, "tri") * env(n(0.6), 0.01, 0.3))
    write("hit", lowpass(noise(n(0.25)), 600) * env(n(0.25), 0.001, 0.2) + tone(90, 0.25) * env(n(0.25), 0.001, 0.2))
    write("squish", lowpass(noise(n(0.35)), 900) * env(n(0.35), 0.002, 0.3) * (1 + np.sin(2 * math.pi * 30 * t_axis(0.35))))
    write("dash", highpass(noise(n(0.18)), 2000) * env(n(0.18), 0.02, 0.12))
    write("skitter", highpass(noise(n(0.3)), 2500) * (np.sin(2 * math.pi * 40 * t_axis(0.3)) > 0.3) * env(n(0.3), 0.005, 0.1))
    write("push", lowpass(noise(n(0.2)), 400) * env(n(0.2), 0.01, 0.15))
    write("sense_on", tone(lambda t: 500 + 700 * t, 0.25) * env(n(0.25), 0.01, 0.15))
    write("slowmo", tone(lambda t: 700 - 500 * t, 0.6, "tri") * env(n(0.6), 0.01, 0.3) + 0.3 * lowpass(noise(n(0.6)), 300))
    write("web_shoot", highpass(noise(n(0.2)), 3000) * env(n(0.2), 0.002, 0.18) + 0.4 * tone(lambda t: 1500 - 3000 * t, 0.2))
    write("web_miss", tone(lambda t: 400 - 300 * t, 0.15, "square") * env(n(0.15), 0.002, 0.1) * 0.4)
    write("swoosh", lowpass(highpass(noise(n(0.35)), 300), 2500) * np.sin(np.pi * t_axis(0.35) / 0.35) ** 2)
    write("smack", highpass(noise(n(0.15)), 800) * env(n(0.15), 0.0005, 0.12) + 0.6 * tone(140, 0.15) * env(n(0.15), 0.0005, 0.1))
    write("thud", tone(lambda t: 70 - 30 * t, 0.45) * env(n(0.45), 0.002, 0.4) + 0.4 * lowpass(noise(n(0.45)), 200) * env(n(0.45), 0.001, 0.2))
    write("clang", sum(tone(f, 0.9) * np.exp(-t_axis(0.9) * k) for f, k in [(523, 4), (1250, 6), (2210, 9), (3170, 12)]))
    write("stun", sum(tone(f, 0.6) * env(n(0.6), 0.005, 0.5) * (t_axis(0.6) > d) for f, d in [(1200, 0), (900, 0.12), (1400, 0.24)]))
    write("squelch", lowpass(noise(n(0.4)), 700) * env(n(0.4), 0.01, 0.3) * (0.6 + 0.4 * np.sin(2 * math.pi * 12 * t_axis(0.4))))
    write("gurgle", lowpass(noise(n(0.8)), 500) * (0.5 + 0.5 * np.sin(2 * math.pi * 7 * t_axis(0.8))) * env(n(0.8), 0.05, 0.3))
    write("spray", highpass(noise(n(1.0)), 2500) * env(n(1.0), 0.05, 0.4))
    write("phone_buzz", tone(180, 0.7, "square") * (np.sin(2 * math.pi * 3 * t_axis(0.7)) > -0.2) * env(n(0.7), 0.01, 0.05) * 0.6)
    write("clatter", sum(highpass(noise(n(0.5)), 2000) * np.exp(-(t_axis(0.5) - d).clip(0) * 30) * (t_axis(0.5) > d)
                         for d in [0, 0.07, 0.15, 0.21, 0.3]) + 0.4 * tone(2600, 0.5) * np.exp(-t_axis(0.5) * 8))
    write("tv_blare", lowpass(noise(n(1.2)), 1500) * (0.5 + 0.5 * np.sin(2 * math.pi * 5 * t_axis(1.2))) + 0.5 * tone(330, 1.2, "saw") * 0.3)
    write("bark", formant_voice(0.22, 220, [(700, 1200)], 1.0) + lowpass(noise(n(0.22)), 1200) * env(n(0.22), 0.002, 0.15) * 0.6)
    write("growl", lowpass(tone(70, 0.8, "saw"), 400) * (0.6 + 0.4 * np.sin(2 * math.pi * 18 * t_axis(0.8))) * env(n(0.8), 0.1, 0.2))
    write("yelp", tone(lambda t: 900 - 600 * t, 0.25, "tri") * env(n(0.25), 0.005, 0.2))
    write("hiss", highpass(noise(n(0.7)), 3500) * env(n(0.7), 0.03, 0.3))
    write("meow", formant_voice(0.6, 420, [(600, 1800), (900, 1400), (500, 1000)], 1.0))
    write("voice_huh", formant_voice(0.5, 110, [(500, 1500), (650, 1100)]))
    write("voice_shout", formant_voice(0.7, 150, [(750, 1200), (600, 1000), (450, 900)]))
    write("voice_call", formant_voice(0.9, 130, [(300, 2200), (700, 1200), (400, 800)]))
    write("voice_ow", formant_voice(0.5, 170, [(700, 1100), (400, 800)]))
    write("voice_spray", formant_voice(0.6, 120, [(400, 900), (600, 1500)]) + 0.3 * highpass(noise(n(0.6)), 2500))
    write("boss_sting", sum(tone(f, 1.2, "saw") * env(n(1.2), 0.01, 0.8) for f in [110, 116.5, 164.8]) * 0.5)
    write("whoosh", lowpass(highpass(noise(n(0.25)), 600), 3000) * np.sin(np.pi * t_axis(0.25) / 0.25))
    write("win", sum(tone(f, 1.0, "tri") * env(n(1.0), 0.01, 0.6) * (t_axis(1.0) > d) for f, d in [(523, 0), (659, 0.12), (784, 0.24), (1046, 0.36)]))
    write("lose", sum(tone(f, 1.0, "tri") * env(n(1.0), 0.01, 0.6) * (t_axis(1.0) > d) for f, d in [(392, 0), (330, 0.18), (262, 0.36)]))
    write("ui_click", tone(1200, 0.04, "square") * env(n(0.04), 0.001, 0.03) * 0.4)
    # Loops
    hb = np.zeros(n(0.9))
    for d in (0.0, 0.22):
        seg = tone(55, 0.18) * env(n(0.18), 0.005, 0.15)
        s = int(d * RATE)
        hb[s:s + len(seg)] += seg
    write("heartbeat", hb, loop=True)
    t = t_axis(2.0)
    write("buzz", (tone(lambda tt: 190 + 12 * np.sin(2 * math.pi * 6 * tt), 2.0, "saw") * (0.7 + 0.3 * np.sin(2 * math.pi * 31 * t))), loop=True, peak=0.6)
    write("vacuum", lowpass(noise(n(2.0)), 900) * 0.8 + 0.3 * tone(120, 2.0, "saw"), loop=True, peak=0.6)
    write("fridge_hum", lowpass(tone(60, 3.0, "saw") + 0.3 * tone(120, 3.0), 300), loop=True, peak=0.5)
    write("tv_mumble", lowpass(noise(n(3.0)), 1200) * (0.4 + 0.6 * (np.sin(2 * math.pi * 2.3 * t_axis(3.0)) > 0)) * (0.6 + 0.4 * np.sin(2 * math.pi * 0.7 * t_axis(3.0))), loop=True, peak=0.5)
    write("dishwasher", lowpass(noise(n(3.0)), 600) * (0.7 + 0.3 * np.sin(2 * math.pi * 1.1 * t_axis(3.0))), loop=True, peak=0.5)
    write("sprinkler", highpass(noise(n(2.0)), 2000) * (0.5 + 0.5 * (np.sin(2 * math.pi * 4 * t_axis(2.0)) > 0)), loop=True, peak=0.5)
    write("fan", lowpass(noise(n(2.0)), 500) + 0.2 * tone(45, 2.0), loop=True, peak=0.5)
    # Ambient music: slow pads + soft plucks, 16 s loop.
    dur = 16.0
    t = t_axis(dur)
    pad = np.zeros_like(t)
    chords = [(110, 130.8, 164.8), (98, 123.5, 146.8), (87.3, 110, 130.8), (98, 123.5, 155.6)]
    for i, ch in enumerate(chords):
        s, e = int(i * 4 * RATE), int((i + 1) * 4 * RATE)
        seg = sum(tone(f, 4.0, "tri") + 0.5 * tone(f * 2, 4.0) for f in ch)
        pad[s:e] += seg[: e - s] * env(e - s, 0.8, 0.8)
    plucks = np.zeros_like(t)
    notes = [440, 523, 659, 587, 494, 440, 392, 523]
    for i, f in enumerate(notes * 2):
        s = int(i * 1.0 * RATE)
        seg = tone(f, 0.8) * np.exp(-t_axis(0.8) * 5)
        plucks[s:s + len(seg)] += seg[: len(plucks) - s]
    write("music_ambient", lowpass(pad, 1200) * 0.6 + plucks * 0.25, loop=True, peak=0.55)


def build_item_sfx():
    """Pickups: bug food, crumb gems and their powers."""
    os.makedirs(SFX, exist_ok=True)
    n = lambda d: int(RATE * d)
    # Two quick bites.
    bite = lowpass(noise(n(0.07)), 2200) * env(n(0.07), 0.001, 0.05)
    gap = np.zeros(n(0.05))
    write("munch", np.concatenate([bite, gap, bite * 0.8]))
    # Sparkly rising arpeggio with a shimmer tail.
    write("gem", sum(tone(f, 0.7) * env(n(0.7), 0.003, 0.55) * (t_axis(0.7) > d) * 0.8
                     for f, d in [(1047, 0), (1319, 0.06), (1568, 0.12), (2093, 0.18), (2637, 0.24)])
          + 0.15 * highpass(noise(n(0.7)), 6000) * env(n(0.7), 0.05, 0.6))
    write("powerup", tone(lambda t: 260 + 900 * t, 0.45, "tri") * env(n(0.45), 0.01, 0.15))
    write("freeze", tone(lambda t: 2400 - 1800 * t, 0.8) * env(n(0.8), 0.005, 0.6) * 0.6
          + 0.4 * highpass(noise(n(0.8)), 5000) * env(n(0.8), 0.01, 0.7))
    write("clink", tone(1900, 0.25) * np.exp(-t_axis(0.25) * 18) + 0.4 * tone(2850, 0.25) * np.exp(-t_axis(0.25) * 25))
    write("shield", (tone(660, 0.6) + 0.6 * tone(990, 0.6) + 0.3 * tone(1320, 0.6)) * np.exp(-t_axis(0.6) * 5))


def build_pet_sfx():
    """A dog snuffling along the ground."""
    os.makedirs(SFX, exist_ok=True)
    n = lambda d: int(RATE * d)
    puff = lowpass(highpass(noise(n(0.09)), 900), 3500) * env(n(0.09), 0.01, 0.06)
    gap = np.zeros(n(0.06))
    write("sniff", np.concatenate([puff, gap, puff * 0.8, gap, puff * 0.9]), peak=0.7)


def build_bug_sfx():
    """A cricket's chirp: three quick trills."""
    os.makedirs(SFX, exist_ok=True)
    n = lambda d: int(RATE * d)
    trill = tone(4400, 0.07) * (0.6 + 0.4 * np.sign(np.sin(2 * math.pi * 60 * t_axis(0.07)))) * env(n(0.07), 0.004, 0.02)
    gap = np.zeros(n(0.045))
    write("chirp", np.concatenate([trill, gap, trill, gap, trill]), peak=0.7)


def build_people_sfx():
    """Snoring for a napping person."""
    os.makedirs(SFX, exist_ok=True)
    n = lambda d: int(RATE * d)
    t = t_axis(1.3)
    breath = lowpass(noise(n(1.3)), 500) * (0.6 + 0.4 * np.sin(2 * math.pi * 38 * t))
    write("snore", breath * env(n(1.3), 0.35, 0.5), peak=0.6)


def build_npc_sfx():
    """Chores and pet habits: broom sweep, digging, lapping water, a light
    switch, a fridge door, a wet dog shaking off."""
    os.makedirs(SFX, exist_ok=True)
    n = lambda d: int(RATE * d)
    # Broom: a soft bristly swish.
    sw = lowpass(highpass(noise(n(0.42)), 1800), 6000)
    sw = sw * env(n(0.42), 0.12, 0.25)
    write("sweep", sw, peak=0.5)
    # Digging: gritty scrapes with a soft thump.
    parts = []
    for i in range(3):
        grit = lowpass(highpass(noise(n(0.11)), 400), 2500) * env(n(0.11), 0.005, 0.08)
        parts += [grit, np.zeros(n(0.05))]
    write("dig", np.concatenate(parts), peak=0.6)
    # Lapping water: quick wet clicks.
    parts = []
    for i in range(4):
        click = (tone(700 + i * 40, 0.035) * 0.5 + lowpass(noise(n(0.035)), 3000) * 0.5) * env(n(0.035), 0.002, 0.025)
        parts += [click, np.zeros(n(0.11))]
    write("lap", np.concatenate(parts), peak=0.55)
    # Light switch.
    write("switch", lowpass(noise(n(0.03)), 6000) * env(n(0.03), 0.001, 0.02) + tone(2200, 0.03) * 0.3 * env(n(0.03), 0.001, 0.02), peak=0.6)
    # Fridge door: a rubber-seal pop and a soft thump.
    pop = lowpass(noise(n(0.08)), 900) * env(n(0.08), 0.003, 0.06)
    thump = tone(90, 0.12) * env(n(0.12), 0.004, 0.1)
    write("door", np.concatenate([pop, np.zeros(n(0.04)), thump]), peak=0.6)
    # A dog shaking off: a burst of spray.
    spray = highpass(noise(n(0.6)), 2500) * env(n(0.6), 0.05, 0.3) * (0.6 + 0.4 * np.sin(2 * math.pi * 9 * t_axis(0.6)))
    write("shake", spray, peak=0.5)


def build_view_overlays():
    """Bug's-eye view overlays: a soft dark vignette (looking out from inside a
    tiny head) and compound-eye facets for flies, both clear in the middle."""
    from PIL import Image
    out = os.path.join(ROOT, "assets", "ui")
    os.makedirs(out, exist_ok=True)
    n = 512
    y, x = np.mgrid[0:n, 0:n].astype(float)
    u = (x - n / 2) / (n / 2)
    v = (y - n / 2) / (n / 2)
    r = np.sqrt(u * u + v * v)
    def smooth(a, b, t):
        k = np.clip((t - a) / (b - a), 0, 1)
        return k * k * (3 - 2 * k)
    # Vignette: warm dark edges.
    a = smooth(0.62, 1.25, r) * 0.75
    img = np.zeros((n, n, 4))
    img[..., 0], img[..., 1], img[..., 2] = 0.05, 0.035, 0.02
    img[..., 3] = a
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(out, "vignette.png"), optimize=True)
    # Compound eye: hexagonal facets that show towards the edges.
    s3 = math.sqrt(3.0)
    size = 26.0
    qx = (x * s3 / 3 - y / 3) / size
    qz = (y * 2 / 3) / size
    # Cube-round to the nearest hex centre, then distance to its edge.
    cx, cz = qx, qz
    cy = -cx - cz
    rx, ry, rz = np.round(cx), np.round(cy), np.round(cz)
    dx, dy, dz = np.abs(rx - cx), np.abs(ry - cy), np.abs(rz - cz)
    fixx = (dx > dy) & (dx > dz)
    fixy = (~fixx) & (dy > dz)
    rx = np.where(fixx, -ry - rz, rx)
    ry = np.where(fixy, -rx - rz, ry)
    rz = np.where(~fixx & ~fixy, -rx - ry, rz)
    # Exact distance to the cell's edge (pointy-top hexagon): 1.0 on an edge.
    hx = size * (s3 * rx + s3 / 2 * rz)
    hy = size * (1.5 * rz)
    qx = np.abs(x - hx)
    qy = np.abs(y - hy)
    d = np.maximum(qx, 0.5 * qx + s3 / 2 * qy) / (size * s3 / 2)
    line = smooth(0.86, 0.98, d)
    ring = smooth(0.7, 1.15, r)
    img = np.zeros((n, n, 4))
    img[..., 0] = 0.08 + 0.1 * line
    img[..., 1] = 0.05 + 0.04 * line
    img[..., 2] = 0.03
    img[..., 3] = np.clip(line * 0.45 * ring + smooth(0.85, 1.4, r) * 0.55, 0, 1)
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(out, "compound_eye.png"), optimize=True)


def build_icons():
    from PIL import Image, ImageDraw
    os.makedirs(ICONS, exist_ok=True)
    gold = (245, 194, 70, 255)
    ink = (14, 12, 10, 255)

    def bug(size, bg=True, pad=0.0):
        img = Image.new("RGBA", (size, size), ink if bg else (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        s = size
        p = pad * s
        cx, cy = s / 2, s * 0.58
        w = (s - 2 * p) * 0.22
        h = (s - 2 * p) * 0.29
        lw = max(2, int(s * 0.025))
        for k in (-1, 0, 1):  # legs
            y = cy + k * h * 0.45
            d.line([(cx - w * 0.6, y), (cx - w * 1.5, y + k * h * 0.25 - h * 0.1)], fill=gold, width=lw)
            d.line([(cx + w * 0.6, y), (cx + w * 1.5, y + k * h * 0.25 - h * 0.1)], fill=gold, width=lw)
        d.ellipse([cx - w, cy - h, cx + w, cy + h], fill=gold)
        d.ellipse([cx - w * 0.55, cy - h * 1.45, cx + w * 0.55, cy - h * 0.7], fill=gold)
        d.line([(cx, cy - h * 0.75), (cx, cy + h * 0.95)], fill=ink, width=lw)
        d.line([(cx - w * 0.2, cy - h * 1.4), (cx - w * 0.9, cy - h * 1.75)], fill=gold, width=lw)
        d.line([(cx + w * 0.2, cy - h * 1.4), (cx + w * 0.9, cy - h * 1.75)], fill=gold, width=lw)
        for ex in (-1, 1):  # big eye glints
            d.ellipse([cx + ex * w * 0.25 - s * 0.02, cy - h * 1.15 - s * 0.02,
                       cx + ex * w * 0.25 + s * 0.02, cy - h * 1.15 + s * 0.02], fill=ink)
        return img

    bug(1024).save(os.path.join(ICONS, "icon_1024.png"))
    bug(512).save(os.path.join(ICONS, "icon.png"))
    bug(192).save(os.path.join(ICONS, "icon_192.png"))
    bug(432, bg=False, pad=0.18).save(os.path.join(ICONS, "adaptive_foreground.png"))
    Image.new("RGBA", (432, 432), ink).save(os.path.join(ICONS, "adaptive_background.png"))
    bug(256).save(os.path.join(ICONS, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    splash = Image.new("RGBA", (1024, 1024), ink)
    splash.paste(bug(560, bg=False), (232, 120), bug(560, bg=False))
    d = ImageDraw.Draw(splash)
    try:
        from PIL import ImageFont
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 76)
    except Exception:
        font = None
    text = "BUG'S-EYE VIEW"
    if font:
        tw = d.textlength(text, font=font)
        d.text(((1024 - tw) / 2, 760), text, fill=gold, font=font)
    else:
        d.text((380, 800), text, fill=gold)
    splash.save(os.path.join(ICONS, "splash.png"))


if __name__ == "__main__":
    build_sfx()
    build_item_sfx()
    build_people_sfx()
    build_pet_sfx()
    build_bug_sfx()
    build_npc_sfx()
    build_view_overlays()
    build_icons()
    print("assets generated")
