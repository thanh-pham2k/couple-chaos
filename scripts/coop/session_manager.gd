extends Node
class_name CoopSessionManager

signal started
signal ended(won: bool)
signal time_changed(seconds: float)
const ROUND_SECONDS := 300.0
var timer := ROUND_SECONDS
var running := false
var ended_once := false

func start_round() -> void:
	if running or ended_once:
		return
	running = true
	started.emit()
	time_changed.emit(timer)

func reset() -> void:
	timer = ROUND_SECONDS
	running = false
	ended_once = false
	time_changed.emit(timer)

func finish(won: bool) -> void:
	if not running or ended_once:
		return
	running = false
	ended_once = true
	ended.emit(won)

func _process(delta: float) -> void:
	if not running:
		return
	timer = maxf(0.0, timer - delta)
	time_changed.emit(timer)
	if timer <= 0.0:
		finish(false)
