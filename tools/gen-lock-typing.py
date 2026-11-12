#!/usr/bin/env python3
"""Synthesise the NIRULOCK typewriter clicks: lock-typing.ogg, -2, -3.

Original work, generated from scratch with the Python standard library
(no samples); ffmpeg with libvorbis encodes them like tools/gen-sounds.py
does (mono, 44.1 kHz, -q:a 6, no metadata). Deterministic: fixed seeds.

    python3 gen-lock-typing.py OUTDIR

Each click is a typebar strike: a very short band-passed noise snap (the
key hitting the platen), a damped low body (the carriage frame) and a faint
inharmonic metal ping. About 85 ms, peak -9 dBFS, fading to true zero, with
no leading silence. The three variants differ in seed, snap band, body pitch
and ping, so fast typing does not sound like a loop.
"""
import math
import os
import random
import struct
import subprocess
import sys
import tempfile
import wave

RATE = 44100
PEAK_DB = -9.0
LENGTH = 0.085

VARIANTS = {
    "lock-typing": dict(seed=11, snap=(2600.0, 1.1), body=172.0, ping=3170.0, ping_gain=0.10),
    "lock-typing-2": dict(seed=23, snap=(3100.0, 1.3), body=196.0, ping=3530.0, ping_gain=0.08),
    "lock-typing-3": dict(seed=37, snap=(2250.0, 1.0), body=154.0, ping=2890.0, ping_gain=0.12),
}


def bandpass(samples, centre, q):
    """RBJ biquad band-pass, constant 0 dB peak gain."""
    w = 2 * math.pi * centre / RATE
    alpha = math.sin(w) / (2 * q)
    b0, b1, b2 = alpha, 0.0, -alpha
    a0, a1, a2 = 1 + alpha, -2 * math.cos(w), 1 - alpha
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for x in samples:
        y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out.append(y)
    return out


def click(seed, snap, body, ping, ping_gain):
    rng = random.Random(seed)
    n = int(LENGTH * RATE)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(n)]
    snap_wave = bandpass(noise, *snap)
    # A second, brighter snap a hair later: the typebar and the platen.
    hi = bandpass(noise[::-1], snap[0] * 1.9, 2.0)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, i / (0.0004 * RATE))  # 0.4 ms, no leading silence
        s = snap_wave[i] * math.exp(-t / 0.0045) * 3.2
        s += hi[i] * math.exp(-max(0.0, t - 0.0012) / 0.0025) * 1.6 * (t >= 0.0012)
        s += math.sin(2 * math.pi * body * t + 0.6) * math.exp(-t / 0.014) * 0.55
        s += math.sin(2 * math.pi * body * 2.43 * t) * math.exp(-t / 0.008) * 0.18
        s += math.sin(2 * math.pi * ping * t) * math.exp(-t / 0.018) * ping_gain
        s += math.sin(2 * math.pi * ping * 1.47 * t) * math.exp(-t / 0.011) * ping_gain * 0.5
        out.append(s * attack)
    # Fade the last 25 ms to true zero.
    fade = int(0.025 * RATE)
    for i in range(fade):
        out[n - fade + i] *= 0.5 + 0.5 * math.cos(math.pi * (i + 1) / fade)
    out[-1] = 0.0
    peak = max(abs(v) for v in out)
    gain = 10 ** (PEAK_DB / 20) / peak
    return [v * gain for v in out]


def write(path, samples):
    fd, wav = tempfile.mkstemp(suffix=".wav")
    os.close(fd)
    try:
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(
                struct.pack("<h", int(round(max(-1.0, min(1.0, v)) * 32767))) for v in samples))
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-map_metadata", "-1",
                        "-c:a", "libvorbis", "-q:a", "6", path], check=True)
    finally:
        os.unlink(wav)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    for name, params in VARIANTS.items():
        write(os.path.join(out, name + ".ogg"), click(**params))


if __name__ == "__main__":
    main()
