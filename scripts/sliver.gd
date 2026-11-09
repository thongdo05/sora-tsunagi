extends Node2D

## A sky fragment. No collision, so it never changes a landing.
## Every shard shares the same size, rotation, glow, and bob phase.

const TUNING := preload("res://assets/tuning/game_tuning.tres")

## Shared look — no per-shard random.
const SPRITE_SCALE := Vector2(0.15, 0.15)
const GLOW_SCALE := Vector2(0.22, 0.22)
const GLOW_COLOR := Color(1.0, 0.78, 0.34, 0.4)
## Slow shared bob. Phase starts at 0 for every shard so the field moves together.
const BOB_SPEED := 2.3

var _holder: Node2D
var _glow: Sprite2D
var _phase: float = 0.0


func setup(texture: Texture2D) -> void:
	_phase = 0.0
	_holder = Node2D.new()
	add_child(_holder)
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow = Sprite2D.new()
	_glow.texture = texture
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.material = glow_mat
	_glow.modulate = GLOW_COLOR
	_glow.scale = GLOW_SCALE
	_holder.add_child(_glow)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = SPRITE_SCALE
	_holder.add_child(sprite)
	z_index = 4


func _process(delta: float) -> void:
	if _holder == null:
		return
	_phase += delta * BOB_SPEED
	_holder.position.y = sin(_phase) * TUNING.sliver_bob
	# No spin — rotation stays 0 so every shard reads the same.
	_holder.rotation = 0.0
	_glow.modulate = GLOW_COLOR
