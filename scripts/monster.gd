class_name GlassMonster
extends Area2D

const TUNING := preload("res://assets/tuning/game_tuning.tres")
const HOUND_SHEET := preload("res://art/enemies/void_hound/sheets/void_hound_run_8f.png")
const WISP_SHEET := preload("res://art/enemies/lantern_wisp/sheets/lantern_wisp_idle_6f.png")
const WISP_LOOP := preload("res://audio/final/enemies/sfx_lantern_wisp_presence_loop.wav")
const HOUND_SHARDS: Array[Texture2D] = [
	preload("res://art/enemies/void_hound/shards/shard_01.png"),
	preload("res://art/enemies/void_hound/shards/shard_02.png"),
	preload("res://art/enemies/void_hound/shards/shard_03.png"),
	preload("res://art/enemies/void_hound/shards/shard_04.png"),
	preload("res://art/enemies/void_hound/shards/shard_05.png"),
	preload("res://art/enemies/void_hound/shards/shard_06.png"),
	preload("res://art/enemies/void_hound/shards/shard_07.png"),
]
const WISP_SHARDS: Array[Texture2D] = [
	preload("res://art/enemies/lantern_wisp/shards/shard_01.png"),
	preload("res://art/enemies/lantern_wisp/shards/shard_02.png"),
	preload("res://art/enemies/lantern_wisp/shards/shard_03.png"),
	preload("res://art/enemies/lantern_wisp/shards/shard_04.png"),
	preload("res://art/enemies/lantern_wisp/shards/shard_05.png"),
	preload("res://art/enemies/lantern_wisp/shards/shard_06.png"),
	preload("res://art/enemies/lantern_wisp/shards/shard_07.png"),
]
## Piece centers on the same canvas as the cell, so flight starts assembled.
const HOUND_CENTERS: Array[Vector2] = [
	Vector2(132, 296), Vector2(250, 289), Vector2(180, 432), Vector2(358, 354),
	Vector2(426, 286), Vector2(547, 380), Vector2(628, 297),
]
const WISP_CENTERS: Array[Vector2] = [
	Vector2(104, 112), Vector2(92, 191), Vector2(102, 270), Vector2(105, 334),
	Vector2(97, 399), Vector2(233, 288), Vector2(306, 261),
]

enum Phase { WAIT, TELEGRAPH, LIVE }

var flyer: bool = false
var phase: int = Phase.WAIT
var telegraph_left: float = 0.0
var _dead: bool = false
var _collision: CollisionShape2D
var _sprite: Sprite2D
var _presence: AudioStreamPlayer
var _anim := 0.0
var _bob := 0.0
var _shattering := false
var _shatter_age := 0.0
var _pieces: Array[Node2D] = []


func _ready() -> void:
	z_index = 3


func setup(is_flyer: bool) -> void:
	flyer = is_flyer
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = false
	add_to_group("monster")
	_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	if flyer:
		# Lantern glass, inside the ribbons. The bob shifts this in _process.
		shape.size = Vector2(34, 78)
		_collision.position = _wisp_hit_center(0.0)
	else:
		# Torso and head, inside the ears, tail, and paws.
		shape.size = Vector2(144, 52)
		_collision.position = Vector2(-2, -54)
	_collision.shape = shape
	add_child(_collision)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.region_enabled = true
	_sprite.visible = false
	_sprite.z_index = 1
	if flyer:
		_sprite.texture = WISP_SHEET
		_sprite.scale = Vector2.ONE * _wisp_scale()
	else:
		_sprite.texture = HOUND_SHEET
		_sprite.scale = Vector2.ONE * _hound_scale()
	add_child(_sprite)
	_apply_frame(0)
	visible = false


func can_be_hit() -> bool:
	return phase == Phase.LIVE and not _dead


func center() -> Vector2:
	if _collision:
		return global_position + _collision.position
	return global_position


func shatter() -> void:
	if _dead:
		return
	_dead = true
	_shattering = true
	_shatter_age = 0.0
	phase = Phase.LIVE
	monitorable = false
	monitoring = false
	visible = true
	if _sprite:
		_sprite.visible = false
	_stop_presence()
	_play( "wisp_shatter" if flyer else "hound_shatter", 0.0)
	_spawn_pieces()
	_spawn_spark()


func _exit_tree() -> void:
	_stop_presence()


func _physics_process(delta: float) -> void:
	if _shattering:
		return
	match phase:
		Phase.WAIT:
			var root: Variant = get_tree().get_first_node_in_group("run")
			var runner: Variant = get_tree().get_first_node_in_group("player")
			if root == null or runner == null:
				return
			if not bool(root.call("is_live")):
				return
			var speed: float = max(float(root.get("run_speed")), TUNING.run_speed_start)
			var lead: float = speed * TUNING.telegraph_time + TUNING.telegraph_extra_px
			if global_position.x - runner.global_position.x < lead:
				_begin_telegraph()
		Phase.TELEGRAPH:
			telegraph_left -= delta
			queue_redraw()
			if telegraph_left <= 0.0:
				phase = Phase.LIVE
				monitorable = true
				monitoring = true
				visible = true
				if _sprite:
					_sprite.visible = true
				if flyer:
					_start_presence()
		Phase.LIVE:
			queue_redraw()


func _process(delta: float) -> void:
	if _shattering:
		_tick_shatter(delta)
		return
	if phase != Phase.LIVE or _sprite == null:
		return
	var frame_sec := 0.090 if flyer else 0.057
	var frames := 6 if flyer else 8
	_anim += delta
	var frame := int(_anim / frame_sec) % frames
	_apply_frame(frame)
	if flyer:
		_bob += delta
		var period := maxf(TUNING.wisp_bob_period, 0.2)
		var wave := sin(TAU * _bob / period) * TUNING.wisp_bob_px
		_sprite.position = _wisp_origin() + Vector2(0, wave)
		if _collision:
			_collision.position = _wisp_hit_center(wave)
	else:
		_sprite.position = _hound_origin()
		queue_redraw()


func _begin_telegraph() -> void:
	phase = Phase.TELEGRAPH
	telegraph_left = TUNING.telegraph_time
	visible = true
	if flyer:
		_play("warning", -2.0)
	else:
		_play("hound_growl", TUNING.hound_growl_db)
		_play("warning", -2.0)


func _draw() -> void:
	if _shattering:
		return
	if phase == Phase.TELEGRAPH:
		_draw_tear()
		return
	if phase != Phase.LIVE or _dead or flyer:
		return
	var shadow := Color(0, 0, 0, TUNING.hound_shadow_alpha)
	_ellipse(Vector2(-2, 4), 80, 12, shadow)


func _draw_tear() -> void:
	var pulse := 0.65 + 0.35 * sin(float(Time.get_ticks_msec()) * 0.02)
	var height := 168.0 if flyer else 150.0
	var origin := Vector2(0, -height + 8.0)
	draw_rect(Rect2(origin + Vector2(-5, 0), Vector2(10, height)), Color(0.07, 0.03, 0.12, 0.94))
	draw_rect(Rect2(origin + Vector2(-11, -6), Vector2(4, height + 12)), Color(0.71, 0.36, 1.0, 0.85 * pulse))
	draw_rect(Rect2(origin + Vector2(7, -6), Vector2(4, height + 12)), Color(0.65, 0.95, 1.0, 0.8 * pulse))
	draw_circle(origin + Vector2(0, 18.0), 7.0 * pulse, Color(0.95, 0.55, 0.8, 0.9))


func _apply_frame(frame: int) -> void:
	if _sprite == null:
		return
	var cell := Vector2(384, 512) if flyer else Vector2(768, 512)
	_sprite.region_rect = Rect2(float(frame) * cell.x, 0, cell.x, cell.y)


func _hound_scale() -> float:
	# 78/720 fit the stride into the old hitbox. 2.5x puts the back near half the pirate's height.
	return (78.0 / 720.0) * 2.5


func _wisp_scale() -> float:
	# 46/400 fit the old ribbon into the old hitbox. Same 2.5x so the lantern reads at jump height.
	return (46.0 / 400.0) * 2.5


func _wisp_hit_center(bob: float) -> Vector2:
	return Vector2(-26, 1) + Vector2(0, bob)


func _hound_origin() -> Vector2:
	# Body center x onto the hitbox, baseline y=496 onto the deck.
	return Vector2(-2, 0) - Vector2(376, 496) * _hound_scale()


func _wisp_origin() -> Vector2:
	return Vector2.ZERO - Vector2(191, 255) * _wisp_scale()


func _spawn_pieces() -> void:
	var textures: Array[Texture2D] = WISP_SHARDS if flyer else HOUND_SHARDS
	var centers: Array[Vector2] = WISP_CENTERS if flyer else HOUND_CENTERS
	var cell := Vector2(384, 512) if flyer else Vector2(768, 512)
	var scale := _wisp_scale() if flyer else _hound_scale()
	var origin := _sprite.position if _sprite != null else (_wisp_origin() if flyer else _hound_origin())
	var body := Vector2(191, 255) if flyer else Vector2(376, 340)
	for i in textures.size():
		var center: Vector2 = centers[i]
		var pivot := Node2D.new()
		pivot.position = origin + center * scale
		var away := center - body
		if away.length_squared() < 4.0:
			away = Vector2.RIGHT
		pivot.set_meta("dir", away.normalized())
		pivot.set_meta("spin", 1.4 if i % 2 == 0 else -1.4)
		var sprite := Sprite2D.new()
		sprite.texture = textures[i]
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale = Vector2.ONE * scale
		sprite.position = (cell * 0.5 - center) * scale
		pivot.add_child(sprite)
		add_child(pivot)
		_pieces.append(pivot)


func _spawn_spark() -> void:
	var spark := Spark.new()
	spark.position = _collision.position if _collision else Vector2.ZERO
	spark.life = TUNING.enemy_spark_seconds
	add_child(spark)


func _tick_shatter(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.2)
	_shatter_age += real
	var life := maxf(TUNING.enemy_shatter_seconds, 0.05)
	var fade := clampf(1.0 - _shatter_age / life, 0.0, 1.0)
	for piece in _pieces:
		if not is_instance_valid(piece):
			continue
		var dir: Vector2 = piece.get_meta("dir")
		piece.position += dir * 225.0 * real
		piece.rotation += float(piece.get_meta("spin")) * real
		piece.modulate.a = fade
	if _shatter_age >= life:
		queue_free()


func _start_presence() -> void:
	if not flyer:
		return
	if _presence == null:
		_presence = AudioStreamPlayer.new()
		_presence.name = "wisp_presence"
		var loop := WISP_LOOP.duplicate() as AudioStreamWAV
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_presence.stream = loop
		_presence.volume_db = TUNING.wisp_presence_db
		add_child(_presence)
	if not _presence.playing:
		_presence.play()


func _stop_presence() -> void:
	if _presence != null and _presence.playing:
		_presence.stop()


func _play(id: String, volume_db: float) -> void:
	var nodes := get_tree().get_nodes_in_group("audio")
	if nodes.size() == 0:
		return
	nodes[0].call("play", id, 0.0, volume_db)


func _ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 14
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)


class Spark extends Node2D:
	var life: float = 0.08
	var age: float = 0.0

	func _process(delta: float) -> void:
		var real := delta / maxf(Engine.time_scale, 0.2)
		age += real
		queue_redraw()
		if age >= life:
			queue_free()

	func _draw() -> void:
		var u := clampf(age / maxf(life, 0.01), 0.0, 1.0)
		var alpha := 1.0 - u
		for i in 7:
			var angle := TAU * float(i) / 7.0
			var dir := Vector2.from_angle(angle)
			var color := Color(0.75, 0.95, 1.0, 0.85 * alpha) if i % 2 == 0 else Color(1, 1, 1, 0.7 * alpha)
			draw_line(dir * 8.0, dir * (22.0 + u * 28.0), color, 2.0)
