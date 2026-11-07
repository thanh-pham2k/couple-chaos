#!/usr/bin/env python3
"""Extract supplied animation candidates without changing source images."""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [('image copy 12.png', 'carry_idle', 4, 1), ('image copy 13.png', 'carry_run', 6, 6), ('image copy 15.png', 'place_item', 6, 6)]
DIRECTIONS = ('down', 'right', 'up')
SOURCE_DIR = ROOT / 'asset/archive/coop_sources' if (ROOT / 'asset/archive/coop_sources').exists() else ROOT / 'asset/inbox'

for filename, action, columns, row_count in SOURCES:
    source = SOURCE_DIR / filename
    rgba = np.asarray(Image.open(source).convert('RGBA')).copy()
    # Thresholding selects the coherent opaque figure; retain a 2px AA border.
    labels, _ = ndimage.label(ndimage.binary_dilation(rgba[:, :, 3] > 96, iterations=2))
    components = []
    for idx, sl in enumerate(ndimage.find_objects(labels), 1):
        if sl is None or np.count_nonzero(labels[sl] == idx) < 1500:
            continue
        yy, xx = sl
        components.append((xx.start, yy.start, xx.stop, yy.stop, idx))
    if len(components) != columns * row_count:
        raise ValueError(f'{filename}: expected {columns*row_count} characters; got {len(components)}')
    components.sort(key=lambda a: a[1])
    rows = [sorted(components[row*columns:(row+1)*columns], key=lambda a: a[0]) for row in range(row_count)]
    for r, boxes in enumerate(rows):
        character = 'boy' if r < 3 else 'girl'
        direction = DIRECTIONS[r % 3]
        group_rows = rows[:3] if character == 'boy' else rows[3:]
        widest = max(b[2]-b[0] for row in group_rows for b in row)
        tallest = max(b[3]-b[1] for row in group_rows for b in row)
        scale = min(116 / widest, 140 / tallest)
        sheet = Image.new('RGBA', (128 * columns, 160))
        for frame, (x0, y0, x1, y1, idx) in enumerate(boxes):
            selected = labels[y0:y1, x0:x1] == idx
            data = rgba[y0:y1, x0:x1].copy()
            data[:,:,3] = np.where(selected, data[:,:,3], 0)
            # Isolated near-transparent red/gray fringe is generation artefact.
            junk = (data[:,:,0] > 180) & (data[:,:,1] < 65) & (data[:,:,2] < 65) & (data[:,:,3] < 180)
            data[junk, 3] = 0
            sprite = Image.fromarray(data).resize((max(1,round((x1-x0)*scale)), max(1,round((y1-y0)*scale))), Image.Resampling.LANCZOS)
            sheet.alpha_composite(sprite,(frame*128+(128-sprite.width)//2,150-sprite.height))
        path = ROOT / 'assets/coop/animations' / character / f'{action}_{direction}.png'
        path.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(path)
        print(path.relative_to(ROOT))
