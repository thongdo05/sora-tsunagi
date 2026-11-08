class_name GlassTrack
extends Node2D

const TUNING := preload("res://assets/tuning/game_tuning.tres")

var platforms: Array[GlassPlatform] = []
var monsters: Array[GlassMonster] = []
var next_x: float = 0.0
var last_y: float = 820.0
var last_monster_x: float = -10000.0
var platform_index: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	last_y = TUNING.ground_y
	_add_platform(0.0, TUNING.ground_y, TUNING.starter_width)
	next_x = TUNING.starter_width


func update(focus_x: float, speed: float, density: float = 0.0) -> void:
	var target := focus_x + TUNING.spawn_ahead
	var guard := 0
	while next_x < target and guard < 12:
		guard += 1
		var gap := _next_gap(speed, platform_index)
		var width := _rng.randf_range(TUNING.platform_min_width, TUNING.platform_max_width)
		if platform_index < 2:
			width = max(width, 900.0)
		elif _rng.randf() < TUNING.short_platform_chance:
			if _rng.randf() < 0.46:
				width = TUNING.buoy_width + _rng.randf_range(-18.0, 28.0)
			else:
				width = TUNING.plank_width + _rng.randf_range(-36.0, 48.0)
		var top := _next_top()
		next_x += gap
		_add_platform(next_x, top, width)
		_maybe_monster(next_x, top, width, density)
		next_x += width
		last_y = top
		platform_index += 1
	_despawn(focus_x - TUNING.despawn_behind)


func surface_at(x: float) -> float:
	var best := INF
	for platform in platforms:
		if not is_instance_valid(platform):
			continue
		var left := platform.global_position.x
		if left - 6.0 <= x and x <= left + platform.width + 6.0:
			best = min(best, platform.global_position.y)
	return best


func nearest_live_monster(from: Vector2, max_dx: float) -> GlassMonster:
	var best: GlassMonster = null
	var best_dx := max_dx
	for monster in monsters:
		if not is_instance_valid(monster) or not monster.can_be_hit():
			continue
		var dx := monster.center().x - from.x
		if dx < 10.0 or dx > best_dx:
			continue
		if abs(monster.center().y - (from.y - 70.0)) > 150.0:
			continue
		best = monster
		best_dx = dx
	return best


func find_respawn(from_x: float) -> Vector2:
	var chosen: GlassPlatform = null
	var fallback: GlassPlatform = null
	for platform in platforms:
		if not is_instance_valid(platform):
			continue
		var left := platform.global_position.x
		var right := left + platform.width
		if right < from_x + 48.0 or platform.width < 240.0:
			continue
		if fallback == null or left < fallback.global_position.x:
			fallback = platform
		if _monster_near(left + minf(120.0, platform.width * 0.3), platform.global_position.y, 160.0):
			continue
		if chosen == null or left < chosen.global_position.x:
			chosen = platform
	if chosen == null:
		chosen = fallback
	if chosen == null and platforms.size() > 0:
		chosen = platforms[platforms.size() - 1]
	if chosen == null:
		return Vector2(from_x + 240.0, TUNING.ground_y - 6.0)
	var stand_x: float = chosen.global_position.x + minf(140.0, chosen.width * 0.28)
	return Vector2(stand_x, chosen.global_position.y - 6.0)


func clear_near(spot: Vector2, radius: float) -> void:
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		if monster.global_position.distance_to(spot) <= radius:
			monster.shatter()


func _monster_near(x: float, y: float, radius: float) -> bool:
	var spot := Vector2(x, y)
	for monster in monsters:
		if not is_instance_valid(monster) or not monster.can_be_hit():
			continue
		if monster.global_position.distance_to(spot) <= radius:
			return true
	return false


func _add_platform(x: float, y: float, width: float) -> void:
	var platform := GlassPlatform.new()
	platform.position = Vector2(x, y)
	platform.setup(width, TUNING.platform_thickness)
	add_child(platform)
	platforms.append(platform)


func _maybe_monster(x: float, y: float, width: float, density: float) -> void:
	if x < TUNING.first_quiet_distance or platform_index < 1:
		return
	if width < 300.0:
		return
	var crowded: float = lerpf(TUNING.min_monster_gap_start, TUNING.min_monster_gap_end, clampf(density, 0.0, 1.0))
	if x - last_monster_x < crowded:
		return
	var chance := lerpf(TUNING.monster_chance_start, TUNING.monster_chance_max, clampf(density, 0.0, 1.0))
	if _rng.randf() > chance:
		return
	var room: float = maxf(40.0, width - TUNING.landing_pocket - 70.0)
	var mx := x + TUNING.landing_pocket + _rng.randf_range(0.0, room)
	var flyer := _rng.randf() < TUNING.flyer_chance
	var my := y - TUNING.flyer_height if flyer else y
	var monster := GlassMonster.new()
	monster.position = Vector2(mx, my)
	monster.setup(flyer)
	add_child(monster)
	monsters.append(monster)
	last_monster_x = mx


func _next_gap(speed: float, index: int) -> float:
	var air := TUNING.jump_air_time()
	var reach: float = maxf(TUNING.gap_absolute_min, speed * air)
	var low := TUNING.gap_reach_min
	var high := TUNING.gap_reach_max
	if index < 3:
		high = min(high, 0.40)
	elif _rng.randf() < TUNING.long_gap_chance:
		low = TUNING.gap_reach_max
		high = TUNING.gap_reach_long
	return clampf(_rng.randf_range(reach * low, reach * high), TUNING.gap_absolute_min, TUNING.gap_absolute_max)


func _next_top() -> float:
	var step := _rng.randf_range(-TUNING.step_down_max, TUNING.step_up_max)
	return clampf(last_y + step, TUNING.platform_y_min, TUNING.platform_y_max)


func _despawn(limit_x: float) -> void:
	var kept_platforms: Array[GlassPlatform] = []
	for platform in platforms:
		if not is_instance_valid(platform):
			continue
		if platform.global_position.x + platform.width < limit_x:
			platform.queue_free()
		else:
			kept_platforms.append(platform)
	platforms = kept_platforms
	var kept_monsters: Array[GlassMonster] = []
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		if monster.global_position.x < limit_x:
			monster.queue_free()
		else:
			kept_monsters.append(monster)
	monsters = kept_monsters
