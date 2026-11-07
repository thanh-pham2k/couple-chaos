extends StaticBody2D
class_name BedInteraction

signal player_entered_bed(player: Player, slot: String)
signal player_slept(player: Player, slot: String)
signal player_woke_up(player: Player, slot: String)
signal player_left_bed(player: Player, slot: String)

const STEP_TIME_ENTER := 0.22
const STEP_TIME_WAKE := 0.24
const BREATHE_INTERVAL := 1.1

@onready var slot_boy: Marker2D = $SlotBoy
@onready var slot_girl: Marker2D = $SlotGirl
@onready var boy_sprite: Sprite2D = $BoyBedSprite
@onready var girl_sprite: Sprite2D = $GirlBedSprite
@onready var blanket_overlay: Sprite2D = $BlanketOverlay
@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $InteractionArea

var nearby_players: Array[Player] = []
var sleeping_players: Dictionary = {} # player -> Dictionary state

func _ready() -> void:
	add_to_group("bed_interaction")
	if boy_sprite:
		boy_sprite.visible = false
	if girl_sprite:
		girl_sprite.visible = false
	if blanket_overlay:
		blanket_overlay.visible = true
	if prompt_label:
		prompt_label.visible = false
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	_update_sleeping_players(delta)
	_update_prompt()

func _update_sleeping_players(delta: float) -> void:
	var finished_players: Array[Player] = []
	
	for player in sleeping_players.keys():
		if not is_instance_valid(player):
			finished_players.append(player)
			continue
		
		var data: Dictionary = sleeping_players[player]
		var sprite: Sprite2D = boy_sprite if data["slot"] == "boy" else girl_sprite
		if not is_instance_valid(sprite):
			continue
		
		data["elapsed"] += delta
		
		match data["state"]:
			"entering":
				# Poses: 0: sit -> 1: lean -> 2: lie_down -> 3: sleep
				if data["step"] == 0 and data["elapsed"] >= STEP_TIME_ENTER:
					data["step"] = 1
					data["elapsed"] = 0.0
					sprite.frame = 1 # Lean backward
				elif data["step"] == 1 and data["elapsed"] >= STEP_TIME_ENTER:
					data["step"] = 2
					data["elapsed"] = 0.0
					sprite.frame = 2 # Lie down
				elif data["step"] == 2 and data["elapsed"] >= STEP_TIME_ENTER:
					data["step"] = 3
					data["elapsed"] = 0.0
					data["state"] = "sleeping"
					sprite.frame = 3 # Sleep
					player_slept.emit(player, data["slot"])
			"sleeping":
				# Alternate between frame 3 (sleep) and frame 4 (sleep_breathe)
				if data["elapsed"] >= BREATHE_INTERVAL:
					data["elapsed"] = 0.0
					sprite.frame = 4 if sprite.frame == 3 else 3
			"waking":
				# Poses: 5: wake_up -> 0: sit -> stand on floor
				if data["step"] == 0 and data["elapsed"] >= STEP_TIME_WAKE:
					data["step"] = 1
					data["elapsed"] = 0.0
					sprite.frame = 0 # Sit
				elif data["step"] == 1 and data["elapsed"] >= STEP_TIME_WAKE:
					finished_players.append(player)

	for p in finished_players:
		_finish_wake_up(p)

func _finish_wake_up(player: Player) -> void:
	if not sleeping_players.has(player):
		return
	var data: Dictionary = sleeping_players[player]
	var sprite: Sprite2D = boy_sprite if data["slot"] == "boy" else girl_sprite
	if is_instance_valid(sprite):
		sprite.visible = false
	
	sleeping_players.erase(player)
	
	if is_instance_valid(player):
		player.is_sleeping = false
		player.visible = true
		player.collision_layer = data.get("orig_collision_layer", 2)
		player.collision_mask = data.get("orig_collision_mask", 7)
		# Restore held item visual if holding
		if player.held_item_type != "" and player.held_item_sprite:
			player.held_item_sprite.visible = true
		# Position beside bed safely
		var stand_offset := Vector2(-55, 30) if data["slot"] == "boy" else Vector2(55, 30)
		player.global_position = global_position + stand_offset
		player.update_sprite_pose("idle")
		player_left_bed.emit(player, data["slot"])

func can_player_enter(player: Player) -> bool:
	if not is_instance_valid(player) or player.is_sleeping or sleeping_players.has(player):
		return false
	if player.is_stunned or player.is_slipping or player.is_placing:
		return false
	return get_available_slot(player) != ""

func get_available_slot(player: Player) -> String:
	var preferred := "boy" if player.character_type == "boy" else "girl"
	var alternate := "girl" if preferred == "boy" else "boy"
	
	var is_preferred_taken := false
	var is_alternate_taken := false
	
	for p in sleeping_players.keys():
		var slot: String = sleeping_players[p]["slot"]
		if slot == preferred:
			is_preferred_taken = true
		elif slot == alternate:
			is_alternate_taken = true
			
	if not is_preferred_taken:
		return preferred
	elif not is_alternate_taken:
		return alternate
	return ""

func enter_bed(player: Player) -> bool:
	if not can_player_enter(player):
		return false
	
	var slot := get_available_slot(player)
	if slot == "":
		return false
		
	var sprite: Sprite2D = boy_sprite if slot == "boy" else girl_sprite
	var marker: Marker2D = slot_boy if slot == "boy" else slot_girl
	
	if not is_instance_valid(sprite) or not is_instance_valid(marker):
		return false
		
	sleeping_players[player] = {
		"slot": slot,
		"state": "entering",
		"step": 0,
		"elapsed": 0.0,
		"orig_pos": player.global_position,
		"orig_collision_layer": player.collision_layer,
		"orig_collision_mask": player.collision_mask
	}
	
	# Freeze player
	player.is_sleeping = true
	player.velocity = Vector2.ZERO
	player.collision_layer = 0
	player.collision_mask = 0
	player.visible = false
	if player.held_item_sprite:
		player.held_item_sprite.visible = false
	
	# Setup bed sprite
	sprite.visible = true
	sprite.frame = 0 # Sit
	sprite.position = marker.position
	
	player_entered_bed.emit(player, slot)
	return true

func wake_up(player: Player) -> bool:
	if not sleeping_players.has(player):
		return false
	var data: Dictionary = sleeping_players[player]
	if data["state"] == "waking":
		return false # already waking
	
	data["state"] = "waking"
	data["step"] = 0
	data["elapsed"] = 0.0
	
	var sprite: Sprite2D = boy_sprite if data["slot"] == "boy" else girl_sprite
	if is_instance_valid(sprite):
		sprite.frame = 5 # Wake up
	
	player_woke_up.emit(player, data["slot"])
	return true

func try_interact(player: Player) -> bool:
	if not is_instance_valid(player):
		return false
	if sleeping_players.has(player):
		return wake_up(player)
	
	if nearby_players.has(player) and can_player_enter(player):
		return enter_bed(player)
	return false

func _unhandled_input(event: InputEvent) -> void:
	if sleeping_players.is_empty():
		return
	if not event.is_pressed() or event.is_echo():
		return
	for player in sleeping_players.keys():
		if not is_instance_valid(player):
			continue
		var prefix = player.player_id + "_"
		var is_wake_key := false
		if event.is_action_pressed(prefix + "grab") or event.is_action_pressed(prefix + "attack") or event.is_action_pressed(prefix + "dash"):
			is_wake_key = true
		elif event is InputEventKey:
			var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if player.player_id == "p1" and (key == KEY_E or key == KEY_F or key == KEY_SPACE):
				is_wake_key = true
			elif player.player_id == "p2" and (key == KEY_J or key == KEY_K or key == KEY_ENTER):
				is_wake_key = true
		
		if is_wake_key:
			wake_up(player)
			get_viewport().set_input_as_handled()
			return

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not nearby_players.has(body):
		nearby_players.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Player and nearby_players.has(body):
		nearby_players.erase(body)

func _update_prompt() -> void:
	if not prompt_label:
		return
	
	# If any player is sleeping, show wake up prompt
	var prompts: Array[String] = []
	for p in sleeping_players.keys():
		if is_instance_valid(p) and sleeping_players[p]["state"] == "sleeping":
			var key := "E" if p.player_id == "p1" else "J"
			prompts.append("[%s] THỨC DẬY" % key)
	
	# For nearby players not yet sleeping
	for p in nearby_players:
		if is_instance_valid(p) and not sleeping_players.has(p) and can_player_enter(p):
			var key := "E" if p.player_id == "p1" else "J"
			prompts.append("[%s] NẰM NGỦ" % key)
	
	if prompts.is_empty():
		prompt_label.visible = false
	else:
		prompt_label.text = " • ".join(prompts)
		prompt_label.visible = true

func reset() -> void:
	for p in sleeping_players.keys():
		if is_instance_valid(p):
			p.is_sleeping = false
			p.visible = true
			if p.held_item_type != "" and p.held_item_sprite:
				p.held_item_sprite.visible = true
	sleeping_players.clear()
	nearby_players.clear()
	if boy_sprite:
		boy_sprite.visible = false
	if girl_sprite:
		girl_sprite.visible = false
	if prompt_label:
		prompt_label.visible = false
