class_name GlassRunner
extends CharacterBody2D

const TUNING := preload("res://assets/tuning/game_tuning.tres")

var run: Variant
var audio: Variant
var drive_speed: float = 0.0
var locked: bool = false
var invuln: float = 0.0
var jumps_left: int = 1
var dash_cd: float = 0.0

var _jump_buffer: float = 0.0
var _dash_buffer: float = 0.0
var _coyote: float = 0.0
var _was_on_floor: bool = false
var _dashing: bool = false
var _dash_time: float = 0.0
var _dash_got_kill: bool = false
var _takeoff_left: float = 0.0
var _cut_done: bool = false
var _dash_blend: float = 0.0
var _speed_scale: float = 1.0
var _rolling: float = 0.0
var _doubling: float = 0.0
var _land_left: float = 0.0
var _dying: bool = false
var _death_fell: bool = false

var _puppet: GlassPuppet
var _hurt: Area2D
var _attack_area: Area2D
var _attack_shape: CollisionShape2D
var _shadow: Node2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 16.0
	floor_max_angle = deg_to_rad(50)
	_build_body()
	_build_puppet()
	_build_shadow()


func begin_death(fell: bool) -> void:
	_dying = true
	_death_fell = fell
	_dashing = false
	_dash_blend = 0.0
	_takeoff_left = 0.0
	_rolling = 0.0
	locked = false
	visible = true
	_hurt.monitoring = false
	_jump_buffer = 0.0
	_dash_buffer = 0.0
	if not fell:
		velocity = Vector2(velocity.x * 0.12, -240.0)
	if _puppet:
		_puppet.modulate.a = 1.0
		_puppet.set_coat(0.0)


func respawn_at(spot: Vector2) -> void:
	global_position = spot
	velocity = Vector2.ZERO
	locked = false
	visible = true
	_dying = false
	_dashing = false
	_dash_got_kill = false
	_dash_blend = 0.0
	_takeoff_left = 0.0
	_rolling = 0.0
	_doubling = 0.0
	_speed_scale = 1.0
	invuln = TUNING.hurt_invuln
	_jump_buffer = 0.0
	_dash_buffer = 0.0
	jumps_left = 1
	_was_on_floor = false
	_coyote = TUNING.coyote_time
	_hurt.monitoring = true
	if _puppet:
		_puppet.modulate = Color.WHITE


func freeze() -> void:
	_dying = false
	locked = true
	_dashing = false
	_hurt.monitoring = false
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	var controls: Variant = run.controls if run != null else null
	if controls != null:
		if controls.jump_pressed:
			_jump_buffer = TUNING.jump_buffer
		if controls.dash_pressed:
			_dash_buffer = TUNING.dash_buffer
		controls.consume()
	_jump_buffer = max(0.0, _jump_buffer - delta)
	_dash_buffer = max(0.0, _dash_buffer - delta)
	dash_cd = max(0.0, dash_cd - delta)
	if invuln > 0.0:
		invuln = max(0.0, invuln - delta)

	if _dying:
		velocity.y += TUNING.fall_gravity * delta
		if velocity.y > TUNING.max_fall_speed:
			velocity.y = TUNING.max_fall_speed
		if not _death_fell:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		move_and_slide()
		if _puppet:
			var fade_rate := 0.45 if _death_fell else 1.6
			_puppet.modulate.a = maxf(0.15 if _death_fell else 0.0, _puppet.modulate.a - delta * fade_rate)
		_drive_puppet()
		return

	if locked:
		velocity = Vector2.ZERO
		move_and_slide()
		_drive_puppet()
		return

	var jump_held := false
	if controls != null:
		jump_held = bool(controls.jump_held)
	if not jump_held and velocity.y < 0.0 and not _cut_done and _takeoff_left <= 0.0 and not _dashing:
		velocity.y *= TUNING.jump_cut_scale
		_cut_done = true

	if not _dashing and _dash_buffer > 0.0 and dash_cd <= 0.0 and drive_speed > 0.0 and _takeoff_left <= 0.0:
		_start_dash()
		_dash_buffer = 0.0

	var grounded := is_on_floor()
	if grounded and _takeoff_left <= 0.0:
		_coyote = TUNING.coyote_time
		jumps_left = 1
	else:
		_coyote = maxf(0.0, _coyote - delta)

	if _takeoff_left > 0.0:
		_takeoff_left = maxf(0.0, _takeoff_left - delta)
		if _takeoff_left <= 0.0:
			_launch(false)
	elif _jump_buffer > 0.0 and not _dashing:
		if grounded or _coyote > 0.0:
			_begin_takeoff()
		elif jumps_left > 0 and not grounded:
			_launch(true)

	_speed_scale = move_toward(_speed_scale, 1.0, delta / maxf(TUNING.hard_land_recover, 0.05) * TUNING.hard_land_loss)
	if _rolling > 0.0:
		_rolling = maxf(0.0, _rolling - delta)
	if _doubling > 0.0:
		_doubling = maxf(0.0, _doubling - delta)

	var gravity := _pick_gravity(jump_held)
	velocity.y += gravity * delta
	if velocity.y > TUNING.max_fall_speed:
		velocity.y = TUNING.max_fall_speed

	var dash_speed := TUNING.dash_distance / maxf(TUNING.dash_duration, 0.05)
	var run_speed := drive_speed * _speed_scale
	if _dashing:
		velocity.y = 0.0
		velocity.x = dash_speed
	elif _dash_blend > 0.0:
		_dash_blend = maxf(0.0, _dash_blend - delta / maxf(TUNING.dash_ease_out, 0.02))
		velocity.x = lerpf(run_speed, dash_speed, _dash_blend)
	else:
		velocity.x = run_speed

	var fell_from := velocity.y
	move_and_slide()
	if drive_speed > 0.0 and not _dashing and not is_on_floor():
		for i in get_slide_collision_count():
			var normal := get_slide_collision(i).get_normal()
			if normal.x < -0.55 and velocity.y >= -20.0:
				velocity.y = TUNING.lip_hop_velocity
				break

	_place_attack()
	_resolve_hits()
	if _dashing:
		_dash_time -= delta
		if _dash_time <= 0.0:
			_dashing = false
			_dash_blend = 1.0
			if not _dash_got_kill and run != null:
				run.on_dash_whiff()

	if is_on_floor() and not _was_on_floor and _takeoff_left <= 0.0:
		_on_land(fell_from)
	if _land_left > 0.0:
		_land_left = maxf(0.0, _land_left - delta)
	_was_on_floor = is_on_floor()
	_drive_puppet()
	_update_shadow()


func _pick_gravity(jump_held: bool) -> float:
	if _dashing or _takeoff_left > 0.0:
		return TUNING.rise_gravity * TUNING.dash_gravity_scale if _dashing else 0.0
	if absf(velocity.y) <= TUNING.apex_speed:
		return TUNING.apex_gravity
	if velocity.y < 0.0:
		return TUNING.rise_gravity
	var fall := TUNING.fall_gravity
	if jump_held:
		fall *= TUNING.fall_hold_scale
	return fall


func _begin_takeoff() -> void:
	_takeoff_left = TUNING.takeoff_time
	_jump_buffer = 0.0
	_coyote = 0.0
	_cut_done = false
	velocity.y = 0.0


func _launch(second: bool) -> void:
	velocity.y = TUNING.double_jump_velocity if second else TUNING.jump_velocity
	_jump_buffer = 0.0
	_coyote = 0.0
	_cut_done = false
	if second:
		jumps_left = 0
		_doubling = 0.42
		_rolling = 0.0
	if audio != null:
		audio.play("jump", 0.07 if second else 0.0)
	_puff()


func _on_land(impact_speed: float) -> void:
	_doubling = 0.0
	_puff()
	if impact_speed >= TUNING.hard_land_speed:
		_rolling = TUNING.roll_time
		_land_left = 0.0
		_speed_scale = minf(_speed_scale, 1.0 - TUNING.hard_land_loss)
	else:
		_rolling = 0.0
		_land_left = 0.16


func _start_dash() -> void:
	_dashing = true
	_dash_time = TUNING.dash_duration
	dash_cd = TUNING.dash_cooldown
	_dash_got_kill = false
	_dash_blend = 1.0
	velocity.y = 0.0
	_takeoff_left = 0.0
	if audio != null:
		audio.play("dash")


func on_attack_impact() -> void:
	if _puppet:
		_puppet.impact()


func _drive_puppet() -> void:
	if _puppet == null:
		return
	var ratio := drive_speed / maxf(TUNING.run_speed_start, 1.0)
	var state := "run"
	if _dashing:
		state = "dash"
	elif _rolling > 0.0:
		state = "roll"
	elif _takeoff_left > 0.0:
		state = "takeoff"
	elif _doubling > 0.0 and not is_on_floor():
		state = "double"
	elif _land_left > 0.0 and is_on_floor():
		state = "land"
	elif not is_on_floor():
		if velocity.y < -TUNING.apex_speed:
			state = "rise"
		elif absf(velocity.y) <= TUNING.apex_speed:
			state = "apex"
		else:
			state = "fall"
	var phase := 0.0
	if _dashing:
		phase = 1.0 - clampf(_dash_time / maxf(TUNING.dash_duration, 0.05), 0.0, 1.0)
	elif _rolling > 0.0:
		phase = 1.0 - clampf(_rolling / maxf(TUNING.roll_time, 0.05), 0.0, 1.0)
	_puppet.set_phase(phase)
	_puppet.play_state(state, ratio)
	var coat := 0.0
	if _dashing:
		var t := 1.0 - clampf(_dash_time / maxf(TUNING.dash_duration, 0.05), 0.0, 1.0)
		if t < 0.22:
			coat = t / 0.22 * 0.35
		elif t < 0.72:
			coat = 1.0
		else:
			coat = clampf((1.0 - t) / 0.28, 0.0, 1.0)
	_puppet.set_coat(coat)
	if _dying:
		return
	if invuln > 0.0:
		_puppet.modulate.a = 0.42 if int(invuln * 10.0) % 2 == 0 else 1.0
	else:
		_puppet.modulate.a = 1.0


func _place_attack() -> void:
	if _attack_shape == null:
		return
	var ahead := global_position + Vector2(TUNING.player_height * 0.42, -TUNING.player_height * 0.32)
	if _dashing and _puppet != null:
		var fist := _puppet.fist_global()
		if fist.x > ahead.x:
			ahead = fist
	_attack_shape.global_position = ahead


func _resolve_hits() -> void:
	if _dashing:
		var areas: Array = _attack_area.get_overlapping_areas()
		areas.append_array(_hurt.get_overlapping_areas())
		for area in areas:
			if area is GlassMonster:
				var monster := area as GlassMonster
				if monster.can_be_hit():
					var at := monster.center()
					monster.shatter()
					_dash_got_kill = true
					if run != null:
						run.register_kill(at)
	elif invuln <= 0.0:
		for area in _hurt.get_overlapping_areas():
			if area is GlassMonster and (area as GlassMonster).can_be_hit():
				if run != null:
					run.on_life_lost(false)
				return


func _update_shadow() -> void:
	if locked and not visible:
		_shadow.visible = false
		return
	var drop := 0.0
	if is_on_floor():
		drop = 2.0
	else:
		var space := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 4), global_position + Vector2(0, 900))
		query.collision_mask = 1
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			_shadow.visible = false
			return
		drop = hit.position.y - global_position.y
	_shadow.visible = true
	_shadow.position = Vector2(8, drop)
	var t := clampf(drop / 240.0, 0.0, 1.0)
	var s := lerpf(1.0, 0.5, t)
	_shadow.scale = Vector2(s, s)
	_shadow.modulate.a = lerpf(0.5, 0.12, t)


func _puff() -> void:
	var dust := Dust.new()
	dust.global_position = global_position + Vector2(0, -2)
	var parent := get_parent()
	if parent:
		parent.add_child(dust)


func _build_body() -> void:
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TUNING.player_height * 0.32, TUNING.player_height * 0.60)
	body.shape = shape
	body.position = Vector2(TUNING.player_height * 0.10, -TUNING.player_height * 0.32)
	add_child(body)

	_hurt = Area2D.new()
	_hurt.collision_layer = 0
	_hurt.collision_mask = 2
	_hurt.monitoring = true
	_hurt.monitorable = false
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = shape.size
	hurt_shape.shape = hurt_rect
	hurt_shape.position = body.position
	_hurt.add_child(hurt_shape)
	add_child(_hurt)

	_attack_area = Area2D.new()
	_attack_area.collision_layer = 0
	_attack_area.collision_mask = 2
	_attack_area.monitoring = true
	_attack_area.monitorable = false
	var attack_shape := CollisionShape2D.new()
	var attack_rect := RectangleShape2D.new()
	attack_rect.size = Vector2(TUNING.player_height * 0.7, TUNING.player_height * 0.42)
	attack_shape.shape = attack_rect
	_attack_shape = attack_shape
	_attack_area.add_child(attack_shape)
	add_child(_attack_area)


func _build_puppet() -> void:
	_puppet = GlassPuppet.new()
	_puppet.z_index = 2
	add_child(_puppet)


func _build_shadow() -> void:
	_shadow = Shadow.new()
	_shadow.z_index = -1
	add_child(_shadow)


class Shadow extends Node2D:
	func _draw() -> void:
		var points := PackedVector2Array()
		for i in 14:
			var angle := TAU * float(i) / 14.0
			points.append(Vector2(cos(angle) * 28.0, sin(angle) * 8.0))
		draw_colored_polygon(points, Color(0.02, 0.01, 0.04, 0.8))


class Dust extends Node2D:
	var age: float = 0.0

	func _process(delta: float) -> void:
		age += delta
		queue_redraw()
		if age > 0.32:
			queue_free()

	func _draw() -> void:
		var t := clampf(age / 0.32, 0.0, 1.0)
		draw_arc(Vector2.ZERO, lerpf(6.0, 20.0, t), 0, TAU, 16, Color(1, 0.82, 0.55, 0.45 * (1.0 - t)), 2.5)
