extends Node

func _ready() -> void:
	var packed := load("res://scenes/coop_slice.tscn") as PackedScene
	assert(packed != null, "coop_slice.tscn must load")
	var game = packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()

	var p1: Player = game.arena.p1
	var p2: Player = game.arena.p2
	var world: Node2D = game.arena.get_node("YSortArena")

	# 1. VERIFY FURNITURE & DECOR ARE FULLY INTACT
	for furn in ["Workstation", "OfficeChair", "TVConsole", "Entryway", "CoffeeTable", "Sofa", "Bed", "Counter", "Fridge", "DiningSet", "Rug"]:
		assert(world.get_node_or_null(furn) != null, "Furniture %s must NOT be deleted" % furn)

	# Verify Coffee Table centered with Sofa at X=620
	var sofa: StaticBody2D = world.get_node("Sofa")
	var table: StaticBody2D = world.get_node("CoffeeTable")
	assert(is_equal_approx(table.position.x, sofa.position.x), "Coffee table must be horizontally centered with sofa")
	assert(table.position.y < sofa.position.y, "Coffee table must be positioned north of sofa")
	assert(sofa.has_node("PillowSlotLeft") and sofa.has_node("PillowSlotRight"), "Sofa must contain explicit pillow anchor markers")

	# 2. VERIFY NON-QUEST CLUTTER & HAZARDS EXIST IN ROOM AND ARE CATEGORIZABLE
	for clutter_node in ["ItemHammer", "ItemBoba", "ItemBanana", "ItemPopcorn", "ItemWallet", "BananaHazard", "BobaHazard"]:
		assert(world.get_node_or_null(clutter_node) != null, "Clutter node %s should be present in room for categorization" % clutter_node)

	# 3. VERIFY INITIAL CLEAN & QUEST STATE
	assert(game.quest.get_goal("clean") == 4, "Clean goal must be synchronized to 4")
	assert(game.quest.get_count("clean") == 0, "Initial clean count must be 0")
	assert(game.spots.size() == 4, "Must have exactly 4 dirty spots")
	for s in game.spots:
		assert(s.state == "dirty", "All 4 spots must start dirty")

	var mop_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "mop_station":
			mop_zone = z
			break
	assert(mop_zone != null, "Mop station must exist")
	assert(mop_zone.position == Vector2(1400, 270), "Mop station must be near kitchen area")
	assert(mop_zone.prop != null and mop_zone.prop.texture.resource_path.ends_with("mop_rack.png"), "Mop station must have mop rack prop")

	# 4. TEST PARTIAL CLEANING (2/4) DOES NOT SATISFY MISSION OR ALLOW MOP RETURN
	p1.pick_up("coop_mop")
	for i in range(2):
		var s: CleaningSpot = game.spots[i]
		p1.global_position = s.global_position + Vector2(0, 30)
		for scrub in range(3):
			game.try_use(p1)
		assert(s.state == "clean", "Spot %d must be cleaned" % i)

	assert(game.quest.get_count("clean") == 2, "Clean count must be 2/4")
	assert(not game.quest.is_all_goals_met(), "Goals must NOT be met with 2/4 stains cleaned")
	assert(not mop_zone.can_accept(p1.held_item_type), "Mop station must REJECT mop when 2/4 stains remain dirty")
	p1.global_position = mop_zone.global_position + Vector2(0, 30)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not mop_zone.nearby.has(p1):
		mop_zone._on_body_entered(p1)
	mop_zone.refresh()
	assert(mop_zone.prompt.text == "HÃY LAU SÀN TRƯỚC (2/4)", "Prompt must show 2/4 progress, got: " + mop_zone.prompt.text)

	# Try to place mop prematurely
	p1.global_position = mop_zone.global_position
	assert(game.try_interact(p1), "Interaction should trigger rejection hint")
	assert(not mop_zone.completed, "Mop station must not be completed")
	assert(p1.held_item_type == "coop_mop", "Mop must stay in player's hands")
	assert(not game.is_room_clean(), "Room must NOT be clean with dirty spots remaining")

	# 5. COMPLETE REMAINING STAINS (4/4)
	for i in range(2, 4):
		var s: CleaningSpot = game.spots[i]
		p1.global_position = s.global_position + Vector2(0, 30)
		for scrub in range(3):
			game.try_use(p1)
		assert(s.state == "clean", "Spot %d must be cleaned" % i)

	assert(game.quest.get_count("clean") == 4, "Clean count must be 4/4")
	# Even with 4/4 clean, room is NOT clean if mop is still held!
	assert(not game.is_room_clean(), "Room must NOT be clean while player still holds the mop")

	# 6. RETURN MOP TO STATION
	p1.global_position = mop_zone.global_position
	assert(mop_zone.can_accept(p1.held_item_type), "Mop station must accept mop after 4/4 stains are clean")
	assert(game.try_interact(p1))
	game._physics_process(game.PLACE_DURATION + 0.05)
	assert(mop_zone.completed, "Mop station must now be completed")
	assert(p1.held_item_type.is_empty(), "Player's hands must be free after returning mop")

	# 7. PLACE REMAINING OBJECTIVES (3 STORE ITEMS, 2 PILLOWS)
	var pillow_ids := ["coop_pillow_1", "coop_pillow_2"]
	for zone in game.zones:
		if zone.target_id == "mop_station":
			continue
		var player := p2
		var obj_id: String = pillow_ids.pop_front() if zone.category == "pillow" else zone.accepts[0]
		player.pick_up(obj_id)
		player.global_position = zone.global_position
		assert(game.try_interact(player))
		game._physics_process(game.PLACE_DURATION + 0.05)
		assert(zone.completed, "Zone %s must be completed" % zone.target_id)

	# 8. VERIFY SUCCESS & OVERLAY ("Dọn xong rồi! 🎉")
	assert(game.is_room_clean(), "All conditions met -> room must be clean!")
	assert(game.quest.finished, "Quest must be finished")
	assert(not game.session.running, "Session must have finished with victory")
	assert(game.overlay.visible, "Overlay must be visible")
	assert(game.overlay_title.text == "Dọn xong rồi! 🎉", "Title must say Dọn xong rồi! 🎉")
	for clutter_node in ["ItemHammer", "ItemBoba", "ItemBanana", "ItemPopcorn", "ItemWallet", "BananaHazard", "BobaHazard"]:
		assert(world.get_node_or_null(clutter_node) == null, "Remaining clutter %s must be cleared on mission completion" % clutter_node)

	# 9. TEST REPLAY / RESTART RESTORES INITIAL STATE
	game.restart_round()
	await get_tree().process_frame
	var new_world: Node2D = game.arena.get_node("YSortArena")
	for clutter_node in ["ItemHammer", "ItemBoba", "ItemBanana", "ItemPopcorn", "ItemWallet", "BananaHazard", "BobaHazard"]:
		assert(new_world.get_node_or_null(clutter_node) != null, "Replay must restore %s" % clutter_node)
	assert(game.quest.get_count("clean") == 0, "Replay must reset clean count to 0")
	assert(game.quest.get_count("store") == 0, "Replay must reset store count to 0")
	assert(game.quest.get_count("pillow") == 0, "Replay must reset pillow count to 0")
	assert(game.spots.size() == 4, "Replay must recreate all 4 spots")
	for s in game.spots:
		assert(s.state == "dirty" and s.progress == 0, "All spots must be dirty on replay")
	for z in game.zones:
		assert(not z.completed, "All zones must be uncompleted on replay")
	assert(not game.quest.finished, "Quest finished flag must be reset")

	print("Co-op Room Cleanliness, Mop Return & Stains Synchronization TEST PASSED!")
	get_tree().quit(0)
