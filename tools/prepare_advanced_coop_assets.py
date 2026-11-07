#!/usr/bin/env python3
"""Prepare advanced co-op assets from inbox sources."""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parent.parent
INBOX = ROOT / 'asset/archive/coop_sources' if (ROOT / 'asset/archive/coop_sources').exists() else ROOT / 'asset/inbox'
OUT_DIR = ROOT / 'assets/coop/advanced'
OUT_DIR.mkdir(parents=True, exist_ok=True)


def source(n: int) -> np.ndarray:
    return np.array(Image.open(INBOX / f'image copy {n}.png').convert('RGBA'))


def isolate(a: np.ndarray, rect, threshold=50) -> Image.Image:
    x0, y0, x1, y1 = rect
    a = a[y0:y1, x0:x1].copy()
    rgb = a[:, :, :3].astype('int16')
    alpha = a[:, :, 3]
    # Strip detached red/bright chroma noise while preserving brown linework
    bad = (rgb[:, :, 0] > 180) & (rgb[:, :, 1] < 60) & (rgb[:, :, 2] < 60)
    alpha[bad] = 0
    seed = alpha > threshold
    labels, _ = ndi.label(ndi.binary_dilation(seed, iterations=2))
    counts = np.bincount(labels.ravel())
    keep = np.where(counts > 250)[0]
    keep = keep[keep != 0]
    mask = np.isin(labels, keep)
    alpha[~mask] = 0
    return Image.fromarray(a)


def bounds(im: Image.Image):
    return im.getchannel('A').point(lambda x: 255 if x > 45 else 0).getbbox()


def fit(im: Image.Image, wh, occupancy=(0.9, 0.9), bottom=True) -> Image.Image:
    bb = bounds(im)
    if not bb:
        raise ValueError('Empty bounding box')
    im = im.crop(bb)
    w, h = wh
    s = min(w * occupancy[0] / im.width, h * occupancy[1] / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', wh)
    pos = ((w - im.width) // 2, h - im.height - 3 if bottom else (h - im.height) // 2)
    out.alpha_composite(im, pos)
    return out


def extract_fx_sheet(arr_row: np.ndarray, is_row0: bool) -> Image.Image:
    windows = [(120, 600), (600, 1080), (1080, 1560), (1560, 2060)]
    cropped_frames = []

    for c, (x0, x1) in enumerate(windows):
        cell = arr_row[:, x0:x1].copy()
        rgb = cell[:, :, :3].astype(float)
        alpha = cell[:, :, 3].astype(float)
        bright = np.mean(rgb, axis=2)
        chroma = np.max(rgb, axis=2) - np.min(rgb, axis=2)

        if is_row0:
            # Place FX: golden/amber stars
            metric = (rgb[:, :, 0] + rgb[:, :, 1]) / 2.0 - rgb[:, :, 2]
            core = ((metric > 30) | (bright < 140)) & (alpha > 180)
        else:
            # Clean FX: green checkmark
            metric = rgb[:, :, 1] - (rgb[:, :, 0] + rgb[:, :, 2]) / 2.0
            core = ((metric > 12) | (bright < 140)) & (alpha > 180)

        # Frame 3 is faded out
        if c == 3:
            if is_row0:
                core = (metric > 15) & (alpha > 90)
            else:
                core = (metric > 6) & (alpha > 90)

        # Discard red generation artifacts
        junk = (rgb[:, :, 0] > 175) & (rgb[:, :, 1] < 70) & (rgb[:, :, 2] < 70)
        core &= ~junk

        # Filter core to main components near center
        labels, num_features = ndi.label(core)
        cy, cx = cell.shape[0] / 2, cell.shape[1] / 2
        valid_core = np.zeros_like(core, dtype=bool)
        for lbl in range(1, num_features + 1):
            mask_lbl = labels == lbl
            cnt = mask_lbl.sum()
            if cnt < 50:
                continue
            ys, xs = np.where(mask_lbl)
            if abs(xs.mean() - cx) < 180 and abs(ys.mean() - cy) < 140:
                valid_core |= mask_lbl

        # Dilate valid core by 3 px to capture anti-aliasing rim
        aa_zone = ndi.binary_dilation(valid_core, iterations=3)

        # Background matte mask: anything outside aa_zone or near-white background
        is_bg = ~aa_zone | (alpha < 20) | ((bright > 180) & (chroma < 15))
        alpha[is_bg] = 0

        # Fringe suppression on transition pixels
        fringe = aa_zone & ~valid_core & (bright > 170)
        alpha[fringe] = alpha[fringe] * np.clip((chroma[fringe] - 10) / 25.0, 0.0, 1.0)

        cell[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
        im_cell = Image.fromarray(cell)
        bbox = im_cell.getchannel('A').getbbox()
        cropped = im_cell.crop(bbox)
        cropped_frames.append(cropped)

    max_w = max(f.width for f in cropped_frames)
    max_h = max(f.height for f in cropped_frames)
    scale = min(112 / max_w, 112 / max_h)

    sheet = Image.new('RGBA', (512, 128), (0, 0, 0, 0))
    for i, frame in enumerate(cropped_frames):
        fw = round(frame.width * scale)
        fh = round(frame.height * scale)
        resized = frame.resize((fw, fh), Image.Resampling.LANCZOS)
        ox = i * 128 + (128 - fw) // 2
        oy = (128 - fh) // 2
        sheet.alpha_composite(resized, (ox, oy))
    return sheet


def main():
    # 1. Sofa Pillows (64x64) from image copy 16.png
    a16 = source(16)
    for i, (x0, x1) in enumerate([(0, 887), (887, 1774)], 1):
        im = isolate(a16, (x0, 0, x1, 887))
        fit(im, (64, 64), (0.92, 0.92)).save(OUT_DIR / f'sofa_pillow_{i}.png')
        print(f'Saved sofa_pillow_{i}.png (64x64)')

    # 2. Prompts (72x72) from image copy 17.png
    a17 = source(17)
    for name, (x0, x1) in zip(
        ['prompt_pickup', 'prompt_place', 'prompt_clean'],
        [(0, 724), (724, 1448), (1448, 2172)]
    ):
        im = isolate(a17, (x0, 0, x1, 724))
        fit(im, (72, 72), (0.9, 0.9), bottom=False).save(OUT_DIR / f'{name}.png')
        print(f'Saved {name}.png (72x72)')

    # 3. Basket (160x160, bottom-anchored) from image copy 18.png
    a18 = source(18)
    for name, (x0, x1) in zip(
        ['basket_idle', 'basket_active', 'basket_success'],
        [(0, 724), (724, 1375), (1375, 2172)]
    ):
        im = isolate(a18, (x0, 0, x1, 724))
        crop = im.crop((0, 0, im.width, 690))
        s = 110 / 548
        crop = crop.resize((round(crop.width * s), round(crop.height * s)), Image.Resampling.LANCZOS)
        out = Image.new('RGBA', (160, 160))
        out.alpha_composite(crop, ((160 - crop.width) // 2, 140 - round(646 * s)))
        out.save(OUT_DIR / f'{name}.png')
        print(f'Saved {name}.png (160x160)')

    # 4. Pillow slots (128x128) from image copy 19.png
    a19 = source(19)
    for name, (x0, x1) in zip(
        ['pillow_slot_neutral', 'pillow_slot_active', 'pillow_slot_success'],
        [(0, 724), (724, 1390), (1390, 2172)]
    ):
        im = isolate(a19, (x0, 0, x1, 724))
        fit(im, (128, 128), (0.9, 0.9)).save(OUT_DIR / f'{name}.png')
        print(f'Saved {name}.png (128x128)')

    # 5. Success VFX (512x128, 4 frames 128x128 centered) from image copy 20.png
    a20 = source(20)
    place_fx = extract_fx_sheet(a20[:362], is_row0=True)
    place_fx.save(OUT_DIR / 'place_success_fx.png')
    print('Saved place_success_fx.png (512x128)')

    clean_fx = extract_fx_sheet(a20[362:724], is_row0=False)
    clean_fx.save(OUT_DIR / 'clean_success_fx.png')
    print('Saved clean_success_fx.png (512x128)')


if __name__ == '__main__':
    main()
