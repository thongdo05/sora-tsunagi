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
	var sample: Dictionary = loop.resolve(layer_name, 0)
	var texture: Texture2D = sample.get("texture")
	if texture == null:
		_free_all()
		return
	var tex := texture.get_size()
	var cover := maxf((view.x * span) / tex.x, (view.y * height_frac) / tex.y)
	var draw := tex * cover
	var tile := draw.x * (1.0 - OVERLAP)
	if tile < 1.0:
		return
	var left := cam.x - view.x * 0.5
	var origin := cam.x * scroll - draw.x * bias
	var top := cam.y - view.y * 0.5 + view.y * anchor + bob
	var first := int(floor((left - origin) / tile)) - 1
	var last := int(ceil((left + view.x - origin) / tile)) + 1
	var keep := {}
	for index in range(first, last + 1):
		var sprite: Sprite2D = _live.get(index)
		if sprite == null:
			sprite = _spawn(index)
			if sprite == null:
				continue
			_live[index] = sprite
		_place_sprite(sprite, index, origin, tile, draw.x, cover, top)
		keep[index] = true
	var center_index := int(floor((cam.x - origin) / tile))
	var center: Dictionary = loop.resolve(layer_name, center_index)
	center_world = center.get("world")
	var stale: Array = []
	for key in _live.keys():
		if not keep.has(key):
			stale.append(key)
	for key in stale:
		var gone: Sprite2D = _live[key]
		if is_instance_valid(gone):
			gone.queue_free()
		_live.erase(key)


func _spawn(index: int) -> Sprite2D:
	var source: Dictionary = loop.resolve(layer_name, index)
	var texture: Texture2D = source.get("texture")
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.material = _material
	sprite.set_meta("flip", bool(source.get("flip", false)))
	add_child(sprite)
	return sprite


func _place_sprite(sprite: Sprite2D, index: int, origin: float, tile: float, width: float, cover: float, top: float) -> void:
	var flipped := bool(sprite.get_meta("flip", false))
	var x0 := origin + float(index) * tile
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
