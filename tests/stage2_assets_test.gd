extends Node

var cat_signal_positions: Array[Vector2] = []
var p1_entered_bed_area := false

func _ready() -> void:
	var packed := load("res://scenes/stage2/stage2_room.tscn") as PackedScene
	assert(packed != null, "Stage 2 room must load")
	var room := packed.instantiate()
	add_child(room)
	await get_tree().process_frame

	var cat_bed := room.get_node("Arena/YSortArena/CatBed") as Node2D
	var marker := cat_bed.get_node("HomeMarker") as Marker2D
	var area := cat_bed.get_node("InteractionArea") as Area2D
	var bell := room.get_node("Arena/YSortArena/Doorbell") as Node2D
	var ring_icon := bell.get_node("RingIcon") as Sprite2D
	var visitor_icon := room.get_node("UI/VisitorAlert") as CanvasItem
	assert(cat_bed.get_node("Sprite2D").texture != null, "Cat bed texture must load")
	assert(bell.get_node("Sprite2D").texture != null, "Doorbell texture must load")
	assert(ring_icon.texture != null, "Ring icon texture must load")
	assert(visitor_icon.texture != null, "Visitor alert texture must load")
	assert(area != null and marker != null, "Cat bed must provide a marker and interaction area")
	assert(marker.global_position.is_equal_approx(cat_bed.to_global(marker.position)), "HomeMarker must identify a world position in the bed")
	assert(not cat_bed is PhysicsBody2D, "Decorative cat bed must not block players")
	assert(not bell is PhysicsBody2D, "Doorbell must not add player collision")
	assert(not ring_icon.visible and not visitor_icon.visible, "Event icons must be hidden initially")

	var cat: BossCat = room.get_node("Arena/YSortArena/BossCat")
	assert(not cat.carrying_remote)
	room.set_cat_remote_visual(true)
	assert(cat.carrying_remote)
	room.set_cat_remote_visual(false)
	assert(not cat.carrying_remote)

	assert(room.has_signal("cat_return_requested"))
	room.cat_return_requested.connect(_on_cat_return_requested)
	room.request_cat_return()
	assert(cat_signal_positions.size() == 1 and cat_signal_positions[0].is_equal_approx(marker.global_position), "Cat return hook must emit the bed's world position")

	bell.trigger_ring(0.15)
	room.notify_visitor_approaching(0.15)
	assert(ring_icon.visible and visitor_icon.visible, "Both notifications must appear when triggered")
	await get_tree().create_timer(0.25).timeout
	assert(not ring_icon.visible and not visitor_icon.visible, "Notifications must hide after their duration")
	# Exercise the P1 movement action and actual CharacterBody2D physics through the bed.
	var p1: Player = room.get_node("Arena/YSortArena/Player1")
	var p2: Player = room.get_node("Arena/YSortArena/Player2")
	p2.set_physics_process(false)
	p1.global_position = cat_bed.global_position + Vector2(110, -5)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body == p1:
			p1_entered_bed_area = true
	)
	await get_tree().physics_frame
	Input.action_press("p1_left")
	for step in range(90):
		await get_tree().physics_frame
		if p1.global_position.x < cat_bed.global_position.x - 70:
			break
	Input.action_release("p1_left")
	assert(p1_entered_bed_area, "P1 must cross the bed's interaction area")
	assert(p1.global_position.x < cat_bed.global_position.x - 70, "P1 must walk through and beyond the cat bed")
	print("Stage 2 assets, cat home signal, P1 traversal and timed event visibility verified.")
	room.queue_free()
	get_tree().quit()

func _on_cat_return_requested(position: Vector2) -> void:
	cat_signal_positions.append(position)
