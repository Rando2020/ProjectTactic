"""Generate the battle_juice_v1 cue pack (original, synthesized, deterministic).

Three short one-shots used by ImpactJuice hit profiles:
  hit-whack.wav    sharp melee WHACK: noise crack + pitched body thump
  hit-thwip.wav    lighter ranged impact: high click + short tick
  ice-shatter.wav  crystalline shatter: bright inharmonic pings + glassy crackle

Stdlib only. Same xorshift32 approach as generate_zane_impact_audio.py so the
bytes are reproducible. Run from the repository root:

    python3 tools/generate_battle_juice_audio.py
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT_DIR = Path(__file__).resolve().parent.parent / "godot" / "assets" / "audio" / "battle_juice_v1"


class XorShift32:
    def __init__(self, seed: int) -> None:
        self.state = seed & 0xFFFFFFFF or 0x9E3779B9

    def next(self) -> float:
        x = self.state
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        self.state = x & 0xFFFFFFFF
        return (self.state / 0xFFFFFFFF) * 2.0 - 1.0


def env(t: float, attack: float, decay: float) -> float:
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) / decay)


def highpass(samples: list[float], cutoff: float) -> list[float]:
    rc = 1.0 / (2 * math.pi * cutoff)
    a = rc / (rc + 1.0 / RATE)
    out, prev_x, prev_y = [], 0.0, 0.0
    for x in samples:
        y = a * (prev_y + x - prev_x)
        out.append(y)
        prev_x, prev_y = x, y
    return out


def normalize(samples: list[float], peak: float = 0.89) -> list[float]:
    top = max(abs(s) for s in samples) or 1.0
    return [s / top * peak for s in samples]


def whack() -> list[float]:
    rng = XorShift32(0xA11CE)
    n = int(RATE * 0.22)
    noise = [rng.next() for _ in range(n)]
    crack = highpass(noise, 1800.0)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        freq = 190.0 * math.exp(-t * 14.0) + 70.0  # downward pitch sweep = weight
        phase += 2 * math.pi * freq / RATE
        body = math.sin(phase) * env(t, 0.002, 0.055)
        snap = crack[i] * env(t, 0.0005, 0.012)
        out.append(body * 0.85 + snap * 0.9)
    return normalize(out)


def thwip() -> list[float]:
    rng = XorShift32(0xB0B5)
    n = int(RATE * 0.12)
    crack = highpass([rng.next() for _ in range(n)], 3200.0)
    out = []
    for i in range(n):
        t = i / RATE
        tick = math.sin(2 * math.pi * 1450.0 * t) * env(t, 0.001, 0.018)
        out.append(tick * 0.6 + crack[i] * env(t, 0.0004, 0.008))
    return normalize(out, 0.8)


def shatter() -> list[float]:
    rng = XorShift32(0xC1CE)
    n = int(RATE * 0.55)
    crackle = highpass([rng.next() for _ in range(n)], 4500.0)
    # Inharmonic partials read as glass/ice rather than a musical note.
    pings = []
    for k in range(9):
        start = abs(rng.next()) * 0.16
        freq = 2200.0 + abs(rng.next()) * 4200.0
        decay = 0.04 + abs(rng.next()) * 0.09
        pings.append((start, freq, decay, 0.35 + abs(rng.next()) * 0.4))
    out = []
    for i in range(n):
        t = i / RATE
        s = 0.0
        for start, freq, decay, amp in pings:
            if t >= start:
                lt = t - start
                s += math.sin(2 * math.pi * freq * lt) * env(lt, 0.0008, decay) * amp
        grain = crackle[i] * env(t, 0.001, 0.07) * (0.6 + 0.4 * math.sin(t * 310.0))
        out.append(s * 0.55 + grain * 0.75)
    return normalize(out, 0.82)


def write(name: str, samples: list[float]) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / name
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))
    return path


def main() -> None:
    for name, fn in (("hit-whack.wav", whack), ("hit-thwip.wav", thwip), ("ice-shatter.wav", shatter)):
        print(write(name, fn()))


if __name__ == "__main__":
    main()
