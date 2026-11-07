extends Node

func _ready() -> void:
	var packed := load("res://scenes/coop_slice.tscn") as PackedScene
	assert(packed != null)
	var game = packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()
	
	var p1: Player = game.arena.p1
	var p2: Player = game.arena.p2
	
	# 1. Test Sofa Pillow placement anchors, texture & markers
	var pillow_1_zone: CoopDropZone = null
	var pillow_2_zone: CoopDropZone = null
	var mop_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "pillow_1": pillow_1_zone = z
		elif z.target_id == "pillow_2": pillow_2_zone = z
		elif z.target_id == "mop_station": mop_zone = z
		
	assert(pillow_1_zone != null and pillow_2_zone != null, "Pillow zones must exist")
	assert(mop_zone != null, "Mop return station must exist")
	assert(pillow_1_zone.position == Vector2(565, 435), "Pillow 1 must align with left sofa seat cushion")
	assert(pillow_2_zone.position == Vector2(675, 435), "Pillow 2 must align with right sofa seat cushion")
	assert(pillow_1_zone.marker.visible and pillow_2_zone.marker.visible, "Markers must be visible before placement")
	
	# Place Pillow 1
	p1.global_position = pillow_1_zone.global_position + Vector2(0, 30)
	p1.pick_up("coop_pillow_1")
	assert(p1.held_item_type == "coop_pillow_1")
	assert(game.try_interact(p1), "Must interact with pillow zone")
	# Simulate placement release and completion
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(pillow_1_zone.completed, "Pillow 1 zone must be completed")
	assert(not pillow_1_zone.marker.visible, "Marker must be hidden after placement")
	var placed_pillow_1 = pillow_1_zone.get_node_or_null("PlacedPillow")
	assert(placed_pillow_1 != null and placed_pillow_1.texture.resource_path.ends_with("sofa_pillow_1.png"), "Placed pillow 1 must use sofa_pillow_1.png")
	game._physics_process(game.PLACE_DURATION)
	
	# 2. Test Mop Station Inactive before cleaning
	p1.global_position = mop_zone.global_position + Vector2(0, 40)
	p1.pick_up("coop_mop")
	assert(p1.held_item_type == "coop_mop")
	assert(not mop_zone.can_accept(p1.held_item_type), "Mop station must not accept mop before cleaning is done")
	mop_zone.refresh()
	assert(mop_zone.prompt.text.begins_with("HÃY LAU SÀN TRƯỚC"), "Prompt must instruct players to clean first")
	
	# Test Mop Scrubbing in air / away from spot
	p1.global_position = Vector2(900, 500)
	assert(game.try_use(p1), "Try use away from spot must still swing mop")
	assert(p1.is_scrubbing_mop and p1.attack_tween != null and p1.attack_tween.is_valid(), "Player must swing mop even in open space")
	
	# 3. Test Mop Cleaning & Scrubbing Animation on Spot 1
	var spot: CleaningSpot = game.spots[0]
	p1.global_position = spot.global_position + Vector2(0, 40)
	var prev_progress = spot.progress
	assert(game.try_use(p1), "Try use mop must scrub spot")
	assert(spot.progress == prev_progress + 1, "Scrub must advance progress")
	assert(p1.is_scrubbing_mop and p1.attack_tween.is_valid(), "Player must play dynamic mop scrubbing sweep on spot")
	
	# Complete spot 1 (3/3)
	game.try_use(p1)
	game.try_use(p1)
	assert(spot.state == "clean", "Spot 1 must be clean after 3 scrubs")
	assert(not spot.graphic.visible, "Decal must be hidden when clean")
	
	# Complete spot 2 (3/3)
	var spot2: CleaningSpot = game.spots[1]
	p1.global_position = spot2.global_position + Vector2(0, 40)
	game.try_use(p1)
	game.try_use(p1)
	game.try_use(p1)
	assert(spot2.state == "clean", "Spot 2 must be clean")
	assert(game.quest.get_count("clean") == 2, "Clean quest category must be 2/2")
	
	# 4. Test Mop Return Station Active after cleaning
	p1.global_position = mop_zone.global_position + Vector2(0, 40)
	assert(mop_zone.can_accept(p1.held_item_type), "Mop zone must accept mop when cleaning is done")
	mop_zone.refresh()
	assert(mop_zone.prompt.text.contains("CẤT CÂY LAU"), "Prompt must change to Cất cây lau")
	assert(game.try_interact(p1), "Must place mop into mop station")
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(mop_zone.completed, "Mop station must be completed")
	game._physics_process(game.PLACE_DURATION)
	assert(p1.held_item_type.is_empty(), "Mop must be cleared from player hands")
	var placed_mop = mop_zone.get_node_or_null("PlacedMop")
	assert(placed_mop != null and placed_mop.texture.resource_path.ends_with("mop.png"), "Mop must be placed upright at station")
	
	print("Co-op mop scrubbing animation, mop return station, and sofa pillow anchors verified successfully!")
	get_tree().quit()
