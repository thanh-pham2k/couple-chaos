extends CharacterBody2D
class_name Player

signal hearts_changed(player_id: String, hearts: int)
signal stamina_changed(player_id: String, stamina: float)
signal item_held_changed(player_id: String, item_type: String)
signal chaos_event(description: String)

@export var player_id: String = "p1" # "p1" or "p2"
@export var character_type: String = "boy" # "boy" or "girl"

const SPEED: float = 340.0
const DASH_SPEED: float = 780.0
const DASH_DURATION: float = 0.22
const STAMINA_MAX: float = 100.0
const STAMINA_REGEN: float = 26.0
const DASH_COST: float = 28.0

var hearts: int = 4
var stamina: float = 100.0
var move_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT
var touch_vector: Vector2 = Vector2.ZERO

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.RIGHT

var is_attacking: bool = false
var attack_timer: float = 0.0

var is_throwing: bool = false
var throw_timer: float = 0.0

# 4-Phase Knockback & Stun State Machine
enum KnockbackState { NONE, AIRBORNE, LANDING, STUNNED, GETTING_UP }
var knockback_state: KnockbackState = KnockbackState.NONE
var knockback_timer: float = 0.0
var knockback_duration: float = 0.0
var knockback_dir: Vector2 = Vector2.ZERO
var invulnerable_timer: float = 0.0

# Compatibility flags for test assertions & state checks
var is_stunned: bool = false
var stun_timer: float = 0.0

var is_slipping: bool = false
var slip_timer: float = 0.0
var slip_dir: Vector2 = Vector2.ZERO

var is_slowed: bool = false
var slow_timer: float = 0.0

var knockback_velocity: Vector2 = Vector2.ZERO
var held_item_type: String = ""

# Animation timers for visual juice
var walk_anim_time: float = 0.0
var idle_anim_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var carry_pivot: Marker2D = $CarryPivot
@onready var held_item_sprite: Sprite2D = $CarryPivot/HeldItemSprite
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var stun_stars: Sprite2D = $StunStars

var textures: Dictionary = {}
var attack_tween: Tween = null

func _ready() -> void:
	facing_direction = Vector2.LEFT if player_id == "p2" else Vector2.RIGHT
	load_character_textures()
	update_sprite_pose("idle")
	if stun_stars:
		stun_stars.visible = false
	if held_item_sprite:
		held_item_sprite.visible = false
	if weapon_sprite:
		weapon_sprite.visible = false
	if sprite and player_id == "p2":
		sprite.flip_h = true
	update_weapon_transform()

func load_character_textures() -> void:
	var path_base = "res://assets/characters/" + character_type + "/"
	var poses = ["idle", "run", "dash", "carry", "swing", "slam", "throw", "slip", "stunned", "angry", "victory"]
	for p in poses:
		var file_path = path_base + p + ".png"
		if ResourceLoader.exists(file_path):
			textures[p] = load(file_path)
		else:
			if ResourceLoader.exists(path_base + "idle.png"):
				textures[p] = load(path_base + "idle.png")

func update_weapon_transform() -> void:
	var is_facing_left = (facing_direction.x < 0) or (sprite and sprite.flip_h)
	if weapon_pivot:
		weapon_pivot.position = Vector2(-24, -62) if is_facing_left else Vector2(24, -62)
		weapon_pivot.scale = Vector2(-1.0 if is_facing_left else 1.0, 1.0)
	if carry_pivot:
		carry_pivot.position = Vector2(-25, -70) if is_facing_left else Vector2(25, -70)
		carry_pivot.scale = Vector2(-1.0 if is_facing_left else 1.0, 1.0)

func _physics_process(delta: float) -> void:
	# 1. Regenerate stamina
	if not is_dashing and stamina < STAMINA_MAX:
		stamina = min(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
		stamina_changed.emit(player_id, stamina)

	# 2. Invulnerability recovery flash
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		if sprite:
			sprite.modulate.a = 0.5 + 0.5 * sin(invulnerable_timer * 30.0)
		if invulnerable_timer <= 0.0 and sprite:
			sprite.modulate.a = 1.0

	# 3. Handle 4-Phase Knockback & Stun State Machine
	if knockback_state != KnockbackState.NONE:
		process_knockback_state(delta)
		return

	# Compatibility check for stun
	if is_stunned:
		stun_timer -= delta
		if stun_stars:
			stun_stars.visible = true
			stun_stars.rotation += 6.0 * delta
		if stun_timer <= 0.0:
			is_stunned = false
			if stun_stars:
				stun_stars.visible = false
			update_sprite_pose("idle")
		return

	# 4. Handle Slipping state (Banana peel)
	if is_slipping:
		slip_timer -= delta
		velocity = slip_dir * (DASH_SPEED * 0.75)
		move_and_slide()
		if sprite:
			sprite.rotation = lerp_angle(sprite.rotation, -PI/2.0 if slip_dir.x >= 0 else PI/2.0, 12.0 * delta)
		if slip_timer <= 0.0:
			is_slipping = false
			if sprite:
				sprite.rotation = 0.0
			update_sprite_pose("idle")
		return

	# 5. Handle Slow down state (Boba puddle)
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0.0:
			is_slowed = false

	# 6. Handle Attack animation lockout
	if is_attacking:
		attack_timer -= delta
		# Small forward lunge momentum
		velocity = facing_direction * 160.0
		move_and_slide()
		if attack_timer <= 0.0:
			is_attacking = false
			if held_item_type == "hammer":
				update_sprite_pose("idle")
			elif held_item_type != "":
				update_sprite_pose("carry")
			else:
				update_sprite_pose("idle")
		return

	# 7. Handle Throw animation lockout
	if is_throwing:
		throw_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if throw_timer <= 0.0:
			is_throwing = false
			update_sprite_pose("idle")
		return

	# 8. Handle Dash duration
	if is_dashing:
		dash_timer -= delta
		velocity = dash_dir * DASH_SPEED
		move_and_slide()
		if dash_timer <= 0.0:
			is_dashing = false
			update_sprite_pose("run" if move_direction != Vector2.ZERO else "idle")
		return

	# 9. Gather player input
	read_input()

	# 10. Movement & animation execution
	var current_speed = SPEED * (0.55 if is_slowed else 1.0)
	if move_direction != Vector2.ZERO:
		velocity = move_direction * current_speed
		facing_direction = move_direction.normalized()
		
		# Flip sprite left/right
		if move_direction.x != 0 and sprite:
			sprite.flip_h = (move_direction.x < 0)
			update_weapon_transform()

		# Walking bobbing juice
		walk_anim_time += delta
		if sprite:
			sprite.position.y = -80.0 + sin(walk_anim_time * 16.0) * 3.5

		# Weapon bobbing during movement
		if weapon_pivot and held_item_type == "hammer" and not is_attacking:
			weapon_pivot.rotation_degrees = 20.0 + sin(walk_anim_time * 16.0) * 8.0

		# Visual pose
		if held_item_type == "hammer":
			update_sprite_pose("run")
		elif held_item_type != "":
			update_sprite_pose("carry")
		else:
			update_sprite_pose("run")
	else:
		velocity = Vector2.ZERO
		walk_anim_time = 0.0
		idle_anim_time += delta
		if sprite:
			sprite.position.y = -80.0
			sprite.scale.y = 1.0 + sin(idle_anim_time * 3.0) * 0.02
		
		# Weapon idle breathing
		if weapon_pivot and held_item_type == "hammer" and not is_attacking:
			weapon_pivot.rotation_degrees = 20.0 + sin(idle_anim_time * 3.0) * 3.0

		if held_item_type == "hammer":
			update_sprite_pose("idle")
		elif held_item_type != "":
			update_sprite_pose("carry")
		else:
			update_sprite_pose("idle")

	move_and_slide()

func process_knockback_state(delta: float) -> void:
	knockback_timer -= delta
	
	match knockback_state:
		KnockbackState.AIRBORNE:
			# Decaying velocity while hurtling in air
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			move_and_slide()
			
			# Parabolic high arc jump
			var progress = 1.0 - clamp(knockback_timer / max(0.001, knockback_duration), 0.0, 1.0)
			if sprite:
				sprite.position.y = -80.0 - sin(progress * PI) * 55.0
				sprite.rotation = -0.45 * (1.0 if knockback_dir.x >= 0 else -1.0)
			
			if knockback_timer <= 0.0:
				# Enter LANDING / BOUNCE
				knockback_state = KnockbackState.LANDING
				knockback_timer = 0.12
				knockback_duration = 0.12
				if sprite:
					sprite.position.y = -80.0
					sprite.rotation = 0.0
					sprite.scale = Vector2(1.35, 0.65) # Ground impact squash
				spawn_vfx_in_world("comic_hit", global_position + Vector2(0, -10))

		KnockbackState.LANDING:
			velocity = Vector2.ZERO
			move_and_slide()
			# Settle squash back
			if sprite:
				sprite.scale = sprite.scale.move_toward(Vector2(1.0, 1.0), 3.0 * delta)
			
			if knockback_timer <= 0.0:
				# Enter STUNNED
				knockback_state = KnockbackState.STUNNED
				knockback_timer = 1.3
				stun_timer = 1.3
				is_stunned = true
				if sprite:
					sprite.scale = Vector2(1.0, 1.0)
				update_sprite_pose("stunned" if character_type == "boy" else "angry")
				if stun_stars:
					stun_stars.visible = true

		KnockbackState.STUNNED:
			velocity = Vector2.ZERO
			move_and_slide()
			# Dizzy wobbling
			if sprite:
				sprite.rotation = sin(knockback_timer * 10.0) * 0.08
			if stun_stars:
				stun_stars.visible = true
				stun_stars.rotation += 6.5 * delta
				stun_stars.position.y = -165.0 + sin(knockback_timer * 8.0) * 5.0
			
			if knockback_timer <= 0.0:
				# Enter GETTING_UP
				knockback_state = KnockbackState.GETTING_UP
				knockback_timer = 0.24
				is_stunned = false
				if stun_stars:
					stun_stars.visible = false
				if sprite:
					sprite.rotation = 0.0
					sprite.scale = Vector2(0.85, 1.2) # Getting up stretch
				update_sprite_pose("idle")

		KnockbackState.GETTING_UP:
			velocity = Vector2.ZERO
			move_and_slide()
			if sprite:
				sprite.scale = sprite.scale.move_toward(Vector2(1.0, 1.0), 2.0 * delta)
			
			if knockback_timer <= 0.0:
				# Recovery complete
				knockback_state = KnockbackState.NONE
				is_stunned = false
				invulnerable_timer = 0.45
				if sprite:
					sprite.scale = Vector2(1.0, 1.0)
					sprite.rotation = 0.0
				update_sprite_pose("idle")

func read_input() -> void:
	var prefix = player_id + "_"
	var input_vec = Vector2.ZERO
	
	# Primary input actions (Input Map)
	if Input.is_action_pressed(prefix + "left"): input_vec.x -= 1.0
	if Input.is_action_pressed(prefix + "right"): input_vec.x += 1.0
	if Input.is_action_pressed(prefix + "up"): input_vec.y -= 1.0
	if Input.is_action_pressed(prefix + "down"): input_vec.y += 1.0

	# Resilient keyboard fallbacks for 2 players
	if player_id == "p1":
		if Input.is_key_pressed(KEY_A): input_vec.x -= 1.0
		if Input.is_key_pressed(KEY_D): input_vec.x += 1.0
		if Input.is_key_pressed(KEY_W): input_vec.y -= 1.0
		if Input.is_key_pressed(KEY_S): input_vec.y += 1.0
		
		# Touch joystick support
		if touch_vector != Vector2.ZERO:
			input_vec = touch_vector
	else:
		if Input.is_key_pressed(KEY_LEFT): input_vec.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT): input_vec.x += 1.0
		if Input.is_key_pressed(KEY_UP): input_vec.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN): input_vec.y += 1.0

	move_direction = input_vec.normalized()
	if move_direction != Vector2.ZERO:
		facing_direction = move_direction

	# Action triggers
	var dash_pressed = Input.is_action_just_pressed(prefix + "dash")
	var attack_pressed = Input.is_action_just_pressed(prefix + "attack")
	var grab_pressed = Input.is_action_just_pressed(prefix + "grab")

	# Resilient keyboard fallback keys
	if player_id == "p1":
		if Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_F):
			if not is_attacking: attack_pressed = true
		if Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_E):
			if not is_throwing: grab_pressed = true
		if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_L):
			if not is_dashing: dash_pressed = true
	else:
		if Input.is_key_pressed(KEY_KP_1) or Input.is_key_pressed(KEY_1):
			if not is_attacking: attack_pressed = true
		if Input.is_key_pressed(KEY_KP_2) or Input.is_key_pressed(KEY_2):
			if not is_throwing: grab_pressed = true
		if Input.is_key_pressed(KEY_KP_0) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_0):
			if not is_dashing: dash_pressed = true

	if dash_pressed:
		trigger_dash()
	elif attack_pressed:
		trigger_attack()
	elif grab_pressed:
		trigger_grab()

func trigger_dash() -> void:
	if is_dashing or is_stunned or is_slipping or is_attacking or knockback_state != KnockbackState.NONE:
		return
	if stamina < DASH_COST:
		return

	stamina -= DASH_COST
	stamina_changed.emit(player_id, stamina)
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_dir = move_direction if move_direction != Vector2.ZERO else facing_direction
	update_sprite_pose("dash")
	
	# Spawn dash dust smoke VFX
	spawn_vfx_in_world("dash_smoke", global_position + Vector2(0, -10))

func trigger_attack() -> void:
	if is_stunned or is_slipping or is_attacking or is_dashing or knockback_state != KnockbackState.NONE:
		return

	is_attacking = true
	attack_timer = 0.36
	
	if held_item_type == "hammer":
		# Dynamic multi-phase hammer swing animation & hit registration
		perform_melee_hit("hammer")
		animate_hammer_swing()
	elif held_item_type == "pillow":
		# Pillow swing!
		perform_melee_hit("pillow")
		animate_pillow_swing()
	elif held_item_type == "banana":
		drop_as_hazard("banana_peel")
		is_attacking = false
	elif held_item_type == "boba":
		drop_as_hazard("boba_puddle")
		is_attacking = false
	elif held_item_type == "popcorn":
		drop_as_hazard("popcorn_mess")
		is_attacking = false
	else:
		# Bare hands punch/slap
		update_sprite_pose("swing")
		perform_melee_hit("bare_hands")

func animate_hammer_swing() -> void:
	update_weapon_transform()
	if character_type == "girl":
		update_sprite_pose("slam")
	else:
		update_sprite_pose("run")

	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()
	attack_tween = create_tween()

	# Phase 1: Anticipation wind-up (0.08s) - Pull hammer far back
	attack_tween.tween_property(weapon_pivot, "rotation_degrees", -45.0, 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	attack_tween.parallel().tween_property(sprite, "scale", Vector2(0.92, 1.08), 0.08)

	# Phase 2: High velocity smash arc (0.10s) - Slam down hard to 115 degrees
	attack_tween.tween_property(weapon_pivot, "rotation_degrees", 115.0, 0.10)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	attack_tween.parallel().tween_property(sprite, "scale", Vector2(1.18, 0.88), 0.10)

	# Phase 3: Impact ground effect at moment of strike!
	attack_tween.tween_callback(func(): spawn_vfx_in_world("comic_hit", global_position + facing_direction * 75.0 + Vector2(0, -25)))

	# Phase 4: Follow-through & return to resting angle (0.14s)
	attack_tween.tween_interval(0.04)
	attack_tween.tween_property(weapon_pivot, "rotation_degrees", 20.0, 0.14)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	attack_tween.parallel().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.14)

func animate_pillow_swing() -> void:
	update_sprite_pose("swing" if character_type == "boy" else "slam")
	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()
	attack_tween = create_tween()
	attack_tween.tween_property(carry_pivot, "rotation_degrees", -30.0, 0.08)
	attack_tween.tween_property(carry_pivot, "rotation_degrees", 55.0, 0.10)
	attack_tween.tween_property(carry_pivot, "rotation_degrees", 0.0, 0.12)

func trigger_grab() -> void:
	if is_stunned or is_slipping or is_attacking or is_throwing or knockback_state != KnockbackState.NONE:
		return

	if held_item_type != "":
		throw_held_item()
	else:
		find_and_pickup_item()

func update_sprite_pose(pose_name: String) -> void:
	if textures.has(pose_name) and sprite:
		sprite.texture = textures[pose_name]

func pick_up(item_name: String) -> void:
	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()
	is_attacking = false
	attack_timer = 0.0

	held_item_type = item_name
	item_held_changed.emit(player_id, held_item_type)
	update_weapon_transform()

	if item_name == "hammer":
		if weapon_sprite:
			var hammer_tex = load("res://assets/items/hammer.png")
			if hammer_tex:
				weapon_sprite.texture = hammer_tex
				weapon_sprite.visible = true
		if weapon_pivot:
			weapon_pivot.rotation_degrees = 20.0
		if held_item_sprite:
			held_item_sprite.visible = false
		update_sprite_pose("idle")
	else:
		if weapon_sprite:
			weapon_sprite.visible = false
		if held_item_sprite:
			var item_tex_path = "res://assets/items/" + item_name + ".png"
			if ResourceLoader.exists(item_tex_path):
				held_item_sprite.texture = load(item_tex_path)
				held_item_sprite.scale = Vector2(0.65, 0.65)
				held_item_sprite.visible = true
		update_sprite_pose("carry")

	chaos_event.emit(player_id.to_upper() + " nhặt được " + item_name.to_upper() + "!")

func throw_held_item() -> void:
	if held_item_type == "":
		return

	is_throwing = true
	throw_timer = 0.28
	update_sprite_pose("throw")

	var throw_dir = facing_direction
	if move_direction != Vector2.ZERO:
		throw_dir = move_direction

	var spawn_pos = global_position + Vector2(0, -60) + throw_dir * 35.0
	spawn_flying_item(held_item_type, spawn_pos, throw_dir)
	chaos_event.emit(player_id.to_upper() + " ném " + held_item_type.to_upper() + " vèo qua phòng!")
	clear_held_item()

func drop_as_hazard(hazard_name: String) -> void:
	var hazard_scene = load("res://scenes/hazard.tscn")
	if hazard_scene:
		var h = hazard_scene.instantiate()
		h.hazard_type = hazard_name
		h.global_position = global_position + facing_direction * 45.0
		get_parent().add_child(h)
		chaos_event.emit(player_id.to_upper() + " đặt bẫy " + hazard_name.to_upper() + " trên sàn!")
	clear_held_item()

func clear_held_item() -> void:
	held_item_type = ""
	item_held_changed.emit(player_id, "")
	if held_item_sprite:
		held_item_sprite.visible = false
	if weapon_sprite:
		weapon_sprite.visible = false
	if weapon_pivot:
		weapon_pivot.rotation_degrees = 20.0

func perform_melee_hit(weapon: String = "bare_hands") -> void:
	var reach = 135.0 if weapon == "hammer" else (115.0 if weapon == "pillow" else 95.0)
	var check_center = global_position + facing_direction * (reach * 0.5)

	# 1. Check hitting opponent player
	var opponent = get_opponent()
	if opponent and opponent.global_position.distance_to(check_center) <= reach:
		var hit_point = (global_position + opponent.global_position) / 2.0 + Vector2(0, -60)
		
		if weapon == "hammer":
			spawn_vfx_in_world("comic_hit", hit_point)
			opponent.take_knockback_hit(1, true, facing_direction, 760.0)
			chaos_event.emit("💥 BONK! " + player_id.to_upper() + " giáng búa hất văng đối thủ!")
		elif weapon == "pillow":
			spawn_vfx_in_world("feather_burst", hit_point)
			opponent.take_knockback_hit(0, true, facing_direction, 580.0)
			chaos_event.emit("🪶 PHẬT! Trận chiến gối bay lông tơi bời!")
		else:
			spawn_vfx_in_world("comic_hit", hit_point)
			opponent.take_knockback_hit(0, false, facing_direction, 420.0)
			chaos_event.emit("🖐️ CHÍ CHÓE! " + player_id.to_upper() + " tát cảnh cáo!")

	# 2. Check hitting or scaring Boss Cat
	var cat = get_tree().get_first_node_in_group("boss_cat") as BossCat
	if cat and cat.global_position.distance_to(check_center) <= 160.0:
		cat.trigger_startle(global_position)
		spawn_vfx_in_world("comic_hit", cat.global_position + Vector2(0, -30))
		chaos_event.emit("🐱 NGOEO! Boss Mèo nhảy dựng hoảng sợ tháo chạy!")

func take_knockback_hit(damage: int, stun: bool, hit_dir: Vector2, force: float = 720.0) -> void:
	if invulnerable_timer > 0.0:
		return

	if damage > 0:
		hearts = max(0, hearts - damage)
		hearts_changed.emit(player_id, hearts)

	# Drop held item upon receiving impact
	if held_item_type != "":
		drop_held_item()

	var normalized_dir = hit_dir.normalized() if hit_dir != Vector2.ZERO else -facing_direction
	knockback_velocity = normalized_dir * force

	if stun:
		knockback_state = KnockbackState.AIRBORNE
		knockback_timer = 0.28
		knockback_duration = 0.28
		knockback_dir = normalized_dir
		is_stunned = true
		stun_timer = 1.7 # Total stun time across phases
		update_sprite_pose("slip" if character_type == "boy" else "angry")
	else:
		# Light stumble
		update_sprite_pose("slip" if character_type == "boy" else "angry")

# Backward compatible hit function for existing tests
func take_hit(damage: int, stun: bool) -> void:
	take_knockback_hit(damage, stun, -facing_direction, 650.0)

func drop_held_item() -> void:
	if held_item_type == "":
		return
	spawn_item_in_world(held_item_type, global_position + Vector2(randf_range(-25, 25), 25))
	clear_held_item()

func trigger_slip(dir: Vector2) -> void:
	if is_slipping or is_stunned or knockback_state != KnockbackState.NONE:
		return
	is_slipping = true
	slip_timer = 0.6
	slip_dir = dir if dir != Vector2.ZERO else facing_direction
	if held_item_type != "":
		drop_held_item()
	update_sprite_pose("slip" if character_type == "boy" else "angry")
	chaos_event.emit(player_id.to_upper() + " trượt vỏ chuối bay người ngã chổng vó!")

func trigger_slow() -> void:
	is_slowed = true
	slow_timer = 2.0

func find_and_pickup_item() -> void:
	var items = get_tree().get_nodes_in_group("items")
	var closest_item: Node2D = null
	var closest_dist: float = 120.0
	for it in items:
		if it is Area2D and it.has_method("get_item_type"):
			var d = global_position.distance_to(it.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_item = it

	if closest_item:
		var type = closest_item.get_item_type()
		pick_up(type)
		closest_item.queue_free()

func spawn_item_in_world(type: String, pos: Vector2) -> void:
	var item_scene = load("res://scenes/item.tscn")
	if item_scene:
		var it = item_scene.instantiate()
		it.item_type = type
		it.global_position = pos
		get_parent().add_child(it)

func spawn_flying_item(type: String, pos: Vector2, dir: Vector2) -> void:
	var item_scene = load("res://scenes/item.tscn")
	if item_scene:
		var it = item_scene.instantiate()
		it.item_type = type
		it.global_position = pos
		it.is_flying = true
		it.fly_direction = dir
		it.thrown_by = player_id
		get_parent().add_child(it)

func spawn_vfx_in_world(vfx_type: String, pos: Vector2) -> void:
	var vfx_scene = load("res://scenes/vfx.tscn")
	if vfx_scene:
		var v = vfx_scene.instantiate()
		v.vfx_name = vfx_type
		v.global_position = pos
		get_parent().add_child(v)

func get_opponent() -> Player:
	var opp_id = "p2" if player_id == "p1" else "p1"
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.player_id == opp_id:
			return node
	return null
