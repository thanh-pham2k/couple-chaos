extends Node

# Exercises the real CharacterBody2D movement path over physics frames.
# Players may cross one another but must still collide with the room.
func _ready() -> void:
	var timeout := get_tree().create_timer(15.0)
	timeout.timeout.connect(func(): push_error("Player movement test timed out"); get_tree().quit(1))
	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var p1: Player = world.get_node("Player1")
	var p2: Player = world.get_node("Player2")
	var cat: BossCat = world.get_node("BossCat")
	cat.set_physics_process(false)
	cat.collision_layer = 0
	p2.set_physics_process(false)
	p1.global_position = Vector2(800, 700)
	p2.global_position = Vector2(880, 700)
	await get_tree().physics_frame
	Input.action_press("p1_right")
	for i in range(40):
		await get_tree().physics_frame
	Input.action_release("p1_right")
	if p1.global_position.x <= p2.global_position.x + 30.0:
		fail("Walking toward the other player must not block passage")
		return

	# They remain free to move apart even if they start on the same point.
	p1.global_position = Vector2(800, 700)
	p2.global_position = Vector2(800, 700)
	await get_tree().physics_frame
	Input.action_press("p1_left")
	for i in range(12):
		await get_tree().physics_frame
	Input.action_release("p1_left")
	if p1.global_position.x >= 760.0:
		fail("Players starting together must be able to move apart")
		return

	# Dashing through the other player should still stop at the arena wall.
	p1.global_position = Vector2(210, 500)
	p2.global_position = Vector2(150, 500)
	p1.move_direction = Vector2.LEFT
	p1.facing_direction = Vector2.LEFT
	p1.stamina = Player.STAMINA_MAX
	await get_tree().physics_frame
	p1.trigger_dash()
	for i in range(20):
		await get_tree().physics_frame
	if p1.global_position.x >= p2.global_position.x - 20.0 or p1.global_position.x < 95.0:
		fail("Dash must cross player but stop at wall: " + str(p1.global_position))
		return

	# Knockback must not be stopped by the other player.
	p1.global_position = Vector2(900, 700)
	p2.global_position = Vector2(950, 700)
	p1.take_knockback_hit(0, true, Vector2.RIGHT, 760.0)
	for i in range(12):
		await get_tree().physics_frame
	if p1.global_position.x <= p2.global_position.x:
		fail("Knockback must not stick against another player")
		return

	# Collision exceptions must not break direct hit logic or Area2D hits.
	p1.knockback_state = Player.KnockbackState.NONE
	p1.is_stunned = false
	p1.invulnerable_timer = 0.0
	p1.global_position = Vector2(800, 700)
	p2.global_position = Vector2(880, 700)
	p1.facing_direction = Vector2.RIGHT
	var hearts_before := p2.hearts
	p1.perform_melee_hit("hammer")
	if p2.hearts != hearts_before - 1:
		fail("Melee hits must still reach the other player")
		return
	p2.invulnerable_timer = 0.0
	p2.knockback_state = Player.KnockbackState.NONE
	p2.is_stunned = false
	p2.global_position = Vector2(1100, 700)
	var item := (load("res://scenes/item.tscn") as PackedScene).instantiate() as ItemPickup
	item.item_type = "hammer"
	item.is_flying = true
	item.fly_direction = Vector2.RIGHT
	item.thrown_by = "p1"
	item.global_position = Vector2(1000, 680)
	world.add_child(item)
	var projectile_before := p2.hearts
	for i in range(18):
		await get_tree().physics_frame
	if p2.hearts != projectile_before - 1:
		fail("Projectile Area2D must still detect and hit the other player")
		return
	# Floor Area2D still detects players despite their mutual body exception.
	p2.global_position = Vector2(1200, 800)
	p2.is_slowed = false
	var hazard := (load("res://scenes/hazard.tscn") as PackedScene).instantiate() as FloorHazard
	hazard.hazard_type = "boba_puddle"
	hazard.global_position = p2.global_position
	world.add_child(hazard)
	for i in range(4):
		await get_tree().physics_frame
	if not p2.is_slowed:
		fail("Floor hazard Area2D must still detect the other player")
		return
	print("Player passage, separation, dash, wall collision, knockback, attacks and hazards verified.")
	get_tree().quit(0)

func fail(message: String) -> void:
	Input.action_release("p1_right")
	Input.action_release("p1_left")
	push_error(message)
	get_tree().quit(1)
