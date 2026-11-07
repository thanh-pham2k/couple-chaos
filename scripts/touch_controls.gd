extends Control
class_name TouchControls

@export var target_player_path: NodePath
var target_player: Player = null

@onready var joystick_base: TextureRect = $JoystickBase
@onready var joystick_stick: TextureRect = $JoystickBase/JoystickStick
@onready var btn_hammer: TextureButton = $ButtonsContainer/BtnHammer
@onready var btn_dash: TextureButton = $ButtonsContainer/BtnDash
@onready var btn_grab: TextureButton = $ButtonsContainer/BtnGrab

var joystick_active: bool = false
var joystick_touch_id: int = -1
var joystick_radius: float = 75.0
var joystick_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	if has_node(target_player_path):
		target_player = get_node(target_player_path) as Player

	if btn_hammer:
		btn_hammer.pressed.connect(_on_hammer_pressed)
	if btn_dash:
		btn_dash.pressed.connect(_on_dash_pressed)
	if btn_grab:
		btn_grab.pressed.connect(_on_grab_pressed)

	if joystick_base:
		joystick_center = joystick_base.size / 2.0
		reset_stick()

func _input(event: InputEvent) -> void:
	if not joystick_base or not joystick_stick:
		return

	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		var touch_pos = event.position
		var base_global_rect = joystick_base.get_global_rect()

		if event.is_pressed():
			if base_global_rect.has_point(touch_pos):
				joystick_active = true
				if "index" in event:
					joystick_touch_id = event.index
				update_joystick(touch_pos)
		else:
			if "index" in event:
				if event.index == joystick_touch_id:
					release_joystick()
			else:
				release_joystick()

	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and joystick_active):
		if "index" in event and event.index != joystick_touch_id:
			return
		if joystick_active:
			update_joystick(event.position)

func update_joystick(touch_pos: Vector2) -> void:
	var base_global_center = joystick_base.global_position + joystick_center
	var diff = touch_pos - base_global_center
	var dist = diff.length()
	var dir = diff.normalized()

	var clamped_dist = min(dist, joystick_radius)
	var stick_offset = dir * clamped_dist

	joystick_stick.position = (joystick_center - joystick_stick.size / 2.0) + stick_offset

	var strength = clamped_dist / joystick_radius
	var move_vector = dir * strength

	if target_player:
		target_player.touch_vector = move_vector

func release_joystick() -> void:
	joystick_active = false
	joystick_touch_id = -1
	reset_stick()
	if target_player:
		target_player.touch_vector = Vector2.ZERO

func reset_stick() -> void:
	if joystick_stick:
		joystick_stick.position = joystick_center - joystick_stick.size / 2.0

func _on_hammer_pressed() -> void:
	if target_player:
		target_player.trigger_attack()

func _on_dash_pressed() -> void:
	if target_player:
		target_player.trigger_dash()

func _on_grab_pressed() -> void:
	if target_player:
		target_player.trigger_grab()
