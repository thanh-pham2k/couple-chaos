extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HAZARD_SCENE := preload("res://scenes/hazard.tscn")
const SPOT_SCRIPT := preload("res://scripts/coop/cleaning_spot.gd")
const QuestManager := preload("res://scripts/coop/quest_manager.gd")

func _ready() -> void:
	print("--- RUNNING COOP MILK TEA & HAZARDS TEST ---")
	
	test_boba_hazard_slow_and_clean()
	test_cleaning_spot_slow_and_clean()
	test_no_double_count_quest()
	test_coop_slice_scrub_both()
	
	print("--- ALL COOP MILK TEA & HAZARDS TESTS PASSED! ---")
	get_tree().quit(0)

func test_boba_hazard_slow_and_clean() -> void:
	print("Testing BobaHazard slow effect and scrub cleaning...")
	var hazard := HAZARD_SCENE.instantiate() as FloorHazard
	hazard.hazard_type = "boba_puddle"
	add_child(hazard)
	hazard.position = Vector2(100, 100)
	
	var player := PLAYER_SCENE.instantiate() as Player
	player.player_id = "p1"
	player.character_type = "boy"
	add_child(player)
	player.position = Vector2(100, 100)
	
	# Step 1: stepping on dirty boba puddle slows player
	assert(player.is_slowed == false, "Player should not start slowed")
	hazard._on_body_entered(player)
	assert(player.is_slowed == true, "Stepping on BobaHazard should slow player")
	player.is_slowed = false
	
	# Step 2: scrub without mop fails
	player.held_item_type = ""
	assert(hazard.scrub(player) == false, "Scrub without mop should return false")
	assert(hazard.progress == 0, "Progress should be 0")
	
	# Step 3: scrub with mop
	player.held_item_type = "coop_mop"
	var signal_emitted := [false]
	hazard.cleaned.connect(func(_id, _p): signal_emitted[0] = true)
	
	assert(hazard.scrub(player) == true, "Scrub 1 should succeed")
	assert(hazard.progress == 1, "Progress should be 1")
	assert(hazard.state == "cleaning", "State should be cleaning")
	assert(hazard.feedback.text == "1/3", "Feedback should show 1/3")
	
	assert(hazard.scrub(player) == true, "Scrub 2 should succeed")
	assert(hazard.progress == 2, "Progress should be 2")
	assert(hazard.feedback.text == "2/3", "Feedback should show 2/3")
	
	assert(hazard.scrub(player) == true, "Scrub 3 should succeed")
	assert(hazard.progress == 3, "Progress should be 3")
	assert(hazard.state == "clean", "State should be clean")
	assert(hazard.feedback.text == "✓", "Feedback should show ✓")
	assert(signal_emitted[0] == true, "Cleaned signal should emit on progress 3")
	
	# Step 4: stepping on cleaned boba puddle no longer slows player
	hazard._on_body_entered(player)
	assert(player.is_slowed == false, "Cleaned boba hazard should not slow player")
	
	# Cleanup
	hazard.queue_free()
	player.queue_free()
	print("PASS: BobaHazard slow and clean verified.")

func test_cleaning_spot_slow_and_clean() -> void:
	print("Testing CleaningSpot (milk tea) slow effect and scrub...")
	var spot := SPOT_SCRIPT.new() as CleaningSpot
	spot.target_id = "tea_1"
	spot.decal_path = "res://assets/coop/spill_milk_tea.png"
	add_child(spot)
	spot.position = Vector2(200, 200)
	
	var player := PLAYER_SCENE.instantiate() as Player
	player.player_id = "p2"
	player.character_type = "girl"
	add_child(player)
	player.position = Vector2(200, 200)
	
	# Step 1: stepping on dirty tea spot slows player
	assert(player.is_slowed == false, "Player should start not slowed")
	spot._on_body_entered(player)
	assert(player.is_slowed == true, "Stepping on milk tea CleaningSpot should slow player")
	player.is_slowed = false
	
	# Step 2: scrub 3 times with mop
	player.held_item_type = "coop_mop"
	var signal_emitted := [false]
	spot.cleaned.connect(func(_id, _p): signal_emitted[0] = true)
	
	spot.scrub(player)
	assert(spot.progress == 1, "Spot progress should be 1")
	spot.scrub(player)
	assert(spot.progress == 2, "Spot progress should be 2")
	spot.scrub(player)
	assert(spot.progress == 3, "Spot progress should be 3")
	assert(spot.state == "clean", "Spot state should be clean")
	assert(signal_emitted[0] == true, "Spot cleaned signal should emit")
	
	# Step 3: stepping on cleaned spot does not slow player
	spot._on_body_entered(player)
	assert(player.is_slowed == false, "Cleaned CleaningSpot should not slow player")
	
	# Cleanup
	spot.queue_free()
	player.queue_free()
	print("PASS: CleaningSpot slow and clean verified.")

func test_no_double_count_quest() -> void:
	print("Testing single-counting in quest manager...")
	var quest := QuestManager.new()
	quest.reset()
	
	assert(quest.get_count("clean") == 0, "Initial clean count is 0")
	var res1 = quest.complete_target("clean", "tea_1")
	assert(res1 == true, "First complete_target should succeed")
	assert(quest.get_count("clean") == 1, "Clean count should now be 1")
	
	var res2 = quest.complete_target("clean", "tea_1")
	assert(res2 == false, "Second complete_target for same tea_1 must return false")
	assert(quest.get_count("clean") == 1, "Clean count must NOT increase on duplicate")
	
	quest.queue_free()
	print("PASS: Quest single-counting verified.")

func test_coop_slice_scrub_both() -> void:
	print("Testing CoopSlice try_use cleans both CleaningSpot and FloorHazard...")
	var slice_scene: PackedScene = load("res://scenes/coop_slice.tscn")
	var slice: Node = slice_scene.instantiate()
	add_child(slice)
	
	# Start round
	slice.session.start_round()
	
	var p1: Player = slice.arena.p1
	p1.held_item_type = "coop_mop"
	
	# Test cleaning spot near p1
	var spot = slice.spots[0]
	p1.global_position = spot.global_position
	assert(slice.try_use(p1) == true, "try_use on CleaningSpot should return true")
	assert(spot.progress == 1, "CleaningSpot progress should advance to 1")
	
	# Test cleaning FloorHazard in arena
	var hazard := HAZARD_SCENE.instantiate() as FloorHazard
	hazard.hazard_type = "boba_puddle"
	slice.arena.get_node("YSortArena").add_child(hazard)
	hazard.global_position = Vector2(500, 500)
	p1.global_position = Vector2(500, 500)
	
	assert(slice.try_use(p1) == true, "try_use on FloorHazard should return true")
	assert(hazard.progress == 1, "FloorHazard progress should advance to 1")
	assert(hazard.state == "cleaning", "FloorHazard state should be cleaning")
	
	slice.try_use(p1)
	slice.try_use(p1)
	assert(hazard.progress == 3, "FloorHazard progress should reach 3")
	assert(hazard.state == "clean", "FloorHazard state should reach clean")
	
	slice.queue_free()
	print("PASS: CoopSlice try_use cleans both spot and hazard verified.")
