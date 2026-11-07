extends Node

# Physical key events across physics frames; positions are arranged as test fixtures,
# so this is not a human playtest or a navigation test.
func _ready() -> void:
	var game = (load("res://scenes/coop_slice.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().process_frame
	for order in [
		[["trash", "coop_trash"], ["pillow_2", "coop_pillow_1"], ["remote", "coop_remote"], ["basket", "coop_gamepad"], ["pillow_1", "coop_pillow_2"]],
		[["pillow_1", "coop_pillow_2"], ["basket", "coop_gamepad"], ["remote", "coop_remote"], ["pillow_2", "coop_pillow_1"], ["trash", "coop_trash"]],
	]:
		game.restart_round()
		await get_tree().process_frame
		game.session.start_round()
		var p1: Player = game.arena.get_node("YSortArena/Player1")
		var p2: Player = game.arena.get_node("YSortArena/Player2")
		game.arena.get_node("YSortArena/BossCat").set_physics_process(false)
		var idx := 0
		for entry in order:
			var player := p1 if idx % 2 == 0 else p2
			var idle := p2 if idx % 2 == 0 else p1
			idle.set_physics_process(false)
			idle.global_position = Vector2(1000, 980)
			player.set_physics_process(true)
			var item: ItemPickup = null
			for candidate in get_tree().get_nodes_in_group("items"):
				if is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and candidate.item_type == entry[1]:
					item = candidate
					break
			assert(item != null, "Required item must exist: " + entry[1])
			player.global_position = item.global_position
			await get_tree().physics_frame
			await _press(KEY_E if player == p1 else KEY_J)
			assert(player.held_item_type == entry[1], "Must pick up correct item: " + entry[1])
			var zone: CoopDropZone = null
			for candidate in game.zones:
				if candidate.target_id == entry[0]: zone = candidate
			assert(zone != null)
			# Fixture uses the visible, accessible approach side of each marker.
			var offset := Vector2(0, 135)
			if zone.target_id == "pillow_1": offset = Vector2(-140, 0)
			if zone.target_id == "pillow_2": offset = Vector2(140, 0)
			player.global_position = zone.global_position + offset
			await get_tree().physics_frame
			await get_tree().physics_frame
			assert(player.global_position.distance_to(zone.global_position) <= 160.0, "Fixture should remain within interaction radius")
			assert(zone.prompt.visible, "Action prompt must show at reachable in-range position: " + entry[0])
			await _press(KEY_E if player == p1 else KEY_J)
			assert(zone.completed and player.held_item_type.is_empty(), "Correct item must deposit regardless of order: " + entry[0])
			idx += 1
		assert(game.quest.get_count("store") == 3 and game.quest.get_count("pillow") == 2, "All objectives should count once")
	# Prompt and action must agree with the root-to-root distance, rather than
	# the enlarged Area2D overlap including the player's collision capsule.
	game.restart_round()
	await get_tree().process_frame
	game.session.start_round()
	var player: Player = game.arena.get_node("YSortArena/Player1")
	game.arena.get_node("YSortArena/Player2").set_physics_process(false)
	game.arena.get_node("YSortArena/BossCat").set_physics_process(false)
	var basket: CoopDropZone = null
	for candidate in game.zones:
		if candidate.target_id == "basket": basket = candidate
	player.pick_up("coop_gamepad")
	player.global_position = basket.global_position + Vector2(0, 162)
	for i in range(4): await get_tree().physics_frame
	assert(not basket.prompt.visible, "Prompt must not show outside the exact interaction radius")
	assert(not game.try_interact(player), "Outside the radius cannot deposit")
	assert(not basket.completed and player.held_item_type == "coop_gamepad")
	player.global_position = basket.global_position + Vector2(0, 158)
	for i in range(4): await get_tree().physics_frame
	assert(basket.prompt.visible, "Prompt must show inside the exact interaction radius")
	await _press(KEY_E)
	assert(basket.completed and player.held_item_type.is_empty(), "In-range key must deposit")
	print("Co-op destinations accept marked items in multiple orders through simulated physical keys; prompt matches distance.")
	get_tree().quit()

func _press(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().physics_frame
	await get_tree().physics_frame
	e = InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = false
	Input.parse_input_event(e)
	await get_tree().physics_frame
