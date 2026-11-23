extends Control
## Pantalla de título estilo arcade. Tocar en cualquier lado (o Enter / botón del mando) abre el selector de mesas.
## Los colores salen de los TableTheme de las mesas, como en el selector y en récords.

const Screen := preload("res://scripts/util/screen.gd")
const OptionsMenu := preload("res://scripts/ui/options_menu.gd")
const SELECT_SCENE := "res://scenes/table_select.tscn"
const RECORDS_SCENE := "res://scenes/records.tscn"
const TABLE_IDS := [GameState.KERNEL_PANIC, GameState.NAUTILUS, GameState.DRACULA, GameState.ALICIA]
const INK := Color("#071119")
const IVORY := Color("#f3ead8")

var _play: Button
var _options_button: Button
var _records_button: Button
var _options: CanvasLayer
var _heading: FontVariation
var _accents: Array[Color] = []
var _blink := 0.0
var _safe_top := 0.0
var _safe_bottom := 0.0


func _ready() -> void:
	GameState.leave_game()
	for id: String in TABLE_IDS:
		_accents.append(GameState.active_theme(id).select_accent)
	_heading = FontVariation.new()
	_heading.base_font = ThemeDB.fallback_font
	_heading.variation_embolden = 0.9
	_play = _make_button("Play", "Tocá para jugar", 34, Vector2(560, 96))
	_play.pressed.connect(start)
	_options_button = _make_button("Options", "Opciones", 24, Vector2(220, 60))
	_options_button.pressed.connect(open_options)
	_records_button = _make_button("Records", "Récords", 24, Vector2(220, 60))
	_records_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(RECORDS_SCENE))
	_play.focus_neighbor_bottom = _play.get_path_to(_options_button)
	_options_button.focus_neighbor_top = _options_button.get_path_to(_play)
	_records_button.focus_neighbor_top = _records_button.get_path_to(_play)
	_options_button.focus_neighbor_right = _options_button.get_path_to(_records_button)
	_records_button.focus_neighbor_left = _records_button.get_path_to(_options_button)
	_options = OptionsMenu.new()
	_options.name = "OptionsMenu"
	_options.closed.connect(func() -> void: _options_button.grab_focus())
	add_child(_options)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_play.grab_focus()


func start() -> void:
	if _options.is_open():
		return
	get_tree().change_scene_to_file(SELECT_SCENE)


func open_options() -> void:
	_options.open()


func _make_button(id: String, text: String, font_size: int, button_size: Vector2) -> Button:
	var accent := _accents[0]
	var button := Button.new()
	button.name = id
	button.text = text
	button.size = button_size
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, IVORY)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": Color("#101d24"), "hover": Color("#1d3a3d"), "pressed": Color("#12232a")}[state]
		box.border_color = accent if state != "normal" else Color(accent, 0.5)
		box.set_border_width_all(2)
		box.set_corner_radius_all(10)
		button.add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = IVORY
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(10)
	button.add_theme_stylebox_override("focus", focus)
	add_child(button)
	return button


func _layout() -> void:
	var safe := Screen.safe_insets(get_viewport())
	_safe_top = safe.top
	_safe_bottom = safe.bottom
	var bottom := size.y - _safe_bottom
	_play.position = Vector2((size.x - _play.size.x) * 0.5, bottom - 330.0)
	var gap := 24.0
	var row := _options_button.size.x + _records_button.size.x + gap
	_options_button.position = Vector2((size.x - row) * 0.5, bottom - 190.0)
	_records_button.position = _options_button.position + Vector2(_options_button.size.x + gap, 0)
	queue_redraw()


func _process(delta: float) -> void:
	_blink += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	if tapped:
		accept_event()
		start()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not _options.is_open():
		get_viewport().set_input_as_handled()
		start()


func _draw() -> void:
	if _heading == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	for y in range(0, int(size.y), 6):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.41, 0.61, 0.62, 0.05))
	var middle := size.x * 0.5
	var top := _safe_top + size.y * 0.2
	_center_text("PINBALL", Vector2(middle, top), 96, IVORY)
	_center_text("TEMÁTICO", Vector2(middle, top + 104), 96, _accents[0])
	# Una barra por mesa, cada una con el acento de su tema.
	var bar := 96.0
	var start_x := middle - bar * _accents.size() * 0.5
	for i in _accents.size():
		var from := Vector2(start_x + i * bar + 6, top + 150)
		draw_line(from, from + Vector2(bar - 12, 0), _accents[i], 6, true)
	_center_text("%d MESAS" % TABLE_IDS.size(), Vector2(middle, top + 200), 26, _accents[1])
	if fmod(_blink, 1.2) < 0.8 and not _options.is_open():
		var pulse := Rect2(_play.position, _play.size)
		draw_rect(pulse.grow(8), Color(_accents[0], 0.35), false, 2, true)


func _center_text(text: String, at: Vector2, font_size: int, tint: Color) -> void:
	var width := _heading.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_heading, at - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
