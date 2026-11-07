class_name GlassRunner
extends CharacterBody2D

const TUNING := preload("res://assets/tuning/game_tuning.tres")
const TEX_SIZE := Vector2(768, 673)
const FEET_TEX := Vector2(210, 654)
const FIST_TEX := Vector2(735, 168)
const BODY_TEX_HEIGHT := 664.0

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
var _bob: float = 0.0
var _land: float = 0.0
var _attack: float = 0.0
var _sprite_scale: float = 1.0
var _fist_local: Vector2 = Vector2.ZERO

var _visual: Node2D
var _sprite: Sprite2D
var _material: ShaderMaterial
var _hurt: Area2D
var _attack_area: Area2D
var _sparks: CPUParticles2D
var _embers: CPUParticles2D
var _shadow: Node2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 16.0
	floor_max_angle = deg_to_rad(50)
	_sprite_scale = TUNING.player_height / BODY_TEX_HEIGHT
	_build_body()
	_build_sprite()
	_build_shadow()


func begin_respawn() -> void:
	locked = true
	_dashing = false
	visible = false
	velocity = Vector2.ZERO
	_hurt.monitoring = false


func respawn_at(spot: Vector2) -> void:
	global_position = spot
	velocity = Vector2.ZERO
	locked = false
	visible = true
	_dashing = false
	_dash_got_kill = false
	invuln = TUNING.hurt_invuln
	jumps_left = 1
	_was_on_floor = false
	_coyote = TUNING.coyote_time
	_hurt.monitoring = true


func freeze() -> void:
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

	if locked:
		velocity = Vector2.ZERO
		move_and_slide()
		_animate(delta)
		return

	if not _dashing and _dash_buffer > 0.0 and dash_cd <= 0.0 and drive_speed > 0.0:
		_start_dash()
		_dash_buffer = 0.0

	var grounded := is_on_floor()
	if grounded:
		_coyote = TUNING.coyote_time
		jumps_left = 1
	else:
		_coyote = max(0.0, _coyote - delta)

	if _jump_buffer > 0.0 and drive_speed >= 0.0 and not locked:
		if grounded or _coyote > 0.0:
			_do_jump(false)
		elif jumps_left > 0 and not grounded:
			_do_jump(true)

	var jump_held := false
	if controls != null:
		jump_held = bool(controls.jump_held)
	var gliding: bool = jump_held and not is_on_floor() and velocity.y > 0.0 and not _dashing
	var gravity := TUNING.gravity
	if _dashing:
		gravity *= TUNING.dash_gravity_scale
	elif gliding:
		gravity = TUNING.glide_gravity
	velocity.y += gravity * delta
	if gliding:
		velocity.y = min(velocity.y, TUNING.glide_max_fall)
	velocity.y = min(velocity.y, TUNING.max_fall_speed)

	if _dashing:
		velocity.x = max(drive_speed, TUNING.dash_distance / max(TUNING.dash_duration, 0.05))
	else:
		velocity.x = drive_speed

	move_and_slide()
	if drive_speed > 0.0 and not _dashing and not is_on_floor():
		for i in get_slide_collision_count():
			var normal := get_slide_collision(i).get_normal()
			if normal.x < -0.55 and velocity.y >= -20.0:
				velocity.y = TUNING.lip_hop_velocity
				break

	_resolve_hits()
	if _dashing:
		_dash_time -= delta
		if _dash_time <= 0.0:
			_dashing = false
			if not _dash_got_kill and run != null:
				run.on_dash_whiff()

	if is_on_floor() and not _was_on_floor:
		_land = 1.0
		_puff()
	_was_on_floor = is_on_floor()
	_animate(delta)
	_update_shadow()


func _start_dash() -> void:
	_dashing = true
	_dash_time = TUNING.dash_duration
	dash_cd = TUNING.dash_cooldown
	_dash_got_kill = false
	if audio != null:
		audio.play("dash")


func _do_jump(second: bool) -> void:
	velocity.y = TUNING.double_jump_velocity if second else TUNING.jump_velocity
	_jump_buffer = 0.0
	_coyote = 0.0
	if second:
		jumps_left = 0
	if audio != null:
		audio.play("jump", 0.09 if second else 0.0)
	_puff()


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


func _animate(delta: float) -> void:
	var moving: bool = drive_speed > 40.0 and is_on_floor()
	var freq: float = 11.0 if moving else 2.4
	_bob += delta * freq
	var bob: float = sin(_bob) * (4.2 if moving else 2.0)
	_visual.position = Vector2(0, bob)
	var squash := Vector2.ONE
	if _dashing:
		squash = Vector2(1.16, 0.88)
		_visual.rotation = lerp(_visual.rotation, -0.08, 0.4)
	elif not is_on_floor():
		var rise := clampf(-velocity.y / abs(TUNING.jump_velocity), -1.0, 1.0)
		squash = Vector2(1.0 - rise * 0.08, 1.0 + rise * 0.12)
		_visual.rotation = lerp(_visual.rotation, clampf(-velocity.y * 0.00005, -0.12, 0.18), 0.2)
	else:
		squash = Vector2(1.0 + sin(_bob) * 0.035, 1.0 - sin(_bob) * 0.045)
		_visual.rotation = lerp(_visual.rotation, 0.0, 0.2)
	if _land > 0.0:
		squash.x += _land * 0.16
		squash.y -= _land * 0.14
		_land = move_toward(_land, 0.0, delta * 7.0)
	_visual.scale = _visual.scale.lerp(squash, 0.35)
	var goal: float = 1.0 if _dashing else 0.0
	_attack = move_toward(_attack, goal, delta / (0.05 if goal > 0.5 else 0.12))
	if _material:
		_material.set_shader_parameter("attack", _attack)
	_sparks.emitting = _attack > 0.15
	_embers.emitting = _attack > 0.15
	_sparks.position = _fist_local
	_embers.position = _fist_local
	if invuln > 0.0:
		_visual.modulate.a = 0.35 if int(invuln * 14.0) % 2 == 0 else 1.0
	else:
		_visual.modulate.a = 1.0


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
	attack_rect.size = Vector2(TUNING.player_height * 0.85, TUNING.player_height * 0.26)
	attack_shape.shape = attack_rect
	_fist_local = (FIST_TEX - FEET_TEX) * _sprite_scale
	attack_shape.position = _fist_local + Vector2(-TUNING.player_height * 0.12, 0)
	_attack_area.add_child(attack_shape)
	add_child(_attack_area)


func _build_sprite() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/pirate_cutout.png")
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	_sprite.scale = Vector2(_sprite_scale, _sprite_scale)
	_sprite.position = -(FEET_TEX - TEX_SIZE * 0.5) * _sprite_scale
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/pirate_arm.gdshader")
	_material.set_shader_parameter("arm_mask", preload("res://assets/sprites/pirate_arm_mask.png"))
	_material.set_shader_parameter("attack", 0.0)
	_material.set_shader_parameter("skin_light", Color("de9e7a"))
	_material.set_shader_parameter("skin_shadow", Color("92543c"))
	_sprite.material = _material
	_visual.add_child(_sprite)
	var blob := _blob_texture()
	_sparks = _make_sparks(blob, Color(1, 0.22, 0.12, 1), 32)
	_embers = _make_sparks(blob, Color(0.08, 0.02, 0.05, 0.9), 22)
	_embers.scale_amount_min = 3.0
	_embers.scale_amount_max = 7.0
	_visual.add_child(_sparks)
	_visual.add_child(_embers)


func _build_shadow() -> void:
	_shadow = Shadow.new()
	_shadow.z_index = -1
	add_child(_shadow)


func _make_sparks(blob: Texture2D, color: Color, amount: int) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = blob
	particles.amount = amount
	particles.lifetime = 0.22
	particles.explosiveness = 0.2
	particles.randomness = 0.65
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 12.0
	particles.direction = Vector2(1, -0.15)
	particles.spread = 58.0
	particles.gravity = Vector2(40, 60)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 240.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.5
	particles.color = color
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	ramp.colors = PackedColorArray([color, Color(color.r * 0.2, color.g * 0.1, color.b * 0.1, 0)])
	particles.color_ramp = ramp
	particles.emitting = false
	particles.local_coords = true
	particles.z_index = 2
	return particles


func _blob_texture() -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var dist := Vector2(x - 7.5, y - 7.5).length() / 7.5
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha *= alpha
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


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
