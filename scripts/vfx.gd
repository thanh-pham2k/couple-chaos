extends Node2D
class_name ComicVFX

@export var vfx_name: String = "feather_burst"
var duration: float = 0.65
var elapsed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var path = "res://assets/vfx/" + vfx_name + ".png"
	if ResourceLoader.exists(path) and sprite:
		sprite.texture = load(path)
	scale = Vector2(0.5, 0.5)

func _process(delta: float) -> void:
	elapsed += delta
	var t = elapsed / duration
	scale = Vector2(0.5, 0.5).lerp(Vector2(1.2, 1.2), t)
	modulate.a = 1.0 - t
	
	if elapsed >= duration:
		queue_free()
