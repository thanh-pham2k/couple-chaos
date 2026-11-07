extends Node

func _ready() -> void:
	print("Instantiating arena scene for screenshot...")
	var arena_scene = load("res://scenes/arena.tscn")
	var arena = arena_scene.instantiate()
	add_child(arena)
	
	# Let scene run for 20 frames
	for i in range(20):
		await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("/tmp/couple_chaos_gameplay.png")
		img.save_png("/Users/thanhpv/.gemini/antigravity/brain/52fcd753-e979-4a3e-8b11-49ae9ce21f95/gameplay_verified.png")
		print("Screenshot save successful!")
	else:
		push_error("Viewport texture image is null!")
	get_tree().quit(0)
