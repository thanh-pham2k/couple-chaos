#!/usr/bin/env python3
"""
tools/organize_production_assets.py
Maps sliced sprites to clean semantic filenames for Godot 4.
"""

import os
import shutil

def copy_if_exists(src, dst):
    if os.path.exists(src):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(src, dst)
        print(f"Mapped: {dst}")
    else:
        print(f"[MISSING] {src}")

def main():
    print("=== MAPPING SEMANTIC ASSETS FOR GODOT ===")
    
    # Boy
    b_dir = "assets/characters/boy"
    copy_if_exists(f"{b_dir}/boy_01.png", f"{b_dir}/idle.png")
    copy_if_exists(f"{b_dir}/boy_02.png", f"{b_dir}/run.png")
    copy_if_exists(f"{b_dir}/boy_03.png", f"{b_dir}/dash.png")
    copy_if_exists(f"{b_dir}/boy_04.png", f"{b_dir}/carry.png")
    copy_if_exists(f"{b_dir}/boy_10.png", f"{b_dir}/swing.png")
    copy_if_exists(f"{b_dir}/boy_11.png", f"{b_dir}/throw.png")
    copy_if_exists(f"{b_dir}/boy_12.png", f"{b_dir}/slip.png")
    copy_if_exists(f"{b_dir}/boy_14.png", f"{b_dir}/stunned.png")
    
    # Girl
    g_dir = "assets/characters/girl"
    copy_if_exists(f"{g_dir}/girl_01.png", f"{g_dir}/idle.png")
    copy_if_exists(f"{g_dir}/girl_02.png", f"{g_dir}/run.png")
    copy_if_exists(f"{g_dir}/girl_03.png", f"{g_dir}/dash.png")
    copy_if_exists(f"{g_dir}/girl_04.png", f"{g_dir}/carry.png")
    copy_if_exists(f"{g_dir}/girl_05.png", f"{g_dir}/slam.png")
    copy_if_exists(f"{g_dir}/girl_11.png", f"{g_dir}/throw.png")
    copy_if_exists(f"{g_dir}/girl_12.png", f"{g_dir}/angry.png")
    copy_if_exists(f"{g_dir}/girl_13.png", f"{g_dir}/victory.png")
    
    # Cat
    c_dir = "assets/pets/cat"
    copy_if_exists(f"{c_dir}/cat_01.png", f"{c_dir}/sleep.png")
    copy_if_exists(f"{c_dir}/cat_02.png", f"{c_dir}/startled.png")
    copy_if_exists(f"{c_dir}/cat_04.png", f"{c_dir}/run.png")
    copy_if_exists(f"{c_dir}/cat_08.png", f"{c_dir}/hiss.png")
    
    # Items
    i_dir = "assets/items"
    copy_if_exists(f"{i_dir}/item_01.png", f"{i_dir}/hammer.png")
    copy_if_exists(f"{i_dir}/item_02.png", f"{i_dir}/pillow.png")
    copy_if_exists(f"{i_dir}/item_03.png", f"{i_dir}/boba.png")
    copy_if_exists(f"{i_dir}/item_08.png", f"{i_dir}/popcorn.png")
    copy_if_exists(f"{i_dir}/item_09.png", f"{i_dir}/banana.png")
    copy_if_exists(f"{i_dir}/item_10.png", f"{i_dir}/box.png")
    copy_if_exists(f"{i_dir}/item_11.png", f"{i_dir}/wallet.png")
    copy_if_exists(f"{i_dir}/item_13.png", f"{i_dir}/gamepad.png")
    
    # Furniture Living
    fl_dir = "assets/furniture/living"
    f_dir = "assets/furniture"
    copy_if_exists(f"{fl_dir}/fur_living_01.png", f"{f_dir}/sofa.png")
    copy_if_exists(f"{fl_dir}/fur_living_02.png", f"{f_dir}/coffee_table.png")
    copy_if_exists(f"{fl_dir}/fur_living_03.png", f"{f_dir}/workstation.png")
    copy_if_exists(f"{fl_dir}/fur_living_04.png", f"{f_dir}/office_chair.png")
    copy_if_exists(f"{fl_dir}/fur_living_05.png", f"{f_dir}/tv_console.png")
    copy_if_exists(f"{fl_dir}/fur_living_06.png", f"{f_dir}/rug.png")
    
    # Furniture Kitchen & Bed
    fk_dir = "assets/furniture/kitchen_bed"
    copy_if_exists(f"{fk_dir}/fur_kitchen_01.png", f"{f_dir}/fridge.png")
    copy_if_exists(f"{fk_dir}/fur_kitchen_02.png", f"{f_dir}/bed.png")
    copy_if_exists(f"{fk_dir}/fur_kitchen_03.png", f"{f_dir}/counter.png")
    copy_if_exists(f"{fk_dir}/fur_kitchen_04.png", f"{f_dir}/dining_set.png")
    copy_if_exists(f"{fk_dir}/fur_kitchen_05.png", f"{f_dir}/entryway.png")
    
    # UI
    u_dir = "assets/ui"
    copy_if_exists(f"{u_dir}/ui_01.png", f"{u_dir}/avatar_p1.png")
    copy_if_exists(f"{u_dir}/ui_02.png", f"{u_dir}/avatar_p2.png")
    copy_if_exists(f"{u_dir}/ui_03.png", f"{u_dir}/btn_hammer.png")
    copy_if_exists(f"{u_dir}/ui_04.png", f"{u_dir}/btn_dash.png")
    copy_if_exists(f"{u_dir}/ui_05.png", f"{u_dir}/btn_grab.png")
    copy_if_exists(f"{u_dir}/ui_06.png", f"{u_dir}/joystick_base.png")
    copy_if_exists(f"{u_dir}/ui_07.png", f"{u_dir}/joystick_stick.png")
    copy_if_exists(f"{u_dir}/ui_10.png", f"{u_dir}/hotbar_slot.png")
    copy_if_exists(f"{u_dir}/ui_19.png", f"{u_dir}/heart.png")
    
    # Hazards & VFX
    v_dir = "assets/vfx_hazards"
    h_dir = "assets/hazards"
    vf_dir = "assets/vfx"
    copy_if_exists(f"{v_dir}/fx_hazard_07.png", f"{h_dir}/boba_puddle.png")
    copy_if_exists(f"{v_dir}/fx_hazard_09.png", f"{h_dir}/popcorn_mess.png")
    copy_if_exists(f"{v_dir}/fx_hazard_19.png", f"{h_dir}/banana_peel.png")
    copy_if_exists(f"{v_dir}/fx_hazard_06.png", f"{vf_dir}/feather_burst.png")
    copy_if_exists(f"{v_dir}/fx_hazard_21.png", f"{vf_dir}/stun_stars.png")
    copy_if_exists(f"{v_dir}/fx_hazard_25.png", f"{vf_dir}/dash_smoke.png")
    
    print("=== MAPPING COMPLETED ===")

if __name__ == "__main__":
    main()
