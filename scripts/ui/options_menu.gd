extends CanvasLayer
## Pantalla de opciones (U-07). Se abre desde la pausa; guarda al cerrarse.

signal closed

const MINT := Color("#75e6c6")
const IVORY := Color("#f3ead8")
const ZONE_LABELS := {"media": "Mitad de pantalla", "baja": "Zona baja"}
const LANGUAGE_LABELS := {"es": "Español", "en": "English"}

var _shade: ColorRect
var _panel: PanelContainer
var _accent := MINT
var _sliders := {}
var _vibration: Button
var _zone: Button
var _language: Button
var _back: Button
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 21
	_shade = ColorRect.new()
	_shade.color = Color(0.015, 0.024, 0.032, 0.92)
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.add_theme_stylebox_override("panel", _box(Color("#101619"), Color("#435052"), 18, 32))
	center.add_child(_panel)
	_panel.draw.connect(func() -> void:
		var width := _panel.size.x
		_panel.draw_line(Vector2(28, 18), Vector2(width - 28, 18), _accent.darkened(0.38), 2.0, true)
		_panel.draw_line(Vector2(width * 0.5 - 52, 18), Vector2(width * 0.5 + 52, 18), _accent, 4.0, true))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	var title := Label.new()
	title.text = "OPCIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", IVORY)
	column.add_child(title)
	for bus in Settings.BUSES:
		column.add_child(_volume_row(bus))
	_vibration = _toggle(column, "Vibración", _on_vibration)
	_zone = _toggle(column, "Zonas táctiles", _on_zone)
	_language = _toggle(column, "Idioma", _on_language)
	_back = Button.new()
	_back.name = "Volver"
	_back.text = "Volver"
	_back.custom_minimum_size = Vector2(496, 72)
	_back.add_theme_font_size_override("font_size", 27)
	_back.pressed.connect(close)
	column.add_child(_back)
	_buttons = [_vibration, _zone, _language, _back]
	_apply_theme()
	_shade.hide()


func is_open() -> bool:
	return _shade.visible


func open() -> void:
	_accent = GameState.active_theme().menu_accent
	_apply_theme()
	_refresh()
	_shade.show()
	_panel.queue_redraw()
	_back.grab_focus()


func close() -> void:
	if not _shade.visible:
		return
	Settings.save_settings()
	_shade.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _shade.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _volume_row(bus: StringName) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var label := Label.new()
	label.text = String(bus)
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", IVORY)
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "Slider" + String(bus)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0, 56)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(value: float) -> void: Settings.set_volume(bus, value))
	row.add_child(slider)
	_sliders[bus] = slider
	return row


func _toggle(parent: Control, id: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = id.replace(" ", "")
	button.custom_minimum_size = Vector2(496, 64)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _refresh() -> void:
	for bus in Settings.BUSES:
		_sliders[bus].set_value_no_signal(Settings.volumes[bus])
	_vibration.text = "Vibración: " + ("sí" if Settings.vibration else "no")
	_zone.text = "Zonas táctiles: " + ZONE_LABELS[Settings.touch_zone]
	_language.text = "Idioma: " + LANGUAGE_LABELS[Settings.language]


func _on_vibration() -> void:
	Settings.set_vibration(not Settings.vibration)
	if Settings.vibration:
		Settings.vibrate(20)
	_refresh()


func _on_zone() -> void:
	var keys: Array = Settings.ZONE_RATIOS.keys()
	Settings.set_touch_zone(keys[(keys.find(Settings.touch_zone) + 1) % keys.size()])
	_refresh()


func _on_language() -> void:
	var langs := Settings.LANGUAGES
	Settings.set_language(langs[(langs.find(Settings.language) + 1) % langs.size()])
	_refresh()


func _box(color: Color, border: Color, radius: int = 10, margin: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	if margin > 0:
		box.set_content_margin_all(margin)
	return box


func _apply_theme() -> void:
	for button in _buttons:
		var primary := button == _back
		var text_color := Color("#111b1b") if primary else IVORY
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(key, text_color)
		if primary:
			button.add_theme_stylebox_override("normal", _box(_accent, _accent.lightened(0.32)))
			button.add_theme_stylebox_override("hover", _box(_accent.lightened(0.22), _accent.lightened(0.46)))
			button.add_theme_stylebox_override("pressed", _box(_accent.darkened(0.22), _accent))
		else:
			button.add_theme_stylebox_override("normal", _box(Color("#172321"), _accent.darkened(0.4)))
			button.add_theme_stylebox_override("hover", _box(Color("#253936"), _accent))
			button.add_theme_stylebox_override("pressed", _box(Color("#1b272b"), _accent))
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = IVORY
		focus.set_border_width_all(4)
		focus.set_corner_radius_all(10)
		focus.set_expand_margin_all(4)
		button.add_theme_stylebox_override("focus", focus)
	for slider: HSlider in _sliders.values():
		var track := _box(Color("#172321"), _accent.darkened(0.4), 6)
		track.content_margin_top = 8
		track.content_margin_bottom = 8
		slider.add_theme_stylebox_override("slider", track)
		slider.add_theme_stylebox_override("grabber_area", _box(_accent, _accent, 6))
		slider.add_theme_stylebox_override("grabber_area_highlight", _box(_accent.lightened(0.2), _accent, 6))
