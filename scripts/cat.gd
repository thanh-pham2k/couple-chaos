extends CharacterBody2D
class_name BossCat

enum State { SLEEP, STARTLED, RUN, HISS, WANDER }

var current_state: State = State.SLEEP
var state_timer: float = 4.0
var walk_time: float = 0.0

var move_dir: Vector2 = Vector2.ZERO
var threat_pos: Vector2 = Vector2.ZERO

const WANDER_SPEED: float = 95.0
const RUN_SPEED: float = 460.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

var textures: Dictionary = {}
var animation_sheets: Dictionary = {}
var animation_key: String = ""
var animation_clock: float = 0.0
const FRAME_COUNTS := {"walk": 6, "run": 8, "panic": 8, "idle": 4, "sleep": 4, "startled": 4, "hiss": 4}
const FRAME_RATES := {"walk": 8.0, "run": 12.0, "panic": 14.0, "idle": 4.0, "sleep": 4.0, "startled": 12.0, "hiss": 6.0}


func _ready() -> void:
	load_textures()
	update_visual()
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)

func load_textures() -> void:
	var path_base = "res://assets/pets/cat/"
	var states = ["sleep", "startled", "run", "hiss"]
	for s in states:
		var p = path_base + s + ".png"
		if ResourceLoader.exists(p):
			textures[s] = load(p)
	for action in ["walk", "run", "panic", "idle"]:
		for direction in ["down", "right", "up"]:
			var key = action + "_" + direction
			var sheet_path = path_base + "animations/" + key + ".png"
			if ResourceLoader.exists(sheet_path):
				var sheet = load(sheet_path) as Texture2D
				if sheet and sheet.get_width() == int(FRAME_COUNTS[action]) * 64 and sheet.get_height() == 64:
					animation_sheets[key] = sheet
	for action in ["sleep", "startled", "hiss"]:
		var sheet_path = path_base + "animations/" + action + ".png"
		if ResourceLoader.exists(sheet_path):
			var sheet = load(sheet_path) as Texture2D
			if sheet and sheet.get_width() == 256 and sheet.get_height() == 64:
				animation_sheets[action] = sheet

func update_animation(delta: float, direction: Vector2 = Vector2.ZERO) -> void:
	if not sprite:
		return
	var action := ""
	match current_state:
		State.SLEEP: action = "sleep"
		State.WANDER: action = "walk"
		State.STARTLED: action = "startled"
		State.RUN: action = "panic"
		State.HISS: action = "hiss"
	var key := action
	if action == "walk" or action == "panic":
		if direction == Vector2.ZERO:
			direction = move_dir
		var facing := "right" if absf(direction.x) > absf(direction.y) else ("up" if direction.y < 0.0 else "down")
		key += "_" + facing
		if action == "panic" and not animation_sheets.has(key):
			key = "run_" + facing
		if facing == "right":
			sprite.flip_h = direction.x < 0.0
		else:
			sprite.flip_h = false
	if not animation_sheets.has(key):
		if animation_key != "":
			animation_key = ""
			sprite.hframes = 1
			sprite.frame = 0
			update_visual()
		return
	if animation_key != key:
		animation_key = key
		animation_clock = 0.0
		sprite.hframes = 1
		sprite.frame = 0
		sprite.texture = animation_sheets[key]
		var actual_action: String = key.get_slice("_", 0)
		sprite.hframes = FRAME_COUNTS[actual_action]
		sprite.position = Vector2(0, -26)
		sprite.rotation = 0.0
		sprite.scale = Vector2.ONE
	var current_action: String = key.get_slice("_", 0)
	animation_clock += delta
	var frame_index := int(animation_clock * float(FRAME_RATES[current_action]))
	if current_action == "startled":
		sprite.frame = mini(frame_index, int(FRAME_COUNTS[current_action]) - 1)
	else:
		sprite.frame = frame_index % int(FRAME_COUNTS[current_action])

func update_visual() -> void:
	if not sprite:
		return
	animation_key = ""
	sprite.hframes = 1
	sprite.frame = 0
	sprite.scale = Vector2.ONE
	sprite.position.x = 0.0
	match current_state:
		State.SLEEP:
			if textures.has("sleep"): sprite.texture = textures["sleep"]
			sprite.position = Vector2(0, -32)
			sprite.rotation = 0.0
		State.WANDER:
			if textures.has("run"): sprite.texture = textures["run"]
			sprite.position = Vector2(0, -32)
			sprite.rotation = 0.0
		State.STARTLED:
			if textures.has("startled"): sprite.texture = textures["startled"]
			sprite.position = Vector2(0, -48) # Shock leap up!
			sprite.rotation = 0.0
		State.RUN:
			if textures.has("run"): sprite.texture = textures["run"]
			sprite.position = Vector2(0, -32)
			sprite.rotation = 0.0
		State.HISS:
			if textures.has("hiss"): sprite.texture = textures["hiss"]
			sprite.position = Vector2(0, -32)

func _physics_process(delta: float) -> void:
	state_timer -= delta
	walk_time += delta
	
	match current_state:
		State.SLEEP:
			update_animation(delta)
			velocity = Vector2.ZERO
			if sprite and animation_key == "":
				sprite.scale.y = 1.0 + sin(walk_time * 2.5) * 0.03
			
			# Check nearby players to wake up if disturbed
			check_proximity_disturbance(90.0)
			
			if state_timer <= 0.0:
				# Naturally wake up to wander
				start_wandering()

		State.WANDER:
			# Leisurely stroll
			var steered_dir = steer_around_obstacles(move_dir)
			velocity = steered_dir * WANDER_SPEED
			update_animation(delta, steered_dir)
			if animation_key == "":
				if steered_dir.x != 0 and sprite:
					sprite.flip_h = steered_dir.x < 0
				if sprite:
					sprite.position.y = -32.0 + sin(walk_time * 12.0) * 2.5
			move_and_slide()
			
			# Check if players rush in
			check_proximity_disturbance(95.0)
			
			if state_timer <= 0.0:
				if randf() > 0.45:
					# Pick new wander direction
					pick_new_wander_dir()
				else:
					# Go to sleep
					current_state = State.SLEEP
					state_timer = randf_range(4.5, 8.0)
					update_visual()

		State.STARTLED:
			update_animation(delta)
			velocity = Vector2.ZERO
			# Startle shudder
			if sprite and animation_key == "":
				sprite.position.x = sin(state_timer * 40.0) * 2.0
			if state_timer <= 0.0:
				start_running_away()

		State.RUN:
			# Panic flee AWAY from threat
			var escape_vector = (global_position - threat_pos).normalized()
			if escape_vector == Vector2.ZERO:
				escape_vector = move_dir if move_dir != Vector2.ZERO else Vector2.RIGHT
			
			var steered_dir = steer_around_obstacles(escape_vector)
			velocity = steered_dir * RUN_SPEED
			update_animation(delta, steered_dir)
			if animation_key == "":
				if steered_dir.x != 0 and sprite:
					sprite.flip_h = steered_dir.x < 0
				if sprite:
					sprite.position.y = -32.0 + sin(walk_time * 26.0) * 4.0
			
			move_and_slide()
			
			# Check if cornered against a wall while player is right next to cat
			if is_on_wall() and get_closest_player_distance() < 75.0:
				current_state = State.HISS
				state_timer = 0.65
				update_visual()
				return
			
			# Safe distance check
			if state_timer <= 0.0 or get_closest_player_distance() > 340.0:
				# Escaped safely! Calm down to wander
				start_wandering()

		State.HISS:
			update_animation(delta)
			velocity = Vector2.ZERO
			# Back arch hiss shake
			if sprite and animation_key == "":
				sprite.position.x = sin(state_timer * 35.0) * 3.0
			if state_timer <= 0.0:
				# Dart away in the clearest available escape direction
				start_running_away()

func check_proximity_disturbance(threshold_dist: float) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if p is Player:
			var d = global_position.distance_to(p.global_position)
			if d < threshold_dist or (d < threshold_dist * 1.5 and p.is_dashing):
				trigger_startle(p.global_position)
				return

func get_closest_player_distance() -> float:
	var min_d = 99999.0
	for p in get_tree().get_nodes_in_group("players"):
		if p is Player:
			var d = global_position.distance_to(p.global_position)
			if d < min_d:
				min_d = d
	return min_d

func trigger_startle(from_pos: Vector2 = Vector2.ZERO) -> void:
	if from_pos != Vector2.ZERO:
		threat_pos = from_pos
	else:
		# Default to closest player
		for p in get_tree().get_nodes_in_group("players"):
			if p is Player:
				threat_pos = p.global_position
				break
	
	current_state = State.STARTLED
	state_timer = 0.35
	update_visual()

func start_running_away() -> void:
	current_state = State.RUN
	state_timer = randf_range(2.6, 4.0)
	var esc = (global_position - threat_pos).normalized()
	if esc == Vector2.ZERO:
		var angles = [0, PI/4, PI/2, 3*PI/4, PI, -PI/4, -PI/2, -3*PI/4]
		esc = Vector2.RIGHT.rotated(angles[randi() % angles.size()])
	move_dir = esc
	update_visual()

func start_wandering() -> void:
	current_state = State.WANDER
	pick_new_wander_dir()
	update_visual()

func pick_new_wander_dir() -> void:
	state_timer = randf_range(3.0, 5.5)
	# Pick a calm random walking direction towards open center of room
	var room_center = Vector2(960, 540)
	var dir_to_center = (room_center - global_position).normalized()
	var random_angle = randf_range(-PI * 0.7, PI * 0.7)
	move_dir = dir_to_center.rotated(random_angle).normalized()

func steer_around_obstacles(desired_dir: Vector2) -> Vector2:
	if desired_dir == Vector2.ZERO:
		return desired_dir
		
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return desired_dir

	# Cast feeler rays to check forward clearance
	var test_angles = [0.0, -PI/4.0, PI/4.0, -PI/2.0, PI/2.0, -3*PI/4.0, 3*PI/4.0]
	var best_dir = desired_dir
	var best_score = -99999.0

	for angle in test_angles:
		var test_dir = desired_dir.rotated(angle).normalized()
		var ray_param = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -10), global_position + Vector2(0, -10) + test_dir * 50.0, 1) # Layer 1 = furniture & walls
		ray_param.exclude = [self]
		var hit = space_state.intersect_ray(ray_param)
		
		var clearance = 50.0
		if hit:
			clearance = global_position.distance_to(hit.position)
		
		var alignment = test_dir.dot(desired_dir)
		var score = alignment * 1.2 + (clearance / 50.0) * 2.5
		if score > best_score:
			best_score = score
			best_dir = test_dir

	return best_dir

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		if current_state == State.SLEEP or current_state == State.WANDER:
			trigger_startle(body.global_position)
