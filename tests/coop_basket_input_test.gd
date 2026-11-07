extends Node

# Drives simulated physical key events over physics frames; not a human playtest.
func _ready() -> void:
	var game = (load("res://scenes/coop_slice.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()
	for id in ["p1", "p2"]:
		game.restart_round()
		await get_tree().process_frame
		game.session.start_round()
		var player: Player = game.arena.get_node("YSortArena/Player1" if id == "p1" else "YSortArena/Player2")
		var other: Player = game.arena.get_node("YSortArena/Player2" if id == "p1" else "YSortArena/Player1")
		other.set_physics_process(false)
		other.global_position = Vector2(1600, 850)
		game.arena.get_node("YSortArena/BossCat").set_physics_process(false)
		var item: ItemPickup = null
		for candidate in get_tree().get_nodes_in_group("items"):
			if is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and candidate.item_type == "coop_gamepad":
				item = candidate
				break
		assert(item != null, "Quest gamepad must be present")
		player.global_position = item.global_position
		await get_tree().physics_frame
		_key(KEY_E if id == "p1" else KEY_J, true)
		await get_tree().physics_frame
		await get_tree().physics_frame
		_key(KEY_E if id == "p1" else KEY_J, false)
		await get_tree().physics_frame
		assert(player.held_item_type == "coop_gamepad", "%s must pick up the objective through InputMap" % id)
		var before := player.global_position
		# Walk from the objective's real scene position toward the basket,
		# around the left side of the sofa, without teleporting between actions.
		_key(KEY_A if id == "p1" else KEY_LEFT, true)
		for frame in range(22): await get_tree().physics_frame
		_key(KEY_A if id == "p1" else KEY_LEFT, false)
		_key(KEY_S if id == "p1" else KEY_DOWN, true)
		for frame in range(12): await get_tree().physics_frame
		_key(KEY_S if id == "p1" else KEY_DOWN, false)
		await get_tree().physics_frame
		assert(player.global_position.distance_to(before) > 30.0, "%s must move while carrying" % id)
		assert(player.held_item_type == "coop_gamepad", "Movement must retain the held item")
		var basket = null
		for zone in game.zones:
			if zone.target_id == "basket": basket = zone
		assert(basket != null and player.global_position.distance_to(basket.global_position) <= 120.0)
		_key(KEY_E if id == "p1" else KEY_J, true)
		await get_tree().physics_frame
		await get_tree().physics_frame
		_key(KEY_E if id == "p1" else KEY_J, false)
		for f in range(25): await get_tree().physics_frame
		assert(basket.completed and player.held_item_type.is_empty(), "%s must place the quest gamepad in the basket" % id)
		assert(game.quest.get_count("store") == 1, "Deposit must count exactly once")

	# Carry the remote along a clear floor route to the wrong destination.
	game.restart_round()
	await get_tree().process_frame
	game.session.start_round()
	var p1: Player = game.arena.get_node("YSortArena/Player1")
	game.arena.get_node("YSortArena/Player2").set_physics_process(false)
	game.arena.get_node("YSortArena/BossCat").set_physics_process(false)
	var remote: ItemPickup = null
	for item in get_tree().get_nodes_in_group("items"):
		if is_instance_valid(item) and not item.is_queued_for_deletion() and item.item_type == "coop_remote": remote = item
	assert(remote != null)
	p1.global_position = remote.global_position
	await get_tree().physics_frame
	_key(KEY_E, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_key(KEY_E, false)
	await get_tree().physics_frame
	assert(p1.held_item_type == "coop_remote")
	_key(KEY_S, true)
	for frame in range(37): await get_tree().physics_frame
	_key(KEY_S, false)
	_key(KEY_A, true)
	for frame in range(85): await get_tree().physics_frame
	_key(KEY_A, false)
	_key(KEY_W, true)
	for frame in range(50): await get_tree().physics_frame
	_key(KEY_W, false)
	await get_tree().physics_frame
	var basket = null
	for zone in game.zones:
		if zone.target_id == "basket": basket = zone
	assert(p1.global_position.distance_to(basket.global_position) < 80.0, "Wrong-item test must reach the basket on foot")
	_key(KEY_E, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_key(KEY_E, false)
	await get_tree().physics_frame
	assert(not basket.completed and p1.held_item_type == "coop_remote", "Basket must reject remote without losing it")
	assert(game.quest.get_count("store") == 0)
	print("P1/P2 physical input pickup, carry and basket deposit; wrong-item rejection verified.")
	get_tree().quit()

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
