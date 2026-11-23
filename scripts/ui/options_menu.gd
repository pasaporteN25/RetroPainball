extends CanvasLayer
## Pantalla de opciones (U-07). Se abre desde la pausa; guarda al cerrarse.

signal closed

const BackNav := preload("res://scripts/util/back_nav.gd")
const Arcade := preload("res://scripts/ui/arcade_style.gd")
const ZONE_LABELS := {"media": "Mitad de pantalla", "baja": "Zona baja"}
const LANGUAGE_LABELS := {"es": "Español", "en": "English"}

var _shade: ColorRect
var _panel: PanelContainer
var _palette: TableTheme
var _title: Label
var _volume_heading: Label
var _sliders := {}
var _volume_labels := {}
var _readouts := {}
var _focus_order: Array[Control] = []
var _vibration: Button
var _zone: Button
var _language: Button
var _back: Button
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 21
	_shade = ColorRect.new()
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Arcade.center_in_safe_area(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size.x = 584
	center.add_child(_panel)
	get_viewport().size_changed.connect(func() -> void: Arcade.center_in_safe_area(_panel.get_parent()))
	_panel.draw.connect(func() -> void: Arcade.draw_trim(_panel, _palette.menu_accent))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	_title = Label.new()
	_title.text = "OPCIONES"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 48)
	column.add_child(_title)
	_volume_heading = Label.new()
	_volume_heading.text = "VOLUMEN"
	_volume_heading.add_theme_font_size_override("font_size", 17)
	column.add_child(_volume_heading)
	for bus in Settings.BUSES:
		column.add_child(_volume_row(bus))
	_vibration = _toggle(column, "Vibración", _on_vibration)
	_zone = _toggle(column, "Zonas táctiles", _on_zone)
	_language = _toggle(column, "Idioma", _on_language)
	_back = Button.new()
	_back.name = "Volver"
	_back.text = "Volver"
	_back.custom_minimum_size = Vector2(0, 72)
	_back.add_theme_font_size_override("font_size", 27)
	_back.pressed.connect(close)
	column.add_child(_back)
	_buttons = [_vibration, _zone, _language, _back]
	for button in _buttons:
		Arcade.enable_pad_accept(button)
	_focus_order.append_array(_buttons)
	for i in _focus_order.size():
		var control := _focus_order[i]
		control.focus_previous = control.get_path_to(_focus_order[posmod(i - 1, _focus_order.size())])
		control.focus_next = control.get_path_to(_focus_order[(i + 1) % _focus_order.size()])
		control.focus_neighbor_top = control.focus_previous
		control.focus_neighbor_bottom = control.focus_next
		control.focus_neighbor_left = NodePath(".")
		control.focus_neighbor_right = NodePath(".")
	_apply_theme()
	_shade.hide()


func is_open() -> bool:
	return _shade.visible


func open() -> void:
	_apply_theme()
	_refresh()
	_shade.show()
	_back.grab_focus()


func close() -> void:
	if not _shade.visible:
		return
	Settings.save_settings()
	_shade.hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _shade.visible and BackNav.is_back_event(event):
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Atrás: cierra las opciones y vuelve a la pantalla anterior.
func go_back() -> void:
	if _shade.visible and BackNav.claim():
		close()


func _volume_row(bus: StringName) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var label := Label.new()
	label.text = String(bus)
	label.custom_minimum_size.x = 122
	label.add_theme_font_size_override("font_size", 24)
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "Slider" + String(bus)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0, 52)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var knob := PlaceholderTexture2D.new()
	knob.size = Vector2(22, 22)
	for icon in ["grabber", "grabber_highlight"]:
		slider.add_theme_icon_override(icon, knob)
	slider.draw.connect(_draw_slider.bind(slider))
	slider.focus_entered.connect(slider.queue_redraw)
	slider.focus_exited.connect(slider.queue_redraw)
	row.add_child(slider)
	var readout := Label.new()
	readout.custom_minimum_size.x = 68
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.add_theme_font_size_override("font_size", 22)
	row.add_child(readout)
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set_volume(bus, value)
		readout.text = "%d%%" % roundi(value * 100))
	_sliders[bus] = slider
	_volume_labels[bus] = label
	_readouts[bus] = readout
	_focus_order.append(slider)
	return row


func _toggle(parent: Control, id: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = id.replace(" ", "")
	button.custom_minimum_size = Vector2(0, 60)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _refresh() -> void:
	for bus in Settings.BUSES:
		_sliders[bus].set_value_no_signal(Settings.volumes[bus])
		_sliders[bus].queue_redraw()
		_readouts[bus].text = "%d%%" % roundi(Settings.volumes[bus] * 100)
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


func _apply_theme() -> void:
	_palette = GameState.active_theme()
	var accent := _palette.menu_accent
	_shade.color = _palette.backdrop_color
	Arcade.panel(_panel, _palette, accent, 28)
	for label: Label in [_title, _volume_heading] + _volume_labels.values() + _readouts.values():
		Arcade.font(label, _palette)
		label.add_theme_color_override("font_color", _palette.text_color)
	_volume_heading.add_theme_color_override("font_color", accent.lightened(0.32))
	for button in _buttons:
		Arcade.button(button, _palette, accent, button == _back)
	for slider: HSlider in _sliders.values():
		var track := Arcade.box(_palette.panel_ink_color.darkened(0.26), _palette.panel_frame_color, 6)
		track.content_margin_top = 7
		track.content_margin_bottom = 7
		var fill := Arcade.box(accent, accent, 6)
		slider.add_theme_stylebox_override("slider", track)
		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
		slider.add_theme_stylebox_override("focus", Arcade.focus_ring(_palette.text_color))
		slider.queue_redraw()


func _draw_slider(slider: HSlider) -> void:
	if slider.has_focus():
		slider.draw_style_box(slider.get_theme_stylebox("focus"), Rect2(Vector2.ZERO, slider.size))
	var point := Vector2(lerpf(11.0, slider.size.x - 11.0, slider.ratio), slider.size.y * 0.5)
	var light := _palette.menu_accent.lightened(0.46)
	slider.draw_circle(point, 14.0, Color(light, 0.17), true, -1.0, true)
	slider.draw_circle(point, 9.0, light, true, -1.0, true)
	slider.draw_circle(point, 4.0, _palette.panel_ink_color, true, -1.0, true)
