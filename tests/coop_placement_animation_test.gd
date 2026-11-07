extends Node

# Controlled physics steps exercise animation/transaction timing, not visual quality.
func _ready() -> void:
	for player_id in ["p1", "p2"]:
		for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]:
			var game = await _new_game()
			var player: Player = game.arena.p1 if player_id == "p1" else game.arena.p2
			var zone = _zone(game, "remote")
			player.global_position = zone.global_position + Vector2(0, 50)
			player.facing_direction = direction
			player.pick_up("coop_remote")
			assert(game.try_interact(player), "Interaction must consume input")
			assert(player.is_placing and not zone.completed and player.held_item_type == "coop_remote", "Placement must reserve without instantly depositing")
			var direction_name := "right" if absf(direction.x) > absf(direction.y) else ("up" if direction.y < 0 else "down")
			assert(player.character_animation_key == "place_item_" + direction_name, "Correct directional placement atlas must play")
			assert(player.sprite.flip_h == (direction == Vector2.LEFT), "Left must mirror right")
			player._physics_process(game.PLACE_RELEASE_TIME - 0.02)
			game._physics_process(game.PLACE_RELEASE_TIME - 0.02)
			assert(player.held_item_type == "coop_remote" and not zone.completed, "Item must stay in hand before release")
			player._physics_process(0.03)
			game._physics_process(0.03)
			assert(player.held_item_type.is_empty() and zone.completed and game.quest.get_count("store") == 1, "Release must deposit exactly once")
			player._physics_process(game.PLACE_DURATION)
			game._physics_process(game.PLACE_DURATION)
			assert(not player.is_placing and game.quest.get_count("store") == 1, "Animation must finish without duplicate rewards")
			game.queue_free()
			await get_tree().process_frame

	# Two players cannot reserve the same destination in the same frame.
	var game = await _new_game()
	var p1: Player = game.arena.p1
	var p2: Player = game.arena.p2
	var zone = _zone(game, "remote")
	p1.global_position = zone.global_position + Vector2(0, 50)
	p2.global_position = p1.global_position
	p1.pick_up("coop_remote")
	p2.pick_up("coop_remote")
	assert(game.try_interact(p1))
	assert(game.try_interact(p2))
	assert(game.pending_placements.has(p1) and not game.pending_placements.has(p2), "Concurrent reservation must choose only one player")
	game._physics_process(game.PLACE_RELEASE_TIME + 0.01)
	assert(game.quest.get_count("store") == 1 and p2.held_item_type == "coop_remote", "Other player's item must remain intact")

	# Interrupted placement drops the item once and releases the reservation.
	game.restart_round()
	await get_tree().process_frame
	game.session.start_round()
	_disable_automatic_physics(game)
	p1 = game.arena.p1
	zone = _zone(game, "remote")
	p1.global_position = zone.global_position + Vector2(0, 50)
	p1.pick_up("coop_remote")
	assert(game.try_interact(p1))
	p1.take_knockback_hit(0, true, Vector2.RIGHT)
	game._physics_process(game.PLACE_DURATION)
	await get_tree().process_frame
	assert(not zone.completed and game.quest.get_count("store") == 0, "Stun before release must cancel the placement")
	assert(not game.pending_placements.has(p1) and not is_instance_valid(zone.reserved_by), "Interrupted reservation must be released")
	var remote_count := 0
	for item in game.get_tree().get_nodes_in_group("items"):
		if is_instance_valid(item) and not item.is_queued_for_deletion() and item.item_type == "coop_remote": remote_count += 1
	# The fixture created a copy via pick_up; the original remains in the scene.
	assert(remote_count == 2, "Interrupted held item should create exactly one floor item")
	game.restart_round()
	await get_tree().process_frame
	assert(game.quest.get_count("store") == 0 and game.pending_placements.is_empty())
	for entry in game.zones:
		assert(not entry.completed and not is_instance_valid(entry.reserved_by), "Replay must clear placement state")
	print("Directional placement, timing, reservation, stun interruption and replay verified.")
	get_tree().quit()

func _new_game():
	var game = (load("res://scenes/coop_slice.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()
	_disable_automatic_physics(game)
	return game

func _disable_automatic_physics(game) -> void:
	game.set_physics_process(false)
	game.arena.p1.set_physics_process(false)
	game.arena.p2.set_physics_process(false)
	game.arena.get_node("YSortArena/BossCat").set_physics_process(false)

func _zone(game, id: String):
	for zone in game.zones:
		if zone.target_id == id: return zone
	assert(false, "Missing zone " + id)
	return null
