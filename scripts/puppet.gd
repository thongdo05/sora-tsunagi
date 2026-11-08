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
const JUMP_SHEET := preload("res://assets/sprites/sheets/pirate_jump_6f.png")
const DASH_SHEET := preload("res://assets/sprites/sheets/pirate_dash_punch_7f.png")
const ROLL_SHEET := preload("res://assets/sprites/sheets/pirate_roll_4f.png")

var fist_anchor: Node2D
var coat_material: ShaderMaterial

var _anim: AnimationPlayer
var _punch_fore: Node2D
var _hip: Node2D
var _impact := 0.0
var _state := ""
var _phase := 0.0
var _frame := -1
var _blend := 1.0
var _rig_mix := 1.0
var _sheet: Sprite2D
var _sheet_prev: Sprite2D
var _sheet_bolts: Bolts
var _sheet_scale := 1.0


func _ready() -> void:
	var figure := TUNING.player_height / 200.0
	scale = Vector2(0.312, 0.312) * figure
	_build()
	_build_anims()
	_build_sheet()
	play_state("run", 1.0)


func set_phase(phase: float) -> void:
	_phase = clampf(phase, 0.0, 1.0)


func play_state(state: String, speed_ratio: float) -> void:
	var sheeted := state != "run"
	if state == "run":
		if _state != "run":
			_state = "run"
			_frame = -1
			if _anim.has_animation("run"):
				_anim.play("run", 0.08)
		_anim.speed_scale = clampf(speed_ratio, 0.85, 2.1)
		_apply_sheet_frame()
		return
	if _state != state:
		_state = state
		_frame = -1
		_blend = 0.0
	if sheeted:
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
	var rig_target := 1.0 if _state == "run" else 0.0
	_rig_mix = move_toward(_rig_mix, rig_target, delta / 0.08)
	if _hip:
		_hip.modulate.a = _rig_mix
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta / 0.08)
	_apply_sheet_frame()
	_layout_sheet()
	if _impact > 0.0:
		_impact = maxf(0.0, _impact - delta * 8.0)
		_punch_fore.modulate = Color(1.0, 0.82, 0.75).lerp(Color.WHITE, 1.0 - _impact)
		var pop := 1.0 + _impact * 0.18
		_punch_fore.scale = Vector2(pop, 1.0 / pop)
	elif _state != "dash":
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

	var back_thigh := _leg("back_thigh", THIGH_TEX, Vector2(-70, 18))
	var back_shin := _leg("back_shin", SHIN_TEX, Vector2(6, 70))
	back_thigh.add_child(back_shin)
	hip.add_child(back_thigh)

	var torso := Sprite2D.new()
	torso.name = "torso"
	torso.texture = TORSO_TEX
	torso.centered = false
	torso.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	torso.position = Vector2(2, 47) - hip_at
	hip.add_child(torso)

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

	var front_thigh := _leg("front_thigh", THIGH_TEX, Vector2(55, 12))
	var front_shin := _leg("front_shin", SHIN_TEX, Vector2(6, 70))
	front_thigh.add_child(front_shin)
	hip.add_child(front_thigh)

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
	sprite.position = Vector2(-texture.get_width() * 0.5, 0)
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
	_keys(anim, "hip:position:y", [[0.0, -158.0], [0.12, -170.0], [0.24, -156.0], [0.36, -170.0], [0.48, -158.0]])
	_keys(anim, "hip/torso:rotation", [[0.0, -0.22], [0.24, -0.16], [0.48, -0.22]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, -0.16], [0.035, -0.34], [0.07, -0.08]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, lean], [0.2, lean]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, 0.08], [0.24, 0.08]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, -0.28], [0.16, -0.18]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, -0.4], [0.18, -0.2], [0.36, -0.18]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, -0.1], [0.16, -0.3], [0.42, 0.05]])
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
	_keys(anim, "hip/torso:rotation", [[0.0, -0.2], [0.07, -0.55], [0.16, -1.15], [0.26, -0.7], [0.34, -0.22]])
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
	if _state == "takeoff":
		squash = -0.07
	elif _state == "land":
		squash = 0.09
	elif _state == "roll":
		squash = 0.05
	var sx := _sheet_scale * (1.0 + squash)
	var sy := _sheet_scale * (1.0 - squash)
	for sprite in [_sheet, _sheet_prev]:
		if sprite == null:
			continue
		sprite.scale = Vector2(sx, sy)
		sprite.position = Vector2(-FOOT.x * sx, -FOOT.y * sy)


func _apply_sheet_frame() -> void:
	if _sheet == null:
		return
	var sheeted := _state != "run"
	if not sheeted:
		_sheet.visible = false
		_sheet_prev.visible = false
		if _sheet_bolts:
			_sheet_bolts.visible = false
		return
	var texture := _texture_for(_state)
	var frame := _frame_for(_state, _phase)
	var count := _frame_count(_state)
	frame = clampi(frame, 0, count - 1)
	if frame != _frame:
		_copy_sheet(_sheet, _sheet_prev)
		_sheet_prev.visible = _frame >= 0
		_frame = frame
		_blend = 0.0 if _frame >= 0 else 1.0
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
	if state == "dash":
		return DASH_SHEET
	if state == "roll":
		return ROLL_SHEET
	return JUMP_SHEET


func _frame_count(state: String) -> int:
	if state == "dash":
		return 7
	if state == "roll":
		return 4
	return 6


func _frame_for(state: String, phase: float) -> int:
	match state:
		"takeoff":
			return 0
		"rise":
			return 1
		"apex":
			return 2
		"fall":
			return 3
		"land":
			return 4
		"double":
			return 5
		"dash":
			return _marks(phase, [0.0, 0.12, 0.26, 0.42, 0.58, 0.74, 0.86, 1.01])
		"roll":
			return _marks(phase, [0.0, 0.16, 0.40, 0.66, 1.01])
		_:
			return 0


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
