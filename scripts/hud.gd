extends CanvasLayer

var score_label: Label
var combo_label: Label
var lives_pips: Control
var start_panel: PanelContainer
var over_panel: PanelContainer
var over_score: Label
var over_detail: Label
var paused_label: Label
var rotate_panel: Control
var _lives: int = 3
var _combo_punch: float = 0.0
var _break: float = 0.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	score_label = _label("0", 52, Color("fff1d8"))
	score_label.position = Vector2(48, 28)
	root.add_child(score_label)
	var score_caption := _label("SCORE", 18, Color("c9b59a"))
	score_caption.position = Vector2(50, 14)
	root.add_child(score_caption)

	combo_label = _label("x0", 42, Color("a7b0c8"))
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.position = Vector2(-70, 26)
	combo_label.pivot_offset = Vector2(70, 24)
	root.add_child(combo_label)

	var lives_caption := _label("LIVES", 18, Color("c9b59a"))
	lives_caption.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lives_caption.position = Vector2(-168, 14)
	root.add_child(lives_caption)
	lives_pips = Pips.new()
	lives_pips.custom_minimum_size = Vector2(110, 32)
	lives_pips.size = Vector2(110, 32)
	lives_pips.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lives_pips.position = Vector2(-168, 36)
	lives_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lives_pips)

	start_panel = _panel()
	start_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_panel.offset_left = 860
	start_panel.offset_top = 180
	start_panel.offset_right = -70
	start_panel.offset_bottom = -180
	var start_box := VBoxContainer.new()
	start_box.add_theme_constant_override("separation", 8)
	start_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_panel.add_child(start_box)
	start_box.add_child(_label("SORA TSUNAGI", 48, Color("fff1d8")))
	start_box.add_child(_label("GLASSFALL", 22, Color("ffb34f")))
	start_box.add_child(_spacer(10))
	start_box.add_child(_label("Left half — tap to jump, tap again to double jump.", 22, Color("fff1d8")))
	start_box.add_child(_label("Hold the left half to glide.", 22, Color("fff1d8")))
	start_box.add_child(_label("Right half — tap to dash through monsters.", 22, Color("fff1d8")))
	start_box.add_child(_spacer(8))
	start_box.add_child(_label("Three lives. One score.", 20, Color("c9b59a")))
	start_box.add_child(_label("Keyboard: Space jump, Shift dash.", 18, Color("a7b0c8")))
	start_box.add_child(_spacer(12))
	start_box.add_child(_label("TAP TO RUN", 28, Color("ffb34f")))
	root.add_child(start_panel)

	over_panel = _panel()
	over_panel.set_anchors_preset(Control.PRESET_CENTER)
	over_panel.offset_left = -280
	over_panel.offset_top = -210
	over_panel.offset_right = 280
	over_panel.offset_bottom = 210
	over_panel.visible = false
	var over_box := VBoxContainer.new()
	over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	over_box.add_theme_constant_override("separation", 6)
	over_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_panel.add_child(over_box)
	over_box.add_child(_label("GLASSFALL", 18, Color("ffb34f")))
	over_box.add_child(_label("RUN OVER", 54, Color("fff1d8")))
	over_score = _label("0", 64, Color("ffd275"))
	over_box.add_child(over_score)
	over_detail = _label("", 22, Color("c9b59a"))
	over_box.add_child(over_detail)
	over_box.add_child(_spacer(16))
	over_box.add_child(_label("TAP TO RUN AGAIN", 26, Color("ffb34f")))
	root.add_child(over_panel)

	paused_label = _label("PAUSED", 42, Color("fff1d8"))
	paused_label.set_anchors_preset(Control.PRESET_CENTER)
	paused_label.position = Vector2(-80, -24)
	paused_label.visible = false
	root.add_child(paused_label)

	rotate_panel = Control.new()
	rotate_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotate_panel.visible = false
	root.add_child(rotate_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotate_panel.add_child(dim)
	var rotate_label := _label("ROTATE TO LANDSCAPE", 36, Color("fff1d8"))
	rotate_label.set_anchors_preset(Control.PRESET_CENTER)
	rotate_label.position = Vector2(-220, -20)
	rotate_panel.add_child(rotate_label)


func _process(delta: float) -> void:
	if _combo_punch > 0.0:
		_combo_punch = max(0.0, _combo_punch - delta * 2.4)
		combo_label.scale = Vector2.ONE * lerpf(1.0, 1.28, _combo_punch)
	else:
		combo_label.scale = Vector2.ONE
	if _break > 0.0:
		_break = max(0.0, _break - delta)
		combo_label.modulate = Color(1, 0.45, 0.4)
	else:
		combo_label.modulate = Color.WHITE
	var view := get_viewport().get_visible_rect().size
	rotate_panel.visible = view.y > view.x * 1.08


func set_score(value: float) -> void:
	score_label.text = _commas(int(value))


func set_lives(value: int) -> void:
	_lives = value
	if lives_pips is Pips:
		(lives_pips as Pips).lives = value
		lives_pips.queue_redraw()


func set_combo(value: int, punch: bool) -> void:
	combo_label.text = "x%d" % value
	if value >= 4:
		combo_label.add_theme_color_override("font_color", Color("ff7058"))
	elif value >= 2:
		combo_label.add_theme_color_override("font_color", Color("ffb34f"))
	elif value == 1:
		combo_label.add_theme_color_override("font_color", Color("fff1d8"))
	else:
		combo_label.add_theme_color_override("font_color", Color("a7b0c8"))
	if punch:
		_combo_punch = 1.0
		_break = 0.0


func break_combo() -> void:
	_break = 0.28
	set_combo(0, false)


func show_start(on: bool) -> void:
	start_panel.visible = on


func show_game_over(score: int, kills: int, best: int) -> void:
	over_panel.visible = true
	over_score.text = _commas(score)
	over_detail.text = "%d KILLS    BEST %s" % [kills, _commas(best)]
	start_panel.visible = false


func hide_game_over() -> void:
	over_panel.visible = false


func show_paused(on: bool) -> void:
	paused_label.visible = on


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.09, 0.72)
	style.border_color = Color(0.9, 0.62, 0.38, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 10)
	return label


func _spacer(height: float) -> Control:
	var control := Control.new()
	control.custom_minimum_size = Vector2(0, height)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


func _commas(value: int) -> String:
	var raw := str(maxi(value, 0))
	var out := ""
	while raw.length() > 3:
		out = "," + raw.substr(raw.length() - 3, 3) + out
		raw = raw.substr(0, raw.length() - 3)
	return raw + out


class Pips extends Control:
	var lives: int = 3

	func _draw() -> void:
		for i in 3:
			var color := Color("ffb34f") if i < lives else Color(1, 1, 1, 0.22)
			var center := Vector2(16 + i * 34, 16)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -11),
				center + Vector2(10, 0),
				center + Vector2(0, 11),
				center + Vector2(-10, 0),
			]), color)
