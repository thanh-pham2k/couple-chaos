extends Node2D

const ARENA_SCENE := preload("res://scenes/arena.tscn")
const ITEM_SCENE := preload("res://scenes/item.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const QUEST_SCRIPT := preload("res://scripts/coop/quest_manager.gd")
const SESSION_SCRIPT := preload("res://scripts/coop/session_manager.gd")
const SPOT_SCRIPT := preload("res://scripts/coop/cleaning_spot.gd")
const ZONE_SCRIPT := preload("res://scripts/coop/drop_zone.gd")

var arena: Node2D
var quest: CoopQuestManager
var session: CoopSessionManager
var zones: Array = []
var spots: Array = []
var timer_text: Label
var progress_text: Dictionary = {}
var status_icons: Dictionary = {}
var hint: Label
var held_hint: Label
var overlay: PanelContainer
var overlay_title: Label
var overlay_details: Label
var start_button: Button
var menu_button: Button
var chaos_timer := 35.0
var chaos_count := 0
const PLACE_DURATION := 0.36
const PLACE_RELEASE_TIME := PLACE_DURATION * 3.0 / 6.0
# At most one in-flight placement per player; each destination is reserved.
var pending_placements: Dictionary = {}

func _enter_tree() -> void:
	add_to_group("coop_session")

func _ready() -> void:
	quest = QUEST_SCRIPT.new()
	quest.name = "QuestManager"
	add_child(quest)
	session = SESSION_SCRIPT.new()
	session.name = "SessionManager"
	add_child(session)
	_build_hud()
	quest.changed.connect(_update_hud)
	quest.all_completed.connect(_on_completed)
	session.started.connect(_on_started)
	session.ended.connect(_on_ended)
	session.time_changed.connect(_on_time_changed)
	restart_round()

func restart_round() -> void:
	_cancel_all_placements()
	if is_instance_valid(arena):
		remove_child(arena)
		arena.queue_free()
	zones.clear()
	spots.clear()
	quest.reset()
	session.reset()
	chaos_timer = 35.0
	chaos_count = 0
	arena = ARENA_SCENE.instantiate()
	arena.name = "Arena"
	add_child(arena)
	arena.set_process(false) # Party Battle keeps its own timer; co-op owns this one.
	arena.hud.mission_label.visible = false
	arena.hud.timer_label.visible = false
	arena.hud.toast_label.visible = false
	_setup_world()
	for player in [arena.p1, arena.p2]:
		player.item_held_changed.connect(_on_player_item_changed)
	_update_held_hint()
	_set_players_enabled(false)
	_update_hud()
	overlay_title.text = "5 phút trước khi khách đến!"
	overlay_details.text = "Cất 3 món • Lau 4 vết bẩn • Đặt lại 2 chiếc gối • Cất cây lau\n\nKhông cần theo thứ tự: remote → TV, tay cầm → giỏ, hộp → thùng\nGối → sofa, cây lau → vết bẩn (F / K)\nE / J: nhặt, đặt hoặc ném\nSpace / Enter: lướt  •  Cả hai cùng hoàn thành nhé!"
	start_button.text = "Bắt đầu"
	overlay.visible = true

func _set_players_enabled(enabled: bool) -> void:
	if arena.touch_controls:
		arena.touch_controls.target_player = arena.p1 if enabled else null
	for player in [arena.p1, arena.p2]:
		player.set_physics_process(enabled)
	var cat := arena.get_node_or_null("YSortArena/BossCat")
	if cat: cat.set_physics_process(enabled)

func _on_started() -> void:
	overlay.visible = false
	_set_players_enabled(true)
	hint.text = "E / 🖐: nhặt hoặc đặt • Tay cầm → giỏ | Remote → TV | Hộp → thùng rác"

func _on_completed() -> void:
	check_room_completion()

func is_room_clean() -> bool:
	if not quest or not quest.is_all_goals_met():
		return false
	for spot in spots:
		if is_instance_valid(spot) and spot.state != "clean":
			return false
	var mop_returned := false
	for zone in zones:
		if is_instance_valid(zone) and zone.target_id == "mop_station":
			if zone.completed:
				mop_returned = true
			break
	if not mop_returned:
		return false
	if is_instance_valid(arena):
		for player in [arena.p1, arena.p2]:
			if is_instance_valid(player) and player.held_item_type.begins_with("coop_"):
				return false
	if not pending_placements.is_empty():
		return false
	return true

func check_room_completion() -> void:
	if not session or not session.running or quest.finished:
		return
	if is_room_clean():
		quest.finished = true
		_cleanup_remaining_hazards()
		session.finish(true)

func _cleanup_remaining_hazards() -> void:
	if not is_instance_valid(arena): return
	var world := arena.get_node_or_null("YSortArena")
	if not world: return
	for child in world.get_children():
		if child is FloorHazard or child is ItemPickup:
			world.remove_child(child)
			child.queue_free()

func _on_ended(won: bool) -> void:
	_cancel_all_placements()
	_set_players_enabled(false)
	overlay_title.text = "Dọn xong rồi! 🎉" if won else "Khách đến rồi! ⏰"
	overlay_details.text = "Phần thưởng: 3 sao • Cả hai đã hợp sức dọn phòng!" if won else "Chưa xong lần này. Cùng thử lại nhé!"
	start_button.text = "Chơi lại"
	overlay.visible = true

func _on_start_pressed() -> void:
	if session.ended_once:
		restart_round()
	session.start_round()

func _on_time_changed(seconds: float) -> void:
	var whole := ceili(seconds)
	timer_text.text = "⏱ %02d:%02d" % [whole / 60, whole % 60]

func _update_hud() -> void:
	if progress_text.is_empty(): return
	for category in ["store", "clean", "pillow"]:
		progress_text[category].text = "%d/%d" % [quest.get_count(category), quest.GOALS[category]]
		status_icons[category].texture = load("res://assets/coop/task_complete.png" if quest.get_count(category) == quest.GOALS[category] else "res://assets/coop/task_pending.png")

func resolve_item_texture(item_type: String) -> String:
	match item_type:
		"coop_mop": return "res://assets/coop/mop.png"
		"coop_remote": return "res://assets/coop/remote.png"
		"coop_trash": return "res://assets/items/box.png"
		"coop_gamepad": return "res://assets/items/gamepad.png"
		"coop_pillow_1": return "res://assets/coop/advanced/sofa_pillow_1.png"
		"coop_pillow_2": return "res://assets/coop/advanced/sofa_pillow_2.png"
	return ""

func _on_player_item_changed(_player_id: String, _item: String) -> void:
	_update_held_hint()
	for zone in zones:
		if is_instance_valid(zone):
			zone.refresh()

func _update_held_hint() -> void:
	if not is_instance_valid(arena) or not held_hint: return
	var descriptions := {
		"coop_remote": "Remote → TV",
		"coop_trash": "Hộp → thùng rác",
		"coop_gamepad": "Tay cầm → giỏ",
		"coop_pillow_1": "Gối → sofa", "coop_pillow_2": "Gối → sofa",
		"coop_mop": "Cây lau → vết bẩn, nhấn F/K",
		"hammer": "Búa đồ chơi → cất vào giỏ",
		"wallet": "Ví tiền → cất vào giỏ",
		"pillow": "Gối phụ → cất vào giỏ",
		"gamepad": "Tay cầm phụ → cất vào giỏ",
		"banana": "Vỏ chuối/chuối → vứt vào thùng rác",
		"popcorn": "Bỏng ngô → vứt vào thùng rác",
		"boba": "Cốc trà sữa → vứt vào thùng rác",
		"box": "Hộp các-tông → vứt vào thùng rác",
	}
	var messages: Array[String] = []
	for player in [arena.p1, arena.p2]:
		if descriptions.has(player.held_item_type):
			messages.append(("P1 " if player.player_id == "p1" else "P2 ") + descriptions[player.held_item_type])
	held_hint.text = "  |  ".join(messages) if not messages.is_empty() else "Không cần theo thứ tự • Đồ ! có đích riêng"

func try_interact(player: Player) -> bool:
	if not session.running: return true
	if pending_placements.has(player): return true
	if player.held_item_type.is_empty():
		for zone in zones:
			if zone.target_id == "mop_station" and zone.completed and zone.global_position.distance_to(player.global_position) <= zone.INTERACTION_RADIUS:
				if zone.retrieve_mop(player):
					hint.text = "Đã lấy lại cây lau sàn!"
					return true
		return false
	
	if player.held_item_type == "coop_mop":
		for zone in zones:
			if zone.target_id == "mop_station" and zone.global_position.distance_to(player.global_position) <= zone.INTERACTION_RADIUS:
				var clean_goal: int = quest.get_goal("clean") if quest.has_method("get_goal") else 4
				if quest.get_count("clean") < clean_goal:
					hint.text = "Còn vết bẩn chưa lau xong! Hãy lau sạch sàn trước khi cất cây lau."
					return true
				_begin_placement(player, zone)
				return true

	for zone in zones:
		if zone.global_position.distance_to(player.global_position) <= zone.INTERACTION_RADIUS and zone.can_accept(player.held_item_type):
			if zone.target_id != "mop_station" and quest.completed[zone.category].has(player.held_item_type):
				hint.text = "Món này đã được cất rồi!"
				return true
			_begin_placement(player, zone)
			return true
	for zone in zones:
		if (not zone.completed or zone.target_id == "basket") and zone.global_position.distance_to(player.global_position) <= zone.INTERACTION_RADIUS:
			if zone.target_id == "mop_station" and player.held_item_type != "coop_mop":
				hint.text = "Đây là chỗ để cây lau sàn!"
			elif zone.target_id == "basket":
				hint.text = "Giỏ nhận TAY CẦM; remote đặt tại TV."
			else:
				hint.text = "Món này chưa đúng chỗ nhé!"
			return true
	return false # Away from a zone, the existing grab action throws the item.

func _begin_placement(player: Player, zone: CoopDropZone) -> void:
	if pending_placements.has(player) or not zone.reserve(player):
		return
	pending_placements[player] = {"zone": zone, "item": player.held_item_type, "elapsed": 0.0, "released": false}
	player.begin_place_animation()
	if zone.target_id == "trash":
		zone.open_trash_lid(PLACE_RELEASE_TIME)

func _cancel_placement(player: Player) -> void:
	if not pending_placements.has(player):
		return
	var zone: CoopDropZone = pending_placements[player]["zone"]
	pending_placements.erase(player)
	if is_instance_valid(zone):
		zone.release_reservation(player)
		if zone.target_id == "trash":
			zone.reset_trash_lid()
	if is_instance_valid(player):
		player.end_place_animation()

func _cancel_all_placements() -> void:
	for player in pending_placements.keys():
		_cancel_placement(player)

func _physics_process(delta: float) -> void:
	for player in pending_placements.keys():
		if not is_instance_valid(player):
			pending_placements.erase(player)
			continue
		var pending: Dictionary = pending_placements[player]
		var zone: CoopDropZone = pending["zone"]
		var interrupted: bool = not session.running or not is_instance_valid(zone) or not player.is_placing or player.is_stunned or player.is_slipping or player.knockback_state != Player.KnockbackState.NONE
		if not pending["released"] and not interrupted:
			interrupted = player.held_item_type != pending["item"] or player.global_position.distance_to(zone.global_position) > zone.INTERACTION_RADIUS
		if interrupted:
			_cancel_placement(player)
			continue
		pending["elapsed"] += delta
		if zone.target_id == "trash":
			zone.update_trash_lid_progress(pending["elapsed"], PLACE_RELEASE_TIME, PLACE_DURATION)
		if not pending["released"] and pending["elapsed"] >= PLACE_RELEASE_TIME:
			# The hand opens on frame 4; acceptance and progress happen exactly once.
			var texture: Texture2D = player.held_item_sprite.texture
			var origin: Vector2 = player.held_item_sprite.global_position
			pending["released"] = true
			if zone.accept_reserved(player):
				_animate_placed_item(texture, origin, zone)
			else:
				_cancel_placement(player)
				continue
		if pending_placements.has(player) and pending["elapsed"] >= PLACE_DURATION:
			pending_placements.erase(player)
			player.end_place_animation()
			check_room_completion()

func _animate_placed_item(texture: Texture2D, origin: Vector2, zone: CoopDropZone) -> void:
	if not texture or not is_instance_valid(arena):
		return
	var visual := Sprite2D.new()
	visual.texture = texture
	visual.scale = Vector2(0.55, 0.55)
	visual.z_index = 4
	arena.get_node("YSortArena").add_child(visual)
	visual.global_position = origin
	var tween := visual.create_tween()
	var dest: Vector2 = zone.global_position
	if zone.target_id == "trash":
		dest += Vector2(0, -45)
	elif zone.category == "pillow":
		dest = zone.global_position
	else:
		dest += Vector2(0, -20)
	tween.tween_property(visual, "global_position", dest, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if zone.target_id == "trash":
		tween.parallel().tween_property(visual, "scale", Vector2(0.22, 0.22), 0.16)
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.16)
	tween.tween_callback(visual.queue_free)

func try_use(player: Player) -> bool:
	if not session.running: return true
	if player.held_item_type != "coop_mop": return false
	for spot in spots:
		if spot.state != "clean" and spot.global_position.distance_to(player.global_position) <= 120.0:
			spot.scrub(player)
			if spot.state == "clean":
				hint.text = "Vết bẩn đã sạch bong! ✨"
			else:
				hint.text = "Đang lau sạch: %d/3 💦" % spot.progress
			return true
	if is_instance_valid(arena):
		var tree := arena.get_tree()
		var hazards := tree.get_nodes_in_group("hazards") if tree else []
		for hazard in hazards:
			if hazard is FloorHazard and hazard.state != "clean" and hazard.global_position.distance_to(player.global_position) <= 120.0:
				if hazard.scrub(player):
					if hazard.state == "clean":
						hint.text = "Đã lau sạch vũng trà sữa bẫy! ✨"
					else:
						hint.text = "Đang lau sạch: %d/3 💦" % hazard.progress
					return true
	player.play_mop_scrub_animation(player.global_position + player.facing_direction * 40.0)
	hint.text = "Mang cây lau tới gần vết bẩn rồi nhấn F / K để lau sàn."
	return true

func _on_deposited(category: String, id: String, _player: Player) -> void:
	if id == "coop_mop":
		hint.text = "Đã cất cây lau sàn gọn gàng lên giá bếp! ✨"
	elif quest.complete_target(category, id):
		hint.text = "Đúng chỗ rồi! ✨"
	check_room_completion()

func _on_stored_extra(id: String, _player: Player) -> void:
	if id in ["banana", "popcorn", "boba", "box"]:
		hint.text = "Đã vứt rác gọn gàng vào thùng! ✨"
	elif id in ["hammer", "wallet", "pillow", "gamepad"]:
		hint.text = "Đã cất đồ gọn gàng vào giỏ! ✨"
	else:
		hint.text = "Đã dọn dẹp vật phẩm! ✨"

func _on_cleaned(id: String, _player: Player) -> void:
	quest.complete_target("clean", id)
	var clean_goal: int = quest.get_goal("clean") if quest.has_method("get_goal") else 4
	if quest.get_count("clean") >= clean_goal:
		hint.text = "Sàn đã sạch bóng! Hãy mang cây lau về cất ở góc phòng nhé! 🧹✨"
	check_room_completion()

func _setup_world() -> void:
	var world: Node2D = arena.get_node("YSortArena")
	# Reusable Party Battle items remain on the floor as clutter to be categorized or tidied on completion.

	# Reuse the existing gamepad instead of spawning an identical non-objective copy.
	# In Co-op it is the unique basket objective and receives the same quest badge.
	var original_gamepad := world.get_node("ItemGamepad") as ItemPickup
	original_gamepad.item_type = "coop_gamepad"
	original_gamepad.update_texture()
	var badge := Label.new()
	badge.name = "QuestBadge"
	badge.text = "!"
	badge.position = Vector2(-5, -50)
	badge.add_theme_font_size_override("font_size", 28)
	badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	badge.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.1))
	badge.add_theme_constant_override("outline_size", 4)
	original_gamepad.add_child(badge)
	# Unique types preserve objective identity when picked up, dropped or thrown.
	# Mop is placed near the kitchen storage rack ready to be taken to clean stains.
	for entry in [["coop_mop", Vector2(1400, 310)], ["coop_remote", Vector2(860, 620)], ["coop_trash", Vector2(1200, 520)], ["coop_pillow_1", Vector2(820, 800)], ["coop_pillow_2", Vector2(1300, 800)]]:
		var item := ITEM_SCENE.instantiate() as ItemPickup
		item.item_type = entry[0]
		item.position = entry[1]
		world.add_child(item)
	for data in [["water_1", "spill_water.png", Vector2(710, 700)], ["tea_1", "spill_milk_tea.png", Vector2(1450, 690)], ["paw_1", "spill_paw.png", Vector2(1110, 895)], ["splatter_1", "spill_splatter.png", Vector2(1600, 790)]]:
		var spot := SPOT_SCRIPT.new() as CleaningSpot
		spot.target_id = data[0]
		spot.decal_path = "res://assets/coop/" + data[1]
		spot.position = data[2]
		world.add_child(spot)
		spot.cleaned.connect(_on_cleaned)
		spots.append(spot)
	_add_zone(world, "remote", ["coop_remote"], "store", Vector2(620, 345), "")
	_add_zone(world, "trash", ["coop_trash", "box", "banana", "popcorn", "boba"], "store", Vector2(1510, 415), "res://assets/coop/advanced/trash_bin_anim.png")
	_add_zone(world, "basket", ["coop_gamepad", "gamepad", "pillow", "wallet", "hammer"], "store", Vector2(380, 480), "res://assets/coop/basket.png")
	var sofa := world.get_node_or_null("Sofa") as Node2D
	var pillow_1_pos := Vector2(562, 466)
	var pillow_2_pos := Vector2(678, 466)
	if is_instance_valid(sofa):
		var slot_l := sofa.get_node_or_null("PillowSlotLeft") as Marker2D
		var slot_r := sofa.get_node_or_null("PillowSlotRight") as Marker2D
		pillow_1_pos = slot_l.global_position if slot_l else sofa.to_global(Vector2(-58, -64))
		pillow_2_pos = slot_r.global_position if slot_r else sofa.to_global(Vector2(58, -64))
	_add_zone(world, "pillow_1", ["coop_pillow_1", "coop_pillow_2"], "pillow", pillow_1_pos, "")
	_add_zone(world, "pillow_2", ["coop_pillow_1", "coop_pillow_2"], "pillow", pillow_2_pos, "")
	_add_zone(world, "mop_station", ["coop_mop"], "clean", Vector2(1400, 270), "res://assets/coop/advanced/mop_rack.png")
	
	for player in [arena.p1, arena.p2]:
		var guidance := CoopItemGuidance.new()
		guidance.name = "ItemGuidance_" + player.player_id
		world.add_child(guidance)
		guidance.setup(player, self)

func _add_zone(world: Node2D, id: String, accepted: Array, category: String, pos: Vector2, prop: String) -> void:
	var zone := ZONE_SCRIPT.new() as CoopDropZone
	zone.target_id = id
	zone.accepts.assign(accepted)
	zone.category = category
	zone.position = pos
	zone.prop_path = prop
	world.add_child(zone)
	zone.deposited.connect(_on_deposited)
	zone.stored_extra.connect(_on_stored_extra)
	zones.append(zone)

func _process(delta: float) -> void:
	if not session or not session.running: return
	chaos_timer -= delta
	if chaos_timer <= 0.0:
		chaos_timer = 45.0
		chaos_count += 1
		# Add a hazard during the round without undoing quest progress.
		var hazard := HAZARD_SCENE.instantiate() as FloorHazard
		hazard.hazard_type = "banana_peel"
		hazard.position = Vector2(960 + 70 * (chaos_count % 3), 760 + 55 * (chaos_count % 2))
		arena.get_node("YSortArena").add_child(hazard)
		hint.text = "Hỗn loạn! Cẩn thận vỏ chuối 🍌"

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(640, 14)
	panel.custom_minimum_size = Vector2(640, 122)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	timer_text = Label.new()
	timer_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_text.add_theme_font_size_override("font_size", 28)
	column.add_child(timer_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	for entry in [["store", "Cất đồ"], ["clean", "Lau"], ["pillow", "Gối"]]:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		status_icons[entry[0]] = icon
		var label := Label.new()
		label.text = entry[1] + " "
		label.add_theme_font_size_override("font_size", 23)
		row.add_child(label)
		var count := Label.new()
		count.custom_minimum_size.x = 78
		count.add_theme_font_size_override("font_size", 23)
		row.add_child(count)
		progress_text[entry[0]] = count
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	column.add_child(hint)
	held_hint = Label.new()
	held_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	held_hint.add_theme_font_size_override("font_size", 18)
	column.add_child(held_hint)
	overlay = PanelContainer.new()
	overlay.position = Vector2(520, 365)
	overlay.size = Vector2(880, 390)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 22)
	overlay.add_child(inner)
	overlay_title = Label.new()
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 36)
	inner.add_child(overlay_title)
	overlay_details = Label.new()
	overlay_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_details.add_theme_font_size_override("font_size", 23)
	inner.add_child(overlay_details)
	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(200, 55)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_start_pressed)
	inner.add_child(start_button)
	menu_button = Button.new()
	menu_button.text = "Về chọn chế độ"
	menu_button.custom_minimum_size = Vector2(200, 45)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/mode_select.tscn"))
	inner.add_child(menu_button)
