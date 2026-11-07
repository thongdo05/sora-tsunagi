extends CanvasLayer

const TUNING := preload("res://assets/tuning/game_tuning.tres")

var score_text: String = "0"
var score_plate: Control
var combo_label: Label
var lives_plate: Control
var start_panel: PanelContainer
var over_panel: PanelContainer
var over_score: Label
var over_detail: Label
var paused_label: Label
var rotate_panel: Control
var _root: Control
var _font: Font
var _font_small: Font
var _lives: int = 3
var _combo_value: int = 0
var _combo_pop: float = 0.0
var _break: float = 0.0
var _web_cache: Vector4 = Vector4.ZERO
var _web_mobile: bool = false
var _web_at: int = -10000


func _ready() -> void:
	layer = 10
	_font = _load_font("res://assets/fonts/ChakraPetch-Bold.ttf")
	_font_small = _load_font("res://assets/fonts/ChakraPetch-SemiBold.ttf")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	score_plate = ScorePlate.new()
	score_plate.custom_minimum_size = Vector2(430, 96)
	score_plate.size = Vector2(430, 96)
	score_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(score_plate as ScorePlate).font = _font
	(score_plate as ScorePlate).caption_font = _font_small
	_root.add_child(score_plate)

	combo_label = Label.new()
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_override("font", _font)
	combo_label.add_theme_font_size_override("font_size", 78)
	combo_label.add_theme_color_override("font_color", Color("fff6e8"))
	combo_label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08, 0.92))
	combo_label.add_theme_constant_override("outline_size", 16)
	combo_label.visible = false
	combo_label.text = ""
	_root.add_child(combo_label)

	lives_plate = LivesPlate.new()
	lives_plate.custom_minimum_size = Vector2(196, 86)
	lives_plate.size = Vector2(196, 86)
	lives_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(lives_plate as LivesPlate).font = _font_small
	_root.add_child(lives_plate)

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
	_root.add_child(start_panel)

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
	_root.add_child(over_panel)

	paused_label = _label("PAUSED", 42, Color("fff1d8"))
	paused_label.set_anchors_preset(Control.PRESET_CENTER)
	paused_label.position = Vector2(-80, -24)
	paused_label.visible = false
	_root.add_child(paused_label)

	rotate_panel = Control.new()
	rotate_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	rotate_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotate_panel.visible = false
	_root.add_child(rotate_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotate_panel.add_child(dim)
	var rotate_label := _label("ROTATE TO LANDSCAPE", 36, Color("fff1d8"))
	rotate_label.set_anchors_preset(Control.PRESET_CENTER)
	rotate_label.position = Vector2(-220, -20)
	rotate_panel.add_child(rotate_label)
	_layout(Vector4(TUNING.hud_safe_min_left, TUNING.hud_safe_min_top, TUNING.hud_safe_min_right, TUNING.hud_safe_min_bottom))


func _process(delta: float) -> void:
	var inset := _insets()
	_layout(inset)
	var base := 1.0 + minf(float(_combo_value), 12.0) * 0.055
	if _combo_pop > 0.0:
		_combo_pop = maxf(0.0, _combo_pop - delta * 3.4)
	var punch := _combo_pop * _combo_pop
	var scale := minf(base + punch * 0.5, 2.2)
	combo_label.scale = Vector2.ONE * scale
	if _break > 0.0:
		_break = maxf(0.0, _break - delta)
		combo_label.modulate = Color(1, 0.42, 0.38)
		if _break <= 0.0:
			combo_label.visible = false
			combo_label.modulate = Color.WHITE
	elif _combo_value > 0:
		combo_label.modulate = Color.WHITE
	var view := get_viewport().get_visible_rect().size
	rotate_panel.visible = view.y > view.x * 1.08


func set_score(value: float) -> void:
	score_text = _commas(int(value))
	if score_plate is ScorePlate:
		(score_plate as ScorePlate).text = score_text
		score_plate.queue_redraw()


func set_lives(value: int) -> void:
	_lives = value
	if lives_plate is LivesPlate:
		(lives_plate as LivesPlate).lives = value
		lives_plate.queue_redraw()


func set_combo(value: int, punch: bool) -> void:
	_combo_value = value
	_break = 0.0
	combo_label.modulate = Color.WHITE
	if value <= 0:
		combo_label.visible = false
		combo_label.text = ""
		combo_label.scale = Vector2.ONE
		return
	combo_label.visible = true
	combo_label.text = "x%d" % value
	if value >= 8:
		combo_label.add_theme_color_override("font_color", Color("ff7058"))
	elif value >= 4:
		combo_label.add_theme_color_override("font_color", Color("ffb34f"))
	else:
		combo_label.add_theme_color_override("font_color", Color("fff6e8"))
	if punch:
		_combo_pop = 1.0
		var base := 1.0 + minf(float(value), 12.0) * 0.055
		combo_label.scale = Vector2.ONE * minf(base + 0.5, 2.2)
	_layout(_insets())


func break_combo() -> void:
	if _combo_value <= 0 and not combo_label.visible:
		return
	_combo_value = 0
	_combo_pop = 0.0
	_break = 0.32
	combo_label.text = "BREAK"
	combo_label.visible = true
	combo_label.add_theme_color_override("font_color", Color("ff7058"))
	combo_label.scale = Vector2(1.15, 1.15)


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


func _layout(inset: Vector4) -> void:
	var view := get_viewport().get_visible_rect().size
	if score_plate:
		score_plate.position = Vector2(inset.x, inset.y)
	if lives_plate:
		lives_plate.position = Vector2(view.x - inset.z - lives_plate.size.x, inset.y)
	if combo_label:
		var width := 420.0
		combo_label.size = Vector2(width, 110)
		combo_label.position = Vector2(view.x * 0.5 - width * 0.5, inset.y - 6.0)
		combo_label.pivot_offset = Vector2(width * 0.5, 58.0)
	if over_panel:
		over_panel.offset_top = -210.0 - inset.w * 0.15
		over_panel.offset_bottom = 210.0 - inset.w * 0.35


func _insets() -> Vector4:
	var left := TUNING.hud_safe_min_left
	var top := TUNING.hud_safe_min_top
	var right := TUNING.hud_safe_min_right
	var bottom := TUNING.hud_safe_min_bottom
	var view := get_viewport().get_visible_rect().size
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var window := Vector2(DisplayServer.window_get_size())
	if screen.x > 0 and screen.y > 0 and window.x > 1.0 and window.y > 1.0:
		var sx := view.x / window.x
		var sy := view.y / window.y
		left = maxf(left, float(safe.position.x) * sx)
		top = maxf(top, float(safe.position.y) * sy)
		var safe_right := float(screen.x - safe.position.x - safe.size.x)
		var safe_bottom := float(screen.y - safe.position.y - safe.size.y)
		right = maxf(right, safe_right * sx)
		bottom = maxf(bottom, safe_bottom * sy)
	_read_web_insets(view)
	left = maxf(left, _web_cache.x)
	top = maxf(top, _web_cache.y)
	right = maxf(right, _web_cache.z)
	bottom = maxf(bottom, _web_cache.w)
	return Vector4(left, top, right, bottom)


func _read_web_insets(view: Vector2) -> void:
	if not OS.has_feature("web"):
		return
	var now := Time.get_ticks_msec()
	if now - _web_at < 400:
		return
	_web_at = now
	var kind: Variant = JavaScriptBridge.eval("typeof soraReadSafeArea", true)
	if str(kind) != "function":
		return
	var packed: Variant = JavaScriptBridge.eval("soraReadSafeArea().join(',')", true)
	var parts := str(packed).split(",")
	if parts.size() < 7:
		return
	var css_w := maxf(float(parts[5]), 1.0)
	var css_h := maxf(float(parts[6]), 1.0)
	var sx := view.x / css_w
	var sy := view.y / css_h
	var css_left := float(parts[0]) * sx
	var css_top := float(parts[1]) * sy
	var css_right := float(parts[2]) * sx
	var css_bottom := float(parts[3]) * sy
	_web_mobile = int(float(parts[4])) == 1
	if _web_mobile and css_left + css_right < 1.0:
		css_left = TUNING.hud_phone_notch
		css_right = TUNING.hud_phone_notch
	if _web_mobile and css_bottom < 1.0:
		css_bottom = TUNING.hud_phone_home
	_web_cache = Vector4(css_left, css_top, css_right, css_bottom)


func _load_font(path: String) -> Font:
	var font := FontFile.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return ThemeDB.fallback_font
	font.data = bytes
	return font


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


class ScorePlate extends Control:
	var font: Font
	var caption_font: Font
	var text: String = "0"

	func _draw() -> void:
		var plate := Rect2(Vector2.ZERO, size)
		draw_rect(plate, Color(0.04, 0.02, 0.08, 0.62))
		draw_rect(Rect2(0, 0, size.x, 3), Color("ffb34f"))
		draw_rect(Rect2(0, size.y - 3, 46, 3), Color("7ec8ff"))
		var caption := caption_font if caption_font != null else font
		if caption == null:
			return
		draw_string(caption, Vector2(18, 30), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e7c99a"))
		var face := font if font != null else caption
		draw_string(face, Vector2(16, 78), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("fff6e8"))


class LivesPlate extends Control:
	var font: Font
	var lives: int = 3

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.08, 0.62))
		draw_rect(Rect2(size.x - 46, 0, 46, 3), Color("7ec8ff"))
		draw_rect(Rect2(0, size.y - 3, size.x, 3), Color("ffb34f"))
		if font != null:
			var caption_width := font.get_string_size("LIVES", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(font, Vector2(size.x - 18 - caption_width, 28), "LIVES", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e7c99a"))
		for i in 3:
			var filled := i < lives
			var color := Color("8ae7ff") if filled else Color(1, 1, 1, 0.16)
			var edge := Color("fff6e8") if filled else Color(1, 1, 1, 0.28)
			var center := Vector2(size.x - 150 + i * 46, 58)
			var gem := PackedVector2Array([
				center + Vector2(0, -16),
				center + Vector2(13, -4),
				center + Vector2(0, 14),
				center + Vector2(-13, -4),
			])
			draw_colored_polygon(gem, color)
			draw_polyline(gem + PackedVector2Array([gem[0]]), edge, 2.0)
			if filled:
				draw_line(center + Vector2(-4, -8), center + Vector2(2, -2), Color(1, 1, 1, 0.8), 2.0)
