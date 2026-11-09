class_name GlassPuppet
extends Node2D

## Cutout parts posed like a parkour sprint. Both arms are the same skin limb.
## The punching forearm turns black only while coat > 0.

const TUNING := preload("res://assets/tuning/game_tuning.tres")
const TORSO_TEX := preload("res://assets/sprites/parts/torso.png")
const HEAD_TEX := preload("res://assets/sprites/parts/head.png")
const UPPER_TEX := preload("res://assets/sprites/parts/upper_arm.png")
const FORE_TEX := preload("res://assets/sprites/parts/forearm.png")
const THIGH_TEX := preload("res://assets/sprites/parts/thigh.png")
const SHIN_TEX := preload("res://assets/sprites/parts/shin.png")

const DASH_ANIM_LENGTH := 0.34
const CELL := 512.0
const FOOT := Vector2(256, 496)
const BODY_PX := 360.0
const JUMP_SHEET := preload("res://assets/sprites/sheets/pirate_jump_8f.png")
const FLIP_SHEET := preload("res://assets/sprites/sheets/pirate_flip_8f.png")
## Front flip for the air jump only. Holds match the sheet: 70, 50, 50, 50, 50, 60, 70, 100 ms.
const FLIP_MS: Array[int] = [70, 50, 50, 50, 50, 60, 70, 100]
## Silhouette center of each flip cell. The lock keeps that center still; physics owns the arc.
const FLIP_CENTER_Y: Array[float] = [362.2, 332.7, 347.4, 362.8, 336.3, 317.9, 268.8, 200.3]
const FLIP_LOCK_Y := 316.05
const OD_ENTRY_SHEET := preload("res://assets/sprites/sheets/pirate_overdrive_entry_2f.png")
const OD_LOOP_SHEET := preload("res://assets/sprites/sheets/pirate_overdrive_loop_8f.png")
const OD_ENTRY_MS: Array[int] = [60, 50]
const OD_LOOP_MS := 55
## Ground anticipation stays the short plant. This is only the push-off pose after the feet leave.
const JUMP_TAKEOFF_AIR := 0.070
## Landing art: fall contact 60ms, absorb 110ms, recover 160ms. Then the run crossfades back.
const LAND_CONTACT := 0.060
const LAND_ABSORB := 0.170
const DASH_SHEET := preload("res://assets/sprites/sheets/pirate_dash_punch_7f.png")
const ROLL_SHEET := preload("res://assets/sprites/sheets/pirate_roll_4f.png")
const RUN_SHEET := preload("res://assets/sprites/sheets/pirate_run_12f.png")
## Native stride: 12 frames in 0.417 s, about 28.8 fps. Scaled with run speed.
const RUN_FRAMES := 12
const RUN_NATIVE_SEC := 0.417
const RUN_FPS_FLOOR := 20.0
const RUN_FPS_CAP := 32.0

var fist_anchor: Node2D
var coat_material: ShaderMaterial

var _anim: AnimationPlayer
var _punch_fore: Node2D
var _hip: Node2D
var _impact := 0.0
var _state := ""
var _phase := 0.0
var _overdrive_time := 0.0
var _flip_active := false
var _flip_time := 0.0
var _frame := -1
var _blend := 1.0
var _rig_mix := 1.0
var _sheet: Sprite2D
var _sheet_prev: Sprite2D
var _sheet_bolts: Bolts
var _sheet_scale := 1.0
var _speed_ratio := 1.0
var _run_time := 0.0
var _vy := 0.0
var _air_time := 0.0
var _land_time := 0.0


func _ready() -> void:
	var figure := TUNING.player_height / 200.0
	scale = Vector2(0.312, 0.312) * figure
	_build()
	_build_anims()
	_build_sheet()
	if _hip:
		_hip.visible = false
	play_state("run", 1.0)


func set_phase(phase: float) -> void:
	_phase = clampf(phase, 0.0, 1.0)


func set_vertical(vy: float) -> void:
	_vy = vy


func play_state(state: String, speed_ratio: float) -> void:
	_speed_ratio = maxf(speed_ratio, 0.0)
	if _state != state:
		if state == "overdrive":
			_overdrive_time = 0.0
		if state == "double":
			_flip_active = true
			_flip_time = 0.0
		if state == "land" or state == "roll" or state == "run" or state == "dash" or state == "overdrive" or state == "takeoff":
			_flip_active = false
		_state = state
		_blend = 0.0
	if _hip:
		_hip.visible = false
	if _anim.is_playing():
		_anim.pause()
	_apply_sheet_frame()


func set_coat(amount: float) -> void:
	if coat_material:
		coat_material.set_shader_parameter("coat", amount)


func impact() -> void:
	_impact = 1.0
	if _punch_fore:
		_punch_fore.modulate = Color(1.0, 0.78, 0.7)
		_punch_fore.scale = Vector2(1.2, 0.84)


func fist_global() -> Vector2:
	if fist_anchor == null:
		return global_position
	return fist_anchor.global_position


func _process(delta: float) -> void:
	if _state == "run":
		_run_time += delta * _run_rate()
	if _state == "overdrive":
		_overdrive_time += delta
	if _flip_active and (_state == "double" or _state == "rise" or _state == "apex" or _state == "fall"):
		_flip_time += delta
	if _jumping():
		_air_time += delta
	else:
		_air_time = 0.0
	if _state == "land":
		_land_time += delta
	else:
		_land_time = 0.0
	if _hip:
		_hip.visible = false
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / 0.08)
	_apply_sheet_frame()
	_layout_sheet()
	if _impact > 0.0:
		_impact = maxf(0.0, _impact - delta * 8.0)
		_punch_fore.modulate = Color(1.0, 0.82, 0.75).lerp(Color.WHITE, 1.0 - _impact)
		var pop := 1.0 + _impact * 0.18
		_punch_fore.scale = Vector2(pop, 1.0 / pop)
	elif _state != "dash" and _state != "overdrive":
		_punch_fore.modulate = Color.WHITE


func _build() -> void:
	# Image-space layout. Feet of the original cut sit at the rig origin.
	var feet := Vector2(520, 590)
	var hip_at := Vector2(420, 490)
	var hip := Node2D.new()
	hip.name = "hip"
	hip.position = hip_at - feet
	add_child(hip)
	_hip = hip

	# Legs go on first so the coat covers the joint. The pivots sit inside the pant cuff.
	var back_thigh := _leg("back_thigh", THIGH_TEX, Vector2(-42, -14))
	var back_shin := _leg("back_shin", SHIN_TEX, Vector2(2, 20))
	back_thigh.add_child(back_shin)
	hip.add_child(back_thigh)

	var front_thigh := _leg("front_thigh", THIGH_TEX, Vector2(30, -14))
	var front_shin := _leg("front_shin", SHIN_TEX, Vector2(2, 20))
	front_thigh.add_child(front_shin)
	hip.add_child(front_thigh)

	# Rotate the coat around the hip, not the top-left of the texture, or the hem leaves the boots.
	var torso_pivot := Node2D.new()
	torso_pivot.name = "torso_pivot"
	hip.add_child(torso_pivot)
	var torso := Sprite2D.new()
	torso.name = "torso"
	torso.texture = TORSO_TEX
	torso.centered = false
	torso.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	torso.position = Vector2(2, 47) - hip_at
	torso_pivot.add_child(torso)

	var head_pivot := Node2D.new()
	head_pivot.name = "head_pivot"
	head_pivot.position = Vector2(400, 180) - hip_at
	hip.add_child(head_pivot)
	var head := Sprite2D.new()
	head.name = "head"
	head.texture = HEAD_TEX
	head.centered = false
	head.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	head.position = Vector2(255, 10) - Vector2(400, 180)
	head_pivot.add_child(head)

	var off_upper := _arm("off_upper", UPPER_TEX, Vector2(340, 230) - hip_at, false)
	var off_fore := _arm("off_fore", FORE_TEX, Vector2(UPPER_TEX.get_width() - 8, 8), false)
	off_upper.add_child(off_fore)
	hip.add_child(off_upper)

	var punch_upper := _arm("punch_upper", UPPER_TEX, Vector2(500, 220) - hip_at, false)
	_punch_fore = _arm("punch_fore", FORE_TEX, Vector2(UPPER_TEX.get_width() - 10, 6), true)
	punch_upper.add_child(_punch_fore)
	hip.add_child(punch_upper)

	fist_anchor = Node2D.new()
	fist_anchor.name = "fist_anchor"
	fist_anchor.position = Vector2(FORE_TEX.get_width() - 8, FORE_TEX.get_height() * 0.45)
	_punch_fore.add_child(fist_anchor)
	var bolts := Bolts.new()
	bolts.name = "bolts"
	bolts.puppet = self
	_punch_fore.add_child(bolts)

	_anim = AnimationPlayer.new()
	_anim.name = "anim"
	add_child(_anim)
	_anim.root_node = NodePath("..")


func _leg(node_name: String, texture: Texture2D, at: Vector2) -> Node2D:
	var pivot := Node2D.new()
	pivot.name = node_name
	pivot.position = at
	var sprite := Sprite2D.new()
	sprite.name = "sprite"
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# The top of the limb tucks under the coat. The rest hangs toward the next joint.
	sprite.position = Vector2(-texture.get_width() * 0.42, -16.0)
	pivot.add_child(sprite)
	return pivot


func _arm(node_name: String, texture: Texture2D, at: Vector2, coated: bool) -> Node2D:
	var pivot := Node2D.new()
	pivot.name = node_name
	pivot.position = at
	var sprite := Sprite2D.new()
	sprite.name = "sprite"
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = Vector2(0, -texture.get_height() * 0.5)
	if coated:
		coat_material = ShaderMaterial.new()
		coat_material.shader = preload("res://shaders/coat_skin.gdshader")
		coat_material.set_shader_parameter("coat", 0.0)
		sprite.material = coat_material
	pivot.add_child(sprite)
	return pivot


func _build_anims() -> void:
	var library := AnimationLibrary.new()
	library.add_animation("run", _run_anim())
	library.add_animation("takeoff", _takeoff_anim())
	library.add_animation("rise", _air_anim("rise", true))
	library.add_animation("apex", _air_anim("apex", false))
	library.add_animation("fall", _fall_anim())
	library.add_animation("land", _land_anim())
	library.add_animation("roll", _roll_anim())
	library.add_animation("double", _double_anim())
	library.add_animation("dash", _dash_anim())
	_anim.add_animation_library("", library)


func _new_anim(length: float, looping: bool) -> Animation:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	return anim


func _keys(anim: Animation, path: String, keys: Array) -> void:
	var idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(idx, NodePath(path))
	anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_CUBIC)
	for item in keys:
		anim.track_insert_key(idx, item[0], item[1])


func _run_anim() -> Animation:
	var anim := _new_anim(0.48, true)
	# High knees, forward lean, arms driving opposite the legs. Contact at 0 and 0.24.
	_keys(anim, "hip:rotation", [[0.0, 0.0], [0.48, 0.0]])
	_keys(anim, "hip:position:y", [[0.0, -108.0], [0.12, -118.0], [0.24, -106.0], [0.36, -118.0], [0.48, -108.0]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, -0.22], [0.24, -0.16], [0.48, -0.22]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, 0.08], [0.24, 0.04], [0.48, 0.08]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, -0.95], [0.12, -0.15], [0.24, 0.85], [0.36, 0.05], [0.48, -0.95]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 0.35], [0.12, 1.15], [0.24, 0.25], [0.36, 0.9], [0.48, 0.35]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, 0.85], [0.12, 0.05], [0.24, -0.95], [0.36, -0.15], [0.48, 0.85]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 0.25], [0.12, 0.9], [0.24, 0.35], [0.36, 1.15], [0.48, 0.25]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, 0.7], [0.24, -0.85], [0.48, 0.7]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.55], [0.24, 0.25], [0.48, 0.55]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.48, Vector2.ONE]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, -0.85], [0.24, 0.7], [0.48, -0.85]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.25], [0.24, 0.55], [0.48, 0.25]])
	return anim


func _takeoff_anim() -> Animation:
	var anim := _new_anim(0.07, false)
	_keys(anim, "hip:rotation", [[0.0, 0.0], [0.07, 0.0]])
	_keys(anim, "hip:position:y", [[0.0, -158.0], [0.035, -144.0], [0.07, -166.0]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, -0.16], [0.035, -0.34], [0.07, -0.08]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, 0.05], [0.07, -0.06]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, 0.2], [0.035, 0.7], [0.07, -0.4]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 0.4], [0.035, 1.3], [0.07, 0.5]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, -0.2], [0.035, 0.45], [0.07, -0.9]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 0.5], [0.035, 1.2], [0.07, 0.3]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, 0.4], [0.035, 0.9], [0.07, -1.3]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.4], [0.07, 0.15]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.07, Vector2.ONE]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, -0.3], [0.035, 0.5], [0.07, -1.2]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.4], [0.07, 0.2]])
	return anim


func _air_anim(kind: String, tucked: bool) -> Animation:
	var anim := _new_anim(0.2, true)
	var thigh := 0.85 if tucked else 0.25
	var shin := 1.35 if tucked else 0.45
	var lean := -0.05 if tucked else 0.02
	_keys(anim, "hip:rotation", [[0.0, 0.0], [0.2, 0.0]])
	_keys(anim, "hip:position:y", [[0.0, -166.0], [0.2, -166.0]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, lean], [0.2, lean]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, -0.04], [0.2, -0.04]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, thigh], [0.2, thigh]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, shin], [0.2, shin]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, thigh * 0.85], [0.2, thigh * 0.85]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, shin], [0.2, shin]])
	var arms := -1.35 if tucked else -0.6
	_keys(anim, "hip/punch_upper:rotation", [[0.0, arms], [0.2, arms]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, arms], [0.2, arms]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.2], [0.2, 0.2]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.2, Vector2.ONE]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.2], [0.2, 0.2]])
	return anim


func _fall_anim() -> Animation:
	var anim := _new_anim(0.24, true)
	_keys(anim, "hip:position:y", [[0.0, -160.0], [0.24, -160.0]])
	_keys(anim, "hip:rotation", [[0.0, 0.12], [0.24, 0.12]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, 0.08], [0.24, 0.08]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, 0.1], [0.24, 0.1]])
	# Legs reach for the landing.
	_keys(anim, "hip/front_thigh:rotation", [[0.0, -0.55], [0.24, -0.55]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 0.35], [0.24, 0.35]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, -0.15], [0.24, -0.15]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 0.7], [0.24, 0.7]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, 0.4], [0.24, 0.4]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, -0.2], [0.24, -0.2]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.45], [0.24, 0.45]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.24, Vector2.ONE]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.4], [0.24, 0.4]])
	return anim


func _land_anim() -> Animation:
	var anim := _new_anim(0.16, false)
	_keys(anim, "hip:rotation", [[0.0, 0.0], [0.16, 0.0]])
	_keys(anim, "hip:position:y", [[0.0, -136.0], [0.08, -144.0], [0.16, -158.0]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, -0.28], [0.16, -0.18]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, 0.12], [0.16, 0.06]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, 0.55], [0.16, 0.1]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 1.45], [0.16, 0.5]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, 0.35], [0.16, -0.2]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 1.3], [0.16, 0.45]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, -0.4], [0.16, 0.3]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, 0.2], [0.16, -0.4]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.7], [0.16, 0.4]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.16, Vector2.ONE]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.6], [0.16, 0.35]])
	return anim


func _roll_anim() -> Animation:
	var anim := _new_anim(0.36, false)
	_keys(anim, "hip:position:y", [[0.0, -138.0], [0.12, -68.0], [0.24, -58.0], [0.36, -158.0]])
	_keys(anim, "hip:rotation", [[0.0, 0.2], [0.12, -1.6], [0.24, -3.4], [0.36, -6.2]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, -0.4], [0.18, -0.2], [0.36, -0.18]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, 0.3], [0.18, -0.2], [0.36, 0.05]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, 1.0], [0.18, 0.4], [0.36, -0.4]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 1.5], [0.18, 1.2], [0.36, 0.4]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, 0.8], [0.18, 0.3], [0.36, 0.2]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 1.4], [0.18, 1.1], [0.36, 0.4]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, -0.8], [0.36, 0.4]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, 0.6], [0.36, -0.5]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.8], [0.36, 0.4]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.36, Vector2.ONE]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.7], [0.36, 0.35]])
	return anim


func _double_anim() -> Animation:
	var anim := _new_anim(0.42, false)
	# Kick off, tuck, gainer-style rotation, then open toward the landing.
	_keys(anim, "hip:position:y", [[0.0, -166.0], [0.2, -178.0], [0.42, -160.0]])
	_keys(anim, "hip:rotation", [[0.0, 0.0], [0.16, -1.4], [0.32, -3.6], [0.42, -5.2]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, -0.1], [0.16, -0.3], [0.42, 0.05]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, -0.1], [0.2, 0.15], [0.42, 0.08]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, -0.8], [0.12, 1.1], [0.28, 0.9], [0.42, -0.4]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 0.2], [0.12, 1.5], [0.28, 1.3], [0.42, 0.4]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, 0.4], [0.12, 1.0], [0.28, 0.7], [0.42, -0.1]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 0.3], [0.12, 1.45], [0.28, 1.2], [0.42, 0.55]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, -1.4], [0.2, -0.4], [0.42, 0.3]])
	_keys(anim, "hip/off_upper:rotation", [[0.0, -1.2], [0.2, 0.2], [0.42, -0.2]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.15], [0.42, 0.4]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [[0.0, Vector2.ONE], [0.42, Vector2.ONE]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.2], [0.42, 0.4]])
	return anim


func _dash_anim() -> Animation:
	var anim := _new_anim(DASH_ANIM_LENGTH, false)
	# Coil from the run, then the hip and shoulder throw the coated fist forward.
	_keys(anim, "hip:position:y", [[0.0, -158.0], [0.07, -140.0], [0.18, -144.0], [0.34, -158.0]])
	_keys(anim, "hip:rotation", [[0.0, 0.0], [0.07, 0.18], [0.16, -0.15], [0.34, 0.0]])
	_keys(anim, "hip/torso_pivot:rotation", [[0.0, -0.2], [0.07, -0.55], [0.16, -1.15], [0.26, -0.7], [0.34, -0.22]])
	_keys(anim, "hip/head_pivot:rotation", [[0.0, 0.06], [0.08, 0.2], [0.18, -0.05], [0.34, 0.06]])
	_keys(anim, "hip/front_thigh:rotation", [[0.0, -0.4], [0.08, 0.3], [0.18, -0.8], [0.34, -0.5]])
	_keys(anim, "hip/front_thigh/front_shin:rotation", [[0.0, 0.6], [0.08, 1.1], [0.2, 0.35], [0.34, 0.4]])
	_keys(anim, "hip/back_thigh:rotation", [[0.0, 0.5], [0.1, 0.9], [0.22, 0.4], [0.34, 0.3]])
	_keys(anim, "hip/back_thigh/back_shin:rotation", [[0.0, 0.4], [0.12, 1.2], [0.34, 0.45]])
	_keys(anim, "hip/punch_upper:rotation", [[0.0, 0.35], [0.07, 0.95], [0.16, -0.35], [0.28, -0.1], [0.34, 0.45]])
	_keys(anim, "hip/punch_upper/punch_fore:rotation", [[0.0, 0.45], [0.07, 1.05], [0.15, 0.05], [0.26, 0.15], [0.34, 0.5]])
	_keys(anim, "hip/punch_upper/punch_fore:scale", [
		[0.0, Vector2.ONE],
		[0.07, Vector2(0.92, 1.0)],
		[0.16, Vector2(1.75, 0.82)],
		[0.26, Vector2(1.25, 0.92)],
		[0.34, Vector2.ONE],
	])
	_keys(anim, "hip/off_upper:rotation", [[0.0, -0.4], [0.08, 0.7], [0.2, -0.9], [0.34, -0.5]])
	_keys(anim, "hip/off_upper/off_fore:rotation", [[0.0, 0.4], [0.08, 0.9], [0.34, 0.35]])
	return anim


func _build_sheet() -> void:
	var world_scale := (TUNING.player_height * 0.86) / BODY_PX
	_sheet_scale = world_scale / maxf(scale.x, 0.001)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/shirt_match.gdshader")
	_sheet = _make_sheet_sprite(material)
	_sheet_prev = _make_sheet_sprite(material)
	_sheet_prev.z_index = 1
	_sheet.z_index = 2
	_sheet_bolts = Bolts.new()
	_sheet_bolts.puppet = self
	_sheet_bolts.follow_coat = false
	_sheet_bolts.position = Vector2(430, 300)
	_sheet_bolts.z_index = 3
	_sheet.add_child(_sheet_bolts)
	_layout_sheet()


func _make_sheet_sprite(material: ShaderMaterial) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.material = material
	sprite.visible = false
	add_child(sprite)
	return sprite


func _layout_sheet() -> void:
	var squash := 0.0
	if _state == "run":
		var step := _run_phase() * TAU * 2.0
		squash = sin(step) * 0.028
	elif _state == "takeoff":
		squash = -0.07
	elif _state == "land":
		squash = 0.09
	elif _state == "roll":
		squash = 0.05
	var sx := _sheet_scale * (1.0 + squash)
	var sy := _sheet_scale * (1.0 - squash)
	var anchor_y := FOOT.y
	if _sheet != null and _sheet.texture == FLIP_SHEET:
		var idx := clampi(_frame, 0, FLIP_CENTER_Y.size() - 1)
		# Shift the cell so the body center stays put. Do not add the authored jump height.
		anchor_y = FLIP_CENTER_Y[idx] - FLIP_LOCK_Y + FOOT.y
	for sprite in [_sheet, _sheet_prev]:
		if sprite == null:
			continue
		sprite.scale = Vector2(sx, sy)
		sprite.position = Vector2(-FOOT.x * sx, -anchor_y * sy)


func _apply_sheet_frame() -> void:
	if _sheet == null:
		return
	var texture := _texture_for(_state)
	var frame := _frame_for(_state, _phase)
	var count := _frame_count(_state)
	frame = clampi(frame, 0, count - 1)
	var same_sheet := _frame >= 0 and _sheet.texture == texture
	var from_flip := _sheet.texture == FLIP_SHEET
	var overdrive_sheet := texture == OD_ENTRY_SHEET or texture == OD_LOOP_SHEET
	# Run, jump, and flip frames cut. Overdrive cuts between its own sheets.
	# Leaving Overdrive for the run still crossfades.
	var hard_cut := from_flip or overdrive_sheet or (same_sheet and (texture == RUN_SHEET or texture == JUMP_SHEET or texture == FLIP_SHEET))
	if frame != _frame or _sheet.texture != texture:
		if hard_cut:
			_sheet_prev.visible = false
			_blend = 1.0
		else:
			_copy_sheet(_sheet, _sheet_prev)
			_sheet_prev.visible = _frame >= 0 and _sheet.texture != null
			_blend = 0.0
		_frame = frame
	_set_cell(_sheet, texture, frame)
	_sheet.visible = true
	var shown := _blend if _sheet_prev.visible else 1.0
	_sheet.modulate.a = shown
	_sheet_prev.modulate.a = 1.0 - shown
	var punch := _state == "dash" and frame >= 2 and frame <= 5
	if _sheet_bolts:
		_sheet_bolts.visible = punch


func _copy_sheet(src: Sprite2D, dst: Sprite2D) -> void:
	if src.texture == null:
		dst.visible = false
		return
	dst.texture = src.texture
	dst.region_rect = src.region_rect
	dst.visible = true


func _set_cell(sprite: Sprite2D, texture: Texture2D, frame: int) -> void:
	sprite.texture = texture
	sprite.region_rect = Rect2(float(frame) * CELL, 0, CELL, CELL)


func _texture_for(state: String) -> Texture2D:
	if _flip_on_sheet():
		return FLIP_SHEET
	if state == "run":
		return RUN_SHEET
	if state == "dash":
		return DASH_SHEET
	if state == "overdrive":
		if _overdrive_ms() < _ms_sum(OD_ENTRY_MS):
			return OD_ENTRY_SHEET
		return OD_LOOP_SHEET
	if state == "roll":
		return ROLL_SHEET
	return JUMP_SHEET


func _frame_count(state: String) -> int:
	if _flip_on_sheet():
		return 8
	if state == "run":
		return RUN_FRAMES
	if state == "dash":
		return 7
	if state == "overdrive":
		if _overdrive_ms() < _ms_sum(OD_ENTRY_MS):
			return 2
		return 8
	if state == "roll":
		return 4
	return 8


## 1.0 plays the native 28.8 fps stride. Run speed scales it, held between 20 and 32 fps.
func _run_rate() -> float:
	var native := float(RUN_FRAMES) / RUN_NATIVE_SEC
	var fps := clampf(native * _speed_ratio, RUN_FPS_FLOOR, RUN_FPS_CAP)
	return fps / native


func _run_phase() -> float:
	var t := fmod(_run_time / RUN_NATIVE_SEC, 1.0)
	if t < 0.0:
		t += 1.0
	return t


func _frame_for(state: String, phase: float) -> int:
	if _flip_visual():
		return _flip_frame()
	match state:
		"run":
			return int(_run_phase() * float(RUN_FRAMES)) % RUN_FRAMES
		"takeoff", "rise", "apex", "fall", "land", "double":
			return _jump_frame()
		"dash":
			return _marks(phase, [0.0, 0.12, 0.26, 0.42, 0.58, 0.74, 0.86, 1.01])
		"overdrive":
			return _overdrive_frame()
		"roll":
			return _marks(phase, [0.0, 0.16, 0.40, 0.66, 1.01])
		_:
			return 0


func _flip_visual() -> bool:
	return _flip_active and (_state == "double" or _state == "rise" or _state == "apex" or _state == "fall")


func _flip_on_sheet() -> bool:
	return _flip_visual() and _flip_time * 1000.0 < float(_ms_sum(FLIP_MS))


func _flip_frame() -> int:
	var total := float(_ms_sum(FLIP_MS))
	var ms := _flip_time * 1000.0
	if ms < total:
		return _step_index(ms, FLIP_MS)
	# After the flip, fall cells 6 then 7 of jump_8f (0-based 5, then 6). Landing is separate.
	if ms < total + 60.0:
		return 5
	return 6


func _overdrive_frame() -> int:
	var entry := _ms_sum(OD_ENTRY_MS)
	var ms := _overdrive_ms()
	if ms < entry:
		return _step_index(ms, OD_ENTRY_MS)
	return int((ms - entry) / float(OD_LOOP_MS)) % 8


func _overdrive_ms() -> float:
	return _overdrive_time * 1000.0


func _ms_sum(durations: Array[int]) -> int:
	var total := 0
	for duration in durations:
		total += duration
	return total


func _step_index(ms: float, durations: Array[int]) -> int:
	var acc := 0.0
	for i in durations.size():
		acc += float(durations[i])
		if ms < acc:
			return i
	return durations.size() - 1


func _jumping() -> bool:
	return _state == "rise" or _state == "apex" or _state == "fall" or _state == "double"


## Physics owns the height. Frames follow grounded state and vertical speed.
## 0-1 ground anticipation and push-off, 2-4 rise / apex / fall, 5-7 landing.
func _jump_frame() -> int:
	if _state == "takeoff":
		return 0
	if _state == "land":
		if _land_time < LAND_CONTACT:
			return 5
		if _land_time < LAND_ABSORB:
			return 6
		return 7
	# A double jump is already in the air, so it skips the ground push-off pose.
	if _state != "double" and _air_time < JUMP_TAKEOFF_AIR and _vy <= TUNING.apex_speed:
		return 1
	if _vy < -TUNING.apex_speed:
		return 2
	if _vy <= TUNING.apex_speed:
		return 3
	return 4


func _marks(phase: float, edges: Array) -> int:
	var t := clampf(phase, 0.0, 0.999)
	for i in edges.size() - 1:
		if t < float(edges[i + 1]):
			return i
	return edges.size() - 2


class Bolts extends Node2D:
	var puppet
	var follow_coat := true

	func _process(_delta: float) -> void:
		if follow_coat:
			var coat := 0.0
			if puppet and puppet.coat_material:
				coat = float(puppet.coat_material.get_shader_parameter("coat"))
			visible = coat > 0.35
		queue_redraw()

	func _draw() -> void:
		if not visible:
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = int(Time.get_ticks_msec() / 45)
		var reach := 150.0
		for i in 6:
			var points := PackedVector2Array()
			var x := 0.0
			points.append(Vector2(20, 0))
			while x < reach:
				x += rng.randf_range(14, 32)
				points.append(Vector2(20 + x, rng.randf_range(-22, 22)))
			var hot := i % 2 == 0
			var color := Color(1.0, 0.16, 0.07, 0.9) if hot else Color(0.04, 0.01, 0.03, 0.95)
			draw_polyline(points, color, 2.2 if hot else 3.4, true)
