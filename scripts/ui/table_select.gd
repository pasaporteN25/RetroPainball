extends Control
## Selector vertical de máquinas. Las teclas y el mando navegan los mismos botones que el touch.

const Screen := preload("res://scripts/util/screen.gd")
const BackNav := preload("res://scripts/util/back_nav.gd")
const GameSave := preload("res://scripts/util/game_save.gd")
const Arcade := preload("res://scripts/ui/arcade_style.gd")
const PosterArt := preload("res://scripts/ui/poster_art.gd")
const TABLE_IDS := [GameState.KERNEL_PANIC, GameState.NAUTILUS, GameState.DRACULA, GameState.ALICIA]
const TABLE_SCENES := [
	"res://scenes/main.tscn", "res://scenes/nautilus.tscn", "res://scenes/dracula.tscn", "res://scenes/alicia.tscn",
]
const INK := Color("#0a1020")
const PANEL := Color("#17243b")
const STEEL := Color("#596c8b")
const LIGHT := Color("#a5b8ce")
const MINT := Color("#91e5cf")
const GOLD := Color("#f8bb72")
const IVORY := Color("#f3eee3")
const MACHINE_SIZE := Vector2(248, 408)
const POSTER_RECT := Rect2(28, 16, 192, 224)
const PLAQUE_SIZE := Vector2(412, 156)
const NO_POINTER := -2
const MOUSE_POINTER := -1


class Machine extends Button:
	var poster := Control.new()

	func _ready() -> void:
		poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(poster)

	func _draw() -> void:
		# El gabinete y el plano inclinado se dibujan en una grilla de 4 px.
		_pixel(8, 98, 46, 3, Color("#0c1222"))
		_pixel(3, 96, 56, 3, Color("#10182b"))
		for x in [11, 44]:
			_pixel(x, 77, 7, 17, PANEL)
			_pixel(x + 1, 79, 3, 13, STEEL)
		for x in [6, 49]:
			_pixel(x, 81, 7, 16, INK)
			_pixel(x + 1, 82, 5, 14, STEEL)
			_pixel(x + 1, 83, 2, 12, LIGHT)
			_pixel(x - 1, 96, 9, 2, PANEL)

		# Cabezal, borde interior del backglass y bandeja del display.
		_pixel(5, 0, 52, 2, STEEL)
		_pixel(3, 2, 56, 61, INK)
		_pixel(4, 2, 54, 60, STEEL)
		_pixel(5, 2, 52, 2, LIGHT)
		_pixel(6, 3, 50, 58, PANEL)
		_pixel(4, 4, 1, 55, LIGHT)
		_pixel(57, 4, 1, 57, PANEL)
		_pixel(8, 61, 46, 6, INK)
		_pixel(19, 61, 24, 4, Color("#332734"))
		for x in range(22, 41, 3):
			_pixel(x, 62, 2, 1, GOLD)
		for x in [10, 47]:
			_pixel(x, 62, 5, 1, STEEL)
			_pixel(x, 64, 5, 1, STEEL)

		# Los escalones abren el tablero hacia el frente.
		for row in 6:
			_pixel(5 - row, 67 + row * 2, 52 + row * 2, 2, STEEL)
			_pixel(7 - row, 67 + row * 2, 48 + row * 2, 2, Color("#24374c"))
			_pixel(6 - row, 67 + row * 2, 1, 2, LIGHT)
		for x in [15, 29, 43]:
			var y := 70 if x == 29 else 72
			_pixel(x, y, 4, 2, GOLD)
			_pixel(x + 1, y + 2, 2, 1, Color("#b9755d"))
		_pixel(53, 70, 1, 8, STEEL)
		_pixel(52, 76, 1, 2, LIGHT)
		_pixel(22, 75, 4, 1, MINT)
		_pixel(25, 76, 4, 1, MINT)
		_pixel(36, 75, 4, 1, MINT)
		_pixel(33, 76, 4, 1, MINT)
		_pixel(32, 72, 2, 2, IVORY)

		# Consola, monedero y tirador.
		_pixel(0, 79, 62, 2, LIGHT)
		_pixel(0, 81, 62, 7, PANEL)
		_pixel(1, 82, 60, 4, STEEL)
		_pixel(1, 85, 60, 2, Color("#344760"))
		_pixel(26, 81, 10, 6, INK)
		_pixel(28, 82, 2, 2, GOLD)
		_pixel(32, 82, 2, 2, GOLD)
		_pixel(4, 83, 3, 2, MINT)
		_pixel(55, 82, 4, 2, INK)
		_pixel(56, 82, 2, 1, IVORY)

	func _pixel(x: int, y: int, width: int, height: int, color: Color) -> void:
		draw_rect(Rect2(x * 4, y * 4, width * 4, height * 4), color)


var _machines: Array[Machine] = []
var _has_save: Array[bool] = []
var _records: Button
var _previous: Button
var _next: Button
var _continue: Button
var _table_name: Label
var _record: Label
var _heading: FontVariation
var _selected := 0
var _display_index := 0.0
var _transition: Tween
var _focus_pending := false
var _stage := Rect2()
var _machine_zoom := 1.0
var _plaque := Rect2()
var _header_y := 0.0
var _clock := 0.0
var _poster_frame := 0
var _pointer := NO_POINTER
var _drag_start := Vector2.ZERO
var _swipe_direction := 0


func _ready() -> void:
	GameState.leave_game()
	_heading = FontVariation.new()
	_heading.base_font = ThemeDB.fallback_font
	_heading.variation_embolden = 0.8
	for i in TABLE_IDS.size():
		var table_id: String = TABLE_IDS[i]
		_has_save.append(not GameState.save_directory.is_empty()
			and not GameSave.load_run(table_id, GameState.save_directory).is_empty())
		_machines.append(_make_machine(i, table_id))
	_records = _make_button("Records", "Récords", Vector2(136, 50), 22)
	_records.pressed.connect(func() -> void:
		BackNav.records_return = BackNav.SELECT_SCENE
		get_tree().change_scene_to_file("res://scenes/records.tscn"))
	_previous = _make_arrow("Previous", "‹", "Mesa anterior", -1)
	_next = _make_arrow("Next", "›", "Mesa siguiente", 1)
	_table_name = _make_label("TableName", 34, IVORY)
	_record = _make_label("HighScore", 22, GOLD)
	_continue = _make_button("Continue", "Continuar", Vector2(184, 46), 22)
	_continue.pressed.connect(func() -> void: _open_table(_selected))
	resized.connect(_layout)
	_layout()
	_sync_selection()


func _make_machine(index: int, table_id: String) -> Machine:
	var machine := Machine.new()
	machine.name = table_id.to_pascal_case()
	machine.text = GameState.active_theme(table_id).display_name
	machine.tooltip_text = machine.text
	machine.size = MACHINE_SIZE
	machine.pivot_offset = MACHINE_SIZE * 0.5
	machine.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var blank := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		machine.add_theme_stylebox_override(state, blank)
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_outline_color"]:
		machine.add_theme_color_override(state, Color.TRANSPARENT)
	machine.poster.draw.connect(func() -> void: PosterArt.draw(machine.poster, table_id, POSTER_RECT, _clock))
	machine.pressed.connect(_activate_machine.bind(index))
	Arcade.enable_pad_accept(machine)
	add_child(machine)
	return machine


func _make_button(node_name: String, label: String, dimensions: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = dimensions
	button.size = dimensions
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _heading)
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, IVORY)
	for state in ["normal", "hover", "pressed", "focus"]:
		var fill: Color = {"normal": PANEL, "hover": Color("#29475a"), "pressed": INK, "focus": Color.TRANSPARENT}[state]
		var box := Arcade.box(fill, STEEL if state == "normal" else MINT, 0)
		box.set_border_width_all(3)
		button.add_theme_stylebox_override(state, box)
	Arcade.enable_pad_accept(button)
	add_child(button)
	return button


func _make_arrow(node_name: String, label: String, hint: String, direction: int) -> Button:
	var button := _make_button(node_name, label, Vector2(64, 64), 48)
	button.tooltip_text = hint
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: _step(direction))
	return button


func _make_label(node_name: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _heading)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
	return label


func _step(direction: int) -> void:
	_select(posmod(_selected + direction, TABLE_IDS.size()), direction)


func _select(index: int, direction := 1) -> void:
	if index == _selected:
		return
	_selected = index
	_sync_selection()
	if _transition != null:
		_transition.kill()
	var half := TABLE_IDS.size() * 0.5
	var offset := wrapf(float(index) - _display_index, -half, half)
	if is_equal_approx(absf(offset), half):
		offset = half * direction
	var target := _display_index + offset
	# Un viaje corto y un rebote elástico chico al calzar en el centro.
	var landing := target - signf(offset) * minf(absf(offset) * 0.18, 0.10)
	_transition = create_tween()
	_transition.tween_method(_set_display_index, _display_index, landing, 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition.tween_method(_set_display_index, landing, target, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _set_display_index(value: float) -> void:
	_display_index = value
	_layout_machines()


func _sync_selection() -> void:
	var machine := _machines[_selected]
	var has_save := _has_save[_selected]
	_table_name.text = machine.text
	_record.text = "RÉCORD  %d" % _selected_record()
	_continue.visible = has_save
	_layout_plaque()
	_records.focus_neighbor_bottom = _records.get_path_to(machine)
	machine.focus_neighbor_top = machine.get_path_to(_records)
	machine.focus_neighbor_bottom = machine.get_path_to(_continue) if has_save else NodePath(".")
	_continue.focus_neighbor_top = _continue.get_path_to(machine)
	_continue.focus_neighbor_bottom = NodePath(".")
	_focus_pending = not machine.visible
	if not _focus_pending:
		machine.grab_focus()


func _selected_record() -> int:
	var table_id: String = TABLE_IDS[_selected]
	var cfg := ConfigFile.new()
	var legacy := 0
	if cfg.load(GameState.record_path) == OK:
		var section := "records" if table_id == GameState.KERNEL_PANIC else "records/" + table_id
		legacy = int(cfg.get_value(section, "high_score", 0))
	var top := GameState.top_scores(table_id)
	return legacy if top.is_empty() else maxi(legacy, int(top[0]["score"]))


func _activate_machine(index: int) -> void:
	if _swipe_direction != 0:
		return
	if index == _selected:
		_open_table(index)
	else:
		_select(index)


func _open_table(index: int) -> void:
	get_tree().change_scene_to_file(TABLE_SCENES[index])


func _layout() -> void:
	var safe := Screen.safe_insets(get_viewport())
	var available := size.y - float(safe.top) - float(safe.bottom)
	var fixed_height := 120.0 + PLAQUE_SIZE.y + 92.0
	var machine_height := minf(MACHINE_SIZE.y * size.x / 540.0, maxf(1.0, available - fixed_height))
	_machine_zoom = machine_height / MACHINE_SIZE.y
	_header_y = float(safe.top) + maxf(0.0, available - fixed_height - machine_height) * 0.42
	_stage = Rect2(0, _header_y + 120, size.x, machine_height + 40)
	_plaque = Rect2((size.x - PLAQUE_SIZE.x) * 0.5, _stage.end.y + 8, PLAQUE_SIZE.x, PLAQUE_SIZE.y)
	_records.position = Vector2(size.x - _records.size.x - 24, float(safe.top) + 12)
	_previous.position = Vector2(24, _plaque.get_center().y - _previous.size.y * 0.5)
	_next.position = Vector2(size.x - _next.size.x - 24, _previous.position.y)
	_layout_plaque()
	_layout_machines()
	queue_redraw()


func _layout_plaque() -> void:
	var offset := 0.0 if _continue.visible else 34.0
	_table_name.position = _plaque.position + Vector2(0, 10 + offset)
	_table_name.size = Vector2(_plaque.size.x, 48)
	_record.position = _plaque.position + Vector2(0, 58 + offset)
	_record.size = Vector2(_plaque.size.x, 28)
	_continue.position = Vector2(_plaque.get_center().x - _continue.size.x * 0.5, _plaque.position.y + 94)


func _layout_machines() -> void:
	var half := TABLE_IDS.size() * 0.5
	for i in _machines.size():
		var machine := _machines[i]
		var offset := wrapf(float(i) - _display_index, -half, half)
		var distance := absf(offset)
		machine.visible = distance < 1.5
		if not machine.visible:
			continue
		var side := minf(distance, 1.0)
		var zoom := _machine_zoom * lerpf(1.0, 0.48, side)
		machine.scale = Vector2(zoom, zoom)
		machine.position = (Vector2(size.x * 0.5 + offset * size.x * 0.345,
			_stage.end.y - 20.0 - MACHINE_SIZE.y * zoom * 0.5) - machine.pivot_offset).round()
		var shade := lerpf(1.0, 0.55, side)
		machine.modulate = Color(shade, shade, shade, 1.0 - smoothstep(1.07, 1.5, distance))
		machine.z_index = 4 - roundi(distance * 2.0)
	if _focus_pending and _machines[_selected].visible:
		_focus_pending = false
		_machines[_selected].grab_focus()


func _draw() -> void:
	if _heading == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	var horizon := roundf(_stage.position.y + _stage.size.y * 0.70)
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color("#10192d"))
	for y in range(int(horizon), int(size.y), 24):
		draw_rect(Rect2(0, y, size.x, 2), Color("#172339"))
	_center_text("RETRO PINBALL", _header_y + 66, 50, IVORY)
	_center_text("Elegí una mesa", _header_y + 104, 25, MINT)
	draw_rect(Rect2(_plaque.position + Vector2(0, 8), _plaque.size - Vector2(0, 16)), STEEL)
	draw_rect(Rect2(_plaque.position + Vector2(8, 0), _plaque.size - Vector2(16, 0)), STEEL)
	draw_rect(_plaque.grow(-4), PANEL)
	draw_rect(Rect2(_plaque.position + Vector2(12, 0), Vector2(_plaque.size.x - 24, 4)), LIGHT)
	_center_text("Deslizá o usá las flechas · Tocá para jugar", _plaque.end.y + 30, 20, LIGHT)


func _center_text(label: String, y: float, font_size: int, tint: Color) -> void:
	var width := _heading.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_heading, Vector2((size.x - width) * 0.5, y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)


func _process(delta: float) -> void:
	_clock += delta
	var frame := int(_clock * 20.0)
	if frame == _poster_frame:
		return
	_poster_frame = frame
	for machine in _machines:
		if machine.visible:
			machine.poster.queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_step(-1 if event.is_action_pressed("ui_left") else 1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept") or Arcade.pad_accept_pressed(event):
		_swipe_direction = 0
		if _focus_pending:
			get_viewport().set_input_as_handled()
			_open_table(_selected)
		return
	# El mouse emulado comparte el gesto del dedo para que el botón no se dispare al soltar.
	if event.device == InputEvent.DEVICE_ID_EMULATION and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.index, event.position)
		else:
			_end_drag(event.index, event.position, event.canceled)
	elif event is InputEventScreenDrag:
		_update_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pointer := _mouse_pointer(event)
		if event.pressed:
			_begin_drag(pointer, event.position)
		else:
			_end_drag(pointer, event.position)
	elif event is InputEventMouseMotion:
		_update_drag(_mouse_pointer(event), event.position)


func _mouse_pointer(event: InputEvent) -> int:
	return _pointer if event.device == InputEvent.DEVICE_ID_EMULATION and _pointer >= 0 else MOUSE_POINTER


func _begin_drag(pointer: int, point: Vector2) -> void:
	if _pointer != NO_POINTER:
		return
	_swipe_direction = 0
	if _stage.has_point(point):
		_pointer = pointer
		_drag_start = point


func _update_drag(pointer: int, point: Vector2) -> void:
	if pointer == _pointer:
		var travel := point - _drag_start
		if absf(travel.x) > maxf(55.0, absf(travel.y)):
			_swipe_direction = 1 if travel.x < 0.0 else -1


func _end_drag(pointer: int, point: Vector2, canceled := false) -> void:
	if pointer != _pointer:
		return
	_update_drag(pointer, point)
	_pointer = NO_POINTER
	if _swipe_direction != 0 and not canceled:
		_step(_swipe_direction)


func _unhandled_input(event: InputEvent) -> void:
	if BackNav.is_back_event(event):
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Atrás en el selector: vuelve al título.
func go_back() -> void:
	if BackNav.claim():
		get_tree().change_scene_to_file.call_deferred(BackNav.TITLE_SCENE)
