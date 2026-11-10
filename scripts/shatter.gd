extends Node2D

## Glass shards for a death. Motion uses the scaled delta, so a slow-mo beat stretches it.

var age: float = 0.0
var _shards: Array[Dictionary] = []


func _ready() -> void:
	z_index = 46
	for i in 18:
		var angle := TAU * float(i) / 18.0 + randf_range(-0.25, 0.25)
		var speed := randf_range(90.0, 320.0)
		var tint := Color("fff8ef")
		if i % 3 == 1:
			tint = Color("9fd7ff")
		elif i % 3 == 2:
			tint = Color("ffb34f")
		_shards.append({
			"p": Vector2(randf_range(-8.0, 8.0), randf_range(-18.0, 6.0)),
			"v": Vector2(cos(angle), sin(angle)) * speed + Vector2(0.0, -50.0),
			"s": randf_range(7.0, 18.0),
			"r": randf() * TAU,
			"spin": randf_range(-8.0, 8.0),
			"c": tint,
		})


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.2)
	age += real
	for shard in _shards:
		shard["v"] = shard["v"] + Vector2(0.0, 520.0) * real
		shard["p"] = shard["p"] + shard["v"] * real
		shard["r"] = float(shard["r"]) + float(shard["spin"]) * real
	queue_redraw()
	if age > 0.55:
		queue_free()


func _draw() -> void:
	var fade := clampf(1.0 - age / 0.55, 0.0, 1.0)
	var ring := lerpf(12.0, 86.0, clampf(age / 0.35, 0.0, 1.0))
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 28, Color(1, 1, 1, fade * 0.85), 3.0)
	for shard in _shards:
		var center: Vector2 = shard["p"]
		var half: float = float(shard["s"])
		var rot: float = float(shard["r"])
		var color: Color = shard["c"]
		color.a = fade
		var points := PackedVector2Array()
		for corner in [Vector2(-half, -half * 0.35), Vector2(half * 0.8, -half * 0.15), Vector2(half * 0.15, half * 0.7)]:
			points.append(center + corner.rotated(rot))
		draw_colored_polygon(points, color)
