#!/usr/bin/env python3
"""Extract character animation candidates from the supplied six-by-six sheets."""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
# Hammer source has no convincing raised/swing poses and is intentionally omitted.
SOURCES = {'carry_run': 'image copy 3.png', 'throw': 'image copy 6.png'}
DIRECTIONS = ('down', 'right', 'up')

def extract(source):
    image = Image.open(source).convert('RGBA')
    rgba = np.asarray(image)
    alpha = rgba[:, :, 3]
    labels, _ = ndimage.label(alpha > 64)
    parts = []
    for number, bounds in enumerate(ndimage.find_objects(labels), 1):
        if bounds is None:
            continue
        selected = labels[bounds] == number
        if selected.sum() < 2500:
            continue
        y, x = bounds
        parts.append((x.start, y.start, x.stop, y.stop, number))
    if len(parts) != 36:
        raise ValueError(f'{source}: expected 36 complete poses; got {len(parts)}')
    # Evenly grouped horizontal rows, then left-to-right reading order.
    parts.sort(key=lambda b: b[1])
    rows = [sorted(parts[i:i + 6], key=lambda b: b[0]) for i in range(0, 36, 6)]
    return image, labels, rows

for action, filename in SOURCES.items():
    image, labels, rows = extract(ROOT / 'asset/archive/animation_sources' / filename)
    # One scale per whole source avoids size pulsation across animation frames.
    widest = max(b[2] - b[0] for row in rows for b in row)
    tallest = max(b[3] - b[1] for row in rows for b in row)
    scale = min(110 / widest, 140 / tallest)
    for row_index, row in enumerate(rows):
        character = 'boy' if row_index < 3 else 'girl'
        direction = DIRECTIONS[row_index % 3]
        sheet = Image.new('RGBA', (128 * 6, 160))
        for frame, (x0, y0, x1, y1, number) in enumerate(row):
            # Include antialiasing around the main component but discard detached noise.
            mask = ndimage.binary_dilation(labels == number, iterations=2)
            left, top = max(x0 - 2, 0), max(y0 - 2, 0)
            right, bottom = min(x1 + 2, image.width), min(y1 + 2, image.height)
            data = np.array(image.crop((left, top, right, bottom)))
            data[:, :, 3] = np.where(mask[top:bottom, left:right], data[:, :, 3], 0)
            sprite = Image.fromarray(data)
            sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
            sheet.alpha_composite(sprite, (frame * 128 + (128 - sprite.width) // 2, 150 - sprite.height))
        output = ROOT / 'assets' / 'characters' / character / 'animations' / f'{action}_{direction}.png'
        output.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(output)
        print(output.relative_to(ROOT))
