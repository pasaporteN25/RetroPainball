extends CanvasLayer
## Panel de pausa independiente, operativo mientras el árbol está pausado.

signal resume_requested
signal tables_requested

const AMBER := Color("#ffbc6b")
const MINT := Color("#75e6c6")
const IVORY := Color("#f3ead8")
const INK := Color("#101619")
const FRAME := Color("#435052")

var _accent := MINT
var _panel: PanelContainer
var _shade: ColorRect
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_shade = ColorRect.new()
	_shade.color = Color(0.015, 0.024, 0.032, 0.86)
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	var panel := _panel
	panel.custom_minimum_size = Vector2(520, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101619")
	style.border_color = Color("#435052")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	panel.draw.connect(func() -> void:
		var width := panel.size.x
		panel.draw_line(Vector2(28, 18), Vector2(width - 28, 18), _accent.darkened(0.38), 2.0, true)
		panel.draw_line(Vector2(width * 0.5 - 52, 18), Vector2(width * 0.5 + 52, 18), _accent, 4.0, true))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", IVORY)
	column.add_child(title)
	for item in [["Continuar", _resume], ["Reiniciar partida", _restart], ["Volver a mesas", _tables]]:
		var button := Button.new()
		button.name = item[0].replace(" ", "")
		button.text = item[0]
		button.custom_minimum_size = Vector2(448, 72)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 27)
		button.pressed.connect(item[1])
		column.add_child(button)
		_buttons.append(button)
	for i in _buttons.size():
		_buttons[i].focus_neighbor_top = _buttons[(i + _buttons.size() - 1) % _buttons.size()].get_path()
		_buttons[i].focus_neighbor_bottom = _buttons[(i + 1) % _buttons.size()].get_path()
	_apply_theme()
	_shade.hide()


func set_paused(value: bool) -> void:
	_shade.visible = value
	if value:
		_apply_theme()
		_buttons[0].grab_focus()
	else:
		get_viewport().gui_release_focus()


func _box(color: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	return box


func _apply_theme() -> void:
	_accent = AMBER if GameState.table_id == "nautilus" else MINT
	_panel.queue_redraw()
	for i in _buttons.size():
		var button := _buttons[i]
		var accent := (AMBER if GameState.table_id == "nautilus" else MINT) if i == 0 else MINT
		var text_color := Color("#111b1b") if i == 0 else IVORY
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_hover_color", text_color)
		button.add_theme_color_override("font_pressed_color", text_color)
		button.add_theme_color_override("font_focus_color", text_color)
		if i == 0:
			button.add_theme_stylebox_override("normal", _box(accent, accent.lightened(0.32)))
			button.add_theme_stylebox_override("hover", _box(accent.lightened(0.22), accent.lightened(0.46)))
			button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.22), accent))
		else:
			button.add_theme_stylebox_override("normal", _box(Color("#172321"), accent.darkened(0.4)))
			button.add_theme_stylebox_override("hover", _box(Color("#253936"), accent))
			button.add_theme_stylebox_override("pressed", _box(Color("#1b272b"), accent))
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = IVORY
		focus.set_border_width_all(4)
		focus.set_corner_radius_all(10)
		focus.set_expand_margin_all(4)
		button.add_theme_stylebox_override("focus", focus)


func _resume() -> void:
	resume_requested.emit()


func _restart() -> void:
	GameState.start_game()


func _tables() -> void:
	tables_requested.emit()
