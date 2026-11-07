#!/usr/bin/env python3
"""
tools/slice_assets.py
Production-grade sprite slicer & transparent PNG extractor for Couple Chaos.
- Flood-fills exterior background from borders to keep interior whites intact.
- Performs anti-aliasing feathering to eliminate white halos.
- Crops each sprite to its tight bounding box and standardizes to ASSET_RULES dimensions.
"""

import os
import sys
import numpy as np
import scipy.ndimage as ndi
from PIL import Image

INBOX_DIR = "asset/archive/inbox_archive" if os.path.exists("asset/archive/inbox_archive") else "asset/inbox"
OUT_BASE = "assets"

def make_transparent_border_floodfill(pil_img, white_thresh=242):
    """
    Remove white background connected to borders, preserving interior whites.
    Applies gentle edge feathering for smooth alpha blending.
    """
    arr = np.array(pil_img.convert("RGBA"))
    rgb = arr[:, :, :3]
    
    # 1. Identify pure/near white pixels
    is_white = np.all(rgb >= white_thresh, axis=2)
    
    # 2. Label connected white components
    labeled, num_features = ndi.label(is_white)
    
    # 3. Find labels that touch the border of the image
    border_labels = set(np.unique(labeled[0, :])) | \
                    set(np.unique(labeled[-1, :])) | \
                    set(np.unique(labeled[:, 0])) | \
                    set(np.unique(labeled[:, -1]))
    border_labels.discard(0) # 0 is non-white
    
    # 4. Exterior background mask
    ext_bg_mask = np.isin(labeled, list(border_labels))
    
    # 5. Set alpha = 0 for exterior background
    alpha = np.where(ext_bg_mask, 0, 255).astype(np.uint8)
    
    # 6. Smooth anti-aliased edge: feather 1px transition
    # Find distance from foreground
    dist = ndi.distance_transform_edt(ext_bg_mask)
    # Blend pixels right at border (dist < 1.5)
    near_edge = (dist > 0) & (dist <= 1.8)
    # Intensity of white in edge pixels
    white_intensity = np.mean(rgb[near_edge].astype(float), axis=1)
    edge_alpha = np.clip((255 - white_intensity) * 2.5, 0, 255).astype(np.uint8)
    alpha[near_edge] = edge_alpha
    
    arr[:, :, 3] = alpha
    return Image.fromarray(arr, "RGBA")

def find_sprite_bboxes(rgba_img, min_area=1200):
    """
    Find distinct sprite bounding boxes from alpha channel.
    """
    arr = np.array(rgba_img)
    alpha = arr[:, :, 3]
    fg_mask = alpha > 30
    
    # Morphological close to join close parts (e.g. detached hands or shoes)
    structure = ndi.generate_binary_structure(2, 2)
    closed_mask = ndi.binary_dilation(fg_mask, structure=structure, iterations=4)
    
    labeled, num = ndi.label(closed_mask)
    sizes = np.bincount(labeled.ravel())
    
    valid_ids = [i for i, s in enumerate(sizes) if i > 0 and s >= min_area]
    
    bboxes = []
    for sp_id in valid_ids:
        # Use exact original fg_mask coords
        sp_mask = (labeled == sp_id) & fg_mask
        coords = np.argwhere(sp_mask)
        if len(coords) == 0:
            continue
        y0, x0 = coords.min(axis=0)
        y1, x1 = coords.max(axis=0) + 1
        bboxes.append((x0, y0, x1 - x0, y1 - y0, len(coords)))
        
    return bboxes

def fit_on_canvas(sprite_img, target_w, target_h, anchor="bottom_center"):
    """
    Resize sprite proportionally to fit within target_w x target_h,
    and place on a transparent canvas at the specified anchor point.
    """
    orig_w, orig_h = sprite_img.size
    scale = min(target_w / orig_w, target_h / orig_h)
    new_w = max(1, int(orig_w * scale))
    new_h = max(1, int(orig_h * scale))
    
    resized = sprite_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    
    if anchor == "bottom_center":
        x = (target_w - new_w) // 2
        y = target_h - new_h
    elif anchor == "center":
        x = (target_w - new_w) // 2
        y = (target_h - new_h) // 2
    else:
        x, y = 0, 0
        
    canvas.paste(resized, (x, y), resized)
    return canvas

def process_batch(file_name, output_dir, target_w, target_h, anchor, name_prefix, expected_count=None):
    os.makedirs(output_dir, exist_ok=True)
    in_path = os.path.join(INBOX_DIR, file_name)
    if not os.path.exists(in_path):
        print(f"[WARN] File not found: {in_path}")
        return []
    
    print(f"--> Processing {file_name}...")
    raw_img = Image.open(in_path)
    rgba = make_transparent_border_floodfill(raw_img)
    
    bboxes = find_sprite_bboxes(rgba, min_area=1000)
    
    # Sort bounding boxes top-to-bottom, left-to-right (grid layout reading order)
    # Group by approximate rows (~height / 2)
    avg_h = np.mean([b[3] for b in bboxes]) if bboxes else 200
    row_thresh = max(80, int(avg_h * 0.5))
    bboxes.sort(key=lambda b: (b[1] // row_thresh, b[0]))
    
    print(f"    Detected {len(bboxes)} sprites in {file_name}")
    saved_files = []
    
    for idx, (x, y, w, h, _) in enumerate(bboxes):
        crop = rgba.crop((x, y, x + w, y + h))
        fitted = fit_on_canvas(crop, target_w, target_h, anchor=anchor)
        out_name = f"{name_prefix}_{idx+1:02d}.png"
        out_path = os.path.join(output_dir, out_name)
        fitted.save(out_path, "PNG")
        saved_files.append(out_path)
        print(f"    Saved: {out_path} ({w}x{h} -> {target_w}x{target_h})")
        
    return saved_files

def main():
    print("=== STARTING COUPLE CHAOS SPRITE SLICING ===")
    
    # 1. Batch 01: Boy P1 -> 128x160, bottom_center
    process_batch("batch_01_boy.png", os.path.join(OUT_BASE, "characters", "boy"), 
                  128, 160, "bottom_center", "boy")
                  
    # 2. Batch 02: Girl P2 -> 128x160, bottom_center
    process_batch("batch_02_girl.png", os.path.join(OUT_BASE, "characters", "girl"), 
                  128, 160, "bottom_center", "girl")
                  
    # 3. Batch 03: Boss Cat -> 64x64, bottom_center
    process_batch("batch_03_cat.png", os.path.join(OUT_BASE, "pets", "cat"), 
                  64, 64, "bottom_center", "cat")
                  
    # 4. Batch 04: Items & Weapons -> 64x64, center
    process_batch("batch_04_items.png", os.path.join(OUT_BASE, "items"), 
                  64, 64, "center", "item")
                  
    # 5. Batch 05: Living Room Furniture -> 260x160 (or proportional), bottom_center
    process_batch("batch_05_living_furniture.png", os.path.join(OUT_BASE, "furniture", "living"), 
                  260, 180, "bottom_center", "fur_living")
                  
    # 6. Batch 06: Kitchen & Bedroom Furniture -> 240x220, bottom_center
    process_batch("batch_06_kitchen_furniture.png", os.path.join(OUT_BASE, "furniture", "kitchen_bed"), 
                  240, 220, "bottom_center", "fur_kitchen")
                  
    # 7. Batch 07: UI Buttons & Joystick -> 100x100, center
    process_batch("batch_07_ui.png", os.path.join(OUT_BASE, "ui"), 
                  120, 120, "center", "ui")
                  
    # 8. Batch 08: Decals & VFX -> 128x128, center
    process_batch("batch_08_decals_vfx.png", os.path.join(OUT_BASE, "vfx_hazards"), 
                  128, 128, "center", "fx_hazard")

    # 9. Batch 00: Room Arena Background
    room_in = os.path.join(INBOX_DIR, "batch_00_room_arena.png")
    if os.path.exists(room_in):
        os.makedirs(os.path.join(OUT_BASE, "environment"), exist_ok=True)
        img = Image.open(room_in)
        # Background arena keeps full resolution or scales to Full HD 1920x1080
        arena = img.convert("RGBA").resize((1920, 1080), Image.Resampling.LANCZOS)
        arena_out = os.path.join(OUT_BASE, "environment", "room_arena.png")
        arena.save(arena_out, "PNG")
        print(f"    Saved Arena Background: {arena_out} (1920x1080)")

    print("=== SLICING COMPLETED SUCCESSFULLY ===")

if __name__ == "__main__":
    main()
