extends Area2D
class_name ItemPickup

@export var item_type: String = "hammer" # hammer, pillow, boba, popcorn, banana, box, wallet, gamepad

var is_flying: bool = false
var fly_direction: Vector2 = Vector2.ZERO
var fly_speed: float = 750.0
var fly_time_left: float = 0.5
var thrown_by: String = ""

# The existing item art is an upright icon; compress it vertically on the
# floor so it reads as resting in the room's perspective.
const FLOOR_ITEM_SCALE := Vector2(1.0, 0.65)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("items")
	update_texture()
	body_entered.connect(_on_body_entered)
	_update_floor_visual()

func get_item_type() -> String:
	return item_type

func update_texture() -> void:
	var path = "res://assets/items/" + item_type + ".png"
	if ResourceLoader.exists(path) and sprite:
		sprite.texture = load(path)

func _physics_process(delta: float) -> void:
	if is_flying:
		var next_position := global_position + fly_direction * fly_speed * delta
		var arena := get_parent()
		while arena and not arena.has_method("get_pickup_bounds"):
			arena = arena.get_parent()
		if arena:
			var bounds: Rect2 = arena.get_pickup_bounds()
			var bounded_position := next_position.clamp(bounds.position, bounds.end)
			global_position = bounded_position
			if bounded_position != next_position:
				land_on_floor()
				return
		else:
			global_position = next_position
		rotation += 14.0 * delta * (1.0 if fly_direction.x >= 0 else -1.0)
		fly_time_left -= delta

		if fly_time_left <= 0.0:
			land_on_floor()
	else:
		# Keep the item on the floor and highlight it without moving its collider.
		# Highlight when nearby any player
		var is_near = false
		for p in get_tree().get_nodes_in_group("players"):
			if p is Player and global_position.distance_to(p.global_position) < 105.0:
				is_near = true
				break
		
		if sprite:
			var target_color := Color(1.0, 1.0, 0.8) if is_near else Color.WHITE
			sprite.modulate = sprite.modulate.lerp(target_color, minf(10.0 * delta, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if not is_flying:
		return
	
	if body is Player and body.player_id != thrown_by:
		# Hit opponent!
		if item_type == "pillow":
			body.take_hit(0, true)
			body.knockback_velocity = fly_direction * 420.0
			spawn_vfx("feather_burst", global_position)
		elif item_type == "hammer":
			body.take_hit(1, true)
			body.knockback_velocity = fly_direction * 500.0
			spawn_vfx("comic_hit", global_position)
		elif item_type == "banana":
			body.trigger_slip(fly_direction)
		elif item_type == "boba":
			body.trigger_slow()
			spawn_hazard("boba_puddle", global_position)
		else:
			body.take_hit(0, false)
			body.knockback_velocity = fly_direction * 350.0
			spawn_vfx("comic_hit", global_position)

		land_on_floor()

func _update_floor_visual() -> void:
	z_index = 0 if is_flying else -1
	if sprite:
		sprite.scale = Vector2.ONE if is_flying else FLOOR_ITEM_SCALE
		sprite.position = Vector2.ZERO

func land_on_floor() -> void:
	is_flying = false
	rotation = 0.0
	_update_floor_visual()
	
	# If banana or boba or popcorn landed, can spawn hazards!
	if item_type == "banana":
		spawn_hazard("banana_peel", global_position)
		queue_free()
		return
	elif item_type == "boba":
		spawn_hazard("boba_puddle", global_position)
		queue_free()
		return
	elif item_type == "popcorn":
		spawn_hazard("popcorn_mess", global_position)
		queue_free()
		return

func spawn_hazard(hazard_type: String, pos: Vector2) -> void:
	var hazard_scene = load("res://scenes/hazard.tscn")
	if hazard_scene:
		var h = hazard_scene.instantiate()
		h.hazard_type = hazard_type
		h.global_position = pos
		get_parent().add_child(h)

func spawn_vfx(vfx_name: String, pos: Vector2) -> void:
	var vfx_scene = load("res://scenes/vfx.tscn")
	if vfx_scene:
		var v = vfx_scene.instantiate()
		v.vfx_name = vfx_name
		v.global_position = pos
		get_parent().add_child(v)
