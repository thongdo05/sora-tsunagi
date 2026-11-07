extends Node2D

const SCROLL := 0.16
const OVERLAP := 0.16

var camera: Camera2D
var _sprites: Array[Sprite2D] = []


func _ready() -> void:
	z_index = -10
	var sky := ColorRect.new()
	sky.color = Color(0.1, 0.16, 0.28)
	sky.position = Vector2(-4000, -2000)
	sky.size = Vector2(20000, 6000)
	sky.z_index = -1
	add_child(sky)
	var texture: Texture2D = preload("res://assets/backgrounds/glassfall_bg.jpg")
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/backdrop_fade.gdshader")
	material.set_shader_parameter("fade", 0.14)
	for _i in 3:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.material = material
		add_child(sprite)
		_sprites.append(sprite)


func _process(_delta: float) -> void:
	if camera == null:
		return
	var view := get_viewport().get_visible_rect().size
	var tex := _sprites[0].texture.get_size()
	var cover: float = maxf(view.x / tex.x, view.y / tex.y)
	var draw := tex * cover
	var tile := draw.x * (1.0 - OVERLAP)
	var cam := camera.global_position
	var left := cam.x - view.x * 0.5
	var base := cam.x * SCROLL
	var index: float = floorf((left - base) / tile) - 1.0
	for i in _sprites.size():
		var sprite := _sprites[i]
		sprite.scale = Vector2(cover, cover)
		sprite.global_position = Vector2(base + (index + float(i)) * tile, cam.y - draw.y * 0.5)
