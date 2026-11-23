extends Control
## Selector de tres iniciales: flechas táctiles, teclado o mando.

signal changed(initials: String)

const Arcade := preload("res://scripts/ui/arcade_style.gd")
const Records := preload("res://scripts/util/records.gd")
const SIZE := Vector2(448, 162)

var palette: TableTheme
var letters: Array[int] = [0, 0, 0]
var current := 0
var _labels: Array[Label] = []
var _wells: Array[Panel] = []
var _arrows: Array[Button] = []
var _selected_well: StyleBoxFlat
var _idle_well: StyleBoxFlat
var _frame: StyleBoxFlat
var _focus: StyleBoxFlat


func _ready() -> void:
	if not palette:
		palette = GameState.active_theme()
	custom_minimum_size = SIZE
	size = SIZE
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	var accent := palette.score_label_color
	_frame = Arcade.box(palette.panel_ink_color.darkened(0.18), palette.panel_frame_color, 12)
	_focus = Arcade.focus_ring(palette.text_color, 12)
	_idle_well = Arcade.box(palette.panel_ink_color, palette.panel_frame_color, 7)
	_selected_well = Arcade.box(palette.panel_ink_color.lerp(accent, 0.13), accent, 7)
	_selected_well.shadow_size = 7
	_selected_well.shadow_color = Color(accent, 0.25)
	for slot in Records.INITIALS_LENGTH:
		var x := 50.0 + slot * 120.0
		_arrow(slot, Rect2(x, 9, 108, 34), 1)
		var well := Panel.new()
		well.position = Vector2(x, 47)
		well.size = Vector2(108, 46)
		well.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(well)
		_wells.append(well)
		var label := Label.new()
		label.size = well.size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 34)
		Arcade.font(label, palette)
		well.add_child(label)
		_labels.append(label)
		_arrow(slot, Rect2(x, 97, 108, 34), -1)
	var hint := Label.new()
	hint.text = "Enter / A → Guardar"
	hint.position = Vector2(0, 135)
	hint.size.x = SIZE.x
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", palette.muted_color)
	Arcade.font(hint, palette)
	add_child(hint)
	set_initials(Records.DEFAULT_INITIALS)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_frame, rect)
	if has_focus():
		draw_style_box(_focus, rect)


func initials() -> String:
	var text := ""
	for value in letters:
		text += char(65 + value)
	return text


func set_initials(text: String) -> void:
	var clean := Records.clean_initials(text)
	for slot in Records.INITIALS_LENGTH:
		letters[slot] = clean.unicode_at(slot) - 65
	current = 0
	_refresh()


## Cambia la letra de un casillero (+1 sigue en el alfabeto, -1 retrocede).
func cycle(slot: int, direction: int) -> void:
	current = slot
	letters[slot] = posmod(letters[slot] + direction, 26)
	_refresh()
	changed.emit(initials())


func type_letter(character: String) -> void:
	letters[current] = character.to_upper().unicode_at(0) - 65
	current = mini(current + 1, Records.INITIALS_LENGTH - 1)
	_refresh()
	changed.emit(initials())


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		cycle(current, 1)
	elif event.is_action_pressed("ui_down"):
		cycle(current, -1)
	elif event.is_action_pressed("ui_left"):
		current = maxi(current - 1, 0)
		_refresh()
	elif event.is_action_pressed("ui_right"):
		current = mini(current + 1, Records.INITIALS_LENGTH - 1)
		_refresh()
	elif (event.is_action_pressed("ui_accept") or Arcade.pad_accept_pressed(event)) and not focus_next.is_empty():
		get_node(focus_next).grab_focus()
	else:
		return
	accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	if key.keycode >= KEY_A and key.keycode <= KEY_Z:
		type_letter(char(key.keycode))
		grab_focus()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for slot in _labels.size():
		_labels[slot].text = char(65 + letters[slot])
		_labels[slot].add_theme_color_override("font_color", palette.score_label_color if slot == current else palette.text_color)
		_wells[slot].add_theme_stylebox_override("panel", _selected_well if slot == current else _idle_well)
	for arrow in _arrows:
		arrow.queue_redraw()


func _arrow(slot: int, rect: Rect2, direction: int) -> void:
	var button := Button.new()
	button.name = "%s%d" % ["Up" if direction > 0 else "Down", slot]
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	Arcade.button(button, palette, palette.score_label_color)
	button.pressed.connect(func() -> void:
		grab_focus()
		cycle(slot, direction))
	button.draw.connect(func() -> void:
		var midpoint := button.size * 0.5
		var rise := float(direction) * 4.0
		var tip := midpoint - Vector2(0, rise)
		var tint := palette.score_label_color if slot == current or button.is_hovered() else palette.muted_color
		button.draw_line(midpoint + Vector2(-9, rise), tip, tint, 2.5, true)
		button.draw_line(tip, midpoint + Vector2(9, rise), tint, 2.5, true))
	add_child(button)
	_arrows.append(button)
