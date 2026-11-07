extends Node

func _ready() -> void:
	print("--- Starting Mop Storage Rack & Sofa Pillow Interaction QA Test ---")
	
	# 1. ASSET QA VALIDATION
	var rack_tex := load("res://assets/coop/advanced/mop_rack.png") as Texture2D
	var pillow_1_tex := load("res://assets/coop/advanced/sofa_pillow_1.png") as Texture2D
	var pillow_2_tex := load("res://assets/coop/advanced/sofa_pillow_2.png") as Texture2D
	assert(rack_tex != null, "Mop rack asset must be imported and valid")
	assert(pillow_1_tex != null, "Sofa pillow 1 asset must be imported and valid")
	assert(pillow_2_tex != null, "Sofa pillow 2 asset must be imported and valid")
	assert(rack_tex.get_size() == Vector2(96, 28), "Mop rack must be 96x28 px")
	assert(pillow_1_tex.get_size() == Vector2(64, 64), "Pillow 1 canvas must be 64x64 px")
	assert(pillow_2_tex.get_size() == Vector2(64, 64), "Pillow 2 canvas must be 64x64 px")

	# 2. SCENE INSTANTIATION & SETUP
	var packed := load("res://scenes/coop_slice.tscn") as PackedScene
	assert(packed != null, "Coop slice scene must exist")
	var game = packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()
	
	var p1: Player = game.arena.p1
	var p2: Player = game.arena.p2
	assert(is_instance_valid(p1) and is_instance_valid(p2), "Both P1 (Boy) and P2 (Girl) must exist")
	
	var mop_zone: CoopDropZone = null
	var pillow_1_zone: CoopDropZone = null
	var pillow_2_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "mop_station": mop_zone = z
		elif z.target_id == "pillow_1": pillow_1_zone = z
		elif z.target_id == "pillow_2": pillow_2_zone = z
		
	assert(mop_zone != null, "Mop storage station must be instantiated")
	assert(pillow_1_zone != null and pillow_2_zone != null, "Both pillow drop zones must be instantiated")

	# 3. MOP RACK POSITIONING & GEOMETRY
	# Rack mounted on kitchen wall near counter (counter is at (1540, 260))
	assert(mop_zone.position == Vector2(1400, 270), "Mop rack must be mounted near the kitchen at (1400, 270)")
	assert(mop_zone.prop != null, "Mop rack sprite prop must exist")
	assert(mop_zone.prop.texture.resource_path.ends_with("mop_rack.png"), "Mop rack prop must use mop_rack.png")

	# 4. SOFA PILLOW ANCHORS & SEAT GEOMETRY
	var sofa := game.arena.get_node("YSortArena/Sofa") as Node2D
	assert(sofa != null, "Sofa must exist")
	var sofa_back := game.arena.get_node("YSortArena/SofaBack") as Sprite2D
	assert(sofa_back != null, "SofaBack must exist for natural backrest/cushion Y-sort layer")
	assert(sofa_back.position.y == 410.0, "SofaBack must be at y=410 to render under pillows")
	assert(sofa_back.texture.resource_path.ends_with("sofa_back_cushion.png"), "SofaBack must use sofa_back_cushion.png")
	assert(sofa.get_node("Sprite2D").texture.resource_path.ends_with("sofa_front.png"), "Sofa front must use sofa_front.png to occlude pillows")

	var slot_l := sofa.get_node("PillowSlotLeft") as Marker2D
	var slot_r := sofa.get_node("PillowSlotRight") as Marker2D
	assert(slot_l != null and slot_r != null, "Sofa must have PillowSlotLeft and PillowSlotRight anchor markers")
	assert(slot_l.position == Vector2(-58, -64), "PillowSlotLeft must be at (-58, -64) on seat cushion")
	assert(slot_r.position == Vector2(58, -64), "PillowSlotRight must be at (58, -64) on seat cushion")
	assert(pillow_1_zone.position == sofa.to_global(slot_l.position), "Pillow 1 zone must align with PillowSlotLeft")
	assert(pillow_2_zone.position == sofa.to_global(slot_r.position), "Pillow 2 zone must align with PillowSlotRight")
	assert(pillow_1_zone.position.y == 426.0, "Pillow 1 must sit on seat cushion at y=426, not on backrest or floor")
	assert(pillow_2_zone.position.y == 426.0, "Pillow 2 must sit on seat cushion at y=426, not on backrest or floor")

	# 5. TEST BOY (P1) PICKUP, CARRY & PLACE PILLOW 1
	p1.pick_up("coop_pillow_1")
	assert(p1.held_item_type == "coop_pillow_1", "P1 must hold pillow 1")
	p1.global_position = pillow_1_zone.global_position
	assert(pillow_1_zone.marker.visible, "Marker must be visible while item is not placed")
	assert(game.try_interact(p1), "P1 must interact with pillow slot")
	assert(p1.is_placing, "P1 must play placement animation")
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(p1.held_item_type.is_empty(), "Pillow must release from P1 hand at release time")
	assert(pillow_1_zone.completed, "Pillow 1 zone must be completed")
	assert(not pillow_1_zone.marker.visible, "Placement marker must be hidden once completed")
	var placed_p1 := pillow_1_zone.get_node_or_null("PlacedPillow") as Sprite2D
	assert(placed_p1 != null, "PlacedPillow node must be added to slot")
	assert(placed_p1.z_index == 0, "Placed pillow z_index must be 0 for natural Y-sort occlusion under sofa front")
	assert(placed_p1.scale == Vector2(0.68, 0.68), "Placed pillow scale must be reduced to Vector2(0.68, 0.68)")
	game._physics_process(game.PLACE_DURATION)
	assert(not p1.is_placing, "P1 placement animation must end")
	assert(game.quest.get_count("pillow") == 1, "Pillow quest count must be 1/2")

	# 6. TEST GIRL (P2) PICKUP, CARRY & PLACE PILLOW 2
	p2.pick_up("coop_pillow_2")
	assert(p2.held_item_type == "coop_pillow_2", "P2 must hold pillow 2")
	p2.global_position = pillow_2_zone.global_position
	assert(game.try_interact(p2), "P2 must interact with pillow slot 2")
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(p2.held_item_type.is_empty(), "P2 hand must be empty after release")
	assert(pillow_2_zone.completed, "Pillow 2 zone must be completed")
	var placed_p2 := pillow_2_zone.get_node_or_null("PlacedPillow") as Sprite2D
	assert(placed_p2 != null and placed_p2.z_index == 0, "Pillow 2 must be placed with z_index 0")
	assert(placed_p2.scale == Vector2(0.68, 0.68), "Pillow 2 scale must be Vector2(0.68, 0.68)")
	game._physics_process(game.PLACE_DURATION)
	assert(game.quest.get_count("pillow") == 2, "Pillow quest count must be 2/2")

	# 7. TEST MOP STORAGE REJECTION WHILE CLEANING IS INCOMPLETE
	p1.pick_up("coop_mop")
	assert(p1.held_item_type == "coop_mop")
	p1.global_position = mop_zone.global_position
	if not mop_zone.nearby.has(p1): mop_zone._on_body_entered(p1)
	mop_zone.refresh()
	assert(not mop_zone.can_accept(p1.held_item_type), "Mop station must reject mop when 0/4 stains cleaned")
	assert(mop_zone.prompt.text == "HÃY LAU SÀN TRƯỚC (0/4)", "Prompt must report progress 0/4")
	assert(game.try_interact(p1), "Premature store attempt must trigger feedback hint")
	assert(p1.held_item_type == "coop_mop", "Mop must remain in player's hands on rejection")
	assert(not mop_zone.completed, "Mop station must NOT be completed prematurely")

	# 8. CLEAN ALL 4 STAINS
	for i in range(4):
		var spot: CleaningSpot = game.spots[i]
		p1.global_position = spot.global_position
		for scrub in range(3):
			game.try_use(p1)
		assert(spot.state == "clean", "Spot %d must be clean" % i)
	assert(game.quest.get_count("clean") == 4, "Clean goal must be 4/4")

	# 9. STORE MOP ON RACK AFTER CLEANING COMPLETION
	p1.global_position = mop_zone.global_position
	if not mop_zone.nearby.has(p1): mop_zone._on_body_entered(p1)
	mop_zone.refresh()
	assert(mop_zone.can_accept(p1.held_item_type), "Mop station must ACCEPT mop when 4/4 stains are clean")
	assert(mop_zone.prompt.text.ends_with("CẤT CÂY LAU"), "Prompt must instruct CẤT CÂY LAU")
	assert(game.try_interact(p1), "Store interaction must start")
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(p1.held_item_type.is_empty(), "Mop must release from player hand")
	assert(mop_zone.completed, "Mop station must be completed")
	var placed_mop := mop_zone.get_node_or_null("PlacedMop") as Sprite2D
	assert(placed_mop != null, "PlacedMop must appear on the rack")
	assert(placed_mop.position == Vector2(0, 5), "PlacedMop must hang properly on rack clips")
	game._physics_process(game.PLACE_DURATION)

	# 10. TEST RETRIEVE MOP FROM RACK AND REUSE (BOTH PLAYERS)
	# P1 with empty hands approaches rack to retrieve mop
	p1.global_position = mop_zone.global_position
	if not mop_zone.nearby.has(p1): mop_zone._on_body_entered(p1)
	mop_zone.refresh()
	assert(mop_zone.prompt.text.ends_with("LẤY CÂY LAU"), "Prompt must show [E / 🖐] LẤY CÂY LAU when mop is on rack and hands empty")
	assert(game.try_interact(p1), "Interacting with completed rack must retrieve mop")
	assert(p1.held_item_type == "coop_mop", "P1 must have retrieved coop_mop into hands")
	assert(not mop_zone.completed, "Mop station must not be completed while mop is retrieved")
	assert(mop_zone.get_node_or_null("PlacedMop") == null, "PlacedMop sprite must be removed upon retrieval")
	
	# P1 can use mop in air or on floor
	assert(game.try_use(p1), "Retrieved mop can be swung/used")
	assert(p1.is_scrubbing_mop, "P1 must play scrubbing animation")

	# P1 returns mop to rack again
	p1.global_position = mop_zone.global_position
	assert(game.try_interact(p1), "P1 can re-store mop")
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(mop_zone.completed and p1.held_item_type.is_empty(), "Mop successfully re-stored")
	game._physics_process(game.PLACE_DURATION)

	# P2 (Girl) retrieves mop (move P1 away first)
	p1.global_position = Vector2(500, 500)
	p2.global_position = mop_zone.global_position
	if not mop_zone.nearby.has(p2): mop_zone._on_body_entered(p2)
	mop_zone.refresh()
	assert(mop_zone.prompt.text == "[J] LẤY CÂY LAU", "P2 prompt must indicate [J] LẤY CÂY LAU when alone near rack")
	assert(game.try_interact(p2), "P2 must also be able to retrieve mop")
	assert(p2.held_item_type == "coop_mop", "P2 now holds mop")
	assert(not mop_zone.completed, "Mop station completed must be false")
	
	# P2 re-stores mop
	p2.global_position = mop_zone.global_position
	assert(game.try_interact(p2))
	game._physics_process(game.PLACE_RELEASE_TIME + 0.05)
	assert(mop_zone.completed and p2.held_item_type.is_empty())
	game._physics_process(game.PLACE_DURATION)

	# 11. COMPLETE STORE OBJECTIVES AND VERIFY VICTORY
	p1.pick_up("coop_remote")
	var remote_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "remote": remote_zone = z
	p1.global_position = remote_zone.global_position
	assert(game.try_interact(p1))
	game._physics_process(game.PLACE_DURATION)
	
	p1.pick_up("coop_trash")
	var trash_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "trash": trash_zone = z
	p1.global_position = trash_zone.global_position
	assert(game.try_interact(p1))
	game._physics_process(game.PLACE_DURATION)

	p1.pick_up("coop_gamepad")
	var basket_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "basket": basket_zone = z
	p1.global_position = basket_zone.global_position
	assert(game.try_interact(p1))
	game._physics_process(game.PLACE_DURATION)

	assert(game.is_room_clean(), "Room must be 100% clean with all tasks done and mop on rack")
	assert(game.quest.finished, "Quest must be finished")
	assert(game.overlay.visible and game.overlay_title.text == "Dọn xong rồi! 🎉", "Victory overlay must appear")

	# 12. TEST REPLAY / RESTART RESTORES INITIAL STATE
	game.restart_round()
	await get_tree().process_frame
	var new_mop_zone: CoopDropZone = null
	var new_p1_zone: CoopDropZone = null
	var new_p2_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "mop_station": new_mop_zone = z
		elif z.target_id == "pillow_1": new_p1_zone = z
		elif z.target_id == "pillow_2": new_p2_zone = z
	
	assert(new_mop_zone != null and not new_mop_zone.completed, "Replay must restore mop station to uncompleted")
	assert(new_mop_zone.get_node_or_null("PlacedMop") == null, "Replay must remove PlacedMop")
	assert(new_p1_zone != null and not new_p1_zone.completed and new_p1_zone.marker.visible, "Replay must restore Pillow 1")
	assert(new_p2_zone != null and not new_p2_zone.completed and new_p2_zone.marker.visible, "Replay must restore Pillow 2")
	assert(game.quest.get_count("clean") == 0, "Clean count reset to 0")
	assert(game.quest.get_count("store") == 0, "Store count reset to 0")
	assert(game.quest.get_count("pillow") == 0, "Pillow count reset to 0")

	print(">>> ALL MOP STORAGE & SOFA PILLOW QA TESTS PASSED SUCCESSFULLY! 100% VERIFIED <<<")
	get_tree().quit(0)
