#!/usr/bin/env python3
"""
tools/create_apartment_background.py
Renders a gorgeous, cohesive cozy 2D isometric apartment background plate (1920x1080)
matching the visual bible of party-chaos.jpg.
"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np

def create_cozy_apartment_bg(width=1920, height=1080):
    img = Image.new("RGBA", (width, height), (250, 240, 230, 255))
    draw = ImageDraw.Draw(img)
    
    wall_height = 240
    
    # 1. Back Wall (Top area y=0 to 240)
    # Warm cream pastel wall
    wall_color = (248, 238, 226, 255)
    draw.rectangle([0, 0, width, wall_height], fill=wall_color)
    
    # Subtle vertical wall panel stripes
    for x in range(0, width, 48):
        draw.line([(x, 0), (x, wall_height)], fill=(240, 228, 214, 255), width=2)
        
    # Top ceiling crown molding
    draw.rectangle([0, 0, width, 18], fill=(235, 220, 204, 255))
    draw.line([(0, 18), (width, 18)], fill=(215, 198, 180, 255), width=2)
    
    # Baseboard molding at bottom of wall
    draw.rectangle([0, wall_height - 24, width, wall_height], fill=(188, 134, 94, 255))
    draw.line([(0, wall_height - 24), (width, wall_height - 24)], fill=(155, 105, 68, 255), width=3)
    draw.line([(0, wall_height), (width, wall_height)], fill=(130, 85, 52, 255), width=3)
    
    # 2. Main Floor (y = wall_height to height)
    # Warm Oak Wood Planks
    plank_h = 36
    plank_colors = [
        (224, 178, 132, 255),
        (216, 170, 124, 255),
        (228, 182, 138, 255),
        (212, 164, 118, 255),
        (220, 174, 128, 255)
    ]
    
    for row_idx, y in enumerate(range(wall_height, height, plank_h)):
        row_color = plank_colors[row_idx % len(plank_colors)]
        draw.rectangle([0, y, width, min(height, y + plank_h)], fill=row_color)
        # Horizontal plank seam
        draw.line([(0, y), (width, y)], fill=(184, 136, 94, 255), width=2)
        
        # Vertical staggered seams
        offset = (row_idx * 160) % 240
        for x in range(offset, width, 240):
            draw.line([(x, y), (x, y + plank_h)], fill=(184, 136, 94, 255), width=2)
            
    # 3. Kitchen Tile Zone (Right side: x=1420 to width, y=wall_height to 720)
    tile_size = 48
    tile_colors = [
        (244, 238, 232, 255),
        (236, 228, 220, 255)
    ]
    for r, y in enumerate(range(wall_height, 740, tile_size)):
        for c, x in enumerate(range(1420, width, tile_size)):
            tc = tile_colors[(r + c) % 2]
            draw.rectangle([x, y, min(width, x + tile_size), min(740, y + tile_size)], fill=tc)
            # Grout lines
            draw.rectangle([x, y, min(width, x + tile_size), min(740, y + tile_size)], outline=(214, 204, 194, 255), width=2)
            
    # Transition strip between wood and kitchen tiles
    draw.line([(1420, wall_height), (1420, 740)], fill=(160, 110, 75, 255), width=6)
    draw.line([(1420, 740), (width, 740)], fill=(160, 110, 75, 255), width=6)

    # 4. Entrance Doorway Arch & Recess on Back Wall (centered at x=1050)
    door_w, door_h = 160, 205
    door_x, door_y = 1050 - door_w // 2, wall_height - door_h
    # Door outer casing moulding
    draw.rectangle([door_x - 10, door_y - 10, door_x + door_w + 10, wall_height], fill=(210, 190, 172, 255), outline=(175, 155, 138, 255), width=2)
    # Door alcove / recess shadow
    draw.rectangle([door_x, door_y, door_x + door_w, wall_height], fill=(232, 222, 212, 255))
    
    # Entrance welcome mat on floor
    mat_x0, mat_y0 = 1050 - 110, wall_height + 6
    mat_x1, mat_y1 = 1050 + 110, wall_height + 65
    draw.rounded_rectangle([mat_x0, mat_y0, mat_x1, mat_y1], radius=10, fill=(198, 180, 160, 255), outline=(160, 140, 120, 255), width=3)
    
    # 5. Window on Back Wall (Above Work Desk: x=160 to 340)
    win_x, win_y = 160, 35
    win_w, win_h = 180, 140
    # Window frame
    draw.rounded_rectangle([win_x - 8, win_y - 8, win_x + win_w + 8, win_y + win_h + 8], radius=6, fill=(235, 222, 210, 255), outline=(190, 175, 160, 255), width=3)
    # Window sky/glass (sunny pastel blue/gold)
    draw.rectangle([win_x, win_y, win_x + win_w, win_y + win_h], fill=(215, 238, 250, 255))
    # Window panes
    draw.line([(win_x + win_w//2, win_y), (win_x + win_w//2, win_y + win_h)], fill=(235, 222, 210, 255), width=4)
    draw.line([(win_x, win_y + win_h//2), (win_x + win_w, win_y + win_h//2)], fill=(235, 222, 210, 255), width=4)
    # Soft window sill
    draw.rectangle([win_x - 14, win_y + win_h + 4, win_x + win_w + 14, win_y + win_h + 16], fill=(210, 195, 180, 255), outline=(175, 160, 145, 255), width=2)
    
    # 6. Soft ambient wall contact shadow on floor
    shadow_overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_overlay)
    for i in range(16):
        alpha = int((1.0 - i / 16.0) * 45)
        s_draw.line([(0, wall_height + i), (width, wall_height + i)], fill=(0, 0, 0, alpha), width=1)
    
    img = Image.alpha_composite(img, shadow_overlay)
    
    # Save background
    img.save("assets/environment/room_arena.png", "PNG")
    print("✓ Successfully generated assets/environment/room_arena.png (1920x1080)")

if __name__ == "__main__":
    create_cozy_apartment_bg()
