extends Node2D

## A honey-gold sky fragment. It has no collision, so it never changes a landing.

const TUNING := preload("res://assets/tuning/game_tuning.tres")

var _holder: Node2D
var _glow: Sprite2D
var _phase: float = 0.0
var _spin: float = 0.5


func setup(texture: Texture2D) -> void:
	_phase = randf() * TAU
	_spin = randf_range(0.45, 0.85)
	if randf() < 0.5:
		_spin = -_spin
	_holder = Node2D.new()
	add_child(_holder)
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow = Sprite2D.new()
	_glow.texture = texture
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.material = glow_mat
	_glow.modulate = Color(1.0, 0.78, 0.34, 0.4)
	_glow.scale = Vector2(0.22, 0.22)
	_holder.add_child(_glow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(0.15, 0.15)
	_holder.add_child(sprite)
	z_index = 4


func _process(delta: float) -> void:
	if _holder == null:
		return
	_phase += delta * 2.3
	_holder.position.y = sin(_phase) * TUNING.sliver_bob
	_holder.rotation = _spin * _phase * 0.32
	_glow.modulate.a = 0.32 + 0.14 * sin(_phase * 1.6)
