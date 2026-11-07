extends Node

func _ready() -> void:
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	add_child(arena)
	await get_tree().process_frame
	arena.set_process(false)
	var player: Player = arena.get_node("YSortArena/Player1")
	player.set_physics_process(false)
	var parent: Node = arena.get_node("YSortArena")
	var bounds: Rect2 = arena.get_pickup_bounds()
	var cases := [
		[Vector2(1800, 700), Vector2.RIGHT, Vector2(1810, 700)],
		[Vector2(120, 700), Vector2.LEFT, Vector2(110, 700)],
		[Vector2(900, 290), Vector2.UP, Vector2(900, 280)],
		[Vector2(900, 990), Vector2.DOWN, Vector2(900, 1000)],
		[Vector2(1800, 990), Vector2(1, 1).normalized(), Vector2(1810, 1000)],
		[Vector2(1950, 700), Vector2.RIGHT, Vector2(1810, 700)],
	]
	for entry in cases:
		var item := (load("res://scenes/item.tscn") as PackedScene).instantiate() as ItemPickup
		parent.add_child(item)
		item.set_physics_process(false)
		item.item_type = "hammer"
		item.global_position = entry[0]
		item.fly_direction = entry[1]
		item.is_flying = true
		item._physics_process(0.1)
		assert(not item.is_flying, "Hammer should land at the boundary")
		assert(item.global_position.is_equal_approx(entry[2]), "Hammer must remain inside the playable area")
		assert(bounds.has_point(item.global_position) or item.global_position.x == bounds.end.x or item.global_position.y == bounds.end.y)
		# Move other pickups away so the real pickup search targets this hammer.
		for other in get_tree().get_nodes_in_group("items"):
			if other != item:
				other.remove_from_group("items")
		player.global_position = item.global_position
		player.find_and_pickup_item()
		assert(player.held_item_type == "hammer", "Landed hammer must be retrievable")
		player.clear_held_item()
		await get_tree().process_frame
	print("Thrown hammers land and can be retrieved at all arena edges.")
	get_tree().quit()
