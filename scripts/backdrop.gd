extends Node2D

## First-world plate. The files are the Moonheld S3 sea painting (moon, purple rift,
## sunken ships). World names in code stay Glassfall.

const SKY_SCROLL := 0.05
const SEA_SCROLL := 0.16
const OVERLAP := 0.12
const SKY := preload("res://assets/worlds/moonheld/bg_sky.webp")
const SEA := preload("res://assets/worlds/moonheld/bg_sea.webp")

var camera: Camera2D
var _sky: Array[Sprite2D] = []
var _sea: Array[Sprite2D] = []
var _motes: Node2D


func _ready() -> void:
	z_index = -20
	var sky := ColorRect.new()
	sky.color = Color(0.04, 0.1, 0.24)
	sky.position = Vector2(-4000, -2000)
	sky.size = Vector2(24000, 6000)
	sky.z_index = -2
	add_child(sky)
	_add_layer(SKY, _sky, 0.07, 0.0, 0.22)
	_add_layer(SEA, _sea, 0.06, 0.5, 0.0)
	_motes = Motes.new()
	_motes.z_index = 4
	add_child(_motes)


func _process(_delta: float) -> void:
	if camera == null:
		return
	var view := get_viewport().get_visible_rect().size
	var cam := camera.global_position
	_place(_sky, SKY_SCROLL, view, cam, 0.92, -0.04)
	_place(_sea, SEA_SCROLL, view, cam, 0.55, 0.50)
	_motes.global_position = cam - view * 0.5


func _add_layer(texture: Texture2D, bucket: Array[Sprite2D], fade_x: float, fade_top: float, fade_bottom: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/layer_fade.gdshader")
	material.set_shader_parameter("fade_x", fade_x)
	material.set_shader_parameter("fade_top", fade_top)
	material.set_shader_parameter("fade_bottom", fade_bottom)
	for _i in 3:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.material = material
		add_child(sprite)
		bucket.append(sprite)


func _place(sprites: Array[Sprite2D], scroll: float, view: Vector2, cam: Vector2, height_frac: float, anchor: float) -> void:
	var tex := sprites[0].texture.get_size()
	var target_h := view.y * height_frac
	var cover: float = maxf((view.x * 1.04) / tex.x, target_h / tex.y)
	var draw := tex * cover
	var tile := draw.x * (1.0 - OVERLAP)
	var left := cam.x - view.x * 0.5
	var base := cam.x * scroll
	var index := floorf((left - base) / tile) - 1.0
	var top := cam.y - view.y * 0.5 + view.y * anchor
	for i in sprites.size():
		var sprite := sprites[i]
		sprite.scale = Vector2(cover, cover)
		sprite.global_position = Vector2(base + (index + float(i)) * tile, top)


class Motes extends Node2D:
	var _motes: Array[Dictionary] = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for _i in 26:
			_motes.append({
				"x": rng.randf(),
				"y": rng.randf(),
				"s": rng.randf_range(1.4, 3.2),
				"v": rng.randf_range(0.008, 0.022),
				"ph": rng.randf() * TAU,
				"a": rng.randf_range(0.10, 0.22),
			})

	func _process(delta: float) -> void:
		for mote in _motes:
			mote["x"] = fposmod(float(mote["x"]) + float(mote["v"]) * delta, 1.0)
			mote["ph"] = float(mote["ph"]) + delta * 0.7
		queue_redraw()

	func _draw() -> void:
		var view := get_viewport().get_visible_rect().size
		for mote in _motes:
			var bob := sin(float(mote["ph"])) * 10.0
			var at := Vector2(float(mote["x"]) * view.x, float(mote["y"]) * view.y * 0.72 + bob)
			draw_circle(at, float(mote["s"]), Color(0.78, 0.9, 1.0, float(mote["a"])))
