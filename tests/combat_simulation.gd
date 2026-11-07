extends Node

func _ready() -> void:
	print("Starting Combat Action Visual Simulation...")
	var arena_scene = load("res://scenes/arena.tscn")
	var arena = arena_scene.instantiate()
	add_child(arena)
	
	# Wait for scene ready
	for i in range(5):
		await get_tree().process_frame
		
	var p1: Player = arena.get_node("YSortArena/Player1")
	var p2: Player = arena.get_node("YSortArena/Player2")
	
	# P1 picks up hammer
	p1.pick_up("hammer")
	
	# P1 moves close to P2
	p1.global_position = Vector2(980, 680)
	p2.global_position = Vector2(1060, 680)
	p1.facing_direction = Vector2.RIGHT
	p2.facing_direction = Vector2.LEFT
	
	# P1 attacks with hammer
	p1.trigger_attack()
	
	# Let 8 frames elapse so hammer smash, comic_hit VFX and airborne knockback are fully visible
	for i in range(8):
		await get_tree().process_frame
		
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("/tmp/combat_verified.png")
		img.save_png("/Users/thanhpv/.gemini/antigravity/brain/52fcd753-e979-4a3e-8b11-49ae9ce21f95/combat_verified.png")
		print("Combat action screenshot saved to combat_verified.png")
	
	get_tree().quit(0)
