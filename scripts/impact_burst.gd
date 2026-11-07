extends Node2D

var age: float = 0.0
var life: float = 0.28


func _ready() -> void:
	z_index = 28


func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= life:
		queue_free()


func _draw() -> void:
	var t := clampf(age / life, 0.0, 1.0)
	var fade := 1.0 - t
	draw_arc(Vector2.ZERO, lerpf(10.0, 62.0, t), 0, TAU, 28, Color(1, 0.96, 0.9, fade), lerpf(7.0, 1.5, t))
	draw_line(Vector2(-36, -8) * (0.45 + t), Vector2(48, 10) * (0.45 + t), Color(1, 0.35, 0.22, fade), 5.0)
	draw_circle(Vector2.ZERO, lerpf(16.0, 4.0, t), Color(1, 1, 1, fade * 0.85))
