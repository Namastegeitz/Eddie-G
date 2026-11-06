"""Synthesises every sound effect and the two music loops as WAV files.

    python3 tools/gen_audio.py            # writes assets/audio/*.wav

All sounds are made from scratch (sine/saw/noise + envelopes), so there are no
licensing questions. Looping files (engine, music) carry a WAV 'smpl' chunk so
Godot loops them automatically.
"""
import os
import struct
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, a=0.01, d=0.2, s=0.6, r=0.1, sec=None):
    """ADSR envelope over n samples (times in seconds)."""
    total = n / SR
    e = np.ones(n)
    ai, di, ri = int(a * SR), int(d * SR), int(r * SR)
    ai = max(ai, 1)
    e[:ai] = np.linspace(0, 1, ai)
    if di > 0:
        e[ai:ai + di] = np.linspace(1, s, len(e[ai:ai + di]))
        e[ai + di:] = s
    if ri > 0 and ri < n:
        e[-ri:] *= np.linspace(1, 0, ri)
    return e


def decay(n, k):
    return np.exp(-np.arange(n) / SR * k)


def sine(f, t):
    if np.isscalar(f):
        return np.sin(2 * np.pi * f * t)
    phase = np.cumsum(f) / SR * 2 * np.pi
    return np.sin(phase)


def saw(f, t):
    if np.isscalar(f):
        ph = (f * t) % 1.0
    else:
        ph = (np.cumsum(f) / SR) % 1.0
    return 2.0 * ph - 1.0


def square(f, t, duty=0.5):
    ph = (np.cumsum(f) / SR) % 1.0 if not np.isscalar(f) else (f * t) % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def noise(n):
    return rng.uniform(-1, 1, n)


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be an array."""
    y = np.zeros_like(x)
    c = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1.0 - np.exp(-2 * np.pi * c / SR)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def write(name, x, loop=False, gain=0.9):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    chunks = b""
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    chunks += b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(pcm)) + pcm
    if loop:
        n = len(x)
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, n - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    data = b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks
    with open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.write(data)
    print("wrote", name, "%.2fs" % (len(x) / SR))


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def main():
    os.makedirs(OUT, exist_ok=True)

    # Engine: 1 s seamless hum (all partials complete whole cycles in 1 s).
    t = t_axis(1.0)
    eng = (0.6 * saw(55, t) + 0.35 * sine(110, t) + 0.25 * square(82, t, 0.3) + 0.15 * sine(220, t)
           + 0.06 * sine(330, t) * sine(3, t))
    eng = lowpass(eng, 900.0)
    write("engine", eng, loop=True, gain=0.7)

    # UI / race cues.
    t = t_axis(0.16)
    write("count", sine(660, t) * env(len(t), 0.005, 0.05, 0.6, 0.06))
    t = t_axis(0.5)
    write("go", (sine(990, t) + 0.4 * sine(1485, t)) * env(len(t), 0.005, 0.1, 0.6, 0.25))
    t = t_axis(0.06)
    write("click", sine(1800, t) * decay(len(t), 60) + 0.3 * noise(len(t)) * decay(len(t), 120), gain=0.5)

    # Boost: rising filtered noise whoosh.
    t = t_axis(0.7)
    n = len(t)
    write("boost", lowpass(noise(n), np.linspace(400, 5000, n)) * env(n, 0.03, 0.2, 0.7, 0.35) + 0.3 * saw(np.linspace(110, 330, n), t) * env(n, 0.02, 0.1, 0.4, 0.3))

    # Energy pod: two bright chimes.
    t = t_axis(0.3)
    n = len(t)
    write("pod", mix(sine(1320, t) * decay(n, 14), np.concatenate([np.zeros(int(0.06 * SR)), sine(1760, t)[: n - int(0.06 * SR)] * decay(n - int(0.06 * SR), 14)])))

    # Crate: sparkly arpeggio.
    notes = [784, 988, 1175, 1568]
    parts = []
    for i, f in enumerate(notes):
        tt = t_axis(0.25)
        parts.append(np.concatenate([np.zeros(int(i * 0.05 * SR)), sine(f, tt) * decay(len(tt), 18)]))
    write("crate", mix(*parts))

    # Finish fanfare.
    seq = [(523, 0.0), (659, 0.12), (784, 0.24), (1047, 0.36), (784, 0.6), (1047, 0.72)]
    parts = []
    for f, start in seq:
        tt = t_axis(0.45)
        tone = (saw(f, tt) * 0.4 + sine(f, tt)) * env(len(tt), 0.01, 0.1, 0.5, 0.2)
        parts.append(np.concatenate([np.zeros(int(start * SR)), lowpass(tone, 3000.0)]))
    write("finish", mix(*parts))

    # Trick: rising whoop.
    t = t_axis(0.45)
    n = len(t)
    write("trick", sine(np.linspace(300, 1400, n), t) * env(n, 0.01, 0.1, 0.7, 0.15) + 0.2 * noise(n) * decay(n, 10))

    # Alarm: two-tone warble.
    t = t_axis(0.7)
    n = len(t)
    f = np.where((t * 8).astype(int) % 2 == 0, 880, 660)
    write("alarm", square(f.astype(float), t, 0.5) * 0.5 * env(n, 0.01, 0.1, 0.8, 0.1), gain=0.6)

    # Drift tier ping.
    t = t_axis(0.14)
    write("tier", sine(1200, t) * decay(len(t), 30))

    # Whoosh (near miss, slipstream).
    t = t_axis(0.45)
    n = len(t)
    write("whoosh", lowpass(noise(n), np.concatenate([np.linspace(300, 3000, n // 2), np.linspace(3000, 300, n - n // 2)])) * np.sin(np.linspace(0, np.pi, n)))

    # Hit: thud + crunch.
    t = t_axis(0.5)
    n = len(t)
    write("hit", sine(np.linspace(120, 40, n), t) * decay(n, 8) + 0.6 * lowpass(noise(n), 1800.0) * decay(n, 14))
    t = t_axis(0.18)
    n = len(t)
    write("bump", sine(np.linspace(90, 50, n), t) * decay(n, 20) + 0.3 * lowpass(noise(n), 900.0) * decay(n, 30))

    # Star Shard: magic cluster.
    parts = []
    for i, f in enumerate([1047, 1319, 1568, 2093, 2637]):
        tt = t_axis(0.6)
        parts.append(np.concatenate([np.zeros(int(i * 0.07 * SR)), sine(f, tt) * decay(len(tt), 7)]))
    write("shard", mix(*parts))

    # Items.
    t = t_axis(1.1)
    n = len(t)
    write("item_comet", sine(np.linspace(1800, 300, n), t) * env(n, 0.02, 0.3, 0.6, 0.2) * 0.6 + np.concatenate([np.zeros(int(0.8 * SR)), lowpass(noise(n - int(0.8 * SR)), 700.0) * decay(n - int(0.8 * SR), 8)]))
    t = t_axis(0.7)
    n = len(t)
    write("item_shield", mix(*[sine(f, t) * env(n, 0.05, 0.2, 0.6, 0.3) for f in (523, 784, 1047)]) * (0.7 + 0.3 * sine(18, t)))
    t = t_axis(0.6)
    n = len(t)
    write("item_rocket", lowpass(noise(n), np.linspace(800, 3500, n)) * env(n, 0.02, 0.15, 0.7, 0.25) + 0.4 * saw(np.linspace(180, 90, n), t) * decay(n, 4))
    t = t_axis(0.35)
    n = len(t)
    write("item_laser", (square(np.linspace(2600, 700, n), t, 0.3) * 0.5 + sine(np.linspace(3200, 900, n), t) * 0.5) * decay(n, 7))
    t = t_axis(0.7)
    n = len(t)
    write("item_emp", sine(np.linspace(90, 40, n), t) * decay(n, 6) + 0.35 * square(60 + 30 * sine(25, t), t, 0.5) * decay(n, 5) + 0.3 * lowpass(noise(n), 2500.0) * decay(n, 10))
    t = t_axis(0.9)
    n = len(t)
    write("item_nitro", lowpass(noise(n), np.linspace(1200, 6000, n)) * env(n, 0.02, 0.1, 0.8, 0.3) + 0.35 * saw(np.linspace(90, 260, n), t) * env(n, 0.02, 0.1, 0.6, 0.3))
    t = t_axis(0.35)
    n = len(t)
    write("item_mine", sine(np.linspace(160, 90, n), t) * decay(n, 15) + sine(1400, t) * np.where(t > 0.18, 1.0, 0.0) * decay(n, 12) * 0.4)
    t = t_axis(0.9)
    n = len(t)
    write("item_tractor", sine(220 + 40 * sine(12, t), t) * env(n, 0.05, 0.2, 0.8, 0.3) + 0.3 * sine(440, t) * env(n, 0.05, 0.2, 0.5, 0.3))

    t = t_axis(0.7)
    n = len(t)
    write("item_warp", sine(np.linspace(300, 2400, n), t) * env(n, 0.02, 0.15, 0.7, 0.25) * 0.6 + 0.4 * lowpass(noise(n), np.linspace(400, 5000, n)) * env(n, 0.05, 0.2, 0.5, 0.3))
    t = t_axis(0.6)
    n = len(t)
    write("item_decoy", square(880 + 120 * sine(30, t), t, 0.4) * env(n, 0.01, 0.1, 0.5, 0.3) * 0.5 + 0.3 * sine(1760, t) * (0.5 + 0.5 * square(14, t)) * decay(n, 6))
    t = t_axis(1.0)
    n = len(t)
    write("item_leech", sine(np.linspace(140, 420, n), t) * env(n, 0.05, 0.2, 0.8, 0.3) * 0.6 + 0.35 * sine(np.linspace(280, 840, n) + 20 * sine(9, t), t) * env(n, 0.05, 0.2, 0.6, 0.3))
    t = t_axis(1.0)
    n = len(t)
    write("item_well", sine(np.linspace(120, 35, n), t) * env(n, 0.05, 0.3, 0.8, 0.4) + 0.3 * lowpass(noise(n), 500.0) * env(n, 0.1, 0.3, 0.6, 0.4))
    t = t_axis(0.6)
    n = len(t)
    write("item_frost", lowpass(noise(n), np.linspace(6000, 2000, n)) * env(n, 0.01, 0.2, 0.4, 0.3) * 0.7 + mix(*[sine(f, t) * decay(n, 9) * 0.25 for f in (2093, 2637, 3136)]))
    t = t_axis(0.8)
    n = len(t)
    write("item_overcharge", saw(np.linspace(110, 440, n), t) * env(n, 0.02, 0.2, 0.7, 0.3) * 0.5 + 0.4 * lowpass(noise(n), np.linspace(1500, 7000, n)) * env(n, 0.02, 0.2, 0.6, 0.3))

    t = t_axis(0.7)
    n = len(t)
    write("item_flare", lowpass(noise(n), np.linspace(9000, 2500, n)) * env(n, 0.005, 0.25, 0.4, 0.4) * 0.8 + 0.35 * sine(np.linspace(1800, 600, n), t) * decay(n, 5))
    t = t_axis(0.6)
    n = len(t)
    write("item_chain", lowpass(noise(n), 6000.0) * (0.5 + 0.5 * square(38, t)) * env(n, 0.005, 0.1, 0.6, 0.3) * 0.7 + 0.3 * saw(np.linspace(900, 260, n), t) * decay(n, 7))
    t = t_axis(0.8)
    n = len(t)
    write("item_plasma", square(110 + 6 * sine(5, t), t, 0.3) * env(n, 0.05, 0.2, 0.7, 0.4) * 0.45 + 0.3 * lowpass(noise(n), 900.0) * env(n, 0.02, 0.3, 0.5, 0.4))
    t = t_axis(1.0)
    n = len(t)
    write("item_stasis", sine(np.linspace(220, 70, n), t) * (0.6 + 0.4 * sine(7, t)) * env(n, 0.05, 0.3, 0.7, 0.4) * 0.7)
    t = t_axis(0.8)
    n = len(t)
    write("item_cloak", sine(np.linspace(500, 1900, n) + 30 * sine(11, t), t) * env(n, 0.02, 0.3, 0.5, 0.4) * 0.5 + 0.3 * lowpass(noise(n), np.linspace(2000, 8000, n)) * env(n, 0.05, 0.3, 0.3, 0.4))
    t = t_axis(0.6)
    n = len(t)
    write("item_repulsor", sine(np.linspace(90, 28, n), t) * env(n, 0.005, 0.15, 0.6, 0.4) + 0.5 * lowpass(noise(n), np.linspace(4000, 300, n)) * decay(n, 8))

    t = t_axis(0.7)
    n = len(t)
    write("glide", lowpass(noise(n), np.linspace(500, 3500, n)) * env(n, 0.04, 0.25, 0.5, 0.4) * 0.6 + 0.3 * sine(np.linspace(240, 520, n), t) * env(n, 0.05, 0.3, 0.5, 0.35))

    # Music: two 16-beat synthwave loops built from a bass arpeggio, pad,
    # lead hook and drums.
    def song(bpm, bars, chords, lead, name, bright):
        beat = 60.0 / bpm
        total = int(round(bars * 4 * beat * SR))
        out = np.zeros(total)
        step = beat / 4  # 16th notes
        for bar in range(bars):
            root = chords[bar % len(chords)]
            for s16 in range(16):
                start = int(round((bar * 16 + s16) * step * SR))
                f = root * (2 if s16 % 4 == 2 else 1) * (1.5 if s16 % 8 == 6 else 1)
                tt = t_axis(step * 0.95)
                note = lowpass(saw(f / 2, tt), 900.0 + 600 * bright) * decay(len(tt), 9)
                out[start:start + len(note)] += 0.35 * note[: max(0, total - start)]
            # pad
            start = int(round(bar * 16 * step * SR))
            tt = t_axis(16 * step)
            pad = sum(sine(root * m, tt) for m in (1, 1.25, 1.5, 2.0)) * env(len(tt), 0.3, 0.5, 0.7, 0.4)
            out[start:start + len(pad)] += 0.08 * pad[: max(0, total - start)]
            # drums
            for b in range(4):
                ks = int(round((bar * 4 + b) * beat * SR))
                kt = t_axis(0.25)
                kick = sine(np.linspace(130, 45, len(kt)), kt) * decay(len(kt), 18)
                out[ks:ks + len(kick)] += 0.6 * kick[: max(0, total - ks)]
                hs = int(round((bar * 4 + b + 0.5) * beat * SR))
                ht = t_axis(0.06)
                hat = noise(len(ht)) * decay(len(ht), 70)
                out[hs:hs + len(hat)] += 0.12 * hat[: max(0, total - hs)]
                if b % 2 == 1:
                    sn = noise(int(0.2 * SR)) * decay(int(0.2 * SR), 22)
                    out[ks:ks + len(sn)] += 0.22 * lowpass(sn, 3500.0)[: max(0, total - ks)]
        # lead hook
        for i, (deg, start_b, dur_b) in enumerate(lead):
            start = int(round(start_b * beat * SR))
            tt = t_axis(dur_b * beat)
            f = deg
            tone = (square(f, tt, 0.25) * 0.3 + sine(f, tt) * 0.7) * env(len(tt), 0.01, 0.1, 0.6, 0.1)
            out[start:start + len(tone)] += 0.18 * lowpass(tone, 2500.0)[: max(0, total - start)]
        write(name, out, loop=True, gain=0.8)

    A, F, C, G, D, E = 110.0, 87.31, 130.81, 98.0, 146.83, 82.41
    song(100, 4, [A, F, C, G], [(440, 0, 1), (523, 1.5, 0.5), (659, 2, 2), (587, 4, 1), (523, 5.5, 0.5), (494, 6, 2),
                                (440, 8, 1), (523, 9.5, 0.5), (659, 10, 1.5), (784, 12, 1), (659, 13, 3)], "music_menu", 0)
    song(128, 8, [D, D, A, A, F, F, G, E], [(587, 0, 0.5), (698, 0.5, 0.5), (880, 1, 1), (784, 2.5, 0.5), (698, 3, 1),
                                            (587, 4, 0.5), (523, 4.5, 0.5), (587, 5, 2), (880, 8, 0.5), (988, 8.5, 0.5),
                                            (1047, 9, 1.5), (988, 11, 1), (880, 12, 2), (784, 16, 1), (698, 17, 1),
                                            (659, 18, 2), (587, 20, 1), (659, 21, 1), (698, 22, 2), (880, 24, 2),
                                            (784, 26, 2), (659, 28, 4)], "music_race", 1)


if __name__ == "__main__":
    main()
