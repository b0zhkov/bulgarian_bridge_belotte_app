"""Synthesizes the game's sound effects (CC0, made for this app).

Run: python3 tool/make_sounds.py  -> assets/sounds/*.wav (22.05 kHz, mono, 16-bit).
Soft and minimal: filtered noise for cards, sine/marimba-like tones for events.
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


# Card swish (deal): short airy band noise with a quick rise and fall.
n = bandnoise(0.11, 1800, 7000)
x = t(0.11)
save('deal', n * np.sin(np.pi * x / 0.11) ** 2, 0.35)

# Card play: soft tap = tiny noise click + low thump.
n = bandnoise(0.07, 600, 3500) * env(int(SR * 0.07), 0.001, 70)
thump = tone(170, 0.07, decay=45, harmonics=((1, 1.0),), attack=0.001)
save('play', n * 0.7 + thump * 0.8, 0.55)

# Trick collect: gentle longer slide with falling brightness.
d = 0.24
n1 = bandnoise(d, 900, 3000)
n2 = bandnoise(d, 3000, 6500)
x = t(d)
w = np.linspace(1, 0.1, len(x))
shape = np.sin(np.pi * x / d) ** 1.5
save('collect', (n1 + n2 * w) * shape, 0.32)

# Your turn: very quiet two-partial chime.
save('turn', tone(988, 0.45, decay=7, harmonics=((1, 1.0), (2.76, 0.12))), 0.18)

# Announcement / declaration: pleasant two-note marimba.
save('announce', seq([659.25, 987.77], 0.09, 0.32, decay=10,
                     harmonics=((1, 1.0), (4, 0.08))), 0.45)

# Belot: bright three-note arpeggio.
save('belot', seq([783.99, 987.77, 1318.5], 0.075, 0.3, decay=11,
                  harmonics=((1, 1.0), (4, 0.08))), 0.45)

# Contra: distinct low double knock (descending fourth), slightly reedy.
reedy = ((1, 1.0), (2, 0.35), (3, 0.25), (5, 0.1))
save('contra', seq([440, 329.63], 0.12, 0.26, decay=12, harmonics=reedy), 0.55)

# Recontra: three knocks, higher.
save('recontra', seq([587.33, 440, 587.33], 0.1, 0.24, decay=13, harmonics=reedy), 0.55)

# Deal result: made (outside) = rising major third; failed/hanging = soft falling.
save('deal_made', seq([523.25, 659.25, 783.99], 0.11, 0.42, decay=7), 0.4)
save('deal_failed', seq([493.88, 392.0], 0.16, 0.5, decay=6), 0.38)

# Match won / lost.
save('match_won', seq([523.25, 659.25, 783.99, 1046.5], 0.13, 0.7, decay=4.5,
                      harmonics=((1, 1.0), (2, 0.2), (3, 0.08))), 0.5)
save('match_lost', seq([392.0, 349.23, 293.66], 0.2, 0.7, decay=4.5), 0.42)

# Silent clip used to unlock web audio on the first tap.
save('silence', np.zeros(int(SR * 0.05)) + 1e-6, 0.0001)
