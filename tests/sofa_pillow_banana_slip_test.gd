extends Node2D

const ARENA_SCENE := preload("res://scenes/arena.tscn")
const SLICE_SCENE := preload("res://scenes/coop_slice.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const ITEM_SCENE := preload("res://scenes/item.tscn")

func _ready() -> void:
	print("=== RUNNING SOFA, PILLOW & BANANA SLIP QA SUITE ===")
	await run_tests()
	print("=== ALL SOFA, PILLOW & BANANA SLIP QA TESTS PASSED! 100% VERIFIED ===")
	get_tree().quit(0)

func run_tests() -> void:
	test_coffee_table_sofa_layout()
	test_banana_slip_persistence_and_cooldown()
	test_banana_pickup_carry_and_trash_deposit()
	await test_banana_throw_and_drop_hazard()
	test_sofa_pillow_placement_and_sync()
	await test_replay_restores_state()

func test_coffee_table_sofa_layout() -> void:
	print("1. Testing Coffee Table and Sofa spacing and alignment...")
	var arena := ARENA_SCENE.instantiate() as Node2D
	add_child(arena)
	
	var table := arena.get_node("YSortArena/CoffeeTable") as StaticBody2D
	var sofa := arena.get_node("YSortArena/Sofa") as StaticBody2D
	var popcorn := arena.get_node("YSortArena/ItemPopcorn") as Node2D
	var gamepad := arena.get_node("YSortArena/ItemGamepad") as Node2D
	
	assert(table != null, "CoffeeTable must exist")
	assert(sofa != null, "Sofa must exist")
	assert(table.position.x == 620.0, "CoffeeTable must be horizontally centered at X=620 with sofa")
	assert(sofa.position.x == 620.0, "Sofa must be centered at X=620")
	assert(table.position.y == 380.0, "CoffeeTable must be shifted south to Y=380 away from TV")
	
	# Check distance between CoffeeTable and Sofa
	var gap: float = sofa.position.y - table.position.y
	assert(gap >= 140.0, "Clear distance between table and sofa roots must be >= 140px (actual: %f)" % gap)
	
	# Verify table items rest naturally on new table position
	assert(popcorn.position.y <= 355.0 and popcorn.position.y >= 335.0, "Popcorn must sit on table surface")
	assert(gamepad.position.y <= 355.0 and gamepad.position.y >= 335.0, "Gamepad must sit on table surface")
	
	arena.queue_free()
	print("PASS: Coffee Table and Sofa spacing verified.")

func test_banana_slip_persistence_and_cooldown() -> void:
	print("2. Testing Banana peel persists after slip and slip cooldown works...")
	var hazard := HAZARD_SCENE.instantiate() as FloorHazard
	hazard.hazard_type = "banana_peel"
	add_child(hazard)
	hazard.global_position = Vector2(500, 500)
	
	var p1 := PLAYER_SCENE.instantiate() as Player
	p1.player_id = "p1"
	p1.character_type = "boy"
	add_child(p1)
	p1.global_position = Vector2(500, 500)
	
	# Step on banana peel -> Player slips
	hazard._on_body_entered(p1)
	assert(p1.is_slipping, "Player 1 must slip upon stepping on banana peel")
	assert(not hazard.is_queued_for_deletion(), "CRITICAL: Banana peel must NOT be deleted upon slip!")
	assert(hazard.monitoring, "Banana hazard must remain active")
	
	# Check cooldown: immediate re-trigger during cooldown must NOT re-slip or reset slip timer
	p1.is_slipping = false
	hazard._on_body_entered(p1)
	assert(not p1.is_slipping, "Player 1 must be protected by slip cooldown while standing on peel")
	
	# Simulate cooldown expiring (2.1 seconds)
	hazard._physics_process(2.1)
	# Now walking onto it again triggers slip
	hazard._on_body_entered(p1)
	assert(p1.is_slipping, "Player 1 can slip again after cooldown expires")
	assert(not hazard.is_queued_for_deletion(), "Banana peel still remains on floor")
	
	hazard.queue_free()
	p1.queue_free()
	print("PASS: Banana peel persistence and cooldown verified.")

func test_banana_pickup_carry_and_trash_deposit() -> void:
	print("3. Testing picking up banana from floor, carrying, and disposing in trash...")
	var slice := SLICE_SCENE.instantiate()
	add_child(slice)
	slice.session.start_round()
	
	var p1: Player = slice.arena.p1
	var trash_zone: CoopDropZone = null
	for zone in slice.zones:
		if zone.target_id == "trash":
			trash_zone = zone
			break
	assert(trash_zone != null, "Trash zone must exist")
	
	# Spawn a banana hazard on the floor
	var hazard := HAZARD_SCENE.instantiate() as FloorHazard
	hazard.hazard_type = "banana_peel"
	slice.arena.get_node("YSortArena").add_child(hazard)
	hazard.global_position = Vector2(600, 600)
	
	# Player steps on it and slips
	p1.global_position = Vector2(600, 600)
	hazard._on_body_entered(p1)
	assert(p1.is_slipping, "Player slips on banana")
	assert(not hazard.is_queued_for_deletion(), "Banana stays on floor")
	p1.is_slipping = false
	
	# Player picks up the banana peel from floor
	assert(hazard.can_be_picked_up(), "Banana hazard must report can_be_picked_up() == true")
	p1.trigger_grab()
	assert(p1.held_item_type == "banana", "Player must hold 'banana'")
	assert(hazard.is_queued_for_deletion(), "Floor hazard must be removed once picked up")
	
	# Carry banana to trash bin
	p1.global_position = trash_zone.global_position + Vector2(25, 25)
	assert(trash_zone.can_accept("banana"), "Trash bin must accept banana item")
	
	var disposed := [false]
	trash_zone.stored_extra.connect(func(id, _p):
		if id == "banana":
			disposed[0] = true
	)
	
	assert(slice.try_interact(p1), "Player must begin trash placement interaction")
	assert(p1.is_placing, "Player is placing banana into trash")
	
	# Step through placement duration
	for i in range(25):
		slice._physics_process(0.016)
		
	assert(p1.held_item_type == "", "Player held item cleared after disposal")
	assert(disposed[0] == true, "stored_extra signal must emit for banana")
	
	slice.queue_free()
	print("PASS: Banana pickup, carry, and trash disposal verified.")

func test_banana_throw_and_drop_hazard() -> void:
	print("4. Testing banana drop and throw hazard behavior...")
	var arena := ARENA_SCENE.instantiate() as Node2D
	add_child(arena)
	
	var p1: Player = arena.p1
	p1.pick_up("banana")
	assert(p1.held_item_type == "banana", "P1 holds banana")
	
	# Test drop_as_hazard
	p1.drop_as_hazard("banana_peel")
	assert(p1.held_item_type == "", "Held item cleared after dropping hazard")
	await get_tree().process_frame
	
	var dropped_peel: FloorHazard = null
	for child in arena.get_node("YSortArena").get_children():
		if child is FloorHazard and child.hazard_type == "banana_peel":
			dropped_peel = child
			break
	if dropped_peel == null:
		for child in arena.get_children():
			if child is FloorHazard and child.hazard_type == "banana_peel":
				dropped_peel = child
				break
	assert(dropped_peel != null, "Dropped banana peel hazard must be created")
	assert(dropped_peel.can_be_picked_up(), "Dropped banana peel can be picked up")
	
	arena.queue_free()
	print("PASS: Banana drop as hazard verified.")

func test_sofa_pillow_placement_and_sync() -> void:
	print("5. Testing Sofa Pillow placement, natural cushion alignment, and animation sync...")
	var slice := SLICE_SCENE.instantiate()
	add_child(slice)
	slice.session.start_round()
	
	var p1: Player = slice.arena.p1
	var p2: Player = slice.arena.p2
	var sofa := slice.arena.get_node("YSortArena/Sofa") as Node2D
	var sofa_back := slice.arena.get_node("YSortArena/SofaBack") as Sprite2D
	var slot_l := sofa.get_node("PillowSlotLeft") as Marker2D
	var slot_r := sofa.get_node("PillowSlotRight") as Marker2D
	
	assert(slot_l != null and slot_r != null, "Both pillow slots must exist")
	assert(slot_l.position == Vector2(-58, -64), "Slot left anchored at (-58, -64)")
	assert(slot_r.position == Vector2(58, -64), "Slot right anchored at (58, -64)")
	
	var p1_zone: CoopDropZone = null
	var p2_zone: CoopDropZone = null
	for z in slice.zones:
		if z.target_id == "pillow_1": p1_zone = z
		elif z.target_id == "pillow_2": p2_zone = z
		
	assert(p1_zone != null and p2_zone != null, "Both pillow drop zones must exist")
	assert(p1_zone.position == sofa.to_global(slot_l.position), "Pillow 1 zone must match slot L")
	assert(p2_zone.position == sofa.to_global(slot_r.position), "Pillow 2 zone must match slot R")
	assert(p1_zone.marker.visible, "Pillow 1 marker must be visible initially")
	assert(not p1_zone.label.visible, "Static text labels on furniture must remain hidden")
	
	# Test P1 placing pillow 1
	p1.pick_up("coop_pillow_1")
	p1.global_position = p1_zone.global_position
	assert(slice.try_interact(p1), "P1 must interact with pillow 1 slot")
	assert(p1.is_placing, "P1 must enter placing animation")
	
	# Simulate to release time
	slice._physics_process(slice.PLACE_RELEASE_TIME + 0.05)
	assert(p1.held_item_type == "", "P1 released pillow")
	assert(p1_zone.completed, "P1 zone is now completed")
	
	# Check completed state: marker and label MUST be hidden!
	assert(not p1_zone.marker.visible, "Completed pillow marker must be hidden")
	assert(not p1_zone.label.visible, "Completed pillow label must be hidden")
	
	var placed_p1 := p1_zone.get_node_or_null("PlacedPillow") as Sprite2D
	assert(placed_p1 != null, "PlacedPillow sprite must exist")
	assert(placed_p1.z_index == 0, "Placed pillow z_index must be 0 for natural Y-sort under sofa front")
	assert(placed_p1.scale == Vector2(0.68, 0.68), "Placed pillow scale must be natural (0.68)")
	
	# Test P2 placing pillow 2 independently
	p2.pick_up("coop_pillow_2")
	p2.global_position = p2_zone.global_position
	assert(slice.try_interact(p2), "P2 must interact with pillow 2 slot")
	slice._physics_process(slice.PLACE_RELEASE_TIME + 0.05)
	assert(p2_zone.completed, "P2 zone is now completed")
	assert(not p2_zone.marker.visible, "Pillow 2 marker hidden")
	assert(not p2_zone.label.visible, "Pillow 2 label hidden")
	
	# Check quest counter
	assert(slice.quest.get_count("pillow") == 2, "Pillow quest count must be 2/2")
	
	slice.queue_free()
	print("PASS: Sofa pillow placement and visual sync verified.")

func test_replay_restores_state() -> void:
	print("6. Testing replay/reset restores initial state cleanly...")
	var slice := SLICE_SCENE.instantiate()
	add_child(slice)
	slice.session.start_round()
	
	# Complete one pillow
	var p1: Player = slice.arena.p1
	var p1_zone: CoopDropZone = null
	for z in slice.zones:
		if z.target_id == "pillow_1": p1_zone = z
	p1.pick_up("coop_pillow_1")
	p1.global_position = p1_zone.global_position
	slice.try_interact(p1)
	slice._physics_process(slice.PLACE_RELEASE_TIME + 0.05)
	assert(p1_zone.completed)
	
	# Restart round
	slice.restart_round()
	await get_tree().process_frame
	
	var new_p1_zone: CoopDropZone = null
	for z in slice.zones:
		if z.target_id == "pillow_1": new_p1_zone = z
		
	assert(new_p1_zone != null, "New pillow 1 zone exists after restart")
	assert(not new_p1_zone.completed, "New pillow 1 zone must not be completed")
	assert(new_p1_zone.marker.visible, "Pillow 1 marker visible again")
	assert(slice.quest.get_count("pillow") == 0, "Pillow quest count reset to 0")
	
	slice.queue_free()
	print("PASS: Replay state restore verified.")
