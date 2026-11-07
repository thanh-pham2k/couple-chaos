extends Area2D
class_name CoopDropZone

signal deposited(category: String, id: String, player: Player)
signal stored_extra(id: String, player: Player)
const INTERACTION_RADIUS := 160.0
var accepts: Array[String] = []
var category := "store"
var completed := false
var target_id := ""
var prop_path := ""
var marker: Sprite2D
var prompt: Label
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
	marker.texture = load("res://assets/coop/zone_neutral.png")
	marker.z_index = -1
	add_child(marker)
	if not prop_path.is_empty():
		var prop := Sprite2D.new()
		prop.texture = load(prop_path)
		prop.position.y = -32
		add_child(prop)
	var label := Label.new()
	label.text = {"remote": "REMOTE → TV", "trash": "HỘP → THÙNG RÁC", "basket": "TAY CẦM → GIỎ", "pillow_1": "GỐI", "pillow_2": "GỐI"}.get(target_id, "")
	label.position = Vector2(-105, -100 if not prop_path.is_empty() else -55)
	label.size = Vector2(210, 25)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.1))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	prompt = Label.new()
	prompt.name = "InteractionPrompt"
	prompt.position = Vector2(-130, -135 if not prop_path.is_empty() else -88)
	prompt.size = Vector2(260, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.91, 0.35))
	prompt.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.07))
	prompt.add_theme_constant_override("outline_size", 5)
	prompt.visible = false
	prompt.z_index = 5
	add_child(prompt)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
	# Area overlap includes the player collider; prompt uses the same root-distance
	# check as interaction, including when crossing the precise radius.
	if not nearby.is_empty():
		refresh()

func refresh() -> void:
	if not marker: return
	var state := "success" if completed else "neutral"
	var keys: Array[String] = []
	var wrong_item_nearby := false
	var correct_item := ""
	var incorrect_item := ""
	for player in nearby:
		if not is_instance_valid(player) or player.global_position.distance_to(global_position) > INTERACTION_RADIUS:
			continue
		if can_accept(player.held_item_type):
			if not completed:
				state = "active"
			keys.append("E / 🖐" if player.player_id == "p1" else "J")
			correct_item = player.held_item_type
		elif not player.held_item_type.is_empty() and not completed:
			wrong_item_nearby = true
			incorrect_item = player.held_item_type
	marker.texture = load("res://assets/coop/zone_" + state + ".png")
	if prompt:
		prompt.visible = not keys.is_empty() or (not completed and wrong_item_nearby)
		if not keys.is_empty():
			prompt.text = "[" + " • ".join(keys) + "] " + ("CẤT TAY CẦM" if target_id == "basket" and correct_item == "coop_gamepad" else "ĐẶT VÀO")
		elif wrong_item_nearby:
			prompt.text = "REMOTE → TV" if target_id == "basket" and incorrect_item == "coop_remote" else "SAI MÓN — XEM TÊN BÊN DƯỚI"

func can_accept(item_type: String) -> bool:
	if not accepts.has(item_type):
		return false
	# Basket stays reusable for ordinary items after the quest item is stored.
	return not completed or (target_id == "basket" and not item_type.begins_with("coop_"))

func accept(player: Player) -> bool:
	if not can_accept(player.held_item_type):
		return false
	var id := player.held_item_type
	var extra := target_id == "basket" and not id.begins_with("coop_")
	if not extra:
		completed = true
	if category == "pillow":
		var pillow := Sprite2D.new()
		pillow.name = "PlacedPillow"
		pillow.texture = load("res://assets/coop/sofa_pillow.png")
		pillow.position.y = 50
		pillow.z_index = 1
		add_child(pillow)
	player.clear_held_item()
	refresh()
	if extra:
		stored_extra.emit(id, player)
	else:
		deposited.emit(category, id, player)
	return true
