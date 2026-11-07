extends Area2D
class_name CleaningSpot

const CoopVisualFeedback := preload("res://scripts/coop/visual_feedback.gd")

signal cleaned(id: String, player: Player)

var target_id := ""
var progress := 0
var state := "dirty"
var decal_path := ""
var graphic: Sprite2D
var feedback: Label

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true
	z_index = -1
	graphic = Sprite2D.new()
	graphic.name = "DecalGraphic"
	if ResourceLoader.exists(decal_path):
		graphic.texture = load(decal_path)
	add_child(graphic)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 42.0
	col.shape = shape
	add_child(col)

	feedback = Label.new()
	feedback.name = "ScrubProgressLabel"
	feedback.position = Vector2(-40, -70)
	feedback.add_theme_font_size_override("font_size", 22)
	feedback.add_theme_color_override("font_color", Color.WHITE)
	feedback.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.1))
	feedback.add_theme_constant_override("outline_size", 4)
	add_child(feedback)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if state == "clean":
		return
	if body is Player:
		# Milk tea puddle slows the player down due to sticky residue
		if target_id.contains("tea") or decal_path.contains("tea"):
			body.trigger_slow()

func scrub(player: Player) -> bool:
	if state == "clean" or player.held_item_type != "coop_mop":
		return false
	progress += 1
	state = "cleaning"
	if player.has_method("play_mop_scrub_animation"):
		player.play_mop_scrub_animation(global_position)
	feedback.text = "%d/3" % progress
	graphic.modulate.a = maxf(0.15, 1.0 - progress * 0.3)
	if progress >= 3:
		state = "clean"
		graphic.visible = false
		feedback.text = "✓"
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		CoopVisualFeedback.play_success_fx(get_parent(), global_position, "clean_success_fx")
		cleaned.emit(target_id, player)
	return true
