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
var slivers_run: int = 0
var slivers_lifetime: int = 0
var streak_count: int = 0
var streak_mult: int = 1
var meter_shards: int = 0

var controls: Variant
var player: GlassRunner
var track: GlassTrack
var hud: Variant
var audio: Variant
var camera: Camera2D

var _last_x: float = 0.0
var _sliver_streak: int = 0
var _sliver_ms: int = -10000
var _world_shown: String = ""
var _fx: Node2D
var _run_origin_ms: int = 0
var _respawn_until: int = 0
var _hitstop_until: int = 0
var _slowmo_until: int = 0
var _restart_locked_until: int = 0
var _shake_until: int = 0
var _shake_mag: float = 0.0
var _focus_paused: bool = false
var _flash: ColorRect
var _flash_a: float = 0.0
var _hurt_a: float = 0.0
var _death_flash: float = 0.0
var _world_fx: Node2D
var _frames: int = 0
var _clock_ms: int = 0


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	add_to_group("run")
	process_physics_priority = 20
	lives = TUNING.lives_per_run
	_load_progress()
	_build()
	player.drive_speed = 0.0
	track.update(player.global_position.x, TUNING.run_speed_start, 0.0)
	_place_camera()
	_clock_ms = Time.get_ticks_msec()
	hud.set_lives(lives)
	hud.set_score(0)
	hud.set_combo(0, false)
	hud.set_slivers(0, false)
	_apply_world_title(true)
	if auto_start:
		auto_start = false
		start_run()
	else:
		state = READY
		hud.show_start(true)
		controls.enabled = false


func _physics_process(_delta: float) -> void:
	if state == PLAYING or state == RESPAWN:
		run_speed = TUNING.speed_for_time(_run_elapsed())
	elif state == GAME_OVER:
		run_speed = 0.0
	else:
		run_speed = TUNING.run_speed_start
	player.drive_speed = run_speed if state == PLAYING else 0.0


func _process(delta: float) -> void:
	_frames += 1
	_tick_real()
	var elapsed := _run_elapsed() if state == PLAYING or state == RESPAWN else 0.0
	if state == PLAYING or state == READY or state == RESPAWN:
		track.update(player.global_position.x, maxf(run_speed, TUNING.run_speed_start), TUNING.density_for_time(elapsed))
	if state == PLAYING:
		var dx := player.global_position.x - _last_x
		if dx > 0.0:
			score += dx * TUNING.points_per_pixel * float(streak_mult)
		_last_x = player.global_position.x
		_collect_slivers()
		if track.take_misses() > 0:
			_break_streak()
		if player.global_position.y > _kill_y():
			on_life_lost(true)
	_place_camera()
	_apply_world_title(false)
	_update_flash(delta)
	hud.set_score(score)
	_maybe_screenshot()


func _run_elapsed() -> float:
	if _run_origin_ms <= 0:
		return 0.0
	return maxf(0.0, (Time.get_ticks_msec() - _run_origin_ms) / 1000.0)


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
		if Time.get_ticks_msec() < _restart_locked_until:
			return
		restart()


func is_live() -> bool:
	return state == PLAYING or state == RESPAWN


func start_run() -> void:
	state = PLAYING
	lives = TUNING.lives_per_run
	score = 0.0
	kills = 0
	combo = 0
	slivers_run = 0
	_sliver_streak = 0
	_sliver_ms = -10000
	streak_count = 0
	streak_mult = 1
	meter_shards = 0
	run_speed = TUNING.run_speed_start
	_run_origin_ms = Time.get_ticks_msec()
	_slowmo_until = 0
	_hitstop_until = 0
	_last_x = player.global_position.x
	controls.enabled = true
	hud.show_start(false)
	hud.hide_game_over()
	hud.set_lives(lives)
	hud.set_combo(0, false)
	hud.set_slivers(0, false)
	hud.set_streak(1, false)
	hud.set_meter(0.0)
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
	var points := TUNING.kill_points * combo * streak_mult
	score += points
	kills += 1
	audio.play("attack", 0.0, -1.0)
	audio.play("kill", min(combo, 10) * 0.025, -3.0)
	_spawn_popup(at + Vector2(0, -28), "+%d" % points)
	_spawn_impact(at)
	_shake(TUNING.shake_strength)
	_flash_a = max(_flash_a, 0.55)
	# Overdrive smashes through a line. Hit-stop would stutter the blast.
	if player == null or not player.overdriving:
		_start_hitstop()
	player.on_attack_impact()
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
	# One run, one score. A life lost does not write this value.
	var held := score
	_release_hitstop()
	lives -= 1
	combo = 0
	_break_streak()
	if track != null:
		track.take_misses()
	hud.set_lives(lives)
	hud.set_combo(0, false)
	hud.set_score(held)
	audio.play("death")
	_shake(TUNING.shake_strength * 0.85)
	_death_flash = maxf(_death_flash, TUNING.death_flash)
	if fell:
		var view := get_viewport().get_visible_rect().size
		var visible_bottom := camera.global_position.y + view.y * 0.5 - 70.0
		if player.global_position.y > visible_bottom:
			player.global_position.y = visible_bottom
	_spawn_shatter(player.global_position + Vector2(10.0, -TUNING.player_height * 0.45))
	var now := Time.get_ticks_msec()
	_slowmo_until = now + int(TUNING.death_slowmo_seconds * 1000.0)
	Engine.time_scale = TUNING.death_slowmo_scale
	if lives <= 0:
		_game_over()
	else:
		state = RESPAWN
		player.begin_death(fell)
		controls.enabled = false
		_respawn_until = now + int(TUNING.respawn_delay * 1000.0)


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
	_restart_locked_until = Time.get_ticks_msec() + TUNING.restart_lock_ms
	var final_score := int(score)
	if final_score > best:
		best = final_score
	_save_progress()
	hud.show_game_over(final_score, kills, best, slivers_run, slivers_lifetime)


func _finish_respawn() -> void:
	_slowmo_until = 0
	Engine.time_scale = 1.0
	var elapsed := _run_elapsed()
	var look_ahead := player.global_position.x + 520.0
	track.update(look_ahead, maxf(run_speed, TUNING.run_speed_start), TUNING.density_for_time(elapsed))
	var spot := track.find_respawn(player.global_position.x + 70.0)
	track.clear_near(spot, 240.0)
	player.respawn_at(spot)
	state = PLAYING
	_last_x = player.global_position.x
	controls.enabled = true
	run_speed = TUNING.speed_for_time(elapsed)
	hud.set_score(score)


func _build() -> void:
	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	var backdrop = preload("res://scripts/backdrop.gd").new()
	backdrop.name = "Backdrop"
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

	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 9
	fx_layer.name = "SliverFX"
	add_child(fx_layer)
	_fx = preload("res://scripts/sliver_fx.gd").new()
	fx_layer.add_child(_fx)

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

	var clock := BeatClock.new()
	clock.name = "BeatClock"
	clock.process_mode = Node.PROCESS_MODE_ALWAYS
	clock.host = self
	add_child(clock)


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
	if TUNING.hit_stop_time_scale <= 0.001:
		get_tree().paused = true
	else:
		Engine.time_scale = TUNING.hit_stop_time_scale


func _release_hitstop() -> void:
	_hitstop_until = 0
	if get_tree().paused and not _focus_paused:
		get_tree().paused = false
	if Time.get_ticks_msec() >= _slowmo_until:
		Engine.time_scale = 1.0


func _tick_real() -> void:
	var now := Time.get_ticks_msec()
	var step := clampf((now - _clock_ms) / 1000.0, 0.0, 0.05)
	_clock_ms = now
	if _hitstop_until > 0 and now >= _hitstop_until:
		_release_hitstop()
	if state == RESPAWN and now >= _respawn_until:
		_finish_respawn()
	if now < _slowmo_until and _hitstop_until <= 0 and not get_tree().paused:
		Engine.time_scale = TUNING.death_slowmo_scale
	elif _hitstop_until <= 0 and now >= _slowmo_until and Engine.time_scale < 0.999 and not get_tree().paused:
		Engine.time_scale = 1.0
	_update_shake()
	if _death_flash > 0.0:
		_death_flash = maxf(0.0, _death_flash - step * 4.4)


func _shake(amount: float) -> void:
	_shake_mag = maxf(_shake_mag, amount)
	_shake_until = maxi(_shake_until, Time.get_ticks_msec() + int(TUNING.shake_duration * 1000.0))


func _update_shake() -> void:
	var now := Time.get_ticks_msec()
	if camera == null:
		return
	if now < _shake_until:
		var remain := float(_shake_until - now) / 1000.0
		var strength := _shake_mag * clampf(remain / maxf(TUNING.shake_duration, 0.05), 0.0, 1.0)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	else:
		camera.offset = Vector2.ZERO
		_shake_mag = 0.0


func _update_flash(delta: float) -> void:
	_flash_a = move_toward(_flash_a, 0.0, delta * 2.2)
	_hurt_a = move_toward(_hurt_a, 0.0, delta * 2.4)
	if _death_flash > 0.02:
		_flash.color = Color(1, 1, 1, _death_flash)
	elif _flash_a >= _hurt_a:
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


func _spawn_shatter(at: Vector2) -> void:
	var node = preload("res://scripts/shatter.gd").new()
	node.position = at
	_world_fx.add_child(node)


class BeatClock extends Node:
	var host: RunRoot

	func _process(_delta: float) -> void:
		if host != null:
			host._tick_real()


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


func _load_progress() -> void:
	var file := ConfigFile.new()
	if file.load("user://sora_progress.cfg") == OK:
		best = int(file.get_value("run", "best", 0))
		slivers_lifetime = int(file.get_value("slivers", "lifetime", 0))
		return
	var legacy := ConfigFile.new()
	if legacy.load("user://glassfall_best.cfg") == OK:
		best = int(legacy.get_value("run", "best", 0))


func _save_progress() -> void:
	var file := ConfigFile.new()
	file.set_value("run", "best", best)
	file.set_value("slivers", "lifetime", slivers_lifetime)
	file.save("user://sora_progress.cfg")


func _collect_slivers() -> void:
	if player == null or track == null:
		return
	var center := player.global_position + Vector2(24.0, -96.0)
	var hits := track.collect_along(center)
	if hits.is_empty():
		return
	var now := Time.get_ticks_msec()
	for at in hits:
		_sliver_streak += 1
		_sliver_ms = now
		slivers_run += 1
		slivers_lifetime += 1
		streak_count += 1
		var next_mult := _multiplier_for(streak_count)
		var stepped := next_mult > streak_mult
		streak_mult = next_mult
		meter_shards = mini(meter_shards + 1, maxi(TUNING.dash_meter_shards, 1))
		var step := float(mini(streak_count - 1, 7)) * 0.07
		if audio != null:
			audio.play("chime", step, -6.0)
		hud.set_slivers(slivers_run, true)
		hud.set_streak(streak_mult, stepped)
		hud.set_meter(meter_ratio())
		if _fx != null:
			_fx.play(_screen_of(at), hud.sliver_anchor())
	_save_progress()


func meter_ratio() -> float:
	return clampf(float(meter_shards) / float(maxi(TUNING.dash_meter_shards, 1)), 0.0, 1.0)


func meter_full() -> bool:
	return meter_shards >= maxi(TUNING.dash_meter_shards, 1)


func spend_meter() -> void:
	meter_shards = 0
	if hud != null:
		hud.set_meter(0.0)


func _multiplier_for(count: int) -> int:
	if count >= TUNING.streak_x5:
		return 5
	if count >= TUNING.streak_x4:
		return 4
	if count >= TUNING.streak_x3:
		return 3
	if count >= TUNING.streak_x2:
		return 2
	return 1


func _break_streak() -> void:
	if streak_count == 0 and streak_mult == 1:
		return
	streak_count = 0
	streak_mult = 1
	_sliver_streak = 0
	if hud != null:
		hud.set_streak(1, false)


func _screen_of(world_pos: Vector2) -> Vector2:
	var view := get_viewport().get_visible_rect().size
	var cam := camera.global_position
	if camera:
		cam += camera.offset
	return world_pos - cam + view * 0.5


func _apply_world_title(force: bool) -> void:
	var world: WorldBackdrop = null
	var backdrop := get_node_or_null("World/Backdrop")
	if backdrop != null and backdrop.get("far_track") != null and backdrop.far_track.center_world != null:
		world = backdrop.far_track.center_world
	if world == null:
		world = preload("res://assets/worlds/world_loop.tres").starting_world()
	if world == null:
		return
	if not force and world.world_id == _world_shown:
		return
	_world_shown = world.world_id
	hud.set_world(world.display_name, world.guardian_name)
