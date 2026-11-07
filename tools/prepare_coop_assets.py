#!/usr/bin/env python3
"""Prepare supplied co-op sprites without modifying their source images."""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
INBOX = ROOT / 'asset/archive/inbox_archive' if (ROOT / 'asset/archive/inbox_archive').exists() else ROOT / 'asset/inbox'
OUTPUT = ROOT / 'assets/coop'
OUTPUT.mkdir(parents=True, exist_ok=True)

def prepare(source, output, size, area=None, mode='single', bottom=False):
    image = Image.open(INBOX / source).convert('RGBA')
    if area:
        image = image.crop(area)
    arr = np.asarray(image).copy()
    alpha = arr[:, :, 3]
    # Segmentation discards distant alpha speckles while retaining antialiased edges.
    core = alpha > (150 if mode == 'marker' else 80)
    labels, _ = ndimage.label(ndimage.binary_dilation(core, iterations=2))
    components = []
    for index, bounds in enumerate(ndimage.find_objects(labels), 1):
        if bounds is None:
            continue
        mass = int(np.count_nonzero(labels[bounds] == index))
        if mass > (100 if mode == 'marker' else 250):
            components.append((mass, index))
    if not components:
        raise ValueError(f'No foreground: {source}, {output}')
    if mode == 'single':
        selected = np.isin(labels, [max(components)[1]])
    else:
        selected = np.isin(labels, [index for _, index in components])
    selected = ndimage.binary_dilation(selected, iterations=2)
    if mode == 'marker':
        # Original marker sheet contains a broad, clipped grey/white glow.
        # Reduce low-alpha glow rather than carrying it onto the floor.
        alpha = np.clip((alpha.astype(np.float32) - 110) * (255 / 145), 0, 255).astype(np.uint8)
    arr[:, :, 3] = np.where(selected, alpha, 0)
    # Drop isolated vivid red extraction residue while preserving red on the remote.
    if source != 'image copy 11.png':
        red = (arr[:, :, 0] > 200) & (arr[:, :, 1] < 55) & (arr[:, :, 2] < 55)
        arr[red, 3] = 0
    rgba = Image.fromarray(arr)
    box = rgba.getchannel('A').getbbox()
    if not box:
        raise ValueError(f'Empty foreground: {source}, {output}')
    cut = rgba.crop(box)
    maxw, maxh = size[0] - 4, size[1] - 4
    scale = min(maxw / cut.width, maxh / cut.height)
    cut = cut.resize((max(1, round(cut.width * scale)), max(1, round(cut.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', size)
    x = (size[0] - cut.width) // 2
    y = size[1] - 2 - cut.height if bottom else (size[1] - cut.height) // 2
    canvas.alpha_composite(cut, (x, y))
    canvas.save(OUTPUT / output)
    print(f'{output}: {size[0]}x{size[1]}')

prepare('image copy.png', 'mop.png', (64, 64))
prepare('image copy 3.png', 'basket.png', (128, 96), bottom=True)
prepare('image copy 6.png', 'task_complete.png', (48, 48))
prepare('image copy 7.png', 'task_pending.png', (48, 48))
prepare('image copy 9.png', 'sofa_pillow.png', (64, 64))
prepare('image copy 10.png', 'trash_bin.png', (96, 112), bottom=True)
prepare('image copy 11.png', 'remote.png', (64, 64))
for output, box in [
    ('spill_water.png', (0, 0, 545, 724)),
    ('spill_milk_tea.png', (545, 0, 1085, 724)),
    ('spill_paw.png', (1085, 0, 1625, 724)),
    ('spill_splatter.png', (1625, 0, 2172, 724)),
]:
    prepare('image copy 2.png', output, (128, 80), box, mode='multi')
for output, box in [
    ('zone_neutral.png', (0, 0, 724, 724)),
    ('zone_active.png', (724, 0, 1448, 724)),
    ('zone_success.png', (1448, 0, 2172, 724)),
]:
    prepare('image copy 8.png', output, (128, 80), box, mode='marker')
