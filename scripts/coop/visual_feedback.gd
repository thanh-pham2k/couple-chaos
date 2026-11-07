extends RefCounted
class_name CoopVisualFeedback

const ROOT := "res://assets/coop/advanced/"

static func make_place_icon(zone: Node2D, prompt: Label) -> Sprite2D:
	var icon := Sprite2D.new()
	icon.name = "PlaceActionIcon"
	icon.texture = load(ROOT + "prompt_place.png")
	icon.scale = Vector2(0.48, 0.48)
	icon.position = Vector2(prompt.position.x + 12.0, prompt.position.y + prompt.size.y * 0.5)
	icon.z_index = 5
	icon.visible = false
	zone.add_child(icon)
	return icon

static func sync_place_icon(icon: Sprite2D, prompt: Label, valid: bool) -> void:
	if is_instance_valid(icon) and is_instance_valid(prompt):
		icon.visible = prompt.visible and valid

static func update_marker(marker: Sprite2D, category: String, state: String, completed: bool, item_held: bool = true) -> void:
	if not is_instance_valid(marker):
		return
	if category == "pillow":
		marker.visible = not completed and item_held
		marker.scale = Vector2(0.48, 0.30)
		marker.position = Vector2(0, -4.0)
		marker.texture = load(ROOT + ("pillow_slot_active.png" if state == "active" else "pillow_slot_neutral.png"))
	elif category == "item_target":
		marker.visible = not completed
		marker.scale = Vector2(0.75, 0.75)
		marker.texture = load(ROOT + "item_target_marker_" + state + ".png")
	else:
		marker.visible = true
		marker.scale = Vector2.ONE
		marker.texture = load("res://assets/coop/zone_" + state + ".png")

static func get_item_target_marker_texture(state: String) -> Texture2D:
	var path := ROOT + "item_target_marker_" + state + ".png"
	return load(path) if ResourceLoader.exists(path) else null

static func get_arrow_texture(state: String) -> Texture2D:
	var path := ROOT + "target_arrow_" + state + ".png"
	return load(path) if ResourceLoader.exists(path) else null

static func update_basket(prop: Sprite2D, state: String) -> void:
	if not is_instance_valid(prop):
		return
	prop.texture = load(ROOT + ("basket_active.png" if state == "active" else "basket_idle.png"))
	prop.scale = Vector2(0.8, 0.8)

static func play_success_fx(parent: Node2D, pos: Vector2, fx_type: String) -> void:
	if not is_instance_valid(parent):
		return
	var fx_path := ROOT + fx_type + ".png"
	if not ResourceLoader.exists(fx_path):
		return
	var fx_sprite := Sprite2D.new()
	fx_sprite.texture = load(fx_path)
	fx_sprite.hframes = 4
	fx_sprite.frame = 0
	fx_sprite.global_position = pos
	fx_sprite.z_index = 10
	fx_sprite.scale = Vector2(0.8, 0.8)
	parent.add_child(fx_sprite)
	
	var tween := fx_sprite.create_tween()
	# Play 4 frames across 0.28 seconds
	tween.tween_property(fx_sprite, "frame", 1, 0.07)
	tween.tween_property(fx_sprite, "frame", 2, 0.07)
	tween.tween_property(fx_sprite, "frame", 3, 0.07)
	tween.tween_interval(0.07)
	tween.parallel().tween_property(fx_sprite, "modulate:a", 0.0, 0.1).set_delay(0.2)
	tween.tween_callback(fx_sprite.queue_free)
