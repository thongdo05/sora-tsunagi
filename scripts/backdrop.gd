extends Node2D

## Streams the world-loop backdrops. Parallax factors stay in game_tuning.tres.
## Panel lists stay in assets/worlds/world_loop.tres.

const TUNING := preload("res://assets/tuning/game_tuning.tres")
const LOOP := preload("res://assets/worlds/world_loop.tres")

var camera: Camera2D
var far_track: BackgroundTrack
var mid_track: BackgroundTrack
var near_track: BackgroundTrack
var _sky: ColorRect
var _motes: Node2D
var _born_ms: int = 0


func _ready() -> void:
	z_index = -20
	_born_ms = Time.get_ticks_msec()
	_sky = ColorRect.new()
	_sky.color = Color(0.035, 0.09, 0.22)
	_sky.position = Vector2(-8000, -3000)
	_sky.size = Vector2(32000, 8000)
	_sky.z_index = -5
	add_child(_sky)
	far_track = _layer("far", -4, TUNING.bg_far_scroll, TUNING.bg_far_span, 1.02, -0.02, 0.22, 0.0, 0.3, 0.0)
	mid_track = _layer("mid", -3, TUNING.bg_mid_scroll, TUNING.bg_mid_span, 0.38, 0.46, 0.16, 0.45, 0.35, 0.0)
	near_track = _layer("near", -2, TUNING.bg_near_scroll, TUNING.bg_near_span, 0.18, 0.84, 0.2, 0.72, 0.0, TUNING.bg_sea_shimmer)
	_motes = Motes.new()
	_motes.z_index = 3
	add_child(_motes)
	if not LOOP.worlds.is_empty():
		_sky.color = LOOP.worlds[0].sky_color


func _process(_delta: float) -> void:
	if camera == null:
		return
	var view := get_viewport().get_visible_rect().size
	var cam := camera.global_position
	var age := (Time.get_ticks_msec() - _born_ms) / 1000.0
	var bob := sin(age * 0.22) * TUNING.bg_sky_bob
	far_track.update(view, cam, bob)
	mid_track.update(view, cam, 0.0)
	near_track.update(view, cam, sin(age * 0.4) * 2.0)
	_tint_sky()
	_motes.global_position = cam - view * 0.5


func _layer(layer_name: String, z: int, scroll: float, span: float, height_frac: float, anchor: float, bias: float, fade_top: float, fade_bottom: float, shimmer: float) -> BackgroundTrack:
	var track := BackgroundTrack.new()
	track.name = layer_name
	track.z_index = z
	track.loop = LOOP
	track.layer_name = layer_name
	track.scroll = scroll
	track.span = span
	track.height_frac = height_frac
	track.anchor = anchor
	track.bias = bias
	track.fade_top = fade_top
	track.fade_bottom = fade_bottom
	track.shimmer = shimmer
	add_child(track)
	return track


func _tint_sky() -> void:
	if far_track.center_world != null:
		_sky.color = far_track.center_world.sky_color


class Motes extends Node2D:
	const DRIFT_TUNING := preload("res://assets/tuning/game_tuning.tres")
	var _motes: Array[Dictionary] = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for _i in 36:
			_motes.append({
				"x": rng.randf(),
				"y": rng.randf_range(0.0, 0.72),
				"s": rng.randf_range(1.2, 2.6),
				"v": rng.randf_range(0.006, 0.02),
				"ph": rng.randf() * TAU,
				"a": rng.randf_range(0.07, 0.16),
			})

	func _process(delta: float) -> void:
		var drift := DRIFT_TUNING.bg_cloud_drift
		var view_x := maxf(get_viewport().get_visible_rect().size.x, 1.0)
		for mote in _motes:
			mote["x"] = fposmod(float(mote["x"]) + (float(mote["v"]) * view_x + drift) * delta / view_x, 1.0)
			mote["ph"] = float(mote["ph"]) + delta * 0.6
		queue_redraw()

	func _draw() -> void:
		var view := get_viewport().get_visible_rect().size
		for mote in _motes:
			var bob := sin(float(mote["ph"])) * 10.0
			var at := Vector2(float(mote["x"]) * view.x, float(mote["y"]) * view.y * 0.78 + bob)
			draw_circle(at, float(mote["s"]), Color(0.8, 0.91, 1.0, float(mote["a"])))
