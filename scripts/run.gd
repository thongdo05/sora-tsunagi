class_name RunRoot
extends Node2D

const TUNING := preload("res://assets/tuning/game_tuning.tres")
const READY := 0
const PLAYING := 1
const RESPAWN := 2
const GAME_OVER := 3

static var auto_start: bool = false
## Phones emit a delayed mouse click after a touch. Ignore it so one tap is one action.
static var ignore_mouse_until_ms: int = 0


static func note_touch() -> void:
	ignore_mouse_until_ms = Time.get_ticks_msec() + 800


static func mouse_is_ghost() -> bool:
	return Time.get_ticks_msec() < ignore_mouse_until_ms

var state: int = READY
var run_speed: float = 0.0
var score: float = 0.0
var kills: int = 0
var combo: int = 0
var lives: int = 3
var best: int = 0

var controls: Variant
var player: GlassRunner
var track: GlassTrack
var hud: Variant
var audio: Variant
var camera: Camera2D

var _last_x: float = 0.0
var _respawn_until: int = 0
var _hitstop_until: int = 0
var _shake_left: float = 0.0
var _shake_mag: float = 0.0
var _focus_paused: bool = false
var _flash: ColorRect
var _flash_a: float = 0.0
var _hurt_a: float = 0.0
var _world_fx: Node2D
var _frames: int = 0


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	add_to_group("run")
	process_physics_priority = 20
	lives = TUNING.lives_per_run
	best = _load_best()
	_build()
	player.drive_speed = 0.0
	track.update(player.global_position.x, TUNING.run_speed_start)
	_place_camera()
	hud.set_lives(lives)
	hud.set_score(0)
	hud.set_combo(0, false)
	if auto_start:
		auto_start = false
		start_run()
	else:
		state = READY
		hud.show_start(true)
		controls.enabled = false


func _physics_process(delta: float) -> void:
	if state == PLAYING:
		run_speed = min(TUNING.run_speed_max, run_speed + TUNING.run_acceleration * delta)
	player.drive_speed = run_speed if state == PLAYING else 0.0


func _process(delta: float) -> void:
	_frames += 1
	if Engine.time_scale < 0.99 and Time.get_ticks_msec() >= _hitstop_until:
		Engine.time_scale = 1.0
	if state == RESPAWN and Time.get_ticks_msec() >= _respawn_until:
		_finish_respawn()
	if state == PLAYING or state == READY or state == RESPAWN:
		track.update(player.global_position.x, max(run_speed, TUNING.run_speed_start))
	if state == PLAYING:
		var dx := player.global_position.x - _last_x
		if dx > 0.0:
			score += dx * TUNING.points_per_pixel
		_last_x = player.global_position.x
		if player.global_position.y > _kill_y():
			on_life_lost(true)
	_place_camera()
	_update_shake(delta)
	_update_flash(delta)
	hud.set_score(score)
	_maybe_screenshot()


func _notification(what: int) -> void:
	if OS.get_environment("SORA_NO_PAUSE") != "":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == PLAYING:
		_focus_paused = true
		get_tree().paused = true
		hud.show_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and _focus_paused:
		_focus_paused = false
		get_tree().paused = false
		hud.show_paused(false)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		note_touch()
	elif event is InputEventMouseButton and mouse_is_ghost():
		get_viewport().set_input_as_handled()
		return
	if state == READY and _is_press(event):
		var left := _is_left_press(event)
		var right := _is_right_press(event)
		start_run()
		if left:
			controls.jump_pressed = true
			controls.jump_held = true
		elif right:
			controls.dash_pressed = true
		get_viewport().set_input_as_handled()
	elif state == GAME_OVER and _is_press(event):
		get_viewport().set_input_as_handled()
		restart()


func is_live() -> bool:
	return state == PLAYING or state == RESPAWN


func start_run() -> void:
	state = PLAYING
	lives = TUNING.lives_per_run
	score = 0.0
	kills = 0
	combo = 0
	run_speed = TUNING.run_speed_start
	_last_x = player.global_position.x
	controls.enabled = true
	hud.show_start(false)
	hud.hide_game_over()
	hud.set_lives(lives)
	hud.set_combo(0, false)
	player.locked = false
	player.visible = true
	player.invuln = 0.0


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	auto_start = true
	get_tree().reload_current_scene()


func register_kill(at: Vector2) -> void:
	if state != PLAYING:
		return
	combo += 1
	var points := TUNING.kill_points * combo
	score += points
	kills += 1
	audio.play("attack", 0.0, -1.0)
	audio.play("kill", min(combo, 10) * 0.025, -3.0)
	_spawn_popup(at + Vector2(0, -28), "+%d" % points)
	_spawn_impact(at)
	_shake(TUNING.shake_strength)
	_flash_a = max(_flash_a, 0.55)
	_start_hitstop()
	hud.set_combo(combo, true)


func on_dash_whiff() -> void:
	if combo <= 0:
		return
	combo = 0
	hud.break_combo()


func on_life_lost(fell: bool) -> void:
	if state != PLAYING:
		return
	if not fell and player.invuln > 0.0:
		return
	Engine.time_scale = 1.0
	_hitstop_until = 0
	lives -= 1
	combo = 0
	hud.set_lives(lives)
	hud.set_combo(0, false)
	audio.play("death")
	_shake(TUNING.shake_strength * 0.6)
	_hurt_a = max(_hurt_a, 0.38)
	if lives <= 0:
		_game_over()
	else:
		state = RESPAWN
		player.begin_respawn()
		controls.enabled = true
		_respawn_until = Time.get_ticks_msec() + int(TUNING.respawn_delay * 1000.0)


func debug_lose_life() -> void:
	if state == GAME_OVER:
		return
	state = PLAYING
	player.invuln = 0.0
	player.locked = false
	on_life_lost(true)


func _game_over() -> void:
	state = GAME_OVER
	run_speed = 0.0
	player.drive_speed = 0.0
	player.freeze()
	controls.enabled = false
	var final_score := int(score)
	if final_score > best:
		best = final_score
		_save_best()
	hud.show_game_over(final_score, kills, best)


func _finish_respawn() -> void:
	var spot := track.find_respawn(player.global_position.x + 30.0)
	player.respawn_at(spot)
	state = PLAYING
	_last_x = player.global_position.x
	run_speed = max(run_speed, TUNING.run_speed_start)


func _build() -> void:
	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	var backdrop = preload("res://scripts/backdrop.gd").new()
	world.add_child(backdrop)

	track = GlassTrack.new()
	track.name = "Track"
	world.add_child(track)

	_world_fx = Node2D.new()
	_world_fx.name = "FX"
	_world_fx.z_index = 40
	world.add_child(_world_fx)

	audio = preload("res://scripts/audio_director.gd").new()
	audio.name = "Audio"
	add_child(audio)
	audio.add_to_group("audio")

	player = GlassRunner.new()
	player.name = "Player"
	player.z_index = 10
	player.run = self
	player.audio = audio
	world.add_child(player)
	player.global_position = Vector2(TUNING.player_start_x, TUNING.ground_y - 8.0)
	player.process_physics_priority = 0

	camera = Camera2D.new()
	camera.name = "Camera"
	camera.enabled = true
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	backdrop.camera = camera

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 6
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash)

	hud = preload("res://scripts/hud.gd").new()
	hud.name = "HUD"
	add_child(hud)

	controls = preload("res://scripts/touch_controls.gd").new()
	controls.name = "Controls"
	add_child(controls)


func _place_camera() -> void:
	var view := get_viewport().get_visible_rect().size
	var x := player.global_position.x + (0.5 - TUNING.camera_anchor) * view.x
	var y := TUNING.ground_y - (TUNING.camera_ground_fraction - 0.5) * view.y
	camera.global_position = Vector2(x, y)


func _kill_y() -> float:
	var view := get_viewport().get_visible_rect().size
	return camera.global_position.y + view.y * 0.5 + TUNING.kill_margin


func _start_hitstop() -> void:
	var until := Time.get_ticks_msec() + TUNING.hit_stop_ms
	if until > _hitstop_until:
		_hitstop_until = until
	Engine.time_scale = TUNING.hit_stop_time_scale


func _shake(amount: float) -> void:
	_shake_mag = max(_shake_mag, amount)
	_shake_left = max(_shake_left, TUNING.shake_duration)


func _update_shake(delta: float) -> void:
	var real: float = delta / maxf(Engine.time_scale, 0.001)
	if _shake_left > 0.0:
		_shake_left = max(0.0, _shake_left - real)
		var strength := _shake_mag * clampf(_shake_left / TUNING.shake_duration, 0.0, 1.0)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	else:
		camera.offset = Vector2.ZERO
		_shake_mag = 0.0


func _update_flash(delta: float) -> void:
	_flash_a = move_toward(_flash_a, 0.0, delta * 3.4)
	_hurt_a = move_toward(_hurt_a, 0.0, delta * 2.4)
	if _flash_a >= _hurt_a:
		_flash.color = Color(1, 0.97, 0.93, _flash_a)
	else:
		_flash.color = Color(0.85, 0.12, 0.16, _hurt_a)


func _spawn_popup(at: Vector2, text: String) -> void:
	var node = preload("res://scripts/floating_text.gd").new()
	node.position = at
	node.setup(text)
	_world_fx.add_child(node)


func _spawn_impact(at: Vector2) -> void:
	var node = preload("res://scripts/impact_burst.gd").new()
	node.position = at
	_world_fx.add_child(node)


func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		return button.pressed and button.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventKey and event.pressed and not event.echo:
		return event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_W, KEY_UP, KEY_SHIFT, KEY_K, KEY_J]
	return false


func _is_left_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position.x < _half()
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position.x < _half()
	if event is InputEventKey:
		return event.physical_keycode in [KEY_SPACE, KEY_W, KEY_UP, KEY_ENTER, KEY_KP_ENTER]
	return true


func _is_right_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position.x >= _half()
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position.x >= _half()
	if event is InputEventKey:
		return event.physical_keycode in [KEY_SHIFT, KEY_K, KEY_J]
	return false


func _half() -> float:
	return get_viewport().get_visible_rect().size.x * 0.5


func _maybe_screenshot() -> void:
	var path := OS.get_environment("SORA_SCREENSHOT")
	if path == "":
		return
	var at := 160
	if OS.get_environment("SORA_SHOT_FRAME") != "":
		at = int(OS.get_environment("SORA_SHOT_FRAME"))
	if _frames == at:
		var image := get_viewport().get_texture().get_image()
		image.save_png(path)


func _load_best() -> int:
	var file := ConfigFile.new()
	if file.load("user://glassfall_best.cfg") == OK:
		return int(file.get_value("run", "best", 0))
	return 0


func _save_best() -> void:
	var file := ConfigFile.new()
	file.set_value("run", "best", best)
	file.save("user://glassfall_best.cfg")
