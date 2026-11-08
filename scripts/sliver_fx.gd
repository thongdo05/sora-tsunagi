extends Node2D

## Collect beat, drawn in screen space: a flash, gold petals, then a trail to the counter.

const FLASH := preload("res://assets/sprites/slivers/fx_flash.webp")
const BURST := preload("res://assets/sprites/slivers/fx_burst.webp")
const TRAIL := preload("res://assets/sprites/slivers/fx_trail.webp")
const SPARK := preload("res://assets/sprites/slivers/fx_spark.webp")
const PETALS: Array[Texture2D] = [
	preload("res://assets/sprites/slivers/petal_01.webp"),
	preload("res://assets/sprites/slivers/petal_02.webp"),
	preload("res://assets/sprites/slivers/petal_03.webp"),
	preload("res://assets/sprites/slivers/petal_04.webp"),
	preload("res://assets/sprites/slivers/petal_05.webp"),
	preload("res://assets/sprites/slivers/petal_06.webp"),
	preload("res://assets/sprites/slivers/petal_07.webp"),
	preload("res://assets/sprites/slivers/petal_08.webp"),
]
## The trail art points up and to the right, about -38 degrees in y-down space.
const TRAIL_ANGLE := -0.668

var _jobs: Array = []
var _add: CanvasItemMaterial


func _ready() -> void:
	_add = CanvasItemMaterial.new()
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func play(from: Vector2, to: Vector2) -> void:
	var flash := _sprite(FLASH, from, 0.26)
	var burst := _sprite(BURST, from, 0.2)
	var petals: Array = []
	for i in 8:
		var petal := _sprite(PETALS[i % PETALS.size()], from, randf_range(0.42, 0.62))
		petal.rotation = randf() * TAU
		var dir := Vector2.from_angle(randf() * TAU) * randf_range(90.0, 190.0)
		petals.append({"node": petal, "vel": dir})
	var trail := _sprite(TRAIL, from, 0.15)
	_jobs.append({
		"t": 0.0,
		"flash": flash,
		"burst": burst,
		"petals": petals,
		"trail": trail,
		"from": from,
		"to": to,
		"sparked": false,
	})


func _sprite(texture: Texture2D, at: Vector2, scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = true
	sprite.position = at
	sprite.scale = Vector2(scale, scale)
	sprite.material = _add
	# Additive white blows out. This keeps the sheet's flash honey-gold.
	sprite.modulate = Color(1.0, 0.8, 0.42, 1.0)
	add_child(sprite)
	return sprite


func _process(delta: float) -> void:
	var done: Array = []
	for job in _jobs:
		job["t"] = float(job["t"]) + delta
		var t := float(job["t"])
		_fade_flash(job, t)
		_fly_petals(job, t, delta)
		_fly_trail(job, t)
		if t > 0.85:
			done.append(job)
	for job in done:
		_jobs.erase(job)


func _fade_flash(job: Dictionary, t: float) -> void:
	var flash: Sprite2D = job["flash"]
	if is_instance_valid(flash):
		var u := clampf(t / 0.14, 0.0, 1.0)
		flash.scale = Vector2.ONE * lerpf(0.18, 0.4, u)
		flash.modulate.a = 1.0 - u
		if u >= 1.0:
			flash.queue_free()
			job["flash"] = null
	var burst: Sprite2D = job["burst"]
	if is_instance_valid(burst):
		var u := clampf(t / 0.36, 0.0, 1.0)
		burst.scale = Vector2.ONE * lerpf(0.12, 0.34, u)
		burst.modulate.a = (1.0 - u) * 0.9
		if u >= 1.0:
			burst.queue_free()
			job["burst"] = null


func _fly_petals(job: Dictionary, t: float, delta: float) -> void:
	for petal in job["petals"]:
		var node: Sprite2D = petal["node"]
		if not is_instance_valid(node):
			continue
		var vel: Vector2 = petal["vel"]
		node.position += vel * delta
		petal["vel"] = vel * 0.9
		node.rotation += delta * 2.4
		node.modulate.a = clampf(1.0 - t / 0.4, 0.0, 1.0)
		if t > 0.4:
			node.queue_free()
			petal["node"] = null


func _fly_trail(job: Dictionary, t: float) -> void:
	var trail: Sprite2D = job["trail"]
	var from: Vector2 = job["from"]
	var to: Vector2 = job["to"]
	if is_instance_valid(trail):
		var u := clampf((t - 0.05) / 0.46, 0.0, 1.0)
		var eased := u * u * (3.0 - 2.0 * u)
		trail.position = from.lerp(to, eased)
		var dir := to - from
		if dir.length_squared() > 4.0:
			trail.rotation = dir.angle() - TRAIL_ANGLE
		trail.modulate.a = sin(clampf(u, 0.0, 1.0) * PI) * 0.95
		if u >= 1.0 and not bool(job["sparked"]):
			job["sparked"] = true
			var spark := _sprite(SPARK, to, 0.7)
			job["spark"] = spark
			trail.queue_free()
			job["trail"] = null
	var spark: Sprite2D = job.get("spark")
	if is_instance_valid(spark):
		var su := clampf((t - 0.52) / 0.2, 0.0, 1.0)
		spark.modulate.a = 1.0 - su
		spark.scale = Vector2.ONE * lerpf(0.55, 1.35, su)
		if su >= 1.0:
			spark.queue_free()
			job["spark"] = null
