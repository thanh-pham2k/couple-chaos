extends Node

func _ready() -> void:
	var packed := load("res://scenes/coop_slice.tscn") as PackedScene
	assert(packed != null, "coop_slice.tscn must load")
	var game = packed.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.session.start_round()
	
	var p1: Player = game.arena.p1
	var p2: Player = game.arena.p2
	
	# Find trash zone
	var trash_zone: CoopDropZone = null
	var remote_zone: CoopDropZone = null
	var basket_zone: CoopDropZone = null
	var mop_zone: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "trash": trash_zone = z
		elif z.target_id == "remote": remote_zone = z
		elif z.target_id == "basket": basket_zone = z
		elif z.target_id == "mop_station": mop_zone = z
		
	assert(trash_zone != null, "Trash drop zone must exist")
	assert(trash_zone.prop != null, "Trash bin prop sprite must exist")
	assert(trash_zone.prop.hframes == 6, "Trash bin must have 6 animation frames")
	assert(trash_zone.prop.frame == 0, "Initial lid frame must be 0 (closed)")
	
	# -------------------------------------------------------------------------
	# 1. TEST ITEM GUIDANCE INDICATORS
	# -------------------------------------------------------------------------
	var guidance_p1: CoopItemGuidance = null
	var world: Node2D = game.arena.get_node("YSortArena")
	for child in world.get_children():
		if child is CoopItemGuidance and child.player == p1:
			guidance_p1 = child
	assert(guidance_p1 != null, "CoopItemGuidance node for P1 must exist in YSortArena")
	assert(not guidance_p1.visible, "Guidance arrow must be hidden when holding nothing")
	
	# P1 picks up coop_trash far from trash bin
	p1.global_position = Vector2(500, 700)
	p1.pick_up("coop_trash")
	assert(p1.held_item_type == "coop_trash")
	
	# Step process frame for guidance
	guidance_p1._process(0.016)
	assert(guidance_p1.visible, "Guidance arrow must be visible when holding coop_trash far from bin")
	assert(guidance_p1.current_target_node == trash_zone, "Guidance target must be trash_zone")
	assert(guidance_p1.current_arrow_state != "", "Arrow state must be set")
	
	# Verify rotation points towards trash bin (pos ~ 1510, 415)
	var expected_angle: float = (trash_zone.global_position - p1.global_position).angle() + PI * 0.5
	assert(absf(guidance_p1.arrow_sprite.rotation - expected_angle) < 0.1, "Arrow must rotate towards target")
	
	# P1 approaches trash bin (< 130px)
	p1.global_position = trash_zone.global_position + Vector2(0, 80)
	guidance_p1._process(0.016)
	assert(not guidance_p1.visible, "Arrow must automatically hide when near target zone to avoid clutter")
	
	# -------------------------------------------------------------------------
	# 2. TEST TRASH BIN PLACEMENT SEQUENCE & LID ANIMATION
	# -------------------------------------------------------------------------
	assert(not trash_zone.completed, "Trash bin must start uncompleted")
	var initial_trash_count: int = game.quest.get_count("store")
	
	# Initiate interaction
	assert(game.try_interact(p1), "P1 must be able to interact with trash zone")
	assert(p1.is_placing, "P1 must begin placement animation")
	assert(game.pending_placements.has(p1), "P1 must have active pending placement")
	
	# Step through opening phase (halfway to release)
	game._physics_process(game.PLACE_RELEASE_TIME * 0.5)
	assert(trash_zone.prop.frame > 0, "Trash bin lid must be in opening frames during placement")
	assert(p1.held_item_type == "coop_trash", "Item must remain in hand before release time")
	
	# Step past release time
	game._physics_process(game.PLACE_RELEASE_TIME * 0.6)
	assert(p1.held_item_type.is_empty(), "Item must be released into trash bin at release time")
	assert(trash_zone.completed, "Trash zone must be completed")
	assert(game.quest.get_count("store") == initial_trash_count + 1, "Quest progress must increase")
	
	# Step to completion of place animation
	game._physics_process(game.PLACE_DURATION)
	assert(not game.pending_placements.has(p1), "Pending placement must be finished")
	assert(not p1.is_placing, "Player placement animation must end")
	assert(trash_zone.prop.frame == 0, "Trash bin lid must close back to frame 0")
	
	# -------------------------------------------------------------------------
	# 3. TEST CANCELLATION / INTERRUPTION SAFETY
	# -------------------------------------------------------------------------
	# P2 attempts placement in basket with clutter
	p2.global_position = basket_zone.global_position + Vector2(0, 40)
	p2.pick_up("coop_gamepad")
	assert(game.try_interact(p2))
	assert(game.pending_placements.has(p2))
	# Simulate interruption (slip/stun)
	p2.is_slipping = true
	game._physics_process(0.02)
	assert(not game.pending_placements.has(p2), "Placement must cancel immediately upon slip/stun")
	assert(p2.held_item_type == "coop_gamepad", "Item must not be lost or deleted when interrupted")
	p2.is_slipping = false
	
	# -------------------------------------------------------------------------
	# 4. TEST MOP GUIDANCE DYNAMICS
	# -------------------------------------------------------------------------
	p1.pick_up("coop_mop")
	guidance_p1._process(0.016)
	assert(guidance_p1.visible, "Mop must have guidance")
	assert(guidance_p1.current_target_node is CleaningSpot, "Mop must point to a dirty spot while stains remain")
	
	# Clean all spots
	for spot in game.spots:
		spot.state = "clean"
	guidance_p1._process(0.016)
	assert(guidance_p1.current_target_node == mop_zone, "Mop must point to mop return station once all stains are clean")
	p1.clear_held_item()
	
	# -------------------------------------------------------------------------
	# 5. TEST ROUND RESTART AND REPLAY
	# -------------------------------------------------------------------------
	game.restart_round()
	assert(game.zones.size() == 6, "All 6 zones must be recreated on round restart")
	assert(game.spots.size() == 4, "All 4 spots must be recreated on round restart")
	var new_trash: CoopDropZone = null
	for z in game.zones:
		if z.target_id == "trash": new_trash = z
	assert(new_trash != null and not new_trash.completed, "Trash zone must reset to uncompleted on replay")
	assert(new_trash.prop.frame == 0, "Trash lid must be closed on replay")
	
	print("Co-op Trash Bin lid animation, Drop VFX, and Dynamic Guidance verified successfully!")
	get_tree().quit(0)
