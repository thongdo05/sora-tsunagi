class_name BackgroundTrack
extends Node2D

## Streams one parallax layer. Panels sit edge to edge. The next one is created
## just ahead of the camera and panels that have scrolled behind are freed.

const OVERLAP := 0.2
const FADE := preload("res://shaders/layer_fade.gdshader")

var loop: WorldLoop
var layer_name: String = "far"
var scroll: float = 0.03
var span: float = 2.4
var height_frac: float = 1.0
var anchor: float = 0.0
var bias: float = 0.0
var fade_top: float = 0.0
var fade_bottom: float = 0.0
var shimmer: float = 0.0

var _live: Dictionary = {}
var _material: ShaderMaterial
var center_world: WorldBackdrop


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = FADE
	_material.set_shader_parameter("fade_x", OVERLAP)
	_material.set_shader_parameter("fade_top", fade_top)
	_material.set_shader_parameter("fade_bottom", fade_bottom)
	_material.set_shader_parameter("shimmer", shimmer)


func live_indices() -> Array:
	var keys: Array = _live.keys()
	keys.sort()
	return keys


func update(view: Vector2, cam: Vector2, bob: float) -> void:
	if loop == null:
		return
	var probe: Dictionary = loop.layout(layer_name, 0)
	var probe_tex: Texture2D = probe.get("texture")
	if probe_tex == null:
		_free_all()
		return
	var full_h := float(probe.get("full_h", probe_tex.get_height()))
	var full_w := float(probe.get("src_w", probe_tex.get_width()))
	var by_height := (view.y * height_frac) / maxf(full_h, 1.0)
	var cover := by_height
	if bool(probe.get("reuse", false)):
		cover = maxf((view.x * span) / maxf(full_w, 1.0), by_height)
	var left := cam.x - view.x * 0.5
	var origin := cam.x * scroll - full_w * cover * bias
	var top := cam.y - view.y * 0.5 + view.y * anchor + bob
	var art_left := (left - origin) / cover
	var art_right := (left + view.x - origin) / cover
	var first := _seek(art_left - full_w)
	var last := first
	var keep := {}
	for step in 8:
		var index := first + step
		var piece: Dictionary = loop.layout(layer_name, index)
		if piece.get("texture") == null:
			if index < 0:
				continue
			break
		var art_x := float(piece["art_x"])
		var src_w := float(piece["src_w"])
		if art_x > art_right + 64.0:
			break
		last = index
		if art_x + src_w < art_left - 64.0:
			continue
		var sprite: Sprite2D = _live.get(index)
		if sprite == null:
			sprite = _spawn(piece)
			if sprite == null:
				continue
			_live[index] = sprite
		_place_sprite(sprite, piece, origin, cover, top)
		keep[index] = true
	var center_art := (cam.x - origin) / cover
	center_world = _world_at(center_art)
	var stale: Array = []
	for key in _live.keys():
		if not keep.has(key):
			stale.append(key)
	for key in stale:
		var gone: Sprite2D = _live[key]
		if is_instance_valid(gone):
			gone.queue_free()
		_live.erase(key)


func _seek(art_x: float) -> int:
	if art_x < 0.0:
		return -2
	var hi := 4
	var lo := 0
	while hi < 5000:
		var piece: Dictionary = loop.layout(layer_name, hi)
		if piece.get("texture") == null:
			return lo
		if float(piece.get("art_x", 0.0)) > art_x:
			break
		lo = hi
		hi *= 2
	var index := lo
	while index < hi:
		var piece: Dictionary = loop.layout(layer_name, index)
		if piece.get("texture") == null:
			return maxi(index - 1, 0)
		if float(piece["art_x"]) + float(piece["src_w"]) >= art_x:
			return index
		index += 1
	return index


func _world_at(art_x: float) -> WorldBackdrop:
	var index := _seek(art_x)
	var piece: Dictionary = loop.layout(layer_name, index)
	return piece.get("world")


func _spawn(piece: Dictionary) -> Sprite2D:
	var texture: Texture2D = piece.get("texture")
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.region_enabled = true
	sprite.region_rect = piece["region"]
	var material := ShaderMaterial.new()
	material.shader = FADE
	material.set_shader_parameter("fade_x", float(piece.get("fade", 0.0)))
	material.set_shader_parameter("fade_top", fade_top)
	material.set_shader_parameter("fade_bottom", fade_bottom)
	material.set_shader_parameter("shimmer", shimmer)
	sprite.material = material
	sprite.set_meta("flip", bool(piece.get("flip", false)))
	add_child(sprite)
	return sprite


func _place_sprite(sprite: Sprite2D, piece: Dictionary, origin: float, cover: float, top: float) -> void:
	var flipped := bool(sprite.get_meta("flip", false))
	var width := float(piece["src_w"]) * cover
	var x0 := origin + float(piece["art_x"]) * cover
	if flipped:
		sprite.scale = Vector2(-cover, cover)
		sprite.position = Vector2(x0 + width, top)
	else:
		sprite.scale = Vector2(cover, cover)
		sprite.position = Vector2(x0, top)


func _free_all() -> void:
	for key in _live.keys():
		var sprite: Sprite2D = _live[key]
		if is_instance_valid(sprite):
			sprite.queue_free()
	_live.clear()
	center_world = null
