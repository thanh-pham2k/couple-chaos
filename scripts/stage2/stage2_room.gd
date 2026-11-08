extends Node2D

signal doorbell_rang
signal visitor_approaching
signal cat_return_requested(home_position: Vector2)

@onready var cat_bed: Node2D = $Arena/YSortArena/CatBed
@onready var doorbell: Node2D = $Arena/YSortArena/Doorbell
@onready var visitor_alert: Sprite2D = $UI/VisitorAlert
@onready var visitor_timer: Timer = $VisitorTimer

func _ready() -> void:
	# This is a Stage 2 integration surface, not a Party Battle round.
	$Arena.set_process(false)
	doorbell.rang.connect(func() -> void: doorbell_rang.emit())
	cat_bed.cat_return_requested.connect(func(pos: Vector2) -> void: cat_return_requested.emit(pos))

func ring_doorbell(duration: float = 2.0) -> void:
	doorbell.trigger_ring(duration)

func notify_visitor_approaching(duration: float = 2.0) -> void:
	visitor_alert.visible = true
	visitor_timer.start(maxf(duration, 0.01))
	visitor_approaching.emit()

func request_cat_return() -> void:
	cat_bed.request_cat_return()

func _on_visitor_timer_timeout() -> void:
	visitor_alert.visible = false
