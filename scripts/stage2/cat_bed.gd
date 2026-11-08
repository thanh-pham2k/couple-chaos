extends Node2D

signal cat_return_requested(home_position: Vector2)

@onready var home_marker: Marker2D = $HomeMarker

# The future Stage 2 controller decides how the cat travels to this point.
func request_cat_return() -> void:
	cat_return_requested.emit(home_marker.global_position)
