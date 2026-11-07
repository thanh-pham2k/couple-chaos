extends Area2D
class_name ItemPickup

@export var item_type: String = "hammer" # hammer, pillow, boba, popcorn, banana, box, wallet, gamepad

var is_flying: bool = false
var fly_direction: Vector2 = Vector2.ZERO
var fly_speed: float = 750.0
var fly_time_left: float = 0.5
var thrown_by: String = ""

var idle_timer: float = 0.0
var base_scale: Vector2 = Vector2(1.0, 1.0)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("items")
	update_texture()
	body_entered.connect(_on_body_entered)
	base_scale = scale

func get_item_type() -> String:
	return item_type

func update_texture() -> void:
	var path = "res://assets/items/" + item_type + ".png"
	if ResourceLoader.exists(path) and sprite:
		sprite.texture = load(path)

func _physics_process(delta: float) -> void:
	if is_flying:
		global_position += fly_direction * fly_speed * delta
		rotation += 14.0 * delta * (1.0 if fly_direction.x >= 0 else -1.0)
		fly_time_left -= delta

		if fly_time_left <= 0.0:
			land_on_floor()
	else:
		# Idle bobbing & proximity highlight
		idle_timer += delta
		if sprite:
			sprite.position.y = sin(idle_timer * 4.5) * 3.0
		
		# Highlight when nearby any player
		var is_near = false
		for p in get_tree().get_nodes_in_group("players"):
			if p is Player and global_position.distance_to(p.global_position) < 105.0:
				is_near = true
				break
		
		scale = scale.lerp(base_scale * (1.15 if is_near else 1.0), 10.0 * delta)

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

func land_on_floor() -> void:
	is_flying = false
	rotation = 0.0
	
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
