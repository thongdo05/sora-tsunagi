extends SceneTree

## Headless-or-windowed playthrough: bot a run, then burn three lives into game over and restart.

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/run.tscn")
	var run: RunRoot = packed.instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	await physics_frame
	var shot := OS.get_environment("SORA_SCREENSHOT")
	if shot != "":
		await process_frame
		_save(shot.trim_suffix(".png") + "-title.png")
	if run.state != RunRoot.READY:
		_fail("expected the start screen, state=%s" % run.state)
	if run.player == null:
		_fail("player was not created")
		quit(1)
		return
	run.start_run()
	var kills_before := 0
	for i in 520:
		if run.state == RunRoot.GAME_OVER:
			_fail("bot died out before the scripted game over (frame %s, score %s)" % [i, run.score])
			break
		_bot(run)
		await physics_frame
		if i == 40 and shot != "":
			await process_frame
			_save(shot.trim_suffix(".png") + "-grounded.png")
		if i == 240 and shot != "":
			await process_frame
			_save(shot)
		kills_before = run.kills
	print("BOT score=%s kills=%s lives=%s state=%s platforms=%s monsters=%s" % [
		int(run.score), run.kills, run.lives, run.state, run.track.platforms.size(), run.track.monsters.size()
	])
	if run.score <= 0.0:
		_fail("score did not increase")
	if run.track.platforms.size() < 3:
		_fail("track did not generate platforms")
	if run.kills < 1 and run.state == RunRoot.PLAYING:
		var monster := GlassMonster.new()
		monster.position = run.player.global_position + Vector2(90, 0)
		monster.setup(false)
		monster.phase = GlassMonster.Phase.LIVE
		monster.monitorable = true
		monster.monitoring = true
		monster.visible = true
		run.track.add_child(monster)
		run.player.dash_cd = 0.0
		for _i in 20:
			run.controls.dash_pressed = true
			await physics_frame
			if run.kills >= 1:
				break
		print("FORCED kills=%s combo=%s" % [run.kills, run.combo])
		if run.kills < 1:
			_fail("dash did not kill a monster placed on the player")
	# Spend whatever lives are left. The bot may already have dropped one.
	var guard := 0
	while run.state != RunRoot.GAME_OVER and guard < 6:
		guard += 1
		var before := run.lives
		run.debug_lose_life()
		await physics_frame
		if run.state != RunRoot.GAME_OVER and run.lives >= before:
			_fail("life loss did not spend a life (lives=%s state=%s)" % [run.lives, run.state])
			break
	if run.state != RunRoot.GAME_OVER:
		_fail("expected game over, state=%s lives=%s" % [run.state, run.lives])
	if int(run.score) <= 0:
		_fail("game over score was empty")
	var over_path := OS.get_environment("SORA_GAMEOVER")
	if over_path != "":
		for _i in 25:
			await process_frame
		_save(over_path)
	var score_before := int(run.score)
	run.restart()
	await process_frame
	await process_frame
	await physics_frame
	var restarted := current_scene as RunRoot
	if restarted == null:
		_fail("restart did not load the run")
	elif restarted.state != RunRoot.PLAYING:
		_fail("restart should drop straight into a run, state=%s" % restarted.state)
	elif restarted.lives != TUNING_LIVES():
		_fail("restart lives=%s" % restarted.lives)
	elif int(restarted.score) > score_before and score_before > 50:
		# A fresh run can score a few points immediately; it must not keep the old total.
		if int(restarted.score) >= score_before:
			_fail("score carried across restart")
	if _failures.is_empty():
		print("SMOKE OK")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("SMOKE FAIL %s" % _failures.size())
		quit(1)


func _bot(run: RunRoot) -> void:
	var controls: Variant = run.controls
	controls.jump_held = false
	controls.jump_pressed = false
	controls.dash_pressed = false
	if run.state != RunRoot.PLAYING:
		return
	var player := run.player
	var x := player.global_position.x
	var y := player.global_position.y
	var monster := run.track.nearest_live_monster(player.global_position, 220.0)
	if monster != null:
		var dx := monster.center().x - x
		if dx < 200.0 and player.dash_cd <= 0.02:
			controls.dash_pressed = true
			return
		if dx < 130.0 and player.is_on_floor() and player.dash_cd > 0.0:
			controls.jump_pressed = true
			return
	var probe := run.track.surface_at(x + 120.0)
	if player.is_on_floor():
		if is_inf(probe) or probe < y - 24.0:
			controls.jump_pressed = true
	elif player.velocity.y > 40.0:
		var ahead := run.track.surface_at(x + 180.0)
		if is_inf(ahead):
			if player.jumps_left > 0:
				controls.jump_pressed = true
			else:
				controls.jump_held = true


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("screenshot unavailable")
		return
	image.save_png(path)
	print("saved ", path, " ", image.get_width(), "x", image.get_height())


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL ", message)


func TUNING_LIVES() -> int:
	return preload("res://assets/tuning/game_tuning.tres").lives_per_run
