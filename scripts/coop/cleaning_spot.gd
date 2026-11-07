extends Area2D
class_name CleaningSpot

signal cleaned(id: String, player: Player)
var target_id := ""
var progress := 0
var state := "dirty"
var decal_path := ""
var graphic: Sprite2D
var feedback: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	z_index = -1
	graphic = Sprite2D.new()
	graphic.texture = load(decal_path)
	add_child(graphic)
	feedback = Label.new()
	feedback.position = Vector2(-40, -70)
	feedback.add_theme_font_size_override("font_size", 22)
	feedback.add_theme_color_override("font_color", Color.WHITE)
	feedback.add_theme_color_override("font_outline_color", Color(0.3, 0.18, 0.1))
	feedback.add_theme_constant_override("outline_size", 4)
	add_child(feedback)

func scrub(player: Player) -> bool:
	if state == "clean" or player.held_item_type != "coop_mop":
		return false
	progress += 1
	state = "cleaning"
	feedback.text = "%d/3" % progress
	graphic.modulate.a = maxf(0.25, 1.0 - progress * 0.22)
	if progress >= 3:
		state = "clean"
		graphic.visible = false
		feedback.text = "✓"
		cleaned.emit(target_id, player)
	return true
