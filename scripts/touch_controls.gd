extends Node

## Two-zone pointer input plus keyboard.
## Left half: tap jumps, hold glides. Right half: tap dashes.

var jump_held: bool = false
var jump_pressed: bool = false
var dash_pressed: bool = false
var enabled: bool = false

var _jump_fingers: Dictionary = {}
var _mouse_jump: bool = false


func _ready() -> void:
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_bind("dash", [KEY_SHIFT, KEY_K, KEY_J])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var already := false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == key:
				already = true
				break
		if already:
			continue
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func consume() -> void:
	jump_pressed = false
	dash_pressed = false


func _input(event: InputEvent) -> void:
	if not enabled or get_tree().paused:
		return
	var handled := false
	if event is InputEventScreenTouch:
		RunRoot.note_touch()
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _is_left(touch.position):
				_jump_fingers[touch.index] = true
				jump_pressed = true
			else:
				dash_pressed = true
		else:
			_jump_fingers.erase(touch.index)
		handled = true
	elif event is InputEventMouseButton:
		if RunRoot.mouse_is_ghost():
			get_viewport().set_input_as_handled()
			return
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				if _is_left(button.position):
					_mouse_jump = true
					jump_pressed = true
				else:
					dash_pressed = true
			else:
				_mouse_jump = false
			handled = true
		elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
			dash_pressed = true
			handled = true
	elif event.is_action_pressed("jump"):
		jump_pressed = true
		handled = true
	elif event.is_action_pressed("dash"):
		dash_pressed = true
		handled = true
	elif event.is_action_released("jump") or event.is_action_released("dash"):
		handled = true
	_sync_held()
	if handled:
		get_viewport().set_input_as_handled()


func _sync_held() -> void:
	jump_held = not _jump_fingers.is_empty() or _mouse_jump or Input.is_action_pressed("jump")


func _is_left(pos: Vector2) -> bool:
	return pos.x < get_viewport().get_visible_rect().size.x * 0.5
