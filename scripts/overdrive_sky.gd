extends Node2D

## Sky flash for the Overdrive punch. Drawn over the parallax and behind
## platforms, the player, and the shards. Darken, a few held bolts, and a
## short red flash on the impact frame. No white strobe.

const TUNING := preload("res://assets/tuning/game_tuning.tres")

var camera: Camera2D
var active: bool = false
var strike: bool = false

var _bolts: Array = []
var _bolt_at: int = -10000


func set_overdrive(on: bool, impact: bool) -> void:
	active = on
	strike = impact
	if not on:
		_bolts.clear()
	queue_redraw()


func _process(_delta: float) -> void:
	if camera != null:
		global_position = camera.global_position + camera.offset
	if not active:
		return
	var now := Time.get_ticks_msec()
	if now - _bolt_at > int(TUNING.overdrive_sky_hold * 1000.0) or _bolts.is_empty():
		_rebuild()
		_bolt_at = now
	queue_redraw()


func _rebuild() -> void:
	_bolts.clear()
	var view := _view()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_msec() / 40) * 17 + 3
	var count := clampi(TUNING.overdrive_sky_bolts, 2, 4)
	for i in count:
		var points := PackedVector2Array()
		var x := rng.randf_range(-view.x * 0.46, view.x * 0.46)
		var y := -view.y * 0.5
		var land_x := x + rng.randf_range(-220.0, 220.0)
		var land_y := rng.randf_range(-view.y * 0.08, view.y * 0.22)
		points.append(Vector2(x, y))
		for step in 7:
			var u := float(step + 1) / 7.0
			var px := lerpf(x, land_x, u) + rng.randf_range(-42.0, 42.0)
			var py := lerpf(y, land_y, u)
			points.append(Vector2(px, py))
		_bolts.append(points)


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size


func _draw() -> void:
	if not active:
		return
	var view := _view()
	var cover := Rect2(-view * 0.5, view)
	draw_rect(cover, Color(0.02, 0.0, 0.035, TUNING.overdrive_sky_dark))
	for points in _bolts:
		if points.size() < 2:
			continue
		draw_polyline(points, Color(0.85, 0.08, 0.06, 0.72), 3.2, true)
		draw_polyline(points, Color(0.05, 0.01, 0.02, 0.9), 1.5, true)
	if strike:
		draw_rect(cover, Color(0.42, 0.03, 0.04, TUNING.overdrive_strike_flash))
