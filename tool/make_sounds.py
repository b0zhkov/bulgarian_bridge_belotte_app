"""Synthesizes the game's sound effects (CC0, made for this app).

Run: python3 tool/make_sounds.py  -> assets/sounds/*.wav (22.05 kHz, mono, 16-bit).
Soft and minimal: a filtered-noise swoosh for card plays, sine/marimba-like
tones for the deal and match results.
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, attack=0.004, decay=8.0):
    x = np.arange(n) / SR
    a = np.clip(x / attack, 0, 1)
    return a * np.exp(-decay * x)


def bandnoise(d, lo, hi):
    n = int(SR * d)
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    spec[(f < lo) | (f > hi)] = 0
    y = np.fft.irfft(spec, n)
    return y / (np.abs(y).max() + 1e-9)


def tone(freq, d, decay=6.0, harmonics=((1, 1.0), (2, 0.18), (3, 0.06)), attack=0.006):
    x = t(d)
    y = sum(a * np.sin(2 * np.pi * freq * h * x) for h, a in harmonics)
    return y * env(len(x), attack, decay)


def seq(notes, gap, d, **kw):
    total = gap * (len(notes) - 1) + d
    out = np.zeros(int(SR * total) + 1)
    for i, f in enumerate(notes):
        s = tone(f, d, **kw)
        k = int(SR * gap * i)
        out[k:k + len(s)] += s
    return out


def fade_out(y, ms=15):
    n = int(SR * ms / 1000)
    y[-n:] *= np.linspace(1, 0, n)
    return y


def save(name, y, gain):
    y = fade_out(y / (np.abs(y).max() + 1e-9) * gain)
    data = (np.clip(y, -1, 1) * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# Card swoosh (a card is played): airy noise whose brightness sweeps up
# then down, quick rise and a soft tail, so it reads as a card sliding
# through the air onto the table.
d = 0.2
x = t(d)
bands = [(500, 1500), (1500, 3000), (3000, 5500), (5500, 9000)]
peaks = [0.06, 0.08, 0.095, 0.11]
y = np.zeros(len(x))
for (lo, hi), pk in zip(bands, peaks):
    y += bandnoise(d, lo, hi) * np.exp(-((x - pk) / 0.045) ** 2)
shape = np.clip(x / 0.012, 0, 1) * np.exp(-np.clip(x - 0.11, 0, None) * 18)
save('swoosh', y * shape, 0.42)

# Deal result: made (outside) = rising major third; failed/hanging = soft falling.
save('deal_made', seq([523.25, 659.25, 783.99], 0.11, 0.42, decay=7), 0.4)
save('deal_failed', seq([493.88, 392.0], 0.16, 0.5, decay=6), 0.38)

# Match won / lost.
save('match_won', seq([523.25, 659.25, 783.99, 1046.5], 0.13, 0.7, decay=4.5,
                      harmonics=((1, 1.0), (2, 0.2), (3, 0.08))), 0.5)
save('match_lost', seq([392.0, 349.23, 293.66], 0.2, 0.7, decay=4.5), 0.42)
