extends Node2D

var text: String = ""
var age: float = 0.0
var life: float = 0.72


func setup(value: String) -> void:
	text = value
	z_index = 30


func _process(delta: float) -> void:
	age += delta
	position.y -= 52.0 * delta
	modulate.a = clampf(1.0 - age / life, 0.0, 1.0)
	queue_redraw()
	if age >= life:
		queue_free()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size := 34
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(-width * 0.5, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 8, Color(0.02, 0.01, 0.05, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("ffd275"))
