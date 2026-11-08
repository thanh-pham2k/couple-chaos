extends Node

func _ready() -> void:
	var game = load("res://scenes/coop_slice.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()
	game.set_physics_process(false)
	var sofa = game.arena.get_node("YSortArena/Sofa")
	var container = sofa.get_node("PlacedPillows")
	var left = _zone(game, "pillow_1")
	var right = _zone(game, "pillow_2")
	assert(container.get_child_count() == 0 and game.quest.get_count("pillow") == 0)
	assert(not sofa.y_sort_enabled and not container.y_sort_enabled)
	assert(sofa.get_node("Base").get_index() < container.get_index() and container.get_index() < sofa.get_node("Foreground").get_index())
	assert(sofa.get_node("Base").z_index == 0 and container.z_index == 0 and sofa.get_node("Foreground").z_index == 0)
	var p1 = game.arena.p1
	var p2 = game.arena.p2
	p1.set_physics_process(false)
	p2.set_physics_process(false)
	p1.pick_up("coop_pillow_1")
	p2.pick_up("coop_pillow_2")
	p1.global_position = left.global_position + Vector2(-40, 0)
	p2.global_position = right.global_position + Vector2(40, 0)
	assert(left.global_position.is_equal_approx(sofa.get_node("PillowSlotLeft").global_position))
	assert(right.global_position.is_equal_approx(sofa.get_node("PillowSlotRight").global_position))
	assert(game.try_interact(p1) and game.try_interact(p2))
	assert(game.pending_placements.size() == 2)
	game._physics_process(game.PLACE_RELEASE_TIME + 0.01)
	assert(container.get_child_count() == 2 and game.quest.get_count("pillow") == 2)
	assert(not left.has_node("PlacedPillow") and not right.has_node("PlacedPillow"))
	assert(not left.marker.visible and not right.marker.visible)
	for entry in [["pillow_1", "PillowSlotLeft"], ["pillow_2", "PillowSlotRight"]]:
		var pillow = container.get_node("Modular_" + entry[0])
		var slot = sofa.get_node(entry[1])
		var expected_texture = "sofa_pillow_yellow_v4.png" if entry[0] == "pillow_1" else "sofa_pillow_pink_v4.png"
		assert(pillow.texture.resource_path.ends_with(expected_texture))
		assert(not pillow.visible and pillow.global_position.is_equal_approx(slot.global_position))
		assert(is_equal_approx(pillow.global_rotation, slot.global_rotation))
	await get_tree().create_timer(0.25).timeout
	assert(container.get_node("Modular_pillow_1").visible and container.get_node("Modular_pillow_2").visible)
	p1.pick_up("coop_pillow_1")
	assert(not left.accept(p1) and container.get_child_count() == 2 and game.quest.get_count("pillow") == 2)
	game.restart_round()
	await get_tree().process_frame
	assert(game.arena.get_node("YSortArena/Sofa/PlacedPillows").get_child_count() == 0)
	assert(game.quest.get_count("pillow") == 0)
	print("Single pillow rendering, simultaneous placement, markers, repeat and replay PASS")
	get_tree().quit()

func _zone(game, id):
	for zone in game.zones:
		if zone.target_id == id:
			return zone
	return null
