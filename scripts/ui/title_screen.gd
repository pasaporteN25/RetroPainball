extends Control
## Pantalla de título estilo arcade. Tocar el fondo, Enter o el botón del mando abre el selector.

const Screen := preload("res://scripts/util/screen.gd")
const BackNav := preload("res://scripts/util/back_nav.gd")
## Atrás en el título: el primer atrás avisa y el segundo (dentro de EXIT_WINDOW segundos) cierra la app.
const EXIT_WINDOW := 2.0
const OptionsMenu := preload("res://scripts/ui/options_menu.gd")
const SELECT_SCENE := "res://scenes/table_select.tscn"
const RECORDS_SCENE := "res://scenes/records.tscn"
const TABLE_IDS := [GameState.KERNEL_PANIC, GameState.NAUTILUS, GameState.DRACULA, GameState.ALICIA]
const INK := Color("#071119")
const IVORY := Color("#f3ead8")
const ART_SIZE := Vector2(720, 1080)
const FADE_TIME := 0.28
const ATTRACT_STEP := 1.0 / 30.0
const BALL_SPEED := 350.0
# Las puntas del recorrido coinciden con el borde interior de las gomas.
const BALL_ROUTE := [
	Vector2(184, 843), Vector2(128, 686), Vector2(292, 482), Vector2(520, 516),
	Vector2(592, 667), Vector2(426, 792), Vector2(520, 924), Vector2(324, 970),
	Vector2(184, 843),
]
const BUMPERS := [Vector2(268, 638), Vector2(454, 602), Vector2(362, 803)]
# Cada letra se arma con tramos de tubo en una cuadrícula de 6 × 10.
const GLYPHS := {
	"P": [
		[Vector2(0, 10), Vector2(0, 0), Vector2(4.8, 0), Vector2(6, 1.2),
			Vector2(6, 3.8), Vector2(4.8, 5), Vector2(0, 5)],
	],
	"R": [
		[Vector2(0, 10), Vector2(0, 0), Vector2(4.8, 0), Vector2(6, 1.2),
			Vector2(6, 3.8), Vector2(4.8, 5), Vector2(0, 5)],
		[Vector2(3.4, 5), Vector2(6, 10)],
	],
	"I": [[Vector2(1, 0), Vector2(5, 0)], [Vector2(3, 0), Vector2(3, 10)], [Vector2(1, 10), Vector2(5, 10)]],
	"N": [[Vector2(0, 10), Vector2(0, 0), Vector2(6, 10), Vector2(6, 0)]],
	"B": [
		[Vector2(0, 0), Vector2(4.7, 0), Vector2(5.8, 1.1), Vector2(5.8, 3.6),
			Vector2(4.4, 5), Vector2(6, 6.6), Vector2(6, 8.8), Vector2(4.8, 10), Vector2(0, 10), Vector2(0, 0)],
		[Vector2(0, 5), Vector2(4.4, 5)],
	],
	"A": [
		[Vector2(0, 10), Vector2(0, 2), Vector2(2, 0), Vector2(4, 0),
			Vector2(6, 2), Vector2(6, 10)],
		[Vector2(0, 6), Vector2(6, 6)],
	],
	"L": [[Vector2(0, 0), Vector2(0, 10), Vector2(6, 10)]],
	"T": [[Vector2(0, 0), Vector2(6, 0)], [Vector2(3, 0), Vector2(3, 10)]],
	"E": [[Vector2(6, 0), Vector2(0, 0), Vector2(0, 10), Vector2(6, 10)], [Vector2(0, 5), Vector2(5, 5)]],
	"M": [[Vector2(0, 10), Vector2(0, 0), Vector2(3, 4.5), Vector2(6, 0), Vector2(6, 10)]],
	"C": [
		[Vector2(6, 1.3), Vector2(4.7, 0), Vector2(1.3, 0), Vector2(0, 1.3),
			Vector2(0, 8.7), Vector2(1.3, 10), Vector2(4.7, 10), Vector2(6, 8.7)],
	],
	"O": [
		[Vector2(1.3, 0), Vector2(4.7, 0), Vector2(6, 1.3), Vector2(6, 8.7),
			Vector2(4.7, 10), Vector2(1.3, 10), Vector2(0, 8.7), Vector2(0, 1.3), Vector2(1.3, 0)],
	],
}

@onready var _attract: Node2D = $Attract
@onready var _transition: ColorRect = $Transition

var _play: Button
var _options_button: Button
var _records_button: Button
var _options: CanvasLayer
var _accents: Array[Color] = []
var _insert_colors: Array[Color] = []
var _frame := PackedVector2Array([
	Vector2(62, 16), Vector2(658, 16), Vector2(688, 46), Vector2(688, 1032),
	Vector2(658, 1062), Vector2(62, 1062), Vector2(32, 1032), Vector2(32, 46),
	Vector2(62, 16),
])
var _rail := PackedVector2Array([
	Vector2(292, 468), Vector2(438, 468), Vector2(526, 504), Vector2(609, 653),
	Vector2(609, 755), Vector2(537, 929), Vector2(428, 983), Vector2(311, 983),
	Vector2(175, 852), Vector2(111, 698), Vector2(111, 649), Vector2(292, 468),
])
var _frame_fill := _frame.slice(0, -1)
var _rail_fill := _rail.slice(0, -1)
var _logo_top: Array[PackedVector2Array] = []
var _logo_bottom: Array[PackedVector2Array] = []
var _ball_path := Curve2D.new()
var _route_length := 0.0
var _clock := 0.0
var _redraw_elapsed := 0.0
var _art_origin := Vector2.ZERO
var _art_scale := 1.0
var _leaving := false
var quit_app: Callable = func() -> void: get_tree().quit()
var _exit_until := -1.0
var _exit_hint: Label


func _ready() -> void:
	GameState.leave_game()
	for id: String in TABLE_IDS:
		var theme := GameState.active_theme(id)
		_accents.append(theme.select_accent)
		_insert_colors.append(theme.lamp_tint)
	_logo_top = _word_paths("RETRO", Vector2(0, 159), Vector2(8.0, 7.5), 18.0)
	_logo_bottom = _word_paths("PINBALL", Vector2(0, 279), Vector2(9.5, 10.0), 23.0)
	for point: Vector2 in BALL_ROUTE:
		_ball_path.add_point(point)
	_route_length = _ball_path.get_baked_length()
	_attract.draw.connect(_draw_attract)
	_transition.color = INK
	_play = _make_button("Play", "Tocá para jugar", 34, true)
	_play.pressed.connect(start)
	_options_button = _make_button("Options", "Opciones", 27)
	_options_button.pressed.connect(open_options)
	_records_button = _make_button("Records", "Récords", 27)
	_records_button.pressed.connect(_show_records)
	_play.focus_neighbor_bottom = _play.get_path_to(_options_button)
	_options_button.focus_neighbor_top = _options_button.get_path_to(_play)
	_records_button.focus_neighbor_top = _records_button.get_path_to(_play)
	_options_button.focus_neighbor_right = _options_button.get_path_to(_records_button)
	_records_button.focus_neighbor_left = _records_button.get_path_to(_options_button)
	_options = OptionsMenu.new()
	_options.name = "OptionsMenu"
	_options.closed.connect(_close_options)
	add_child(_options)
	_exit_hint = Label.new()
	_exit_hint.name = "ExitHint"
	_exit_hint.text = "Tocá atrás otra vez para salir"
	_exit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exit_hint.add_theme_font_size_override("font_size", 24)
	_exit_hint.add_theme_color_override("font_color", IVORY)
	_exit_hint.add_theme_color_override("font_outline_color", INK)
	_exit_hint.add_theme_constant_override("outline_size", 8)
	_exit_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exit_hint.hide()
	add_child(_exit_hint)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_play.grab_focus()


func start() -> void:
	if _leaving or _options.is_open():
		return
	_leaving = true
	_transition.modulate.a = 0.0
	_transition.show()
	var fade := create_tween()
	fade.tween_property(_transition, "modulate:a", 1.0, FADE_TIME).set_trans(Tween.TRANS_SINE)
	fade.tween_callback(_show_selector)


func _show_selector() -> void:
	if get_tree().change_scene_to_file(SELECT_SCENE) != OK:
		_transition.hide()
		_leaving = false


func open_options() -> void:
	if _leaving:
		return
	set_process(false)
	_options.open()


func _close_options() -> void:
	set_process(true)
	_options_button.grab_focus()


func _show_records() -> void:
	if not _leaving and not _options.is_open():
		BackNav.records_return = BackNav.TITLE_SCENE
		get_tree().change_scene_to_file(RECORDS_SCENE)


func _make_button(id: String, caption: String, font_size: int, primary := false) -> Button:
	var accent := _accents[0]
	var button := Button.new()
	button.name = id
	button.text = caption
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, INK if primary else IVORY)
	var fill := accent if primary else Color("#122029")
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		if state == "hover":
			box.bg_color = fill.lightened(0.12)
		elif state == "pressed":
			box.bg_color = fill.darkened(0.18)
		box.border_color = accent if primary else Color(accent, 0.40)
		box.set_border_width_all(2)
		box.set_corner_radius_all(14)
		button.add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color(accent.lerp(IVORY, 0.45), 0.86)
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(19)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		focus.set_expand_margin(side, 5.0)
	button.add_theme_stylebox_override("focus", focus)
	add_child(button)
	return button


func _layout() -> void:
	var safe := Screen.safe_insets(get_viewport())
	var top: float = safe.top
	var bottom: float = size.y - safe.bottom
	var available := bottom - top
	var width := minf(560.0, size.x - 80.0)
	var gap := 20.0
	_play.size = Vector2(width, 96)
	_options_button.size = Vector2((width - gap) * 0.5, 68)
	_records_button.size = _options_button.size
	var row_x := (size.x - width) * 0.5
	var row_y := bottom - clampf(available * 0.075, 38.0, 128.0) - _options_button.size.y
	_options_button.position = Vector2(row_x, row_y)
	_records_button.position = _options_button.position + Vector2(_options_button.size.x + gap, 0)
	_play.position = Vector2(row_x, row_y - 24.0 - _play.size.y)
	var art_height := maxf(1.0, _play.position.y - top - 70.0)
	_art_scale = minf(size.x / ART_SIZE.x, art_height / ART_SIZE.y)
	_art_origin = Vector2((size.x - ART_SIZE.x * _art_scale) * 0.5,
		top + (_play.position.y - top - 36.0 - ART_SIZE.y * _art_scale) * 0.5)
	_attract.position = _art_origin
	_attract.scale = Vector2.ONE * _art_scale
	_exit_hint.size = Vector2(size.x, 40.0)
	_exit_hint.position = Vector2(0.0, size.y - 120.0)
	queue_redraw()


func _process(delta: float) -> void:
	if _exit_hint.visible and not exit_armed():
		_exit_hint.hide()
	_clock += delta
	_redraw_elapsed += delta
	if _redraw_elapsed >= ATTRACT_STEP:
		_redraw_elapsed = fmod(_redraw_elapsed, ATTRACT_STEP)
		_attract.queue_redraw()


func _input(_event: InputEvent) -> void:
	if _leaving:
		get_viewport().set_input_as_handled()


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
	elif BackNav.is_back_event(event) and not _options.is_open():
		get_viewport().set_input_as_handled()
		go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func exit_armed() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _exit_until


## Atrás en el título: doble atrás para salir de la app (con las opciones abiertas, ellas lo atienden).
func go_back() -> void:
	if _leaving or _options.is_open() or not BackNav.claim():
		return
	if exit_armed():
		quit_app.call()
		return
	_exit_until = Time.get_ticks_msec() / 1000.0 + EXIT_WINDOW
	_exit_hint.show()


func _draw() -> void:
	if _accents.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	for y in range(0, int(size.y), 10):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(_accents[0], 0.04))
	draw_set_transform(_art_origin, 0.0, Vector2.ONE * _art_scale)
	draw_colored_polygon(_frame_fill, Color("#0b1822"))
	draw_polyline(_frame, Color(_accents[0], 0.25), 2.0, true)
	draw_set_transform(_art_origin + Vector2(14, 23) * _art_scale, 0.0, Vector2(0.961, 0.957) * _art_scale)
	draw_polyline(_frame, Color(_accents[0], 0.09), 2.0, true)
	draw_set_transform(_art_origin, 0.0, Vector2.ONE * _art_scale)
	# Los remaches, la cabecera y las pistas quedan en la capa estática.
	for point in [Vector2(66, 50), Vector2(654, 50), Vector2(66, 1028), Vector2(654, 1028)]:
		draw_circle(point, 6.0, Color(_accents[0], 0.28), false, 1.5, true)
		draw_line(point - Vector2(2, 2), point + Vector2(2, 2), Color(_accents[0], 0.32), 1.5, true)
	var badge := Vector2(360, 87)
	draw_arc(badge, 23.0, 0.0, TAU, 48, Color(_accents[1], 0.72), 2.0, true)
	draw_circle(badge, 8.0, _accents[1], true, -1.0, true)
	draw_circle(badge - Vector2(2, 3), 2.6, IVORY, true, -1.0, true)
	for side in [-1.0, 1.0]:
		var direction := Vector2(side, 0)
		draw_line(badge + direction * 48, badge + direction * 225, Color(_accents[1], 0.28), 2.0, true)
		draw_line(badge + direction * 66 + Vector2(0, 8), badge + direction * 185 + Vector2(0, 8), Color(_accents[1], 0.14), 1.5, true)
		draw_circle(badge + direction * 225, 3.0, Color(_accents[1], 0.55), true, -1.0, true)
	_draw_playfield()


func _draw_playfield() -> void:
	var mint := _accents[0]
	var gold := _accents[1]
	var caption := "%d MESAS" % TABLE_IDS.size()
	var font := ThemeDB.fallback_font
	var caption_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, Vector2((720.0 - caption_width) * 0.5, 442), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(IVORY, 0.75))
	draw_line(Vector2(99, 434), Vector2(280, 434), Color(gold, 0.20), 1.5, true)
	draw_line(Vector2(440, 434), Vector2(621, 434), Color(gold, 0.20), 1.5, true)
	draw_colored_polygon(_rail_fill, Color("#0d202b"))
	for x in range(147, 585, 24):
		for y in range(520, 914, 24):
			var point := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(point, _rail_fill):
				draw_circle(point, 1.4, Color(mint, 0.14), true, -1.0, true)
	draw_polyline(_rail, Color(mint, 0.09), 18.0, true)
	draw_polyline(_rail, Color(mint, 0.47), 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(83, 573), Vector2(83, 705), Vector2(149, 865), Vector2(231, 951)]), Color(mint, 0.23), 2.0, true)
	draw_polyline(PackedVector2Array([Vector2(555, 501), Vector2(633, 645), Vector2(633, 760), Vector2(564, 923)]), Color(mint, 0.23), 2.0, true)
	for i in BUMPERS.size():
		var center: Vector2 = BUMPERS[i]
		var tint := gold if i == 1 else mint
		draw_circle(center, 60.0, Color(tint, 0.055), true, -1.0, true)
		draw_circle(center, 52.0, Color("#102632"), true, -1.0, true)
		draw_circle(center, 52.0, Color(tint, 0.32), false, 2.0, true)
		draw_circle(center, 35.0, Color(tint, 0.12), true, -1.0, true)
		draw_circle(center, 35.0, Color(tint, 0.56), false, 2.0, true)
		draw_arc(center, 42.0, -2.72, -1.05, 20, Color(tint, 0.69), 3.0, true)
		draw_arc(center, 42.0, 0.45, 2.19, 20, Color(tint, 0.30), 3.0, true)
		draw_circle(center, 8.0, Color(tint, 0.46), false, 1.6, true)
	var flippers := PackedVector2Array([Vector2(210, 869), Vector2(312, 920), Vector2(410, 920), Vector2(505, 869)])
	for i in [0, 2]:
		draw_line(flippers[i], flippers[i + 1], Color(mint, 0.11), 18.0, true)
		draw_line(flippers[i], flippers[i + 1], Color(mint, 0.46), 3.0, true)
		draw_circle(flippers[0 if i == 0 else 3], 6.0, Color(mint, 0.56), false, 2.0, true)
	draw_line(Vector2(179, 1022), Vector2(541, 1022), Color(mint, 0.16), 2.0, true)


func _word_paths(word: String, origin: Vector2, unit: Vector2, gap: float) -> Array[PackedVector2Array]:
	var paths: Array[PackedVector2Array] = []
	var advance := 6.0 * unit.x + gap
	origin.x = (ART_SIZE.x - advance * word.length() + gap) * 0.5
	for i in word.length():
		var letter := word.substr(i, 1)
		var at := origin + Vector2(i * advance, 0)
		for glyph: Array in GLYPHS["A" if letter == "Á" else letter]:
			var stroke := PackedVector2Array()
			for point: Vector2 in glyph:
				stroke.append(at + point * unit)
			paths.append(stroke)
		if letter == "Á":
			paths.append(PackedVector2Array([at + Vector2(19, -14), at + Vector2(32, -25)]))
	return paths


func _draw_attract() -> void:
	var breath := 0.88 + 0.12 * sin(_clock * 1.65)
	_draw_tubes(_logo_top, _accents[0], breath, _tube_level(_clock))
	_draw_tubes(_logo_bottom, _accents[1], breath, 1.0)
	_draw_ball()
	for i in _insert_colors.size():
		var at := Vector2(240 + i * 80, 1022)
		var tint := _insert_colors[i]
		var level := _insert_level(i, _clock)
		_attract.draw_circle(at, 22.0, Color(tint, level * 0.13), true, -1.0, true)
		_attract.draw_circle(at, 13.0, tint.darkened(0.76).lerp(tint, level), true, -1.0, true)
		_attract.draw_circle(at, 13.0, Color(tint.lerp(IVORY, level * 0.55), 0.60), false, 1.5, true)
		_attract.draw_circle(at - Vector2(3, 4), 3.0, Color(IVORY, level * 0.91), true, -1.0, true)


func _draw_tubes(paths: Array[PackedVector2Array], tint: Color, breath: float, last_level: float) -> void:
	for i in paths.size():
		var stroke := paths[i]
		var level := (last_level if i == paths.size() - 1 else 1.0) * breath
		_attract.draw_polyline(stroke, Color(tint, 0.065 * level), 36.0, true)
		_attract.draw_polyline(stroke, Color(tint, 0.15 * level), 21.0, true)
		_attract.draw_polyline(stroke, Color(tint, 0.45 * level), 11.0, true)
		var core := tint.darkened(0.68).lerp(tint.lerp(IVORY, 0.72), level)
		_attract.draw_polyline(stroke, core, 4.0, true)
		_attract.draw_circle(stroke[0], 2.0, core, true, -1.0, true)
		_attract.draw_circle(stroke[-1], 2.0, core, true, -1.0, true)


func _tube_level(time: float) -> float:
	# Un falso contacto breve en la última L, con dos bajones de intensidad suaves.
	var phase := fposmod(time, 7.4)
	return 1.0 - 0.49 * (1.0 - smoothstep(0.0, 0.16, absf(phase - 2.20))) \
		- 0.27 * (1.0 - smoothstep(0.0, 0.11, absf(phase - 2.48)))


func _insert_level(index: int, time: float) -> float:
	var phase := fposmod(time / 0.62 - index + _insert_colors.size() * 0.5, _insert_colors.size())
	var distance := absf(phase - _insert_colors.size() * 0.5)
	return 0.14 + 0.86 * (1.0 - smoothstep(0.0, 1.32, distance))


func _ball_at(time: float) -> Vector2:
	var offset := fposmod(110.0 + time * BALL_SPEED, _route_length)
	return _ball_path.sample_baked(offset)


func _draw_ball() -> void:
	var tint := _accents[0]
	var center := _ball_at(_clock)
	var previous := center
	# Muestrear hacia atrás mantiene la estela pegada al recorrido en cada rebote.
	for i in range(1, 17):
		var point := _ball_at(_clock - i * 0.016)
		var strength := 1.0 - (i - 1) / 16.0
		_attract.draw_line(previous, point, Color(tint, strength * 0.28), 1.0 + strength * 8.0, true)
		previous = point
	_attract.draw_circle(center, 28.0, Color(tint, 0.08), true, -1.0, true)
	_attract.draw_circle(center, 20.0, Color(tint, 0.17), true, -1.0, true)
	_attract.draw_circle(center, 12.0, Color("#639595"), true, -1.0, true)
	_attract.draw_circle(center - Vector2(1, 2), 9.0, tint.lerp(IVORY, 0.66), true, -1.0, true)
	_attract.draw_circle(center - Vector2(4, 5), 3.3, Color.WHITE, true, -1.0, true)
