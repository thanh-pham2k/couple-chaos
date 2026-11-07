extends Node

# Exercises actual physics against each furniture footprint. Visual occlusion
# still needs inspection in the renderer.
func _ready() -> void:
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var player: Player = world.get_node("Player1")
	var cat: BossCat = world.get_node("BossCat")
	assert(world.y_sort_enabled, "Arena must sort world objects by their foot position")
	assert(player.get_parent() == world and cat.get_parent() == world, "Player and cat must share the sorting layer")
	player.set_physics_process(false)
	cat.set_physics_process(false)
	world.get_node("Player2").set_physics_process(false)
	world.get_node("Player2").collision_layer = 0
	cat.collision_layer = 0
	# Isolate the obstacle under test so nearby furniture cannot satisfy the test.
	arena.get_node("Boundaries").collision_layer = 0
	var furniture: Array[StaticBody2D] = []
	for node in world.get_children():
		if node is StaticBody2D:
			furniture.append(node)
			node.collision_layer = 0
	await get_tree().physics_frame
	for name in ["Bed", "Sofa"]:
		var obstacle: StaticBody2D = world.get_node(name)
		obstacle.collision_layer = 1
		var collider: CollisionShape2D = obstacle.get_node("CollisionShape2D")
		var rect: RectangleShape2D = collider.shape
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var half_extent: float = rect.size.x / 2.0 if dir.x != 0.0 else rect.size.y / 2.0
			# Start well outside the shape and sweep towards its center.
			player.global_position = collider.global_position - dir * (half_extent + 75.0) + Vector2(0, 20)
			await get_tree().physics_frame
			for distance in [100.0, 260.0]:
				var collision := player.move_and_collide(dir * distance, true)
				assert(collision != null and collision.get_collider() == obstacle, "%s must block approach %s" % [name, dir])
				assert(collision.get_travel().length() < distance, "A dash must not pass through furniture")
		obstacle.collision_layer = 0
	var hazard: FloorHazard = world.get_node("BobaHazard")
	assert(hazard.z_index < player.z_index, "Floor hazard must render below characters")
	assert(hazard.global_position.y > 240.0, "Boba hazard must be placed on the playable floor")
	print("Player collision against bed and sofa on four sides, Y-sort setup and floor hazard layer verified.")
	get_tree().quit()
