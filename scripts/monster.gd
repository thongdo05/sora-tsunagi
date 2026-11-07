class_name GlassMonster
extends Area2D

const TUNING := preload("res://assets/tuning/game_tuning.tres")

enum Phase { WAIT, TELEGRAPH, LIVE }

var flyer: bool = false
var phase: int = Phase.WAIT
var telegraph_left: float = 0.0
var _dead: bool = false
var _collision: CollisionShape2D


func setup(is_flyer: bool) -> void:
	flyer = is_flyer
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = false
	add_to_group("monster")
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	if flyer:
		shape.size = Vector2(64, 46)
		_collision.position = Vector2(0, 0)
	else:
		shape.size = Vector2(78, 46)
		_collision.position = Vector2(-2, -24)
	_collision.shape = shape
	add_child(_collision)
	visible = false


func can_be_hit() -> bool:
	return phase == Phase.LIVE and not _dead


func center() -> Vector2:
	if _collision:
		return global_position + _collision.position
	return global_position


func shatter() -> void:
	if _dead:
		return
	_dead = true
	phase = Phase.LIVE
	monitorable = false
	monitoring = false
	visible = false
	queue_free()


func _physics_process(delta: float) -> void:
	match phase:
		Phase.WAIT:
			var root: Variant = get_tree().get_first_node_in_group("run")
			var runner: Variant = get_tree().get_first_node_in_group("player")
			if root == null or runner == null:
				return
			if not bool(root.call("is_live")):
				return
			var speed: float = max(float(root.get("run_speed")), TUNING.run_speed_start)
			var lead: float = speed * TUNING.telegraph_time + TUNING.telegraph_extra_px
			if global_position.x - runner.global_position.x < lead:
				_begin_telegraph()
		Phase.TELEGRAPH:
			telegraph_left -= delta
			queue_redraw()
			if telegraph_left <= 0.0:
				phase = Phase.LIVE
				monitorable = true
				monitoring = true
				visible = true
		Phase.LIVE:
			queue_redraw()


func _begin_telegraph() -> void:
	phase = Phase.TELEGRAPH
	telegraph_left = TUNING.telegraph_time
	visible = true
	var nodes := get_tree().get_nodes_in_group("audio")
	if nodes.size() > 0:
		nodes[0].call("play", "warning", 0.0, -2.0)


func _draw() -> void:
	if phase == Phase.TELEGRAPH:
		_draw_tear()
		return
	if phase != Phase.LIVE or _dead:
		return
	var bob := sin(float(Time.get_ticks_msec()) * 0.008) * (5.0 if flyer else 1.6)
	draw_set_transform(Vector2(0, bob), 0, Vector2.ONE)
	if flyer:
		_draw_flyer()
	else:
		_draw_hound()


func _draw_tear() -> void:
	var pulse := 0.65 + 0.35 * sin(float(Time.get_ticks_msec()) * 0.02)
	var height := 168.0 if flyer else 150.0
	var origin := Vector2(0, -height + 8.0)
	draw_rect(Rect2(origin + Vector2(-5, 0), Vector2(10, height)), Color(0.07, 0.03, 0.12, 0.94))
	draw_rect(Rect2(origin + Vector2(-11, -6), Vector2(4, height + 12)), Color(0.71, 0.36, 1.0, 0.85 * pulse))
	draw_rect(Rect2(origin + Vector2(7, -6), Vector2(4, height + 12)), Color(0.65, 0.95, 1.0, 0.8 * pulse))
	draw_circle(origin + Vector2(0, 18.0), 7.0 * pulse, Color(0.95, 0.55, 0.8, 0.9))


func _draw_hound() -> void:
	_ellipse(Vector2(-2, 2), 30, 7, Color(0, 0, 0, 0.35))
	draw_rect(Rect2(-28, -16, 7, 16), Color("0b2422"))
	draw_rect(Rect2(-10, -14, 7, 14), Color("0b2422"))
	draw_rect(Rect2(6, -14, 7, 14), Color("0b2422"))
	draw_rect(Rect2(20, -12, 6, 12), Color("0b2422"))
	_ellipse(Vector2(-2, -26), 34, 16, Color("123832"))
	_ellipse(Vector2(-4, -30), 22, 8, Color("1d6a58"))
	draw_circle(Vector2(-30, -30), 12, Color("143f38"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -40), Vector2(20, -58), Vector2(26, -36),
	]), Color("7dffe0"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -38), Vector2(2, -52), Vector2(8, -34),
	]), Color("1ea37a"))
	draw_circle(Vector2(-36, -32), 2.6, Color("ffe08a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(18, -50), Vector2(23, -44), Vector2(16, -44),
	]), Color("f34f93"))


func _draw_flyer() -> void:
	_ellipse(Vector2(0, 10), 18, 5, Color(0, 0, 0, 0.28))
	_ellipse(Vector2(0, 0), 22, 14, Color("102e36"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -8), Vector2(0, -36), Vector2(8, -6),
	]), Color("7dffe0"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, -4), Vector2(22, -22), Vector2(16, 2),
	]), Color("1ea37a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -2), Vector2(-28, -18), Vector2(-8, -4),
	]), Color("3ecfb0"))
	draw_circle(Vector2(-6, -2), 2.4, Color("ffe08a"))
	draw_circle(Vector2(4, -1), 2.4, Color("ffe08a"))


func _ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 14
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)
