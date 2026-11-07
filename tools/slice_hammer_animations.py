#!/usr/bin/env python3
"""Extract the usable idle/run poses from the supplied hammer contact sheet.

Attack rows are deliberately omitted: the up poses touch the image boundary,
and the right-facing sequence does not depict a meaningful hammer swing.
"""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'asset/inbox/image.png'
DIRECTIONS = ('down', 'right', 'up')
ROWS = {'idle': ((0, 130), (130, 258), (258, 390)),
        'run': ((390, 507), (507, 615), (615, 735))}

def main():
    original = np.array(Image.open(SOURCE).convert('RGBA'))
    # Remove obvious isolated red masking artifacts surrounding the sprites.
    rgba = original.copy()
    red_artifact = ((rgba[:, :, 0] > 170) & (rgba[:, :, 1] < 70)
                    & (rgba[:, :, 2] < 70))
    rgba[red_artifact, 3] = 0
    mask = rgba[:, :, 3] > 100
    labels, _ = ndimage.label(ndimage.binary_dilation(mask, iterations=2))
    components = []
    for index, bounds in enumerate(ndimage.find_objects(labels), 1):
        if bounds is None or np.count_nonzero(labels[bounds] == index) < 1100:
            continue
        y, x = bounds
        components.append((x.start, y.start, x.stop, y.stop, index))

    for action, rows in ROWS.items():
        frame_count = 4 if action == 'idle' else 6
        for row_index, (y0, y1) in enumerate(rows):
            for character, left, right in (('boy', 0, 768), ('girl', 768, 1536)):
                boxes = sorted((b for b in components if y0 <= b[1] < y1 and left <= b[0] < right), key=lambda b: b[0])
                if len(boxes) != frame_count:
                    raise ValueError(f'{character} {action} {DIRECTIONS[row_index]}: got {len(boxes)} poses')
                sheet = Image.new('RGBA', (128 * frame_count, 160))
                # A common scale per source pose preserves the relative size of the hammer and body.
                scale = min(112 / max(b[2]-b[0] for b in boxes), 140 / max(b[3]-b[1] for b in boxes))
                for frame, (x0, top, x1, bottom, label) in enumerate(boxes):
                    selected = labels[top:bottom, x0:x1] == label
                    data = rgba[top:bottom, x0:x1].copy()
                    data[:, :, 3] = np.where(selected, data[:, :, 3], 0)
                    pose = Image.fromarray(data)
                    pose = pose.resize((max(1, round(pose.width*scale)), max(1, round(pose.height*scale))), Image.Resampling.LANCZOS)
                    sheet.alpha_composite(pose, (frame*128 + (128-pose.width)//2, 150-pose.height))
                out = ROOT / 'assets/characters' / character / 'animations' / f'hammer_{action}_{DIRECTIONS[row_index]}.png'
                out.parent.mkdir(parents=True, exist_ok=True)
                sheet.save(out)
                print(out.relative_to(ROOT))

if __name__ == '__main__':
    main()
