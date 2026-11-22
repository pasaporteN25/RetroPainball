extends Control
## Selector de 3 iniciales al estilo arcade: cada letra tiene flechas ▲ ▼ (touch) y también
## se puede escribir con el teclado (letras, ↑ ↓ y ← →).

signal changed(initials: String)

const Records := preload("res://scripts/util/records.gd")
const AMBER := Color("#ffbc6b")
const MINT := Color("#75e6c6")
const IVORY := Color("#f3ead8")
const STEEL := Color("#a7b5b9")

var letters: Array[int] = [0, 0, 0]
var current := 0
var _labels: Array[Label] = []


func _ready() -> void:
	custom_minimum_size = Vector2(448, 128)
	size = custom_minimum_size
	for slot in Records.INITIALS_LENGTH:
		var x := 64.0 + slot * 108.0
		_arrow(slot, "▲", Rect2(x, 0, 96, 34), 1)
		var well := Panel.new()
		well.position = Vector2(x, 36)
		well.size = Vector2(96, 56)
		well.mouse_filter = Control.MOUSE_FILTER_IGNORE
		well.add_theme_stylebox_override("panel", _box(Color("#211715"), 8, Color("#54392b")))
		add_child(well)
		var label := Label.new()
		label.size = well.size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 44)
		well.add_child(label)
		_labels.append(label)
		_arrow(slot, "▼", Rect2(x, 94, 96, 34), -1)
	set_initials(Records.DEFAULT_INITIALS)


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


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: InputEventKey = event
	if key.keycode >= KEY_A and key.keycode <= KEY_Z:
		type_letter(char(key.keycode))
	elif key.keycode == KEY_UP:
		cycle(current, 1)
	elif key.keycode == KEY_DOWN:
		cycle(current, -1)
	elif key.keycode == KEY_LEFT:
		current = maxi(current - 1, 0)
		_refresh()
	elif key.keycode == KEY_RIGHT:
		current = mini(current + 1, Records.INITIALS_LENGTH - 1)
		_refresh()
	else:
		return
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	for slot in _labels.size():
		_labels[slot].text = char(65 + letters[slot])
		_labels[slot].add_theme_color_override("font_color", AMBER if slot == current else IVORY)


func _arrow(slot: int, glyph: String, rect: Rect2, direction: int) -> void:
	var button := Button.new()
	button.name = "%s%d" % ["Up" if direction > 0 else "Down", slot]
	button.text = glyph
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", STEEL)
	button.add_theme_color_override("font_hover_color", IVORY)
	button.add_theme_stylebox_override("normal", _box(Color("#101619"), 8))
	button.add_theme_stylebox_override("hover", _box(Color("#253336"), 8))
	button.add_theme_stylebox_override("pressed", _box(Color("#1b272b"), 8))
	button.pressed.connect(cycle.bind(slot, direction))
	add_child(button)


func _box(color: Color, radius: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(2)
	return box
