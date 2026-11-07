extends CanvasLayer
class_name GameHUD

@onready var p1_hearts_container: HBoxContainer = $TopHUD/P1Profile/Hearts
@onready var p1_stamina_bar: ProgressBar = $TopHUD/P1Profile/StaminaBar
@onready var p2_hearts_container: HBoxContainer = $TopHUD/P2Profile/Hearts
@onready var p2_stamina_bar: ProgressBar = $TopHUD/P2Profile/StaminaBar

@onready var timer_label: Label = $TopHUD/CenterHUD/TimerLabel
@onready var mission_label: Label = $TopHUD/CenterHUD/MissionLabel
@onready var toast_label: Label = $ToastLabel
@onready var hotbar_container: Control = $BottomHUD/Hotbar

var toast_timer: float = 0.0

func _ready() -> void:
	if toast_label:
		toast_label.text = ""

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and toast_label:
			toast_label.text = ""

func update_hearts(player_id: String, count: int) -> void:
	var container = p1_hearts_container if player_id == "p1" else p2_hearts_container
	if not container:
		return
	var heart_nodes = container.get_children()
	for i in range(heart_nodes.size()):
		if heart_nodes[i] is TextureRect:
			heart_nodes[i].visible = (i < count)

func update_stamina(player_id: String, val: float) -> void:
	var bar = p1_stamina_bar if player_id == "p1" else p2_stamina_bar
	if bar:
		bar.value = val

func update_timer(seconds_left: int) -> void:
	if timer_label:
		var mins = seconds_left / 60
		var secs = seconds_left % 60
		timer_label.text = "⏱️ %02d:%02d" % [mins, secs]
		if seconds_left <= 15:
			timer_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			timer_label.modulate = Color.WHITE

func update_mission(chaos_stars: int, max_stars: int = 5) -> void:
	if mission_label:
		mission_label.text = "📋 Nhiệm vụ: Gây hỗn loạn! ⭐ %d/%d" % [chaos_stars, max_stars]

func show_toast(msg: String) -> void:
	if toast_label:
		toast_label.text = msg
		toast_timer = 2.2
