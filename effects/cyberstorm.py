"""Custom per-key Cyberstorm animation for a QMK/OpenRGB GMMK Pro."""

import argparse
import colorsys
import math
import os
import random
import sys
import time

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO_ROOT, ".runtime"))

from openrgb import OpenRGBClient
from openrgb.utils import RGBColor


# QMK reports the LEDs in PCB-chain order. These coordinates map the 82 key
# LEDs back to approximate physical locations on the ANSI keybed.
KEY_POSITIONS = [
    (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
    (2, 0), (1, 1), (1.5, 2), (1.75, 3), (2.25, 4), (1.25, 5),
    (3, 0), (2, 1), (2.5, 2), (2.75, 3), (3.25, 4), (2.5, 5),
    (4, 0), (3, 1), (3.5, 2), (3.75, 3), (4.25, 4),
    (5, 0), (4, 1), (4.5, 2), (4.75, 3), (5.25, 4),
    (6.5, 0), (5, 1), (5.5, 2), (5.75, 3), (6.25, 4), (6.5, 5),
    (7.5, 0), (6, 1), (6.5, 2), (6.75, 3), (7.25, 4),
    (8.5, 0), (7, 1), (7.5, 2), (7.75, 3), (8.25, 4),
    (9.5, 0), (8, 1), (8.5, 2), (8.75, 3), (9.25, 4), (10.25, 5),
    (11, 0), (9, 1), (9.5, 2), (9.75, 3), (10.25, 4), (11.25, 5),
    (12, 0), (10, 1), (10.5, 2), (10.75, 3), (11.25, 4),
    (13, 0), (11, 1), (11.5, 2), (11.75, 3), (12.5, 5),
    (14, 0), (15, 0), (15, 1), (15, 2), (12, 1), (16, 5),
    (15, 4), (13.5, 1), (15, 3), (12.5, 2), (13, 4), (13.5, 2),
    (15, 3.9), (14, 5), (13, 3), (15, 5),
]


def clamp(value, low=0.0, high=1.0):
    return max(low, min(high, value))


def plasma_color(x, y, t, seed_phase):
    field = (
        math.sin(x * 0.78 + t * 1.7)
        + math.sin(y * 1.55 - t * 2.15)
        + math.sin((x + y) * 0.53 + t * 1.1)
    ) / 3.0
    blend = 0.5 + 0.5 * field
    hue = (0.51 + 0.39 * blend) % 1.0

    core_x = 8.0 + 6.0 * math.cos(t * 0.73)
    core_y = 2.55 + 2.1 * math.sin(t * 1.07)
    distance = math.sqrt(((x - core_x) / 2.4) ** 2 + ((y - core_y) / 1.3) ** 2)
    core = math.exp(-(distance * distance))

    sparkle_wave = 0.5 + 0.5 * math.sin(t * 4.8 + seed_phase)
    sparkle = sparkle_wave**18
    value = clamp(0.24 + 0.48 * (0.5 + 0.5 * field) + 0.50 * core + 0.72 * sparkle)
    saturation = clamp(0.96 - 0.62 * core - 0.75 * sparkle, 0.12, 1.0)
    red, green, blue = colorsys.hsv_to_rgb(hue, saturation, value)
    return RGBColor(int(red * 255), int(green * 255), int(blue * 255))


def underglow_color(index, t):
    phase = (index / 16.0 - t * 0.42) % 1.0
    reverse = (index / 16.0 + t * 0.27 + 0.5) % 1.0
    trail_a = math.exp(-((min(phase, 1.0 - phase)) / 0.11) ** 2)
    trail_b = math.exp(-((min(reverse, 1.0 - reverse)) / 0.09) ** 2)
    pulse = 0.15 + 0.85 * max(trail_a, trail_b)
    hue = 0.50 if trail_a >= trail_b else 0.91
    red, green, blue = colorsys.hsv_to_rgb(hue, 0.94, pulse)
    return RGBColor(int(red * 255), int(green * 255), int(blue * 255))


def run(frame_limit=0, fps=24.0, sync_rival=True):
    client = OpenRGBClient(name="GMMK Cyberstorm")
    matches = [device for device in client.devices if "GMMK Pro" in device.name]
    if not matches:
        raise RuntimeError("GMMK Pro was not found by the OpenRGB SDK server")

    keyboard = matches[0]
    keyboard.set_custom_mode()
    led_count = len(keyboard.leds)
    if led_count < 82:
        raise RuntimeError(f"Expected at least 82 GMMK LEDs, found {led_count}")

    mouse_matches = [device for device in client.devices if "Rival 310" in device.name]
    mouse = mouse_matches[0] if sync_rival and mouse_matches else None
    if mouse is not None:
        mouse.set_custom_mode()

    rng = random.Random(0x5044)
    sparkle_phases = [rng.uniform(0.0, math.tau) for _ in range(82)]
    frame_period = 1.0 / fps
    start = time.perf_counter()
    frame = 0

    while frame_limit <= 0 or frame < frame_limit:
        deadline = start + frame * frame_period
        now = time.perf_counter()
        if now < deadline:
            time.sleep(deadline - now)
        t = time.perf_counter() - start

        colors = [
            plasma_color(x, y, t, sparkle_phases[index])
            for index, (x, y) in enumerate(KEY_POSITIONS)
        ]
        colors.extend(underglow_color(index, t) for index in range(led_count - 82))
        keyboard.set_colors(colors, fast=True)

        if mouse is not None:
            mouse_colors = [
                plasma_color(
                    8.0 + 5.4 * math.cos(t * 0.73 + led_index * math.pi),
                    2.5 + 1.9 * math.sin(t * 1.07 + led_index * math.pi),
                    t,
                    sparkle_phases[(19 + led_index * 37) % len(sparkle_phases)],
                )
                for led_index in range(len(mouse.leds))
            ]
            mouse.set_colors(mouse_colors, fast=True)
        frame += 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Custom GMMK Pro Cyberstorm animation")
    parser.add_argument("--frames", type=int, default=0, help="stop after N frames; 0 runs forever")
    parser.add_argument("--fps", type=float, default=24.0)
    parser.add_argument("--no-mouse", action="store_true", help="do not synchronize a Rival 310")
    args = parser.parse_args()
    run(args.frames, args.fps, not args.no_mouse)
