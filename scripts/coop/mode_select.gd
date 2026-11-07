extends Control

func _ready() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/environment/room_arena.png")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.position = Vector2(610, 260)
	panel.size = Vector2(700, 480)
	add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Couple Chaos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Chọn chế độ chơi"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 25)
	column.add_child(subtitle)
	var coop := Button.new()
	coop.text = "🧹 Co-op: 5 phút trước khi khách đến!"
	coop.custom_minimum_size = Vector2(500, 64)
	coop.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coop.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/coop_slice.tscn"))
	column.add_child(coop)
	var battle := Button.new()
	battle.text = "🔨 Party Battle"
	battle.custom_minimum_size = Vector2(500, 64)
	battle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	battle.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/arena.tscn"))
	column.add_child(battle)
