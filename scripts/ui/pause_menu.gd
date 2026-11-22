extends CanvasLayer
## Panel de pausa independiente, operativo mientras el árbol está pausado.

signal resume_requested
signal tables_requested

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
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101619")
	style.border_color = Color("#435052")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
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
	_shade.hide()


func set_paused(value: bool) -> void:
	_shade.visible = value
	if value:
		_buttons[0].grab_focus()
	else:
		get_viewport().gui_release_focus()


func _resume() -> void:
	resume_requested.emit()


func _restart() -> void:
	GameState.start_game()


func _tables() -> void:
	tables_requested.emit()
