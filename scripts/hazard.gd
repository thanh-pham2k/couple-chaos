extends Area2D
class_name FloorHazard

@export var hazard_type: String = "banana_peel" # banana_peel, boba_puddle, popcorn_mess

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("hazards")
	update_texture()
	body_entered.connect(_on_body_entered)

func update_texture() -> void:
	var path = "res://assets/hazards/" + hazard_type + ".png"
	if ResourceLoader.exists(path) and sprite:
		sprite.texture = load(path)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if hazard_type == "banana_peel":
			var slip_dir = body.velocity.normalized()
			if slip_dir == Vector2.ZERO:
				slip_dir = Vector2.DOWN
			body.trigger_slip(slip_dir)
			set_deferred("monitoring", false)
			queue_free() # Banana peel gets consumed
		elif hazard_type == "boba_puddle":
			body.trigger_slow()
