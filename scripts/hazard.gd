extends Area2D
class_name FloorHazard

const CoopVisualFeedback := preload("res://scripts/coop/visual_feedback.gd")

signal cleaned(id: String, player: Player)

@export var hazard_type: String = "banana_peel" # banana_peel, boba_puddle, popcorn_mess

var progress: int = 0
var state: String = "dirty"
var target_id: String = ""
var feedback: Label
var slip_cooldowns: Dictionary = {} # player_id -> remaining cooldown in seconds

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("hazards")
	if target_id.is_empty():
		target_id = name
	update_texture()
	body_entered.connect(_on_body_entered)
	_setup_feedback_label()

func _physics_process(delta: float) -> void:
	if state == "clean" or is_queued_for_deletion():
		return
	for p_id in slip_cooldowns.keys():
		slip_cooldowns[p_id] -= delta
		if slip_cooldowns[p_id] <= 0.0:
			slip_cooldowns.erase(p_id)
	
	if hazard_type == "banana_peel" and monitoring:
		for body in get_overlapping_bodies():
			if body is Player:
				_check_slip_for_player(body)

func _setup_feedback_label() -> void:
	feedback = Label.new()
	feedback.name = "ScrubProgressLabel"
	feedback.position = Vector2(-40, -70)
	feedback.add_theme_font_size_override("font_size", 22)
	feedback.add_theme_color_override("font_color", Color.WHITE)
	feedback.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.1))
	feedback.add_theme_constant_override("outline_size", 4)
	add_child(feedback)

func update_texture() -> void:
	var path = "res://assets/hazards/" + hazard_type + ".png"
	if ResourceLoader.exists(path) and sprite:
		sprite.texture = load(path)

func scrub(player: Player) -> bool:
	if state == "clean" or player.held_item_type != "coop_mop":
		return false
	progress += 1
	state = "cleaning"
	if player.has_method("play_mop_scrub_animation"):
		player.play_mop_scrub_animation(global_position)
	if feedback:
		feedback.text = "%d/3" % progress
	if sprite:
		sprite.modulate.a = maxf(0.15, 1.0 - progress * 0.3)
	if progress >= 3:
		state = "clean"
		if sprite:
			sprite.visible = false
		if feedback:
			feedback.text = "✓"
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		CoopVisualFeedback.play_success_fx(get_parent(), global_position, "clean_success_fx")
		cleaned.emit(target_id, player)
	return true

func reset() -> void:
	progress = 0
	state = "dirty"
	slip_cooldowns.clear()
	if sprite:
		sprite.visible = true
		sprite.modulate.a = 1.0
	if feedback:
		feedback.text = ""
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func can_be_picked_up() -> bool:
	return hazard_type == "banana_peel" and state != "clean" and not is_queued_for_deletion()

func get_item_type() -> String:
	if hazard_type == "banana_peel":
		return "banana"
	elif hazard_type == "boba_puddle":
		return "boba"
	elif hazard_type == "popcorn_mess":
		return "popcorn"
	return ""

func _on_body_entered(body: Node2D) -> void:
	if state == "clean" or is_queued_for_deletion():
		return
	if body is Player:
		if hazard_type == "banana_peel":
			_check_slip_for_player(body)
		elif hazard_type == "boba_puddle":
			body.trigger_slow()

func _check_slip_for_player(body: Player) -> void:
	if slip_cooldowns.has(body.player_id) or body.is_slipping or body.is_stunned:
		return
	slip_cooldowns[body.player_id] = 2.0
	var slip_dir = body.velocity.normalized()
	if slip_dir == Vector2.ZERO:
		slip_dir = body.facing_direction if body.facing_direction != Vector2.ZERO else Vector2.DOWN
	body.trigger_slip(slip_dir)
