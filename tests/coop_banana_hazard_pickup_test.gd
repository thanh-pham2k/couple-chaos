extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const SLICE_SCENE := preload("res://scenes/coop_slice.tscn")

func _ready() -> void:
	print("--- RUNNING COOP BANANA HAZARD PICKUP TEST ---")
	
	test_pickup_banana_hazard()
	test_deposit_banana_into_trash()
	test_dynamic_chaos_banana_hazard()
	test_slip_still_works_when_not_picking_up()
	
	print("--- ALL COOP BANANA HAZARD PICKUP TESTS PASSED! ---")
	get_tree().quit(0)

func test_pickup_banana_hazard() -> void:
	print("Testing pickup banana hazard from floor...")
	var hazard := HAZARD_SCENE.instantiate() as FloorHazard
	hazard.hazard_type = "banana_peel"
	add_child(hazard)
	hazard.global_position = Vector2(400, 400)
	
	var player := PLAYER_SCENE.instantiate() as Player
	player.player_id = "p1"
	player.character_type = "boy"
	add_child(player)
	player.global_position = Vector2(460, 400) # 60px away (within 120px pickup reach)
	
	assert(player.held_item_type == "", "Player should start empty handed")
	assert(player.is_slipping == false, "Player should not be slipping")
	assert(hazard.can_be_picked_up() == true, "Banana hazard should be pickable")
	
	player.trigger_grab()
	
	assert(player.held_item_type == "banana", "Player should now hold 'banana'")
	assert(hazard.is_queued_for_deletion() == true, "Hazard should be queued for deletion")
	assert(player.is_slipping == false, "Player should not slip when picking up")
	
	hazard.queue_free()
	player.queue_free()
	print("PASS: Banana hazard pickup verified.")

func test_deposit_banana_into_trash() -> void:
	print("Testing depositing picked banana into trash bin...")
	var slice: Node = SLICE_SCENE.instantiate()
	add_child(slice)
	slice.session.start_round()
	
	var p1: Player = slice.arena.p1
	var trash_zone: CoopDropZone = null
	for zone in slice.zones:
		if zone.target_id == "trash":
			trash_zone = zone
			break
	assert(trash_zone != null, "Trash zone must exist")
	
	# Give player a banana (as if picked up from floor)
	p1.pick_up("banana")
	assert(p1.held_item_type == "banana")
	assert(trash_zone.can_accept("banana") == true, "Trash zone must accept banana")
	
	p1.global_position = trash_zone.global_position + Vector2(20, 20)
	
	var stored_signal := [false]
	trash_zone.stored_extra.connect(func(id, _p):
		if id == "banana":
			stored_signal[0] = true
	)
	
	assert(slice.try_interact(p1) == true, "try_interact should begin trash placement")
	assert(p1.is_placing == true, "Player should enter placing state")
	
	# Simulate physics process until placed
	for i in range(25):
		slice._physics_process(0.016)
	
	assert(p1.held_item_type == "", "Player should be empty handed after trash placement")
	assert(stored_signal[0] == true, "stored_extra signal must emit for banana")
	
	slice.queue_free()
	print("PASS: Banana deposit into trash verified.")

func test_dynamic_chaos_banana_hazard() -> void:
	print("Testing picking up dynamically spawned chaos banana...")
	var slice: Node = SLICE_SCENE.instantiate()
	add_child(slice)
	slice.session.start_round()
	
	var p2: Player = slice.arena.p2
	
	# Simulate random chaos banana spawn during round
	var dynamic_hazard := HAZARD_SCENE.instantiate() as FloorHazard
	dynamic_hazard.hazard_type = "banana_peel"
	slice.arena.get_node("YSortArena").add_child(dynamic_hazard)
	dynamic_hazard.global_position = Vector2(1000, 700)
	
	p2.global_position = Vector2(1035, 700) # 35px away, safely away from remote (860, 620)
	assert(p2.held_item_type == "")
	
	p2.trigger_grab()
	
	assert(p2.held_item_type == "banana", "P2 should pick up dynamic chaos banana")
	assert(dynamic_hazard.is_queued_for_deletion() == true, "Dynamic hazard should be queued for deletion")
	
	slice.queue_free()
	print("PASS: Dynamic chaos banana pickup verified.")

func test_slip_still_works_when_not_picking_up() -> void:
	print("Testing walking onto banana still causes slip...")
	var hazard := HAZARD_SCENE.instantiate() as FloorHazard
	hazard.hazard_type = "banana_peel"
	add_child(hazard)
	hazard.global_position = Vector2(300, 300)
	
	var player := PLAYER_SCENE.instantiate() as Player
	player.player_id = "p1"
	player.character_type = "boy"
	add_child(player)
	player.global_position = Vector2(300, 300)
	player.velocity = Vector2.RIGHT * 100.0
	
	# Walking onto it triggers body_entered
	hazard._on_body_entered(player)
	assert(player.is_slipping == true, "Stepping directly on banana must trigger slip")
	
	hazard.queue_free()
	player.queue_free()
	print("PASS: Natural hazard slip behavior preserved.")
