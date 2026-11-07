extends Node2D

# Tests actual atlas transitions, attack timing and directional fallback.
# This is not a visual-quality test of the candidate artwork.
func _ready() -> void:
	var packed := load("res://scenes/player.tscn") as PackedScene
	var p1 := packed.instantiate() as Player
	var p2 := packed.instantiate() as Player
	p1.player_id = "p1"
	p1.character_type = "boy"
	p2.player_id = "p2"
	p2.character_type = "girl"
	add_child(p1)
	add_child(p2)
	p1.set_physics_process(false)
	p2.set_physics_process(false)
	p1.global_position = Vector2(400, 400)
	p2.global_position = Vector2(460, 400)
	p1.facing_direction = Vector2.RIGHT
	p2.facing_direction = Vector2.LEFT

	for player in [p1, p2]:
		player.pick_up("hammer")
		for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2.UP]:
			player.facing_direction = direction
			assert(player.update_character_animation("hammer_idle", 0.0), "Missing usable idle atlas")
			assert(player.sprite.hframes == 4 and not player.weapon_sprite.visible, "Idle atlas must hide separate hammer")
			var expected_scale := Player.HAMMER_HOLD_SCALE if direction == Vector2.DOWN else Player.HAMMER_SIDE_HOLD_SCALE
			assert(is_equal_approx(player.sprite.scale.x, expected_scale))
			assert(is_equal_approx(player.sprite.position.y + 70.0 * player.sprite.scale.y, 0.0), "Foot anchor must stay on the floor")
			assert(player.update_character_animation("hammer_run", 0.2), "Missing usable run atlas")
			assert(player.sprite.hframes == 6 and player.sprite.frame == 2 and not player.weapon_sprite.visible)
		player.facing_direction = Vector2.LEFT
		assert(player.update_character_animation("hammer_run", 0.0))
		assert(player.sprite.flip_h, "Left should mirror the right-facing atlas")
		player.update_sprite_pose("idle")
		assert(player.sprite.hframes == 1 and player.weapon_sprite.visible, "Fallback must restore the separate hammer")
		assert(player.sprite.scale == Vector2.ONE, "Fallback must restore original sprite scale")

	# Boy has only a down-facing attack sheet; missing directions and Girl
	# must fall back to the separate hammer without a delayed hit.
	p2.global_position = Vector2(1500, 900)
	for entry in [[p1, Vector2.RIGHT], [p1, Vector2.UP], [p2, Vector2.DOWN], [p2, Vector2.RIGHT], [p2, Vector2.UP]]:
		var player: Player = entry[0]
		player.facing_direction = entry[1]
		assert(not player.update_character_animation("hammer_attack", 0.0), "Unexpected attack atlas")
		player.trigger_attack()
		assert(not player.hammer_hit_pending and player.weapon_sprite.visible, "Missing atlas must use fallback weapon")
		player.pick_up("hammer")

	assert(p1.character_animations.has("hammer_attack_down"), "Boy down attack atlas must load")
	p1.global_position = Vector2(400, 400)
	p2.global_position = Vector2(400, 460)
	p1.facing_direction = Vector2.DOWN
	p1.pick_up("hammer")
	var before := p2.hearts
	p1.trigger_attack()
	assert(p1.hammer_hit_pending and p2.hearts == before, "Attack must not hit at wind-up")
	assert(is_equal_approx(p1.sprite.scale.x, Player.HAMMER_ATTACK_SCALE))
	assert(is_equal_approx(p1.sprite.position.y + 60.0 * p1.sprite.scale.y, 0.0), "Attack foot anchor must stay on the floor")
	p1._physics_process(Player.HAMMER_IMPACT_TIME - 0.02)
	assert(p2.hearts == before, "Attack must not hit before impact")
	p1._physics_process(0.03)
	assert(p2.hearts == before - 1 and not p1.hammer_hit_pending, "Impact must damage exactly once")
	p1._physics_process(0.03)
	assert(p2.hearts == before - 1, "Attack must not hit twice")

	p1.is_attacking = false
	p1.pick_up("hammer")
	p1.trigger_attack()
	assert(p1.hammer_hit_pending)
	var before_interrupt := p2.hearts
	p1.take_knockback_hit(0, true, Vector2.LEFT)
	assert(not p1.hammer_hit_pending and not p1.is_attacking, "Hit must cancel a pending attack")
	p1._physics_process(Player.HAMMER_ATTACK_DURATION)
	assert(p2.hearts == before_interrupt, "Interrupted attack must not deal damage")
	print("Hammer idle/run, real Boy down attack, fallback, impact timing and interruption verified.")
	get_tree().quit(0)
