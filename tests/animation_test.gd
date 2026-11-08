extends Node

# Verifies atlas loading and state/direction selection; visual quality must be
# reviewed separately in a running renderer.
func _ready() -> void:
	var packed := load("res://scenes/cat.tscn") as PackedScene
	assert(packed != null, "Cat scene must load")
	var cat := packed.instantiate() as BossCat
	add_child(cat)
	await get_tree().process_frame
	cat.set_physics_process(false)

	for action in ["walk", "run", "panic", "idle", "carrywalk", "carryrun"]:
		for direction in ["down", "right", "up"]:
			var key: String = action + "_" + direction
			assert(cat.animation_sheets.has(key), "Missing valid sheet: " + key)
			var tex: Texture2D = cat.animation_sheets[key]
			assert(tex.get_size() == Vector2(cat.FRAME_COUNTS[action] * 64, 64), "Incorrect dimensions: " + key)

	cat.current_state = BossCat.State.WANDER
	for entry in [[Vector2.DOWN, "walk_down"], [Vector2.RIGHT, "walk_right"], [Vector2.UP, "walk_up"]]:
		cat.update_animation(0.0, entry[0])
		assert(cat.animation_key == entry[1], "Incorrect walk direction")
		assert(cat.sprite.frame == 0, "Changing direction should reset the animation")
		assert(cat.sprite.hframes == 6, "Walk must have 6 frames")

	cat.update_animation(0.0, Vector2.LEFT)
	assert(cat.animation_key == "walk_right" and cat.sprite.flip_h, "Left should mirror right")
	cat.update_animation(0.0, Vector2.RIGHT)
	assert(not cat.sprite.flip_h, "Right must clear horizontal flip")
	cat.update_animation(0.25, Vector2.RIGHT)
	assert(cat.sprite.frame == 2, "Walk should advance at 8 frames per second")
	cat.update_animation(0.50, Vector2.RIGHT)
	assert(cat.sprite.frame == 0, "Walk should loop after six frames")

	cat.current_state = BossCat.State.RUN
	cat.update_animation(0.0, Vector2.UP)
	assert(cat.animation_key == "panic_up" and cat.sprite.hframes == 8, "Fleeing should use the directional panic sheet")
	assert(cat.sprite.frame == 0, "Changing state should reset the frame")
	cat.update_animation(0.15, Vector2.UP)
	assert(cat.sprite.frame > 0, "Panic animation must advance")

	# Remote animations are opt-in and retain the ordinary AI states and directions.
	assert(not cat.carrying_remote)
	cat.set_remote_visual(true)
	cat.current_state = BossCat.State.WANDER
	for entry in [[Vector2.DOWN, "carrywalk_down"], [Vector2.RIGHT, "carrywalk_right"], [Vector2.UP, "carrywalk_up"]]:
		cat.update_animation(0.0, entry[0])
		assert(cat.animation_key == entry[1] and cat.sprite.hframes == 6)
	cat.update_animation(0.0, Vector2.LEFT)
	assert(cat.animation_key == "carrywalk_right" and cat.sprite.flip_h)
	var saved_sheet: Texture2D = cat.animation_sheets["carrywalk_down"]
	cat.animation_sheets.erase("carrywalk_down")
	cat.update_animation(0.0, Vector2.DOWN)
	assert(cat.animation_key == "walk_down", "Missing carry atlas must fall back to regular walk")
	cat.animation_sheets["carrywalk_down"] = saved_sheet
	cat.current_state = BossCat.State.RUN
	cat.update_animation(0.0, Vector2.RIGHT)
	assert(cat.animation_key == "carryrun_right" and cat.sprite.hframes == 6)
	cat.update_animation(0.1, Vector2.RIGHT)
	assert(cat.sprite.frame == 1)
	cat.set_remote_visual(false)
	cat.update_animation(0.0, Vector2.RIGHT)
	assert(cat.animation_key == "panic_right" and cat.sprite.hframes == 8)

	cat.current_state = BossCat.State.SLEEP
	cat.update_animation(0.0)
	assert(cat.animation_key == "sleep" and cat.sprite.hframes == 4, "Sleeping should use four-frame sheet")
	cat.update_animation(0.30)
	assert(cat.sprite.frame == 1, "Sleeping animation should advance")

	# Exercise the real physics callback over multiple engine ticks.
	cat.current_state = BossCat.State.WANDER
	cat.move_dir = Vector2.RIGHT
	cat.state_timer = 10.0
	cat.set_physics_process(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var first_frame := cat.sprite.frame
	for i in range(20):
		await get_tree().physics_frame
	assert(cat.animation_key == "walk_right", "Physics should select walking animation")
	assert(cat.sprite.frame != first_frame, "Animation must advance across physics ticks")
	# Verify both characters load and advance their six-frame carrying/throwing sheets.
	for kind in ["boy", "girl"]:
		var player := (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
		player.character_type = kind
		add_child(player)
		player.set_physics_process(false)
		player.facing_direction = Vector2.RIGHT
		assert(player.update_character_animation("carry_run", 0.0))
		assert(player.character_animation_key == "carry_run_right" and player.sprite.hframes == 6)
		player.update_character_animation("carry_run", 0.2)
		assert(player.sprite.frame == 2, "Carrying animation must advance")
		player.facing_direction = Vector2.LEFT
		player.update_character_animation("throw", 0.05)
		assert(player.character_animation_key == "throw_right" and player.sprite.flip_h)
		player.update_sprite_pose("idle")
		assert(player.sprite.hframes == 1 and player.character_animation_key == "")
		player.queue_free()
	print("Cat and player atlas loading, progression, direction and physics verified.")
	get_tree().quit(0)
