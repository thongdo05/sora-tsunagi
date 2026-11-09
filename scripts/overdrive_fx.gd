extends Node2D

## Overdrive aura. Strokes only: red and black lightning plus speed lines.
## Nothing is filled in, so the black never reads as a coat of armor.

var active: bool = false


func _process(_delta: float) -> void:
	visible = active
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_msec() / 40)
	# Speed lines trail behind the lunge. Thin, unfilled.
	for i in 9:
		var y := rng.randf_range(-168.0, -28.0)
		var x1 := rng.randf_range(-420.0, -180.0)
		var x0 := x1 + rng.randf_range(70.0, 180.0)
		var hot := i % 3 != 0
		var color := Color(1.0, 0.28, 0.16, 0.55) if hot else Color(0.08, 0.02, 0.03, 0.7)
		draw_line(Vector2(x0, y), Vector2(x1, y), color, 1.6 if hot else 1.2)
	# Lightning around the body, never a silhouette.
	var body := Vector2(36.0, -108.0)
	for i in 5:
		var points := PackedVector2Array()
		var along := 0.0
		var reach := rng.randf_range(70.0, 130.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		points.append(body + Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-50.0, 40.0)))
		while along < reach:
			along += rng.randf_range(16.0, 34.0)
			var outward := side * rng.randf_range(18.0, 52.0)
			points.append(body + Vector2(along * 0.85 + outward * 0.25, -along * 0.35 + outward))
		# Strokes only. Half the bolts are red with a black core, half are black with a red edge.
		# Nothing is filled, so the black never reads as armor.
		if i % 2 == 0:
			draw_polyline(points, Color(1.0, 0.18, 0.08, 0.88), 3.2, true)
			draw_polyline(points, Color(0.05, 0.01, 0.02, 0.95), 1.3, true)
		else:
			draw_polyline(points, Color(1.0, 0.22, 0.1, 0.7), 4.0, true)
			draw_polyline(points, Color(0.04, 0.008, 0.015, 0.96), 2.4, true)
