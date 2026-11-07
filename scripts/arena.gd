extends Node2D

@onready var p1: Player = $YSortArena/Player1
@onready var p2: Player = $YSortArena/Player2
@onready var hud: GameHUD = $HUD
@onready var touch_controls: TouchControls = $TouchControlsLayer/TouchControls

var match_time_left: float = 138.0 # 02:18 countdown as in reference screenshot
var chaos_score: int = 3 # ⭐ 3/5 initial
const MAX_CHAOS_STARS: int = 5

# Keep landed pickups inside the walkable side of the four arena walls.
@export var pickup_bounds: Rect2 = Rect2(110, 280, 1700, 720)

func get_pickup_bounds() -> Rect2:
	return Rect2(to_global(pickup_bounds.position), pickup_bounds.size)

func _ready() -> void:
	# Link touch controls to P1
	if touch_controls:
		touch_controls.target_player = p1

	# Connect Player signals to HUD
	if p1:
		p1.hearts_changed.connect(_on_player_hearts_changed)
		p1.stamina_changed.connect(_on_player_stamina_changed)
		p1.chaos_event.connect(_on_chaos_event)
	if p2:
		p2.hearts_changed.connect(_on_player_hearts_changed)
		p2.stamina_changed.connect(_on_player_stamina_changed)
		p2.chaos_event.connect(_on_chaos_event)

	# Initial HUD update
	if hud:
		hud.update_hearts("p1", p1.hearts if p1 else 4)
		hud.update_hearts("p2", p2.hearts if p2 else 4)
		hud.update_stamina("p1", p1.stamina if p1 else 100.0)
		hud.update_stamina("p2", p2.stamina if p2 else 100.0)
		hud.update_timer(int(match_time_left))
		hud.update_mission(chaos_score, MAX_CHAOS_STARS)
		hud.show_toast("Couple Chaos — Trận chiến bắt đầu!")

func _process(delta: float) -> void:
	if match_time_left > 0.0:
		match_time_left -= delta
		if hud:
			hud.update_timer(int(match_time_left))
		if match_time_left <= 0.0:
			end_match()

func _on_player_hearts_changed(pid: String, h: int) -> void:
	if hud:
		hud.update_hearts(pid, h)
	if h <= 0:
		var loser = "Bạn Trai P1" if pid == "p1" else "Bạn Gái P2"
		var winner = "Bạn Gái P2" if pid == "p1" else "Bạn Trai P1"
		if hud:
			hud.show_toast(loser + " đã cạn máu! " + winner + " CHIẾN THẮNG! 🏆")

func _on_player_stamina_changed(pid: String, s: float) -> void:
	if hud:
		hud.update_stamina(pid, s)

func _on_chaos_event(desc: String) -> void:
	if hud:
		hud.show_toast(desc)
	chaos_score = min(MAX_CHAOS_STARS, chaos_score + 1)
	if hud:
		hud.update_mission(chaos_score, MAX_CHAOS_STARS)

func end_match() -> void:
	if hud:
		hud.show_toast("HẾT GIỜ! Hỗn loạn đạt " + str(chaos_score) + "/5 ⭐!")
