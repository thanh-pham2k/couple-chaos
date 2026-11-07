extends Node

# Exercises cooperative interactions in an isolated scene; this is not a
# substitute for two humans playing on physical devices.
func _ready() -> void:
	var packed := load("res://scenes/coop_slice.tscn") as PackedScene
	assert(packed != null, "Co-op scene must load")
	var game = packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	var p1: Player = game.get_node("Arena/YSortArena/Player1")
	var p2: Player = game.get_node("Arena/YSortArena/Player2")
	p1.set_physics_process(false)
	p2.set_physics_process(false)
	assert(game.quest.get_count("store") == 0)
	assert(game.quest.get_count("clean") == 0)
	assert(game.quest.get_count("pillow") == 0)
	assert(not game.session.running, "Session must wait for start")
	game.session.start_round()
	assert(game.session.running and game.session.timer > 299.0)
	# Hits remain playful: knockback is preserved, but no hearts are deducted.
	var extra := (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
	game.arena.get_node("YSortArena").add_child(extra)
	extra.set_physics_process(false)
	var hearts_before := extra.hearts
	extra.take_knockback_hit(1, true, Vector2.RIGHT, 600.0)
	assert(extra.hearts == hearts_before and extra.knockback_state == Player.KnockbackState.AIRBORNE)
	extra.queue_free()
	p1.set_physics_process(false)
	p2.set_physics_process(false)

	# Wrong item cannot complete a destination or be consumed.
	var wrong_zone = game.zones[0]
	p1.pick_up("coop_mop")
	p1.global_position = wrong_zone.global_position
	assert(not wrong_zone.accept(p1), "Wrong item must be rejected")
	assert(p1.held_item_type == "coop_mop" and not wrong_zone.completed)
	p1.clear_held_item()

	# A required item thrown toward the boundary must remain retrievable.
	var remote = _find_item("coop_remote")
	assert(remote != null)
	p1.global_position = remote.global_position
	p1.trigger_grab()
	assert(p1.held_item_type == "coop_remote")
	await get_tree().process_frame
	p1.global_position = Vector2(1800, 700)
	p1.facing_direction = Vector2.RIGHT
	p1.move_direction = Vector2.RIGHT
	p1.trigger_grab()
	assert(p1.is_throwing)
	p1.advance_throw(Player.THROW_RELEASE_TIME + 0.01)
	p1._physics_process(Player.THROW_DURATION)
	await get_tree().process_frame
	remote = _find_item("coop_remote")
	assert(remote != null, "Thrown quest item must not disappear")
	remote.set_physics_process(false)
	remote._physics_process(0.1)
	assert(not remote.is_flying and remote.global_position.x <= game.arena.get_pickup_bounds().end.x)

	# Both players contribute to the required item and pillow placements.
	var n := 0
	var pillow_ids := ["coop_pillow_2", "coop_pillow_1"]
	for zone in game.zones:
		if zone.target_id == "mop_station":
			continue # Mop station is completed after cleaning all floor stains
		var player: Player = p1 if n % 2 == 0 else p2
		var objective_id: String = pillow_ids.pop_front() if zone.category == "pillow" else zone.accepts[0]
		assert(zone.accepts.has(objective_id), "Either pillow must fit either sofa position")
		var item = _find_item(objective_id)
		assert(item != null, "Every required item must exist in the arena")
		player.global_position = item.global_position
		player.trigger_grab()
		assert(player.held_item_type == objective_id, "Both players must be able to pick up required items")
		await get_tree().process_frame
		player.global_position = zone.global_position
		player.trigger_grab()
		game._physics_process(game.PLACE_DURATION + 0.05)
		assert(zone.completed and player.held_item_type.is_empty())
		if zone.category == "pillow":
			var placed := zone.get_node_or_null("PlacedPillow") as Sprite2D
			assert(placed != null and placed.visible and placed.texture != null, "Returned pillows must remain visible")
		assert(not game.quest.complete_target(zone.category, objective_id), "A duplicate must not increase progress")
		n += 1
	assert(game.quest.get_count("store") == 3)
	assert(game.quest.get_count("pillow") == 2)
	assert(game.session.running, "Cleaning must still be required")

	# Four varieties are present; all four must be cleaned to satisfy the clean goal.
	assert(game.spots.size() == 4, "All four spill types must be present")
	for spot in game.spots:
		assert(spot.state == "dirty" and spot.progress == 0)
	# Cleaning must require the mop, three strokes, and only count once.
	for i in range(4):
		var player: Player = p1 if i % 2 == 0 else p2
		var spot = game.spots[i]
		player.global_position = spot.global_position
		player.clear_held_item()
		assert(not game.try_use(player), "Cleaning without a mop must fail")
		var mop = _find_item("coop_mop")
		assert(mop != null, "Mop must remain retrievable")
		player.global_position = mop.global_position
		player.trigger_grab()
		assert(player.held_item_type == "coop_mop", "Player must be able to pick up the mop")
		await get_tree().process_frame
		player.global_position = spot.global_position
		for stroke in range(3):
			player.trigger_attack()
		assert(spot.state == "clean" and spot.progress == 3)
		assert(not spot.scrub(player), "Already clean spot must not count twice")
		if i < 3:
			player.drop_held_item()
			await get_tree().process_frame
	assert(game.quest.get_count("clean") == 4)
	# Mop must still be returned to station before the round is considered clean.
	assert(game.session.running, "Cleaning done but mop still in hand; round must not end yet")
	var mop_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "mop_station":
			mop_zone = z
			break
	assert(mop_zone != null and not mop_zone.completed)
	p2.global_position = mop_zone.global_position
	assert(game.try_interact(p2))
	game._physics_process(game.PLACE_DURATION + 0.05)
	assert(mop_zone.completed and p2.held_item_type.is_empty())
	assert(game.quest.finished and not game.session.running, "All goals and clean room must finish the round")

	# Restart restores quest, timer, interaction targets and movable items.
	game.restart_round()
	await get_tree().process_frame
	assert(game.quest.get_count("store") == 0 and game.quest.get_count("clean") == 0 and game.quest.get_count("pillow") == 0)
	assert(not game.quest.finished and is_equal_approx(game.session.timer, 300.0))
	for zone in game.zones:
		assert(not zone.completed, "Replay must reset every drop zone")
	for spot in game.spots:
		assert(spot.state == "dirty" and spot.progress == 0, "Replay must reset every spill")
	game.session.start_round()
	game.session.timer = 0.01
	game.session._process(0.02)
	assert(not game.session.running and game.session.ended_once, "Time expiry must end the round")
	print("Co-op goals, both players, wrong/duplicate items, completion, replay and timeout verified.")
	get_tree().quit()

func _find_item(item_type: String):
	for item in get_tree().get_nodes_in_group("items"):
		if not item.is_queued_for_deletion() and item.item_type == item_type:
			return item
	return null
