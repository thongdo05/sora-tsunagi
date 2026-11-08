extends Node2D

## Moonheld S3 plate on the Glassfall run, in three depths.
## Copies alternate mirrored so a wrap meets itself. Factors live in game_tuning.tres.

const TUNING := preload("res://assets/tuning/game_tuning.tres")
const FAR := preload("res://assets/worlds/moonheld/bg_far.webp")
const MID := preload("res://assets/worlds/moonheld/bg_mid.webp")
const NEAR := preload("res://assets/worlds/moonheld/bg_near.webp")
const COPIES := 4
const OVERLAP := 0.2

var camera: Camera2D
var _far: Array[Sprite2D] = []
var _mid: Array[Sprite2D] = []
var _near: Array[Sprite2D] = []
var _motes: Node2D
var _born_ms: int = 0


func _ready() -> void:
	z_index = -20
	_born_ms = Time.get_ticks_msec()
	var sky := ColorRect.new()
	sky.color = Color(0.035, 0.09, 0.22)
	sky.position = Vector2(-8000, -3000)
	sky.size = Vector2(32000, 8000)
	sky.z_index = -5
	add_child(sky)
	_add_layer(FAR, _far, -4, OVERLAP, 0.0, 0.3, 0.0)
	_add_layer(MID, _mid, -3, OVERLAP, 0.45, 0.35, 0.0)
	_add_layer(NEAR, _near, -2, OVERLAP, 0.72, 0.0, TUNING.bg_sea_shimmer)
	_motes = Motes.new()
	_motes.z_index = 3
	add_child(_motes)


func _process(_delta: float) -> void:
	if camera == null:
		return
	var view := get_viewport().get_visible_rect().size
	var cam := camera.global_position
	var age := (Time.get_ticks_msec() - _born_ms) / 1000.0
	var bob := sin(age * 0.22) * TUNING.bg_sky_bob
	_place(_far, TUNING.bg_far_scroll, TUNING.bg_far_span, view, cam, 1.02, -0.02, bob, 0.22)
	_place(_mid, TUNING.bg_mid_scroll, TUNING.bg_mid_span, view, cam, 0.38, 0.46, 0.0, 0.16)
	_place(_near, TUNING.bg_near_scroll, TUNING.bg_near_span, view, cam, 0.18, 0.84, sin(age * 0.4) * 2.0, 0.2)
	_motes.global_position = cam - view * 0.5
	if OS.get_environment("SORA_BG_LOOPS") != "":
		_print_loops(view)


func _add_layer(texture: Texture2D, bucket: Array[Sprite2D], z: int, fade_x: float, fade_top: float, fade_bottom: float, shimmer: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/layer_fade.gdshader")
	material.set_shader_parameter("fade_x", fade_x)
	material.set_shader_parameter("fade_top", fade_top)
	material.set_shader_parameter("fade_bottom", fade_bottom)
	material.set_shader_parameter("shimmer", shimmer)
	for _i in COPIES:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.material = material
		sprite.z_index = z
		add_child(sprite)
		bucket.append(sprite)


func _place(sprites: Array[Sprite2D], scroll: float, span: float, view: Vector2, cam: Vector2, height_frac: float, anchor: float, bob: float, bias: float) -> void:
	var tex := sprites[0].texture.get_size()
	var cover := maxf((view.x * span) / tex.x, (view.y * height_frac) / tex.y)
	var draw := tex * cover
	var tile := draw.x * (1.0 - OVERLAP)
	var left := cam.x - view.x * 0.5
	var origin := cam.x * scroll - draw.x * bias
	var index := int(floor((left - origin) / tile)) - 1
	var top := cam.y - view.y * 0.5 + view.y * anchor + bob
	for i in sprites.size():
		var n := index + i
		var sprite := sprites[i]
		sprite.scale = Vector2(cover, cover)
		sprite.position = Vector2(origin + float(n) * tile, top)


func _print_loops(view: Vector2) -> void:
	var far_w := _width(FAR, view, TUNING.bg_far_span, 1.02)
	var mid_w := _width(MID, view, TUNING.bg_mid_span, 0.38)
	var near_w := _width(NEAR, view, TUNING.bg_near_span, 0.18)
	print("BG view %.0fx%.0f" % [view.x, view.y])
	_report("far", far_w, TUNING.bg_far_scroll)
	_report("mid", mid_w, TUNING.bg_mid_scroll)
	_report("near", near_w, TUNING.bg_near_scroll)


func _width(texture: Texture2D, view: Vector2, span: float, height_frac: float) -> float:
	var tex := texture.get_size()
	var cover := maxf((view.x * span) / tex.x, (view.y * height_frac) / tex.y)
	return tex.x * cover


func _report(name: String, width: float, scroll: float) -> void:
	var step := width * (1.0 - OVERLAP)
	var start := step / (scroll * TUNING.run_speed_start)
	var fast := step / (scroll * TUNING.run_speed_max)
	print("BG %s width %.0f step %.0f scroll %.3f start %.1fs max %.1fs" % [name, width, step, scroll, start, fast])


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
