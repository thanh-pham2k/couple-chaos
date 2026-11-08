extends Area2D
class_name CoopDropZone

const CoopVisualFeedback := preload("res://scripts/coop/visual_feedback.gd")

signal deposited(category: String, id: String, player: Player)
signal stored_extra(id: String, player: Player)

const INTERACTION_RADIUS := 160.0
var accepts: Array[String] = []
var category := "store"
var completed := false
var reserved_by: Player = null
var target_id := ""
var prop_path := ""
var marker: Sprite2D
var prop: Sprite2D
var prompt: Label
var place_icon: Sprite2D
var label: Label
var nearby: Array[Player] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = INTERACTION_RADIUS + 60.0
	shape.shape = circle
	add_child(shape)
	
	marker = Sprite2D.new()
	marker.name = "DropZoneMarker"
	marker.z_index = 0 if category == "pillow" else -1
	add_child(marker)
	
	if not prop_path.is_empty():
		prop = Sprite2D.new()
		prop.name = "ZoneProp"
		prop.texture = load(prop_path)
		prop.position.y = -20 if target_id == "mop_station" else -32
		add_child(prop)
		if target_id == "basket":
			CoopVisualFeedback.update_basket(prop, "idle")
		elif target_id == "trash":
			prop.hframes = 6
			prop.frame = 0
			
	label = Label.new()
	label.visible = false
	add_child(label)
	
	prompt = Label.new()
	prompt.name = "InteractionPrompt"
	prompt.position = Vector2(-130, -135 if not prop_path.is_empty() else (-105 if category == "pillow" else -88))
	prompt.size = Vector2(260, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.91, 0.35))
	prompt.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.07))
	prompt.add_theme_constant_override("outline_size", 5)
	prompt.visible = false
	prompt.z_index = 5
	add_child(prompt)
	
	place_icon = CoopVisualFeedback.make_place_icon(self, prompt)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	refresh()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not nearby.has(body):
		nearby.append(body)
		body.item_held_changed.connect(_on_held_changed)
		refresh()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		nearby.erase(body)
		if body.item_held_changed.is_connected(_on_held_changed):
			body.item_held_changed.disconnect(_on_held_changed)
		refresh()

func _on_held_changed(_player_id: String, _item: String) -> void:
	refresh()

func _physics_process(_delta: float) -> void:
	if not nearby.is_empty():
		refresh()

func refresh() -> void:
	if not marker: return
	var state := "success" if completed else "neutral"
	var keys: Array[String] = []
	var wrong_item_nearby := false
	var correct_item := ""
	var incorrect_item := ""
	var item_held := false
	
	if not completed and is_inside_tree():
		var session := get_tree().get_first_node_in_group("coop_session")
		if session and "arena" in session and session.arena:
			for p in [session.arena.p1, session.arena.p2]:
				if is_instance_valid(p) and can_accept(p.held_item_type):
					item_held = true
					break

	var can_retrieve_mop := false
	var active_slot := false
	for player in nearby:
		if not is_instance_valid(player) or player.global_position.distance_to(global_position) > INTERACTION_RADIUS:
			continue
		if can_accept(player.held_item_type):
			item_held = true
			if not completed:
				active_slot = true
			keys.append("E / 🖐" if player.player_id == "p1" else "J")
			correct_item = player.held_item_type
		elif not player.held_item_type.is_empty() and not completed:
			wrong_item_nearby = true
			incorrect_item = player.held_item_type
		elif target_id == "mop_station" and completed and player.held_item_type.is_empty():
			keys.append("E / 🖐" if player.player_id == "p1" else "J")
			can_retrieve_mop = true
			active_slot = true
			
	if not completed and active_slot:
		state = "active"
	CoopVisualFeedback.update_marker(marker, category, state, completed, item_held)
	if target_id == "basket" and is_instance_valid(prop):
		CoopVisualFeedback.update_basket(prop, state)
		
	if prompt:
		prompt.visible = not keys.is_empty() or (not completed and wrong_item_nearby)
		if not keys.is_empty():
			var action_name := "ĐẶT VÀO"
			if can_retrieve_mop:
				action_name = "LẤY CÂY LAU"
			elif target_id == "basket" and correct_item == "coop_gamepad":
				action_name = "CẤT TAY CẦM"
			elif target_id == "trash":
				action_name = "VỨT RÁC"
			elif target_id == "mop_station":
				action_name = "CẤT CÂY LAU"
			elif category == "pillow":
				action_name = "ĐẶT GỐI"
			prompt.text = "[" + " • ".join(keys) + "] " + action_name
		elif wrong_item_nearby:
			if target_id == "mop_station" and incorrect_item == "coop_mop":
				var clean_count: int = 0
				var clean_goal: int = 4
				var session := get_tree().get_first_node_in_group("coop_session")
				if session and "quest" in session:
					clean_count = session.quest.get_count("clean")
					clean_goal = session.quest.get_goal("clean")
				prompt.text = "HÃY LAU SÀN TRƯỚC (%d/%d)" % [clean_count, clean_goal]
			elif target_id == "basket" and incorrect_item == "coop_remote":
				prompt.text = "REMOTE → TV"
			else:
				prompt.text = "SAI VỊ TRÍ ĐẶT ĐỒ"
			
	CoopVisualFeedback.sync_place_icon(place_icon, prompt, not keys.is_empty())

func update_trash_lid_progress(elapsed: float, release_time: float, total_time: float) -> void:
	if not is_instance_valid(prop) or target_id != "trash":
		return
	if elapsed < release_time:
		var p: float = clampf(elapsed / release_time, 0.0, 1.0)
		prop.frame = mini(3, int(p * 3.99))
	else:
		var p: float = clampf((elapsed - release_time) / (total_time - release_time), 0.0, 1.0)
		if p >= 0.99:
			prop.frame = 0
		elif p >= 0.66:
			prop.frame = 5
		elif p >= 0.33:
			prop.frame = 4
		else:
			prop.frame = 3

func open_trash_lid(_duration: float = 0.18) -> void:
	if not is_instance_valid(prop) or target_id != "trash":
		return
	prop.frame = 1

func close_trash_lid(_duration: float = 0.18) -> void:
	if not is_instance_valid(prop) or target_id != "trash":
		return
	prop.frame = 0

func reset_trash_lid() -> void:
	if not is_instance_valid(prop) or target_id != "trash":
		return
	prop.frame = 0

func can_accept(item_type: String) -> bool:
	if is_instance_valid(reserved_by):
		return false
	if not accepts.has(item_type):
		return false
	if target_id == "mop_station":
		var session := get_tree().get_first_node_in_group("coop_session")
		if session and "quest" in session:
			var clean_goal: int = session.quest.get_goal("clean") if session.quest.has_method("get_goal") else 4
			return not completed and session.quest.get_count("clean") >= clean_goal
		return not completed
	return not completed or (target_id in ["basket", "trash"] and not item_type.begins_with("coop_"))

func reserve(player: Player) -> bool:
	if not can_accept(player.held_item_type):
		return false
	reserved_by = player
	refresh()
	return true

func release_reservation(player: Player) -> void:
	if reserved_by == player:
		reserved_by = null
		refresh()

func accept_reserved(player: Player) -> bool:
	if reserved_by != player:
		return false
	reserved_by = null
	return accept(player)

func accept(player: Player) -> bool:
	if not can_accept(player.held_item_type):
		return false
	var id := player.held_item_type
	var extra := (target_id in ["basket", "trash"]) and not id.begins_with("coop_")
	if not extra:
		completed = true
		
	if category == "pillow":
		var sofa := get_parent().get_node_or_null("Sofa") as Node2D
		var container := sofa.get_node_or_null("PlacedPillows") as Node2D if sofa else null
		var slot := sofa.get_node_or_null("PillowSlotLeft" if target_id == "pillow_1" else "PillowSlotRight") as Marker2D if sofa else null
		var pillow := Sprite2D.new()
		pillow.texture = load("res://assets/coop/advanced/sofa_pillow_1.png" if target_id == "pillow_1" else "res://assets/coop/advanced/sofa_pillow_2.png")
		pillow.scale = Vector2(0.9, 0.9)
		if container:
			pillow.name = "Modular_" + target_id
			container.add_child(pillow)
			pillow.position = container.to_local(slot.global_position if slot else global_position)
			if slot:
				pillow.rotation = slot.global_rotation - container.global_rotation
		else:
			pillow.name = "PlacedPillow"
			add_child(pillow)

		CoopVisualFeedback.play_success_fx(get_parent(), global_position, "place_success_fx")
	elif target_id == "remote":
		var remote := Sprite2D.new()
		remote.name = "PlacedRemote"
		remote.texture = load("res://assets/coop/remote.png")
		remote.scale = Vector2(0.45, 0.45)
		remote.position = Vector2(34, -118)
		remote.z_index = 1
		add_child(remote)
		CoopVisualFeedback.play_success_fx(get_parent(), global_position, "place_success_fx")
	elif target_id == "mop_station":
		var placed_mop := Sprite2D.new()
		placed_mop.name = "PlacedMop"
		placed_mop.texture = load("res://assets/coop/mop.png")
		placed_mop.scale = Vector2(0.85, 0.85)
		placed_mop.rotation_degrees = 0.0
		placed_mop.position = Vector2(0, 5)
		placed_mop.z_index = 1
		add_child(placed_mop)
		CoopVisualFeedback.play_success_fx(get_parent(), global_position, "place_success_fx")
	elif target_id == "basket":
		CoopVisualFeedback.play_success_fx(get_parent(), global_position, "place_success_fx")
	elif target_id == "trash":
		close_trash_lid(0.18)
		CoopVisualFeedback.play_success_fx(get_parent(), global_position + Vector2(0, -60), "trash_drop_fx")
		
	player.clear_held_item()
	refresh()
	if extra:
		stored_extra.emit(id, player)
	else:
		deposited.emit(category, id, player)
	return true

func retrieve_mop(player: Player) -> bool:
	if target_id != "mop_station" or not completed:
		return false
	if not is_instance_valid(player) or not player.held_item_type.is_empty():
		return false
	var placed := get_node_or_null("PlacedMop")
	if is_instance_valid(placed):
		remove_child(placed)
		placed.queue_free()
	completed = false
	player.pick_up("coop_mop")
	refresh()
	return true
