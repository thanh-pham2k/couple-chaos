extends SceneTree

func _init() -> void:
	var assets := {
		"res://assets/coop/advanced/trash_bin_anim.png": Vector2i(576, 112),
		"res://assets/coop/advanced/item_target_marker_neutral.png": Vector2i(128, 128),
		"res://assets/coop/advanced/item_target_marker_active.png": Vector2i(128, 128),
		"res://assets/coop/advanced/item_target_marker_success.png": Vector2i(128, 128),
		"res://assets/coop/advanced/target_arrow_idle.png": Vector2i(64, 64),
		"res://assets/coop/advanced/target_arrow_active.png": Vector2i(64, 64),
		"res://assets/coop/advanced/target_arrow_near.png": Vector2i(64, 64),
		"res://assets/coop/advanced/trash_drop_fx.png": Vector2i(512, 128)
	}
	
	for path in assets.keys():
		var tex: Texture2D = load(path)
		assert(tex != null, "Failed to load " + path)
		var exp_size: Vector2i = assets[path]
		var act_size := Vector2i(tex.get_width(), tex.get_height())
		assert(act_size == exp_size, "Size mismatch on " + path + ": " + str(act_size) + " vs " + str(exp_size))
		print("[PASS] Godot ResourceLoader verified: ", path, " -> ", act_size)
	
	print("\nALL 8 GAMEPLAY ASSETS VERIFIED IN GODOT RUNTIME!")
	quit(0)
