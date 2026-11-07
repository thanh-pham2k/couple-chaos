#!/usr/bin/env python3
"""
tools/extract_all_assets_perfect.py
Precision sprite extractor that:
1. Uses explicit bounding boxes for every single asset to prevent merging or wrong crops.
2. Performs boundary flood-fill to remove pure white background without touching interior white details.
3. Applies smooth alpha feathering to eliminate white halos.
4. Scales and pads each sprite according to the exact ASSET_RULES.md dimensions and anchors.
"""

import os
import numpy as np
import scipy.ndimage as ndi
from PIL import Image

INBOX = "asset/inbox"
ASSETS_OUT = "assets"

def make_transparent_crop(source_img, crop_box, white_thresh=242):
    """
    Crops crop_box = (x0, y0, x1, y1) from source_img, then flood-fills
    the exterior background with transparent alpha.
    """
    crop = source_img.crop(crop_box).convert("RGBA")
    arr = np.array(crop)
    rgb = arr[:, :, :3]
    
    # Identify near-white pixels
    is_white = np.all(rgb >= white_thresh, axis=2)
    labeled, num_features = ndi.label(is_white)
    
    # Border labels (connected to edge of this crop)
    border_labels = set(np.unique(labeled[0, :])) | \
                    set(np.unique(labeled[-1, :])) | \
                    set(np.unique(labeled[:, 0])) | \
                    set(np.unique(labeled[:, -1]))
    border_labels.discard(0)
    
    ext_bg = np.isin(labeled, list(border_labels))
    alpha = np.where(ext_bg, 0, 255).astype(np.uint8)
    
    # Edge feathering (1.5px transition)
    dist = ndi.distance_transform_edt(ext_bg)
    near_edge = (dist > 0) & (dist <= 1.8)
    if np.any(near_edge):
        white_intensity = np.mean(rgb[near_edge].astype(float), axis=1)
        edge_alpha = np.clip((255 - white_intensity) * 2.5, 0, 255).astype(np.uint8)
        alpha[near_edge] = edge_alpha
        
    arr[:, :, 3] = alpha
    result = Image.fromarray(arr, "RGBA")
    
    # Crop to non-zero alpha tight bounding box
    bbox = result.getbbox()
    if bbox:
        result = result.crop(bbox)
    return result

def fit_to_target(img, target_w, target_h, anchor="bottom_center"):
    orig_w, orig_h = img.size
    scale = min(target_w / orig_w, target_h / orig_h)
    new_w = max(1, int(orig_w * scale))
    new_h = max(1, int(orig_h * scale))
    
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
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

def main():
    print("=== STARTING PRECISION SPRITE EXTRACTION ===")
    
    # 1. BOY (image.png) -> 128x160, bottom_center
    src_boy = Image.open(os.path.join(INBOX, "image.png"))
    boy_specs = {
        "idle": (83, 13, 333, 436),
        "run": (506, 24, 772, 429),
        "dash": (836, 50, 1259, 403),
        "carry": (1344, 16, 1599, 440),
        "swing": (54, 487, 380, 897),
        "throw": (425, 493, 677, 898),
        "slip": (861, 516, 1257, 831),
        "stunned": (1307, 535, 1604, 889)
    }
    os.makedirs(f"{ASSETS_OUT}/characters/boy", exist_ok=True)
    for pose, box in boy_specs.items():
        crop = make_transparent_crop(src_boy, box)
        fitted = fit_to_target(crop, 128, 160, "bottom_center")
        out_p = f"{ASSETS_OUT}/characters/boy/{pose}.png"
        fitted.save(out_p, "PNG")
        print(f"  [Boy] {pose} -> {out_p} (128x160)")

    # 2. GIRL (image copy.png) -> 128x160, bottom_center
    src_girl = Image.open(os.path.join(INBOX, "image copy.png"))
    girl_specs = {
        "idle": (68, 20, 326, 444),
        "run": (477, 25, 735, 431),
        "dash": (893, 24, 1233, 391),
        "carry": (1282, 21, 1654, 438),
        "slam": (35, 485, 340, 901),
        "throw": (452, 480, 721, 906),
        "angry": (924, 472, 1183, 906),
        "victory": (1290, 469, 1579, 816)
    }
    os.makedirs(f"{ASSETS_OUT}/characters/girl", exist_ok=True)
    for pose, box in girl_specs.items():
        crop = make_transparent_crop(src_girl, box)
        fitted = fit_to_target(crop, 128, 160, "bottom_center")
        out_p = f"{ASSETS_OUT}/characters/girl/{pose}.png"
        fitted.save(out_p, "PNG")
        print(f"  [Girl] {pose} -> {out_p} (128x160)")

    # 3. CAT (image copy 2.png) -> 64x64, bottom_center
    src_cat = Image.open(os.path.join(INBOX, "image copy 2.png"))
    cat_specs = {
        "sleep": (287, 137, 667, 417),
        "startled": (940, 30, 1363, 359),
        "run": (296, 545, 760, 836),
        "hiss": (943, 486, 1427, 894)
    }
    os.makedirs(f"{ASSETS_OUT}/pets/cat", exist_ok=True)
    for pose, box in cat_specs.items():
        crop = make_transparent_crop(src_cat, box)
        fitted = fit_to_target(crop, 64, 64, "bottom_center")
        out_p = f"{ASSETS_OUT}/pets/cat/{pose}.png"
        fitted.save(out_p, "PNG")
        print(f"  [Cat] {pose} -> {out_p} (64x64)")

    # 4. LIVING FURNITURE (image copy 3.png)
    src_fl = Image.open(os.path.join(INBOX, "image copy 3.png"))
    living_specs = {
        "sofa": ((40, 60, 720, 460), 260, 160, "bottom_center"),
        "coffee_table": ((760, 147, 1138, 443), 140, 90, "bottom_center"),
        "workstation": ((1169, 52, 1633, 497), 180, 140, "bottom_center"),
        "office_chair": ((155, 529, 397, 871), 80, 90, "bottom_center"),
        "tv_console": ((526, 463, 1034, 896), 200, 160, "bottom_center"),
        "rug": ((1095, 573, 1595, 884), 320, 180, "center")
    }
    os.makedirs(f"{ASSETS_OUT}/furniture", exist_ok=True)
    for name, (box, tw, th, anc) in living_specs.items():
        crop = make_transparent_crop(src_fl, box)
        fitted = fit_to_target(crop, tw, th, anc)
        out_p = f"{ASSETS_OUT}/furniture/{name}.png"
        fitted.save(out_p, "PNG")
        print(f"  [Furniture] {name} -> {out_p} ({tw}x{th})")

    # 5. KITCHEN & BEDROOM FURNITURE (image copy 4.png)
    src_fk = Image.open(os.path.join(INBOX, "image copy 4.png"))
    kitchen_specs = {
        "fridge": ((69, 11, 373, 520), 120, 200, "bottom_center"),
        "bed": ((431, 29, 1054, 519), 240, 240, "bottom_center"),
        "counter": ((1070, 21, 1616, 491), 220, 150, "bottom_center"),
        "dining_set": ((137, 510, 808, 925), 180, 140, "bottom_center"),
        "entryway": ((952, 486, 1230, 920), 140, 190, "bottom_center")
    }
    for name, (box, tw, th, anc) in kitchen_specs.items():
        crop = make_transparent_crop(src_fk, box)
        fitted = fit_to_target(crop, tw, th, anc)
        out_p = f"{ASSETS_OUT}/furniture/{name}.png"
        fitted.save(out_p, "PNG")
        print(f"  [Furniture] {name} -> {out_p} ({tw}x{th})")

    # 6. ITEMS & WEAPONS (image copy 5.png) -> 64x64, center
    src_items = Image.open(os.path.join(INBOX, "image copy 5.png"))
    item_specs = {
        "hammer": (45, 75, 394, 452),
        "pillow": (455, 122, 839, 443),
        "boba": (908, 59, 1166, 436),
        "popcorn": (1265, 96, 1630, 451),
        "banana": (19, 554, 206, 787),
        "box": (466, 566, 855, 859),
        "wallet": (886, 556, 1192, 861),
        "gamepad": (1254, 590, 1639, 838)
    }
    os.makedirs(f"{ASSETS_OUT}/items", exist_ok=True)
    for name, box in item_specs.items():
        crop = make_transparent_crop(src_items, box)
        fitted = fit_to_target(crop, 64, 64, "center")
        out_p = f"{ASSETS_OUT}/items/{name}.png"
        fitted.save(out_p, "PNG")
        print(f"  [Item] {name} -> {out_p} (64x64)")

    # 7. HAZARDS & DECALS (image copy 6.png) and VFX (image copy 7.png)
    src_decals = Image.open(os.path.join(INBOX, "image copy 6.png"))
    src_vfx = Image.open(os.path.join(INBOX, "image copy 7.png"))
    os.makedirs(f"{ASSETS_OUT}/hazards", exist_ok=True)
    os.makedirs(f"{ASSETS_OUT}/vfx", exist_ok=True)
    
    # Floor Hazards & Decals (image copy 6)
    boba_puddle = make_transparent_crop(src_decals, (104, 78, 709, 422))
    fit_to_target(boba_puddle, 128, 80, "center").save(f"{ASSETS_OUT}/hazards/boba_puddle.png")
    
    popcorn_mess = make_transparent_crop(src_decals, (965, 50, 1568, 423))
    fit_to_target(popcorn_mess, 110, 70, "center").save(f"{ASSETS_OUT}/hazards/popcorn_mess.png")
    
    banana_peel = make_transparent_crop(src_decals, (558, 411, 1058, 623))
    fit_to_target(banana_peel, 64, 48, "center").save(f"{ASSETS_OUT}/hazards/banana_peel.png")
    
    # Action VFX (image copy 7)
    feather_burst = make_transparent_crop(src_vfx, (50, 20, 750, 450))
    fit_to_target(feather_burst, 128, 128, "center").save(f"{ASSETS_OUT}/vfx/feather_burst.png")
    
    stun_stars = make_transparent_crop(src_vfx, (888, 25, 1508, 283))
    fit_to_target(stun_stars, 100, 70, "center").save(f"{ASSETS_OUT}/vfx/stun_stars.png")
    
    dash_smoke = make_transparent_crop(src_vfx, (1100, 320, 1505, 555))
    fit_to_target(dash_smoke, 100, 80, "center").save(f"{ASSETS_OUT}/vfx/dash_smoke.png")
    
    comic_hit = make_transparent_crop(src_vfx, (66, 561, 592, 912))
    fit_to_target(comic_hit, 110, 90, "center").save(f"{ASSETS_OUT}/vfx/comic_hit.png")
    print("  [Hazards & VFX] Extracted all decals and effects.")

    # 8. UI ELEMENTS (image copy 8.png)
    src_ui = Image.open(os.path.join(INBOX, "image copy 8.png"))
    os.makedirs(f"{ASSETS_OUT}/ui", exist_ok=True)
    
    avatar = make_transparent_crop(src_ui, (188, 12, 517, 338))
    fit_to_target(avatar, 80, 80, "center").save(f"{ASSETS_OUT}/ui/avatar_p1.png")
    fit_to_target(avatar, 80, 80, "center").save(f"{ASSETS_OUT}/ui/avatar_p2.png")
    
    heart = make_transparent_crop(src_ui, (584, 80, 781, 250))
    fit_to_target(heart, 36, 36, "center").save(f"{ASSETS_OUT}/ui/heart.png")
    
    stamina = make_transparent_crop(src_ui, (837, 65, 1483, 267))
    fit_to_target(stamina, 160, 24, "center").save(f"{ASSETS_OUT}/ui/stamina_bar.png")
    
    btn_hammer = make_transparent_crop(src_ui, (53, 360, 391, 700))
    fit_to_target(btn_hammer, 100, 100, "center").save(f"{ASSETS_OUT}/ui/btn_hammer.png")
    
    btn_dash = make_transparent_crop(src_ui, (452, 359, 787, 696))
    fit_to_target(btn_dash, 72, 72, "center").save(f"{ASSETS_OUT}/ui/btn_dash.png")
    
    btn_grab = make_transparent_crop(src_ui, (817, 358, 1149, 694))
    fit_to_target(btn_grab, 72, 72, "center").save(f"{ASSETS_OUT}/ui/btn_grab.png")
    
    joy_base = make_transparent_crop(src_ui, (1184, 320, 1589, 717))
    fit_to_target(joy_base, 160, 160, "center").save(f"{ASSETS_OUT}/ui/joystick_base.png")
    
    # Joy stick knob (inner circle of joystick)
    joy_stick = joy_base.crop((joy_base.size[0]//4, joy_base.size[1]//4, 3*joy_base.size[0]//4, 3*joy_base.size[1]//4))
    fit_to_target(joy_stick, 70, 70, "center").save(f"{ASSETS_OUT}/ui/joystick_stick.png")
    
    # Hotbar slot & full tray
    hotbar = make_transparent_crop(src_ui, (251, 735, 1414, 927))
    fit_to_target(hotbar, 480, 78, "center").save(f"{ASSETS_OUT}/ui/hotbar_tray.png")
    slot_w = hotbar.size[0] // 5
    slot_1 = hotbar.crop((0, 0, slot_w, hotbar.size[1]))
    fit_to_target(slot_1, 56, 56, "center").save(f"{ASSETS_OUT}/ui/hotbar_slot.png")
    print("  [UI] Extracted all mobile touch and HUD controls.")

    print("=== ALL ASSETS EXTRACTED WITH MATHEMATICAL PRECISION! ===")

if __name__ == "__main__":
    main()
