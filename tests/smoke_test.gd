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
	print("BOT score=%s kills=%s lives=%s state=%s platforms=%s monsters=%s slivers=%s" % [
		int(run.score), run.kills, run.lives, run.state, run.track.platforms.size(), run.track.monsters.size(), run.slivers_run
	])
	if run.hud.world_title() != "MOONHELD":
		_fail("world title is %s" % run.hud.world_title())
	if run.track.slivers.is_empty() and run.slivers_run < 1:
		_fail("no sky slivers were placed")
	if run.slivers_run < 1 and not run.track.slivers.is_empty():
		run.player.global_position = run.track.slivers[0].global_position + Vector2(0, 90)
		await process_frame
		await process_frame
	if run.slivers_run < 1:
		_fail("a sliver on the player was not collected")
	if run.slivers_lifetime < run.slivers_run:
		_fail("lifetime slivers did not keep the run count")
	if run.score <= 0.0:
		_fail("score did not increase")
	var pace := preload("res://assets/tuning/game_tuning.tres")
	var speed_early := pace.speed_for_time(0.0)
	var speed_mid := pace.speed_for_time(pace.pace_ramp_seconds * 0.67)
	var speed_end := pace.speed_for_time(pace.pace_ramp_seconds)
	if speed_end < speed_early * 1.6:
		_fail("speed ramp too flat %s -> %s" % [speed_early, speed_end])
	if speed_mid <= speed_early + 40.0:
		_fail("speed has not climbed by two thirds of the ramp")
	if pace.density_for_time(pace.pace_ramp_seconds) < 0.99:
		_fail("density curve does not reach the end of the ramp")
	if pace.hit_stop_ms < 60 or pace.hit_stop_ms > 90:
		_fail("hit stop %sms is outside the felt range" % pace.hit_stop_ms)
	_check_backdrop(run)
	if run.state == RunRoot.GAME_OVER:
		run.state = RunRoot.PLAYING
	run.lives = maxi(run.lives, 2)
	run.player.invuln = 0.0
	run.player.locked = false
	if run.state == RunRoot.PLAYING:
		run.score = 2433
		run.hud.set_score(run.score)
		var shown_before: String = run.hud.score_text
		run.debug_lose_life()
		if int(run.score) != 2433:
			_fail("score changed on the death frame %s" % run.score)
		if shown_before != "2,433" or run.hud.score_text != "2,433":
			_fail("score label reset on death (%s -> %s)" % [shown_before, run.hud.score_text])
		var started := Time.get_ticks_msec()
		while run.state == RunRoot.RESPAWN and Time.get_ticks_msec() - started < 4000:
			await physics_frame
		if run.state != RunRoot.PLAYING:
			_fail("respawn did not return to play (state=%s)" % run.state)
		elif int(run.score) < 2433:
			_fail("score dropped across respawn to %s" % int(run.score))
		elif int(str(run.hud.score_text).replace(",", "")) < 2433:
			_fail("hud showed %s after respawn" % run.hud.score_text)
		print("SCORE HELD %s -> %s hud=%s state=%s" % [2433, int(run.score), run.hud.score_text, run.state])
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


func _check_backdrop(run: RunRoot) -> void:
	var loop := load("res://assets/worlds/world_loop.tres") as WorldLoop
	if loop == null or loop.worlds.size() != 3:
		_fail("world loop should be Glassfall, Moonheld, Lanternfall")
		return
	var ids: Array[String] = []
	for world in loop.worlds:
		ids.append(world.world_id)
	if ids != ["glassfall", "moonheld", "lanternfall"]:
		_fail("world loop order %s" % str(ids))
	var glass := loop.worlds[0]
	if not glass.far_panels.is_empty():
		_fail("glassfall has no plates yet, found %s" % glass.far_panels.size())
	if loop.start_id != "moonheld":
		_fail("the run should start at moonheld, start_id=%s" % loop.start_id)
	var opening := loop.starting_world()
	if opening == null or opening.world_id != "moonheld" or opening.display_name != "Moonheld":
		_fail("starting world should be named Moonheld")
	elif opening.guardian_name != "Pelagic Regent":
		_fail("Moonheld's guardian should be Pelagic Regent, got %s" % opening.guardian_name)
	if glass.guardian_name != "Meridian Exile" or loop.worlds[2].guardian_name != "Veil Archon":
		_fail("guardian map drifted")
	var moon := loop.worlds[1]
	if moon.far_panels.size() != 6 or moon.mid_panels.size() != 6 or moon.reuses("far"):
		_fail("moonheld should be a 6-panel chain")
	var first: Dictionary = loop.layout("far", 0)
	var second: Dictionary = loop.layout("far", 1)
	var last: Dictionary = loop.layout("far", 5)
	if first.get("texture") == null or first.get("world").world_id != "moonheld":
		_fail("the run should open on the moonheld chain")
	elif bool(first.get("flip")) or bool(second.get("flip")):
		_fail("unique panels should not mirror")
	elif int(second.get("art_x")) != 2304 or int(last.get("art_x")) != 11520:
		_fail("stride art_x %s %s" % [second.get("art_x"), last.get("art_x")])
	elif int(second.get("src_w")) != 2304 or int(last.get("src_w")) != 2816:
		_fail("panel crop %s %s" % [second.get("src_w"), last.get("src_w")])
	var tex: Texture2D = first.get("texture")
	var long := WorldBackdrop.new()
	long.world_id = "glassfall-long"
	long.reuse_until = 4
	long.far_panels = [tex, tex, tex, tex]
	var nxt := WorldBackdrop.new()
	nxt.world_id = "moonheld-next"
	nxt.reuse_until = 4
	nxt.far_panels = [tex]
	var chain := WorldLoop.new()
	chain.worlds = [long, nxt]
	var at_end: Dictionary = chain.resolve("far", 3)
	var handed: Dictionary = chain.resolve("far", 4)
	if str(at_end.get("world").world_id) != "glassfall-long":
		_fail("panel 3 should stay on the first world")
	elif str(handed.get("world").world_id) != "moonheld-next":
		_fail("panel 4 should cross into the next world, got %s" % handed.get("world").world_id)
	var backdrop: Node = run.get_node_or_null("World/Backdrop")
	if backdrop == null or backdrop.get("far_track") == null:
		_fail("backdrop track is missing")
		return
	var view := run.get_viewport().get_visible_rect().size
	backdrop.far_track.update(view, Vector2(280000, 500), 0.0)
	var live: Array = backdrop.far_track.live_indices()
	if live.is_empty() or int(live[0]) < 2:
		_fail("panels behind the camera were not freed %s" % str(live))
	elif int(live[live.size() - 1]) <= int(live[0]):
		_fail("track did not keep a span of panels %s" % str(live))


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL ", message)


func TUNING_LIVES() -> int:
	return preload("res://assets/tuning/game_tuning.tres").lives_per_run
