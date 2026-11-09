extends Node2D

## Collect beat, drawn in screen space: a small additive white glint, then done.
## No burst, petals, or trail — those read as too much on a phone.

const FLASH := preload("res://assets/sprites/slivers/fx_flash.webp")

## Total lifetime of one collect flash. Matches Thong's ~0.15 s ask.
const FLASH_LIFE := 0.15
## Spawn scale of the flash sprite (texture is 338x578).
const FLASH_SCALE0 := 0.14
## End scale — a small pop, not a screen fill.
const FLASH_SCALE1 := 0.26

var _jobs: Array = []
var _hot: CanvasItemMaterial


func _ready() -> void:
	_hot = CanvasItemMaterial.new()
	_hot.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func play(from: Vector2, _to: Vector2) -> void:
	var flash := _hot_sprite(FLASH, from, FLASH_SCALE0)
	_jobs.append({
		"t": 0.0,
		"flash": flash,
	})


func _hot_sprite(texture: Texture2D, at: Vector2, scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = true
	sprite.position = at
	sprite.scale = Vector2(scale, scale)
	sprite.material = _hot
	add_child(sprite)
	return sprite


func _process(delta: float) -> void:
	var done: Array = []
	for job in _jobs:
		job["t"] = float(job["t"]) + delta
		var t := float(job["t"])
		_fade_flash(job, t)
		if t > FLASH_LIFE:
			done.append(job)
	for job in done:
		_jobs.erase(job)
		var flash: Sprite2D = job["flash"]
		if is_instance_valid(flash):
			flash.queue_free()


func _fade_flash(job: Dictionary, t: float) -> void:
	var flash: Sprite2D = job["flash"]
	if is_instance_valid(flash):
		var u := clampf(t / FLASH_LIFE, 0.0, 1.0)
		flash.scale = Vector2.ONE * lerpf(FLASH_SCALE0, FLASH_SCALE1, u)
		# Ease out so the hot core is brief.
		var a := 1.0 - u * u
		flash.modulate = Color(1.0, 1.0, 1.0, a)
		if u >= 1.0:
			flash.queue_free()
			job["flash"] = null
