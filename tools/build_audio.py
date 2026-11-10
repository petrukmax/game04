#!/usr/bin/env python3
"""Generate every WAV used by AudioManager with pure Python synthesis.

Run from the project root:  python tools/build_audio.py
No samples, plugins or downloads: each sound is synthesised from oscillators,
noise and envelopes so the game ships with fully original audio.
"""
from __future__ import annotations

import math
import random
import wave
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio"
RATE = 22050
TAU = math.tau


def clamp(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return low if value < low else high if value > high else value


def envelope(p: float, attack: float, release: float, power: float = 1.0) -> float:
    """Attack/release envelope where attack and release are fractions of length."""
    attack = max(attack, 0.0005)
    release = max(release, 0.0005)
    if p < attack:
        value = p / attack
    elif p > 1.0 - release:
        value = (1.0 - p) / release
    else:
        value = 1.0
    return clamp(value, 0.0, 1.0) ** power


def wave_shape(kind: str, phase: float) -> float:
    cycle = phase % TAU
    if kind == "sine":
        return math.sin(cycle)
    if kind == "square":
        return 1.0 if cycle < math.pi else -1.0
    if kind == "saw":
        return (cycle / math.pi) - 1.0
    if kind == "tri":
        return 1.0 - 4.0 * abs((cycle / TAU) - 0.5)
    return math.sin(cycle)


def sweep(
    start_hz: float,
    end_hz: float,
    duration: float,
    kind: str = "sine",
    volume: float = 0.5,
    attack: float = 0.005,
    release: float = 0.05,
    noise: float = 0.0,
    seed: int = 1,
    wobble: float = 0.0,
    curve: float = 1.0,
) -> list[float]:
    total = max(1, int(RATE * duration))
    rng = random.Random(seed)
    phase = 0.0
    out: list[float] = []
    for i in range(total):
        p = i / (total - 1)
        shaped = p ** curve
        hz = start_hz + (end_hz - start_hz) * shaped
        if wobble:
            hz *= 1.0 + wobble * math.sin(TAU * 7.0 * (i / RATE))
        phase += TAU * hz / RATE
        value = wave_shape(kind, phase)
        if noise > 0.0:
            value = value * (1.0 - noise) + rng.uniform(-1.0, 1.0) * noise
        value *= envelope(p, attack / duration, release / duration)
        out.append(value * volume)
    return out


def noise_burst(
    duration: float,
    volume: float = 0.5,
    lowpass: float = 0.35,
    attack: float = 0.004,
    release: float = 0.1,
    seed: int = 7,
    power: float = 1.0,
) -> list[float]:
    total = max(1, int(RATE * duration))
    rng = random.Random(seed)
    last = 0.0
    out: list[float] = []
    for i in range(total):
        p = i / (total - 1)
        raw = rng.uniform(-1.0, 1.0)
        last += (raw - last) * clamp(lowpass, 0.01, 1.0)
        value = last * envelope(p, attack / duration, release / duration, power)
        out.append(value * volume)
    return out


def silence(duration: float) -> list[float]:
    return [0.0] * max(1, int(RATE * duration))


def mix(*tracks: list[float]) -> list[float]:
    length = max((len(track) for track in tracks), default=0)
    out = [0.0] * length
    for track in tracks:
        for i, value in enumerate(track):
            out[i] += value
    return out


def pad(track: list[float], duration: float) -> list[float]:
    return track + [0.0] * max(0, int(RATE * duration) - len(track))


def sequence(*notes: tuple[float, float, float]) -> list[float]:
    """notes: (start_hz, end_hz, duration) played back to back."""
    out: list[float] = []
    for index, (start, end, duration) in enumerate(notes):
        out += sweep(start, end, duration, "tri", 0.42, 0.008, 0.08, seed=index + 3)
    return out


def write_wav(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max((abs(sample) for sample in samples), default=1.0) or 1.0
    gain = 0.92 / peak if peak > 0.92 else 1.0
    data = array("h", (int(clamp(sample * gain) * 32767) for sample in samples))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(data.tobytes())


def build() -> None:
    sounds: dict[str, list[float]] = {}

    # --- Interface ---------------------------------------------------------
    sounds["ui_click"] = sweep(940, 720, 0.055, "square", 0.30, release=0.03)
    sounds["ui_hover"] = sweep(1250, 1350, 0.035, "sine", 0.16, release=0.025)
    sounds["ui_confirm"] = sequence((620, 760, 0.07), (880, 1180, 0.1))
    sounds["ui_error"] = sequence((240, 190, 0.1), (190, 130, 0.12))
    sounds["ui_cancel"] = sweep(520, 300, 0.09, "tri", 0.28, release=0.05)

    # --- Construction and economy -----------------------------------------
    sounds["build"] = mix(
        noise_burst(0.16, 0.55, 0.16, release=0.13, seed=4),
        sweep(150, 70, 0.2, "sine", 0.5, release=0.12),
        pad(sweep(940, 760, 0.12, "tri", 0.16, release=0.1), 0.2),
    )
    sounds["upgrade"] = mix(
        sequence((480, 620, 0.07), (620, 820, 0.07), (820, 1120, 0.11)),
        pad(sweep(1500, 1900, 0.2, "sine", 0.08, release=0.15), 0.25),
    )
    sounds["sell"] = mix(
        sequence((780, 900, 0.06), (1030, 1300, 0.11)),
        pad(noise_burst(0.08, 0.14, 0.6, seed=9), 0.05),
    )

    # --- Tower weapons -----------------------------------------------------
    sounds["shot_kinetic"] = mix(
        noise_burst(0.06, 0.5, 0.8, release=0.05, seed=11),
        sweep(420, 150, 0.07, "square", 0.28, release=0.05),
    )
    sounds["shot_cannon"] = mix(
        noise_burst(0.22, 0.75, 0.12, release=0.18, seed=12),
        sweep(110, 44, 0.28, "sine", 0.7, release=0.2, noise=0.1, seed=13),
    )
    sounds["shot_flame"] = noise_burst(0.3, 0.45, 0.25, attack=0.03, release=0.25, seed=14, power=0.6)
    sounds["shot_tesla"] = mix(
        noise_burst(0.14, 0.35, 0.95, release=0.1, seed=15),
        sweep(1600, 240, 0.16, "saw", 0.28, release=0.12, wobble=0.35),
        pad(sweep(80, 60, 0.18, "sine", 0.2, release=0.15), 0.16),
    )
    sounds["shot_missile"] = mix(
        noise_burst(0.32, 0.3, 0.3, attack=0.03, release=0.22, seed=16),
        sweep(280, 900, 0.3, "tri", 0.22, attack=0.02, release=0.2),
    )
    sounds["shot_frost"] = mix(
        sweep(2100, 3200, 0.12, "sine", 0.22, release=0.1),
        pad(sweep(2600, 1800, 0.18, "tri", 0.14, release=0.14), 0.08),
        pad(noise_burst(0.16, 0.16, 0.9, seed=17), 0.1),
        silence(0.18),
    )
    sounds["shot_rail"] = mix(
        sweep(1800, 90, 0.2, "saw", 0.4, release=0.16, noise=0.12, seed=18),
        pad(noise_burst(0.22, 0.3, 0.85, seed=19), 0.15),
    )
    sounds["support_pulse"] = sweep(420, 560, 0.22, "sine", 0.22, attack=0.03, release=0.17)
    sounds["mine_deploy"] = mix(
        sequence((900, 900, 0.05), (1200, 1200, 0.05)),
        pad(noise_burst(0.14, 0.12, 0.5, seed=20), 0.08),
    )
    sounds["orbital_charge"] = mix(
        sweep(180, 1200, 0.8, "tri", 0.3, attack=0.25, release=0.1),
        pad(noise_burst(0.85, 0.18, 0.2, attack=0.4, release=0.12, seed=21), 0.8),
    )
    sounds["orbital_impact"] = mix(
        noise_burst(0.7, 0.8, 0.08, release=0.55, seed=22),
        sweep(90, 30, 0.8, "sine", 0.8, release=0.6, noise=0.15),
        pad(sweep(300, 60, 0.5, "saw", 0.25, release=0.45), 0.1),
    )

    # --- Enemies -----------------------------------------------------------
    sounds["enemy_spawn"] = mix(
        sweep(120, 210, 0.34, "saw", 0.24, attack=0.05, release=0.2, wobble=0.08),
        pad(noise_burst(0.34, 0.16, 0.2, attack=0.08, release=0.2, seed=23), 0.3),
    )
    sounds["enemy_hit"] = mix(
        noise_burst(0.05, 0.4, 0.55, release=0.04, seed=24),
        sweep(240, 140, 0.06, "square", 0.18, release=0.045),
    )
    sounds["enemy_death"] = mix(
        sweep(300, 55, 0.28, "saw", 0.34, release=0.22, noise=0.2, seed=25),
        pad(noise_burst(0.3, 0.32, 0.3, release=0.25, seed=26), 0.2),
    )
    sounds["shield_break"] = mix(
        noise_burst(0.32, 0.4, 0.95, release=0.26, seed=27),
        sweep(2800, 500, 0.3, "sine", 0.2, release=0.25, wobble=0.2),
        pad(sweep(160, 90, 0.2, "sine", 0.25, release=0.15), 0.18),
    )
    sounds["burrow"] = mix(
        noise_burst(0.4, 0.4, 0.1, attack=0.09, release=0.28, seed=28),
        sweep(90, 42, 0.44, "sine", 0.4, attack=0.06, release=0.3),
    )
    sounds["emerge"] = mix(
        noise_burst(0.4, 0.42, 0.14, attack=0.03, release=0.3, seed=29),
        sweep(42, 150, 0.4, "saw", 0.3, release=0.28, wobble=0.12),
    )
    sounds["boss_roar"] = mix(
        sweep(85, 38, 1.0, "saw", 0.55, attack=0.06, release=0.7, wobble=0.14, noise=0.1, seed=30),
        pad(noise_burst(1.05, 0.4, 0.09, attack=0.1, release=0.7, seed=31), 0.9),
        pad(sweep(170, 64, 0.8, "square", 0.18, attack=0.08, release=0.6, wobble=0.2), 0.2),
    )
    sounds["base_damage"] = mix(
        sweep(220, 140, 0.4, "square", 0.3, release=0.3, wobble=0.06),
        pad(sweep(160, 110, 0.55, "sine", 0.34, release=0.4), 0.16),
        pad(noise_burst(0.25, 0.3, 0.2, release=0.2, seed=32), 0.1),
    )

    # --- Wave flow ---------------------------------------------------------
    sounds["wave_start"] = mix(
        sweep(220, 320, 0.18, "saw", 0.32, release=0.1),
        pad(sweep(320, 440, 0.24, "saw", 0.3, release=0.16), 0.18),
        pad(sweep(440, 520, 0.3, "tri", 0.26, release=0.22), 0.4),
        pad(noise_burst(0.5, 0.12, 0.4, attack=0.05, release=0.35, seed=33), 0.2),
    )
    sounds["wave_complete"] = sequence(
        (660, 690, 0.09), (880, 900, 0.09), (1100, 1320, 0.22)
    )
    sounds["victory"] = sequence(
        (523, 540, 0.14), (659, 680, 0.14), (784, 810, 0.14), (1047, 1320, 0.5)
    )
    sounds["defeat"] = sequence((392, 370, 0.22), (330, 311, 0.22), (262, 196, 0.7))

    # --- Abilities ---------------------------------------------------------
    sounds["ability_emp"] = mix(
        sweep(90, 1400, 0.5, "saw", 0.3, attack=0.02, release=0.35, wobble=0.18),
        pad(noise_burst(0.55, 0.34, 0.85, release=0.4, seed=36), 0.2),
        pad(sweep(1400, 200, 0.35, "sine", 0.2, release=0.28), 0.32),
    )
    sounds["ability_strike"] = mix(
        sweep(1400, 180, 0.5, "sine", 0.32, attack=0.02, release=0.4),
        pad(noise_burst(0.4, 0.2, 0.3, attack=0.1, release=0.3, seed=37), 0.3),
    )
    sounds["ability_repair"] = sequence(
        (620, 640, 0.08), (830, 850, 0.08), (1040, 1240, 0.2)
    )
    sounds["ability_supply"] = sequence(
        (880, 900, 0.07), (1170, 1200, 0.07), (1560, 1900, 0.16)
    )
    sounds["drone_shot"] = mix(
        sweep(1500, 900, 0.06, "square", 0.2, release=0.045),
        pad(noise_burst(0.05, 0.16, 0.9, seed=38), 0.02),
    )

    # --- Ambience ----------------------------------------------------------
    duration = 8.0
    total = int(RATE * duration)
    rng = random.Random(41)
    low = 0.0
    ambient: list[float] = []
    for i in range(total):
        t = i / RATE
        # Whole-cycle frequencies so the loop point stays seamless.
        drone = (
            math.sin(TAU * 55.0 * t) * 0.16
            + math.sin(TAU * 82.5 * t) * 0.08
            + math.sin(TAU * 110.0 * t) * 0.05
        )
        drone *= 0.75 + 0.25 * math.sin(TAU * 0.125 * t)
        low += (rng.uniform(-1.0, 1.0) - low) * 0.02
        wind = low * (0.5 + 0.4 * math.sin(TAU * 0.25 * t + 1.2))
        shimmer = math.sin(TAU * 880.0 * t + math.sin(TAU * 0.5 * t)) * 0.012
        ambient.append(drone + wind * 0.35 + shimmer)
    sounds["ambient_mars"] = ambient

    for name, samples in sounds.items():
        write_wav(name, samples)
    print(f"Generated {len(sounds)} WAV files in {OUT}")


if __name__ == "__main__":
    build()
