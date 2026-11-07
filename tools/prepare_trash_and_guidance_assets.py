#!/usr/bin/env python3
"""Prepare trash bin animation and guidance/feedback assets for Couple Chaos Co-op mode.

Extracts, cleans, and normalizes 4 gameplay assets from asset/inbox:
1. source_trash_bin_animation.png (asset/inbox/image.png)
   -> assets/coop/advanced/trash_bin_anim.png (6 frames, 576x112, fixed bottom baseline, stationary body)
2. source_item_target_marker.png (asset/inbox/image copy.png)
   -> assets/coop/advanced/item_target_marker_neutral.png (128x128, center anchor)
   -> assets/coop/advanced/item_target_marker_active.png (128x128, center anchor)
   -> assets/coop/advanced/item_target_marker_success.png (128x128, center anchor)
3. source_target_direction_arrow.png (asset/inbox/image copy 2.png)
   -> assets/coop/advanced/target_arrow_idle.png (64x64, center pivot)
   -> assets/coop/advanced/target_arrow_active.png (64x64, center pivot)
   -> assets/coop/advanced/target_arrow_near.png (64x64, center pivot)
4. source_trash_drop_fx.png (asset/inbox/image copy 3.png)
   -> assets/coop/advanced/trash_drop_fx.png (4 frames, 512x128, centered)
"""
from __future__ import annotations

import argparse
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parent.parent
INBOX = ROOT / "asset/archive/coop_trash_and_guidance" if (ROOT / "asset/archive/coop_trash_and_guidance").exists() else ROOT / "asset/inbox"
OUT_DIR = ROOT / "assets/coop/advanced"


def clean_chroma_noise(arr: np.ndarray, alpha_cutoff: int = 25) -> np.ndarray:
    """Strip background matte fringes and isolated reddish generation noise."""
    arr = arr.copy()
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3]

    # Suppress reddish generation artifacts common in AI generation sheets
    bad_red = (rgb[:, :, 0] > 175) & (rgb[:, :, 1] < 70) & (rgb[:, :, 2] < 70) & (alpha < 120)
    alpha[bad_red] = 0
    alpha[alpha < alpha_cutoff] = 0

    arr[:, :, 3] = alpha
    return arr


def process_trash_bin(bin_size: tuple[int, int] = (96, 112)) -> Path:
    """Extract 6 frames of trash bin animation with stationary body and fixed baseline."""
    src_path = INBOX / "image.png"
    if not src_path.exists():
        raise FileNotFoundError(f"Source not found: {src_path}")

    arr = clean_chroma_noise(np.array(Image.open(src_path).convert("RGBA")))
    w_col = arr.shape[1] // 6  # 362 px per column

    # Compute body horizontal centers and baseline
    # The body is stationary in lower region (y between 450 and 550)
    anchors_cx = []
    baseline_y = 567

    for col_idx in range(6):
        cell = arr[:, col_idx * w_col : (col_idx + 1) * w_col]
        centers = []
        for y in range(450, 550, 5):
            row_pts = np.where(cell[y, :, 3] > 60)[0]
            if len(row_pts) > 0:
                centers.append((row_pts.min() + row_pts.max()) / 2.0)
        cx = float(np.median(centers))
        anchors_cx.append(cx)

    # Common window relative to body anchor (cx, baseline)
    half_w = 152
    top_h = 442
    bot_h = 4
    win_w = half_w * 2  # 304
    win_h = top_h + bot_h  # 446

    fw, fh = bin_size
    # Target anchor in target frame: center x, bottom - 4 y
    target_anchor_x = fw // 2
    target_anchor_y = fh - 4

    available_h = target_anchor_y - 4
    scale = available_h / float(top_h)
    resized_w = round(win_w * scale)
    resized_h = round(win_h * scale)

    res_anchor_x = round(half_w * scale)
    res_anchor_y = round(top_h * scale)
    pos_x = target_anchor_x - res_anchor_x
    pos_y = target_anchor_y - res_anchor_y

    sheet = Image.new("RGBA", (fw * 6, fh), (0, 0, 0, 0))

    for col_idx in range(6):
        cx = anchors_cx[col_idx]
        col_start = col_idx * w_col
        global_cx = col_start + cx

        x0 = int(round(global_cx - half_w))
        x1 = int(round(global_cx + half_w))
        y0 = int(round(baseline_y - top_h))
        y1 = int(round(baseline_y + bot_h))

        window_arr = arr[y0:y1, x0:x1].copy()

        # Isolate main trash bin component in this window
        core = window_arr[:, :, 3] > 40
        lbl, num = ndi.label(core)
        sizes = np.bincount(lbl.ravel())
        if len(sizes) > 1:
            main_lbl = sizes[1:].argmax() + 1
            keep = ndi.binary_dilation(lbl == main_lbl, iterations=2)
            window_arr[~keep, 3] = 0

        crop_im = Image.fromarray(window_arr)
        resized_frame = crop_im.resize((resized_w, resized_h), Image.Resampling.LANCZOS)

        frame_canvas = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        frame_canvas.alpha_composite(resized_frame, (pos_x, pos_y))

        sheet.alpha_composite(frame_canvas, (col_idx * fw, 0))

    out_path = OUT_DIR / "trash_bin_anim.png"
    sheet.save(out_path)
    print(f"[PASS] Saved trash_bin_anim.png: size={sheet.size} (6 frames of {fw}x{fh})")
    return out_path


def process_target_markers(marker_size: tuple[int, int] = (128, 128)) -> list[Path]:
    """Extract neutral, active, and success item target markers."""
    src_path = INBOX / "image copy.png"
    if not src_path.exists():
        raise FileNotFoundError(f"Source not found: {src_path}")

    arr = clean_chroma_noise(np.array(Image.open(src_path).convert("RGBA")))
    cols = [(0, 724), (724, 1448), (1448, 2172)]
    names = ["item_target_marker_neutral", "item_target_marker_active", "item_target_marker_success"]
    mw, mh = marker_size

    out_paths = []
    for (x0, x1), name in zip(cols, names):
        cell = arr[:, x0:x1].copy()
        alpha = cell[:, :, 3]

        # Connected components filter: keep marker components near center
        core = alpha > 40
        lbl, num = ndi.label(core)
        sizes = np.bincount(lbl.ravel())

        keep_mask = np.zeros_like(core, dtype=bool)
        for l in range(1, num + 1):
            if sizes[l] < 200:
                continue
            ys, xs = np.where(lbl == l)
            if abs(xs.mean() - 362) < 260 and abs(ys.mean() - 364) < 160:
                keep_mask |= (lbl == l)

        keep_zone = ndi.binary_dilation(keep_mask, iterations=2)
        cell[~keep_zone, 3] = 0

        im_clean = Image.fromarray(cell)
        bbox = im_clean.getchannel("A").getbbox()
        cropped = im_clean.crop(bbox)

        # Scale into target marker dimensions
        # Occupancy 0.90 width-wise
        max_target_w = mw - 12
        max_target_h = mh - 12 if mh < 128 else 72
        scale = min(max_target_w / cropped.width, max_target_h / cropped.height)
        scaled_w = round(cropped.width * scale)
        scaled_h = round(cropped.height * scale)

        resized = cropped.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", marker_size, (0, 0, 0, 0))

        # Center anchor: (mw // 2, mh // 2)
        ox = (mw - scaled_w) // 2
        oy = (mh - scaled_h) // 2
        canvas.alpha_composite(resized, (ox, oy))

        out_path = OUT_DIR / f"{name}.png"
        canvas.save(out_path)
        print(f"[PASS] Saved {name}.png: size={canvas.size} (center anchor)")
        out_paths.append(out_path)

    return out_paths


def process_direction_arrows() -> list[Path]:
    """Extract idle, active, and near target upward-pointing arrows centered in 64x64."""
    src_path = INBOX / "image copy 2.png"
    if not src_path.exists():
        raise FileNotFoundError(f"Source not found: {src_path}")

    arr = clean_chroma_noise(np.array(Image.open(src_path).convert("RGBA")))
    intervals = [(723, 863), (1016, 1156), (1309, 1449)]
    names = ["target_arrow_idle", "target_arrow_active", "target_arrow_near"]

    out_paths = []
    for (x0, x1), name in zip(intervals, names):
        cell = arr[550:705, x0 - 5 : x1 + 5].copy()
        alpha = cell[:, :, 3]

        core = alpha > 40
        lbl, num = ndi.label(core)
        sizes = np.bincount(lbl.ravel())
        if len(sizes) > 1:
            main_lbl = sizes[1:].argmax() + 1
            keep = ndi.binary_dilation(lbl == main_lbl, iterations=2)
            cell[~keep, 3] = 0

        im_arrow = Image.fromarray(cell)
        bbox = im_arrow.getchannel("A").getbbox()
        cropped = im_arrow.crop(bbox)

        # Fit within 64x64 with center pivot
        target_h = 54
        scale = target_h / float(cropped.height)
        scaled_w = round(cropped.width * scale)
        scaled_h = target_h

        resized = cropped.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))

        ox = (64 - scaled_w) // 2
        oy = (64 - scaled_h) // 2
        canvas.alpha_composite(resized, (ox, oy))

        out_path = OUT_DIR / f"{name}.png"
        canvas.save(out_path)
        print(f"[PASS] Saved {name}.png: size={canvas.size} (center pivot)")
        out_paths.append(out_path)

    return out_paths


def process_trash_drop_fx() -> Path:
    """Extract 4 frames of trash drop effect into 512x128 horizontal sheet."""
    src_path = INBOX / "image copy 3.png"
    if not src_path.exists():
        raise FileNotFoundError(f"Source not found: {src_path}")

    arr = clean_chroma_noise(np.array(Image.open(src_path).convert("RGBA")))
    intervals = [(172, 366), (649, 981), (1207, 1471), (1764, 1984)]

    cropped_frames = []
    for x0, x1 in intervals:
        cell = arr[:, x0:x1].copy()
        alpha = cell[:, :, 3]

        core = alpha > 40
        lbl, num = ndi.label(core)
        sizes = np.bincount(lbl.ravel())

        keep_mask = np.zeros_like(core, dtype=bool)
        for l in range(1, num + 1):
            if sizes[l] > 100:
                keep_mask |= (lbl == l)

        keep_zone = ndi.binary_dilation(keep_mask, iterations=2)
        cell[~keep_zone, 3] = 0

        cim = Image.fromarray(cell)
        bbox = cim.getchannel("A").getbbox()
        cropped_frames.append(cim.crop(bbox))

    # Shared scale across all frames to preserve burst expansion animation
    max_w = max(f.width for f in cropped_frames)
    max_h = max(f.height for f in cropped_frames)
    scale = min(112.0 / max_w, 112.0 / max_h)

    sheet = Image.new("RGBA", (512, 128), (0, 0, 0, 0))
    for i, frame in enumerate(cropped_frames):
        fw = round(frame.width * scale)
        fh = round(frame.height * scale)
        resized = frame.resize((fw, fh), Image.Resampling.LANCZOS)
        ox = i * 128 + (128 - fw) // 2
        oy = (128 - fh) // 2
        sheet.alpha_composite(resized, (ox, oy))

    out_path = OUT_DIR / "trash_drop_fx.png"
    sheet.save(out_path)
    print(f"[PASS] Saved trash_drop_fx.png: size={sheet.size} (4 frames of 128x128)")
    return out_path


def verify_all_assets() -> bool:
    """Verify all expected output assets exist, are valid RGBA PNGs, and match specifications."""
    expected = {
        "trash_bin_anim.png": {"size": (576, 112), "frames": 6, "frame_w": 96, "frame_h": 112},
        "item_target_marker_neutral.png": {"size": (128, 128)},
        "item_target_marker_active.png": {"size": (128, 128)},
        "item_target_marker_success.png": {"size": (128, 128)},
        "target_arrow_idle.png": {"size": (64, 64)},
        "target_arrow_active.png": {"size": (64, 64)},
        "target_arrow_near.png": {"size": (64, 64)},
        "trash_drop_fx.png": {"size": (512, 128), "frames": 4, "frame_w": 128, "frame_h": 128},
    }

    print("\n" + "=" * 70)
    print("ASSET VERIFICATION & QA REPORT")
    print("=" * 70)
    all_pass = True

    for filename, specs in expected.items():
        file_path = OUT_DIR / filename
        if not file_path.exists():
            print(f"[MISSING]   {filename}")
            all_pass = False
            continue

        try:
            im = Image.open(file_path)
            mode = im.mode
            size = im.size
            alpha_ch = im.getchannel("A")
            bbox = alpha_ch.getbbox()

            expected_size = specs["size"]
            size_match = size == expected_size
            mode_match = mode == "RGBA"
            content_valid = bbox is not None

            if size_match and mode_match and content_valid:
                print(f"[PASS]      {filename:32s} | Size: {size[0]}x{size[1]} | Mode: {mode} | Content: {bbox}")
            else:
                print(f"[FAIL]      {filename:32s} | Size: {size} (exp: {expected_size}) | Mode: {mode} | Valid: {content_valid}")
                all_pass = False
        except Exception as e:
            print(f"[FAIL]      {filename:32s} | Error: {e}")
            all_pass = False

    print("=" * 70)
    print(f"Overall Status: {'ALL PASS' if all_pass else 'SOME FAILED'}")
    print("=" * 70 + "\n")
    return all_pass


def main():
    parser = argparse.ArgumentParser(description="Prepare trash and guidance assets for Couple Chaos.")
    parser.add_argument("--bin-width", type=int, default=96, help="Trash bin frame width (default: 96)")
    parser.add_argument("--bin-height", type=int, default=112, help="Trash bin frame height (default: 112)")
    parser.add_argument("--marker-width", type=int, default=128, help="Marker width (default: 128)")
    parser.add_argument("--marker-height", type=int, default=128, help="Marker height (default: 128)")
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    process_trash_bin(bin_size=(args.bin_width, args.bin_height))
    process_target_markers(marker_size=(args.marker_width, args.marker_height))
    process_direction_arrows()
    process_trash_drop_fx()
    verify_all_assets()


if __name__ == "__main__":
    main()
