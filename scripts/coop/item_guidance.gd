extends Node2D
class_name CoopItemGuidance

const ARROW_ROOT := "res://assets/coop/advanced/"

var player: Player
var session_node: Node2D
var arrow_sprite: Sprite2D
var current_target_node: Node2D
var current_arrow_state := ""

func _ready() -> void:
	z_index = 8
	arrow_sprite = Sprite2D.new()
	arrow_sprite.name = "GuidanceArrow"
	arrow_sprite.scale = Vector2(0.65, 0.65)
	add_child(arrow_sprite)
	visible = false

func setup(p: Player, session: Node2D) -> void:
	player = p
	session_node = session

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(session_node):
		visible = false
		return
		
	var held_item: String = player.held_item_type
	if held_item.is_empty():
		visible = false
		current_target_node = null
		return
		
	current_target_node = _find_target(held_item)
	if not is_instance_valid(current_target_node):
		visible = false
		return
		
	var target_pos: Vector2 = current_target_node.global_position
	# Adjust target position for visual centers
	if "target_id" in current_target_node:
		if current_target_node.target_id == "trash":
			target_pos += Vector2(0, -30)
		elif current_target_node.target_id == "basket":
			target_pos += Vector2(0, -20)
			
	var dist := player.global_position.distance_to(target_pos)
	
	# If player is very close to destination (inside interaction radius), hide arrow to avoid visual clutter
	if dist < 130.0:
		visible = false
		return
		
	visible = true
	# Position arrow floating above player's head
	global_position = player.global_position + Vector2(0, -96)
	
	# Rotate arrow toward target (base arrow texture points straight UP)
	var diff: Vector2 = target_pos - player.global_position
	arrow_sprite.rotation = diff.angle() + PI * 0.5
	
	# Dynamic state based on distance
	if dist < 280.0:
		_set_state("near")
	elif dist < 580.0:
		_set_state("active")
	else:
		_set_state("idle")

func _find_target(item_type: String) -> Node2D:
	if not is_instance_valid(session_node):
		return null
		
	var zones: Array = session_node.get("zones")
	var spots: Array = session_node.get("spots")
	
	if item_type == "coop_trash":
		for z in zones:
			if z is CoopDropZone and z.target_id == "trash" and not z.completed:
				return z
	elif item_type == "coop_remote":
		for z in zones:
			if z is CoopDropZone and z.target_id == "remote" and not z.completed:
				return z
	elif item_type == "coop_pillow_1" or item_type == "coop_pillow_2":
		# Prefer corresponding slot if open, else other slot
		var pref_id := "pillow_1" if item_type == "coop_pillow_1" else "pillow_2"
		for z in zones:
			if z is CoopDropZone and z.target_id == pref_id and not z.completed:
				return z
		for z in zones:
			if z is CoopDropZone and z.category == "pillow" and not z.completed:
				return z
	elif item_type == "coop_mop":
		# If dirty spots remain, point to nearest dirty spot!
		var nearest_dirty: Node2D = null
		var min_dist := 999999.0
		for s in spots:
			if s is CleaningSpot and s.state != "clean":
				var d: float = player.global_position.distance_to(s.global_position)
				if d < min_dist:
					min_dist = d
					nearest_dirty = s
		if nearest_dirty:
			return nearest_dirty
		# If all clean, point to mop return station!
		for z in zones:
			if z is CoopDropZone and z.target_id == "mop_station" and not z.completed:
				return z
	elif item_type in ["coop_trash", "box", "banana", "popcorn", "boba"]:
		for z in zones:
			if z is CoopDropZone and z.target_id == "trash":
				return z
	elif item_type == "coop_gamepad" or not item_type.begins_with("coop_"):
		# Household clutter & gamepad -> basket
		for z in zones:
			if z is CoopDropZone and z.target_id == "basket":
				return z
				
	return null

func _set_state(state: String) -> void:
	if current_arrow_state == state:
		return
	current_arrow_state = state
	var path := ARROW_ROOT + "target_arrow_" + state + ".png"
	if ResourceLoader.exists(path):
		arrow_sprite.texture = load(path)
