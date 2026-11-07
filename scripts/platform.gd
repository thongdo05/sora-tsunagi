class_name GlassPlatform
extends StaticBody2D

var width: float = 480.0
var thickness: float = 58.0


func setup(platform_width: float, platform_thickness: float) -> void:
	width = platform_width
	thickness = platform_thickness
	collision_layer = 1
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 42)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(width * 0.5, 16)
	collision.one_way_collision = true
	collision.one_way_collision_margin = 10.0
	add_child(collision)
	queue_redraw()


func _draw() -> void:
	var lip := PackedVector2Array([
		Vector2(0, 16),
		Vector2(22, 3),
		Vector2(width - 26, 4),
		Vector2(width, 15),
		Vector2(width - 6, 16),
		Vector2(8, 16),
	])
	var body := PackedVector2Array([
		Vector2(6, 14),
		Vector2(width - 6, 14),
		Vector2(width - 14, thickness),
		Vector2(16, thickness - 2),
	])
	draw_colored_polygon(body, Color("2a3144"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(10, thickness - 16),
		Vector2(width - 12, thickness - 14),
		Vector2(width - 16, thickness),
		Vector2(18, thickness - 2),
	]), Color(0.05, 0.05, 0.08, 0.55))
	draw_colored_polygon(lip, Color("e0a15c"))
	draw_line(Vector2(28, 8), Vector2(width - 34, 9), Color("ffe0b0"), 2.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(hash(Vector2i(int(position.x), int(position.y)))))
	var cracks := 3 + int(width / 280.0)
	for _i in cracks:
		var start := Vector2(rng.randf_range(20, width - 20), rng.randf_range(18, thickness - 12))
		var ending := start + Vector2(rng.randf_range(-36, 36), rng.randf_range(8, 20))
		draw_line(start, ending, Color(0.07, 0.05, 0.1, 0.75), 2.0)
	var specks := 2 + int(width / 400.0)
	for _j in specks:
		var at := Vector2(rng.randf_range(30, width - 30), rng.randf_range(20, 34))
		draw_circle(at, rng.randf_range(1.5, 3.0), Color(0.35, 0.85, 0.82, 0.55))
