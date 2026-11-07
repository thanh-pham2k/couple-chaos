extends Node2D

const ARENA_SCENE := preload("res://scenes/arena.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BedInteraction := preload("res://scripts/bed_interaction.gd")

func _ready() -> void:
	print("--- STARTING TWO-PLAYER BED & FURNITURE QA TEST ---")
	
	test_furniture_layout_and_nodes()
	test_boy_sleep_cycle()
	test_girl_sleep_cycle()
	test_two_player_simultaneous_sleep()
	test_sleep_with_held_item()
	test_key_press_wake_up()
	test_bed_reset_on_replay()
	
	print(">>> ALL TWO-PLAYER BED & FURNITURE QA TESTS PASSED! 100% VERIFIED <<<")
	get_tree().quit(0)

func test_furniture_layout_and_nodes() -> void:
	print("1. Testing Coffee Table and Dining Set nodes and layout...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	
	# Verify Coffee Table
	var table: StaticBody2D = world.get_node_or_null("CoffeeTable")
	assert(table != null, "CoffeeTable node must exist")
	var sofa: StaticBody2D = world.get_node_or_null("Sofa")
	assert(sofa != null, "Sofa node must exist")
	assert(is_equal_approx(table.position.x, sofa.position.x), "Coffee table must be aligned horizontally with sofa (X=620)")
	assert(table.position.y < sofa.position.y, "Coffee table must sit north/in front of sofa")
	var table_sprite: Sprite2D = table.get_node("Sprite2D")
	assert(table_sprite.texture != null and table_sprite.texture.resource_path.contains("coffee_table_front"), "Coffee table must use front-facing texture")
	var table_col: CollisionShape2D = table.get_node("CollisionShape2D")
	assert(table_col.shape is RectangleShape2D, "Coffee table must have valid collision")
	
	# Verify Dining Set (3 independent nodes)
	var d_table: StaticBody2D = world.get_node_or_null("DiningSet")
	assert(d_table != null, "DiningTable (DiningSet) must exist")
	var d_chair_l: StaticBody2D = world.get_node_or_null("DiningChairLeft")
	assert(d_chair_l != null, "DiningChairLeft must exist as independent node")
	var d_chair_r: StaticBody2D = world.get_node_or_null("DiningChairRight")
	assert(d_chair_r != null, "DiningChairRight must exist as independent node")
	
	var dt_sprite: Sprite2D = d_table.get_node("Sprite2D")
	assert(dt_sprite.texture.resource_path.contains("dining_table"), "Dining table must use dining_table.png")
	var cl_sprite: Sprite2D = d_chair_l.get_node("Sprite2D")
	assert(cl_sprite.texture.resource_path.contains("dining_chair_left"), "Left chair must use dining_chair_left.png")
	var cr_sprite: Sprite2D = d_chair_r.get_node("Sprite2D")
	assert(cr_sprite.texture.resource_path.contains("dining_chair_right"), "Right chair must use dining_chair_right.png")
	
	assert(d_chair_l.position.x < d_table.position.x, "Left chair must be positioned to the left of table")
	assert(d_chair_r.position.x > d_table.position.x, "Right chair must be positioned to the right of table")
	
	arena.free()
	print("PASS: Coffee Table and Dining Set independent nodes verified.")

func test_boy_sleep_cycle() -> void:
	print("2. Testing Boy sleep cycle (entering -> sleeping -> waking)...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var bed: BedInteraction = world.get_node("Bed") as BedInteraction
	assert(bed != null, "Bed must have BedInteraction script")
	
	var boy: Player = world.get_node("Player1")
	assert(boy.character_type == "boy")
	
	# Position near bed
	boy.global_position = bed.global_position + Vector2(0, 50)
	
	var entered_emitted := [false]
	var slept_emitted := [false]
	var woke_emitted := [false]
	var left_emitted := [false]
	
	bed.player_entered_bed.connect(func(_p, _s): entered_emitted[0] = true)
	bed.player_slept.connect(func(_p, _s): slept_emitted[0] = true)
	bed.player_woke_up.connect(func(_p, _s): woke_emitted[0] = true)
	bed.player_left_bed.connect(func(_p, _s): left_emitted[0] = true)
	
	# Enter bed
	assert(bed.enter_bed(boy) == true, "Boy should enter bed successfully")
	assert(boy.is_sleeping == true, "Boy must have is_sleeping == true")
	assert(boy.visible == false, "Player sprite on floor must be hidden while in bed")
	assert(bed.boy_sprite.visible == true, "BoyBedSprite on bed must be visible")
	assert(bed.boy_sprite.frame == 0, "Initial pose must be 0 (sit)")
	assert(entered_emitted[0] == true, "player_entered_bed signal should emit")
	
	# Progress animation steps
	# Step 1: lean
	bed._update_sleeping_players(0.25)
	assert(bed.boy_sprite.frame == 1, "Frame should advance to 1 (lean)")
	
	# Step 2: lie_down
	bed._update_sleeping_players(0.25)
	assert(bed.boy_sprite.frame == 2, "Frame should advance to 2 (lie_down)")
	
	# Step 3: sleep
	bed._update_sleeping_players(0.25)
	assert(bed.boy_sprite.frame == 3, "Frame should advance to 3 (sleep)")
	assert(slept_emitted[0] == true, "player_slept signal should emit")
	assert(bed.sleeping_players[boy]["state"] == "sleeping")
	
	# Test breathing variation
	bed._update_sleeping_players(1.2)
	assert(bed.boy_sprite.frame == 4, "Frame should alternate to 4 (sleep_breathe)")
	bed._update_sleeping_players(1.2)
	assert(bed.boy_sprite.frame == 3, "Frame should return to 3 (sleep)")
	
	# Movement restriction check
	boy.trigger_dash()
	assert(boy.is_dashing == false, "Boy cannot dash while sleeping")
	boy.trigger_attack()
	assert(boy.is_attacking == false, "Boy cannot attack while sleeping")
	
	# Wake up
	assert(bed.wake_up(boy) == true, "Wake up should initiate")
	assert(woke_emitted[0] == true, "player_woke_up signal should emit")
	assert(bed.boy_sprite.frame == 5, "Frame should be 5 (wake_up)")
	
	# Progress waking steps
	bed._update_sleeping_players(0.26)
	assert(bed.boy_sprite.frame == 0, "Frame should transition through 0 (sit)")
	
	bed._update_sleeping_players(0.26)
	assert(boy.is_sleeping == false, "Boy must no longer be sleeping")
	assert(boy.visible == true, "Boy floor sprite must be restored")
	assert(bed.boy_sprite.visible == false, "BoyBedSprite must be hidden after leaving bed")
	assert(left_emitted[0] == true, "player_left_bed signal should emit")
	
	arena.free()
	print("PASS: Boy complete sleep cycle verified.")

func test_girl_sleep_cycle() -> void:
	print("3. Testing Girl sleep cycle...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var bed: BedInteraction = world.get_node("Bed") as BedInteraction
	var girl: Player = world.get_node("Player2")
	assert(girl.character_type == "girl")
	
	girl.global_position = bed.global_position + Vector2(0, 50)
	
	assert(bed.enter_bed(girl) == true)
	assert(bed.sleeping_players[girl]["slot"] == "girl", "Girl must occupy right slot")
	assert(bed.girl_sprite.visible == true, "GirlBedSprite must be visible")
	
	# Advance to sleeping state
	for i in range(3):
		bed._update_sleeping_players(0.25)
	assert(bed.girl_sprite.frame == 3)
	
	# Wake up
	bed.wake_up(girl)
	for i in range(2):
		bed._update_sleeping_players(0.26)
	assert(girl.is_sleeping == false)
	assert(bed.girl_sprite.visible == false)
	
	arena.free()
	print("PASS: Girl complete sleep cycle verified.")

func test_two_player_simultaneous_sleep() -> void:
	print("4. Testing simultaneous sleep of both Boy and Girl...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var bed: BedInteraction = world.get_node("Bed") as BedInteraction
	var p1: Player = world.get_node("Player1")
	var p2: Player = world.get_node("Player2")
	
	# Both enter bed
	assert(bed.enter_bed(p1) == true, "P1 enters bed")
	assert(bed.enter_bed(p2) == true, "P2 enters bed simultaneously")
	
	assert(bed.sleeping_players.size() == 2, "Both players must be registered sleeping")
	assert(bed.boy_sprite.visible == true and bed.girl_sprite.visible == true, "Both bed sprites must be visible")
	assert(bed.blanket_overlay.visible == true, "Blanket overlay must be visible covering both")
	assert(bed.blanket_overlay.z_index > bed.boy_sprite.z_index, "Blanket must render above sleeping characters")
	
	# Advance both to deep sleep
	for i in range(3):
		bed._update_sleeping_players(0.25)
	assert(bed.boy_sprite.frame == 3 and bed.girl_sprite.frame == 3)
	
	# P1 wakes up first while P2 continues sleeping
	bed.wake_up(p1)
	for i in range(2):
		bed._update_sleeping_players(0.26)
	
	assert(p1.is_sleeping == false, "P1 should be awake on floor")
	assert(p2.is_sleeping == true, "P2 must remain sleeping independently")
	assert(bed.boy_sprite.visible == false, "Boy sprite hidden")
	assert(bed.girl_sprite.visible == true, "Girl sprite still active")
	
	# P2 now wakes up
	bed.wake_up(p2)
	for i in range(2):
		bed._update_sleeping_players(0.26)
	assert(p2.is_sleeping == false, "P2 now also awake")
	assert(bed.girl_sprite.visible == false)
	assert(bed.sleeping_players.is_empty(), "Bed is now completely empty")
	
	arena.free()
	print("PASS: Simultaneous independent sleep verified.")

func test_sleep_with_held_item() -> void:
	print("5. Testing entering bed while holding an item...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var bed: BedInteraction = world.get_node("Bed") as BedInteraction
	var boy: Player = world.get_node("Player1")
	
	# Give item to boy
	boy.pick_up("pillow")
	assert(boy.held_item_type == "pillow")
	assert(boy.held_item_sprite.visible == true)
	
	# Enter bed
	assert(bed.enter_bed(boy) == true)
	assert(boy.held_item_sprite.visible == false, "Held item must be hidden while sleeping")
	
	# Advance and wake up
	for i in range(3):
		bed._update_sleeping_players(0.25)
	bed.wake_up(boy)
	for i in range(2):
		bed._update_sleeping_players(0.26)
		
	assert(boy.is_sleeping == false)
	assert(boy.held_item_type == "pillow", "Item must still be retained")
	assert(boy.held_item_sprite.visible == true, "Held item sprite must be restored after waking")
	
	arena.free()
	print("PASS: Sleep with held item verified.")

func test_key_press_wake_up() -> void:
	print("6. Testing physical key press (E / J) wakes up player from bed...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var bed: BedInteraction = world.get_node("Bed") as BedInteraction
	var p1: Player = world.get_node("Player1")
	var p2: Player = world.get_node("Player2")
	
	# P1 enters bed
	assert(bed.enter_bed(p1) == true)
	for i in range(3):
		bed._update_sleeping_players(0.25)
	assert(p1.is_sleeping == true)
	assert(bed.sleeping_players[p1]["state"] == "sleeping")
	
	# Simulate pressing E key
	var ev_e := InputEventKey.new()
	ev_e.physical_keycode = KEY_E
	ev_e.keycode = KEY_E
	ev_e.pressed = true
	p1._unhandled_input(ev_e)
	
	assert(bed.sleeping_players[p1]["state"] == "waking", "Pressing E must transition sleeping player into 'waking'")
	for i in range(2):
		bed._update_sleeping_players(0.26)
	assert(p1.is_sleeping == false, "P1 must wake up onto floor after E press")
	
	# P2 enters bed and wakes up with J key
	assert(bed.enter_bed(p2) == true)
	for i in range(3):
		bed._update_sleeping_players(0.25)
	assert(p2.is_sleeping == true)
	
	var ev_j := InputEventKey.new()
	ev_j.physical_keycode = KEY_J
	ev_j.keycode = KEY_J
	ev_j.pressed = true
	p2._unhandled_input(ev_j)
	
	assert(bed.sleeping_players[p2]["state"] == "waking", "Pressing J must transition sleeping player into 'waking'")
	for i in range(2):
		bed._update_sleeping_players(0.26)
	assert(p2.is_sleeping == false, "P2 must wake up onto floor after J press")
	
	arena.free()
	print("PASS: Key press (E / J) wake up verified.")

func test_bed_reset_on_replay() -> void:
	print("6. Testing bed reset safety on replay...")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
	var world: Node2D = arena.get_node("YSortArena")
	var bed: BedInteraction = world.get_node("Bed") as BedInteraction
	var p1: Player = world.get_node("Player1")
	
	bed.enter_bed(p1)
	assert(bed.sleeping_players.has(p1))
	
	# Call reset
	bed.reset()
	assert(bed.sleeping_players.is_empty(), "Sleeping players dictionary must be cleared")
	assert(p1.is_sleeping == false, "Player must not remain trapped in sleeping state")
	assert(p1.visible == true, "Player sprite must be visible")
	assert(bed.boy_sprite.visible == false and bed.girl_sprite.visible == false)
	
	arena.free()
	print("PASS: Bed reset verified.")
