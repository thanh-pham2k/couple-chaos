extends Node2D

signal rang

@onready var ring_icon: Sprite2D = $RingIcon
@onready var ring_timer: Timer = $RingTimer

func trigger_ring(duration: float = 2.0) -> void:
	ring_icon.visible = true
	ring_timer.start(maxf(duration, 0.01))
	rang.emit()

func _on_ring_timer_timeout() -> void:
	ring_icon.visible = false
