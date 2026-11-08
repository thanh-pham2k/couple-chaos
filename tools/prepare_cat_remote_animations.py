#!/usr/bin/env python3
"""Normalize supplied six-by-three cat-with-remote sheets into 64px frames.

The source grid is not divisible by six or three. Fractional cell boundaries
are rounded, then a single scale and a fixed ground line per direction retain
relative motion, including airborne poses. No generated/repainted artwork.
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, label

ROOT = Path(__file__).resolve().parents[1]
SIZE = 64
# Coordinates in the original ~296 px cells; deliberately shared by all frames.
GROUND_LINES = (280, 242, 275)
SCALE = 56.0 / 270.0
DIRECTIONS = ("down", "right", "up")


def extract_frame(sheet: np.ndarray, row: int, column: int, remove_shadow: bool) -> Image.Image:
    height, width = sheet.shape[:2]
    x0, x1 = (round(column * width / 6), round((column + 1) * width / 6))
    y0, y1 = (round(row * height / 3), round((row + 1) * height / 3))
    frame = sheet[y0:y1, x0:x1].copy()
    alpha = frame[:, :, 3]

    # The running sheet has muted grey/brown ovals painted into the source.
    # Remove those near the ground only; the dark remote higher up is untouched.
    if remove_shadow:
        rgb = frame[:, :, :3].astype(np.int16)
        rr, gg, bb = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
        yy = np.arange(frame.shape[0])[:, None]
        near_ground = yy >= (220 if row == 1 else 240)
        shadow = near_ground & (rr >= 120) & (rr <= 165) & (gg >= 105) & (gg <= 150) & (bb >= 90) & (bb <= 135) & ((rr - bb) <= 40)
        alpha[shadow] = 0

    # Pixels at alpha 1–15 cover much of the generated sheets. Select only the
    # large cat component and retain its adjacent original antialiasing.
    components, count = label(alpha >= 128)
    if count == 0:
        raise ValueError(f"No cat silhouette in row {row}, frame {column}")
    counts = np.bincount(components.ravel())
    counts[0] = 0
    main = components == counts.argmax()
    keep = binary_dilation(main, iterations=2)
    frame[:, :, 3] = np.where(keep, alpha, 0)
    frame[frame[:, :, 3] == 0, :3] = 0

    source = Image.fromarray(frame)
    resized = source.resize((round(source.width * SCALE), round(source.height * SCALE)), Image.Resampling.LANCZOS)
    output = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # The entire cell is transformed identically across frames, not cropped
    # and independently rescaled; preserve intended vertical run motion.
    left = round(SIZE / 2 - (source.width / 2) * SCALE)
    top = round(60 - GROUND_LINES[row] * SCALE)
    output.alpha_composite(resized, (left, top))
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--walk", type=Path, default=ROOT / "asset/archive/stage2_sources/source_cat_remote_walk.png")
    parser.add_argument("--run", type=Path, default=ROOT / "asset/archive/stage2_sources/source_cat_remote_run.png")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/pets/cat/animations")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for motion, path in (("carrywalk", args.walk), ("carryrun", args.run)):
        sheet = np.array(Image.open(path).convert("RGBA"))
        for row, direction in enumerate(DIRECTIONS):
            atlas = Image.new("RGBA", (SIZE * 6, SIZE))
            for column in range(6):
                atlas.alpha_composite(extract_frame(sheet, row, column, motion == "carryrun"), (SIZE * column, 0))
            target = args.output / f"{motion}_{direction}.png"
            atlas.save(target)
            print(target)


if __name__ == "__main__":
    main()
