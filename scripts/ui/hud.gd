extends CanvasLayer
## Marcador, avisos de partida y paneles del gabinete.

signal checkpoint_requested

const SevenSegment := preload("res://scripts/ui/seven_segment.gd")
const BallLamps := preload("res://scripts/ui/ball_lamps.gd")
const Screen := preload("res://scripts/util/screen.gd")

const AMBER := Color("#ffbc6b")
const MINT := Color("#75e6c6")
const CORAL := Color("#ff786b")
const IVORY := Color("#f3ead8")
const STEEL := Color("#a7b5b9")
const FRAME := Color("#435052")
const INK := Color("#101619")
const BAR_SIZE := Vector2(680.0, 98.0)
const PAUSE_RECT := Rect2(13.0, 14.0, 68.0, 70.0)
const SCORE_RECT := Rect2(93.0, 12.0, 315.0, 74.0)
const RECORD_RECT := Rect2(416.0, 12.0, 132.0, 74.0)
const LAMPS_RECT := Rect2(556.0, 12.0, 111.0, 74.0)

var _root: Control
var _bar: Control
var _display: SevenSegment
var _lamps: BallLamps
var _record: Label
var _toast: Panel
var _message: Label
var _pause: ColorRect
var _game_over: ColorRect
var _pause_card: Panel
var _game_over_card: Panel
var _paused_score: Label
var _go_score: Label
var _go_record: Label
var _shown_score := 0.0
var _message_tween: Tween


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.balls_changed.connect(func(n: int) -> void: _lamps.lit = n)
	GameState.message.connect(show_message)
	GameState.game_started.connect(_on_game_started)
	GameState.game_resumed.connect(_on_game_resumed)
	GameState.game_ended.connect(_on_game_ended)
	get_viewport().size_changed.connect(_layout)
	_update_record()
	_layout()


func _process(delta: float) -> void:
	# El display rueda hasta el puntaje real y se reinicia al empezar una partida.
	var target := float(GameState.score)
	if _shown_score > target:
		_shown_score = target
	_shown_score = lerpf(_shown_score, target, 1.0 - exp(-10.0 * delta))
	if target - _shown_score < 1.0:
		_shown_score = target
	_display.value = int(_shown_score)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and GameState.playing:
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if GameState.playing:
				toggle_pause()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if GameState.playing and not get_tree().paused:
				toggle_pause()


func toggle_pause() -> void:
	var tree := get_tree()
	if not tree.paused:
		checkpoint_requested.emit()
	tree.paused = not tree.paused
	_paused_score.text = _format(GameState.score)
	_pause.visible = tree.paused


func show_message(text: String) -> void:
	_message.text = text
	if _message_tween:
		_message_tween.kill()
	_toast.show()
	_toast.modulate.a = 1.0
	_toast.scale = Vector2(0.9, 0.9)
	_message_tween = create_tween()
	_message_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_message_tween.tween_property(_toast, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)
	_message_tween.tween_interval(1.2)
	_message_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)
	_message_tween.tween_callback(_toast.hide)


func _on_game_started() -> void:
	_on_game_resumed()


func _on_game_resumed() -> void:
	_shown_score = float(GameState.score)
	_display.value = GameState.score
	_update_record()
	_game_over.hide()
	_pause.hide()
	get_tree().paused = false


func _on_game_ended(final_score: int, is_record: bool) -> void:
	_update_record()
	_go_score.text = _format(final_score)
	_go_record.text = "¡NUEVO RÉCORD!" if is_record else "RÉCORD  %s" % _format(GameState.high_score)
	_go_record.add_theme_color_override("font_color", MINT if is_record else STEEL)
	_game_over.show()


func _update_record() -> void:
	_record.text = _format(GameState.high_score)
	var font := _record.get_theme_font("font")
	var font_size := 20
	while font_size > 9 and font.get_string_size(_record.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _record.size.x:
		font_size -= 1
	_record.add_theme_font_size_override("font_size", font_size)


func _layout() -> void:
	var insets := Screen.safe_insets(get_viewport())
	var visible := _root.get_viewport_rect().size
	_bar.position = Vector2((visible.x - BAR_SIZE.x) * 0.5, insets.top + 11.0)
	_toast.position = Vector2((visible.x - _toast.size.x) * 0.5, insets.top + 117.0)
	var safe_height: float = visible.y - insets.top - insets.bottom
	for card: Panel in [_pause_card, _game_over_card]:
		var card_center := maxf(card.size.y * 0.5, safe_height * 0.43)
		card.position = Vector2((visible.x - card.size.x) * 0.5, insets.top + card_center - card.size.y * 0.5)


func _build() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_bar()
	_build_toast()
	_build_overlays()


func _build_bar() -> void:
	_bar = Control.new()
	_bar.name = "Backbox"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.size = BAR_SIZE
	_bar.draw.connect(_draw_bar)
	_root.add_child(_bar)

	var menu := Button.new()
	menu.name = "PauseButton"
	menu.tooltip_text = "Pausa"
	menu.position = PAUSE_RECT.position
	menu.size = PAUSE_RECT.size
	menu.focus_mode = Control.FOCUS_NONE
	menu.add_theme_stylebox_override("normal", _box(Color("#2e2220"), 8, Color("#665042")))
	menu.add_theme_stylebox_override("hover", _box(Color("#483128"), 8, AMBER.darkened(0.35)))
	menu.add_theme_stylebox_override("pressed", _box(Color("#1c1a1b"), 8, AMBER))
	menu.draw.connect(func() -> void:
		var icon := AMBER.lightened(0.35) if menu.is_hovered() else AMBER
		menu.draw_rect(Rect2(22.0, 21.0, 7.0, 28.0), icon)
		menu.draw_rect(Rect2(39.0, 21.0, 7.0, 28.0), icon))
	menu.pressed.connect(func() -> void:
		if GameState.playing:
			toggle_pause())
	_bar.add_child(menu)

	_label(_bar, "PUNTAJE", Rect2(107, 15, 179, 20), 15, AMBER, HORIZONTAL_ALIGNMENT_LEFT)
	_display = SevenSegment.new()
	_display.position = Vector2(105.0, 38.0)
	_display.size = Vector2(290.0, 39.0)
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_display)

	_label(_bar, "RÉCORD", Rect2(423, 15, 118, 20), 15, STEEL)
	_record = _label(_bar, "", Rect2(423, 40, 118, 33), 20, IVORY)

	_label(_bar, "BOLAS", Rect2(556, 15, 111, 20), 15, MINT)
	_lamps = BallLamps.new()
	_lamps.position = Vector2(565.0, 39.0)
	_lamps.size = Vector2(93.0, 32.0)
	_lamps.total = GameState.BALLS_PER_GAME
	_lamps.lit = GameState.balls_left
	_lamps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_lamps)


func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, BAR_SIZE)
	_bar.draw_style_box(_box(Color("#040809"), 13), Rect2(Vector2(0.0, 4.0), BAR_SIZE))
	_bar.draw_style_box(_box(Color("#232f33"), 12, FRAME), rect)
	_bar.draw_line(Vector2(15, 4), Vector2(665, 4), Color("#778688"), 1.0, true)
	_bar.draw_line(Vector2(15, 93), Vector2(665, 93), Color("#0e1619"), 2.0, true)
	for housing: Rect2 in [SCORE_RECT, RECORD_RECT, LAMPS_RECT]:
		_bar.draw_style_box(_box(Color("#111719"), 7, Color("#101516")), housing)
		_bar.draw_line(Vector2(housing.position.x + 8, housing.end.y), Vector2(housing.end.x - 8, housing.end.y), Color("#536164"), 1.0, true)
	_bar.draw_style_box(_box(Color("#211715"), 6, Color("#393028")), Rect2(99, 35, 303, 45))
	for y in range(39, 81, 4):
		_bar.draw_line(Vector2(102, y), Vector2(399, y), Color(0.96, 0.55, 0.27, 0.06))
	_bar.draw_line(Vector2(432, 33), Vector2(532, 33), Color("#303b3f"))
	_bar.draw_line(Vector2(574, 33), Vector2(649, 33), Color("#27443e"))


func _build_toast() -> void:
	_toast = Panel.new()
	_toast.name = "Status"
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.size = Vector2(292.0, 47.0)
	_toast.pivot_offset = _toast.size * 0.5
	_toast.add_theme_stylebox_override("panel", _box(Color("#172321"), 8, Color("#507267")))
	_toast.draw.connect(func() -> void:
		for x in [17.0, 275.0]:
			_toast.draw_circle(Vector2(x, 24.0), 7.0, Color(MINT, 0.12), true, -1.0, true)
			_toast.draw_circle(Vector2(x, 24.0), 3.0, MINT, true, -1.0, true))
	_message = _label(_toast, "", Rect2(29, 0, 234, 47), 22, IVORY)
	_toast.hide()
	_root.add_child(_toast)


func _build_overlays() -> void:
	_pause = _overlay("Pause")
	_pause_card = _card(_pause, Vector2(520.0, 352.0), MINT)
	_label(_pause_card, "PAUSA", Rect2(35, 36, 450, 57), 52, IVORY)
	_paused_score = _score_readout(_pause_card, 106.0)
	_button(_pause_card, "Continuar", Rect2(36, 217, 448, 66), MINT, toggle_pause)
	_button(_pause_card, "Reiniciar", Rect2(36, 290, 220, 42), MINT, GameState.start_game, false)
	_button(_pause_card, "Mesas", Rect2(264, 290, 220, 42), MINT, _open_tables, false)

	_game_over = _overlay("GameOver")
	_game_over_card = _card(_game_over, Vector2(520.0, 403.0), CORAL)
	_label(_game_over_card, "FIN DEL JUEGO", Rect2(35, 36, 450, 57), 49, IVORY)
	_go_score = _score_readout(_game_over_card, 106.0)
	_go_record = _label(_game_over_card, "", Rect2(35, 199, 450, 45), 23, MINT)
	_button(_game_over_card, "Jugar de nuevo", Rect2(36, 266, 448, 72), MINT, GameState.start_game)
	_button(_game_over_card, "Mesas", Rect2(36, 345, 448, 42), MINT, _open_tables, false)


func _open_tables() -> void:
	checkpoint_requested.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/table_select.tscn")


func _overlay(overlay_name: String) -> ColorRect:
	var shade := ColorRect.new()
	shade.name = overlay_name
	shade.color = Color(0.015, 0.024, 0.032, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.hide()
	_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return shade


func _card(parent: Control, dimensions: Vector2, accent: Color) -> Panel:
	var card := Panel.new()
	card.size = dimensions
	card.add_theme_stylebox_override("panel", _box(INK, 18, FRAME))
	card.draw.connect(func() -> void:
		var end := card.size
		card.draw_line(Vector2(28, 18), Vector2(end.x - 28, 18), accent.darkened(0.38), 2.0, true)
		card.draw_line(Vector2(end.x * 0.5 - 52, 18), Vector2(end.x * 0.5 + 52, 18), accent, 4.0, true)
		for point in [Vector2(18, 42), Vector2(end.x - 18, 42), Vector2(18, end.y - 18), end - Vector2(18, 18)]:
			card.draw_circle(point, 4.0, Color("#384547"), true, -1.0, true)
			card.draw_line(point - Vector2(2, 0), point + Vector2(2, 0), Color("#879399"), 1.0, true))
	parent.add_child(card)
	return card


func _score_readout(card: Panel, y: float) -> Label:
	var inset := Panel.new()
	inset.position = Vector2(36, y)
	inset.size = Vector2(448, 90)
	inset.add_theme_stylebox_override("panel", _box(Color("#211715"), 10, Color("#54392b")))
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inset)
	_label(inset, "PUNTAJE", Rect2(0, 7, 448, 22), 16, AMBER)
	return _label(inset, "", Rect2(12, 26, 424, 56), 45, IVORY)


func _button(parent: Control, title: String, rect: Rect2, accent: Color, action: Callable, primary := true) -> void:
	var button := Button.new()
	button.text = title
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 29 if primary else 23)
	if primary:
		var label_color := Color("#111b1b")
		button.add_theme_color_override("font_color", label_color)
		button.add_theme_color_override("font_hover_color", label_color)
		button.add_theme_color_override("font_pressed_color", label_color)
		button.add_theme_stylebox_override("normal", _box(accent, 10, accent.lightened(0.32)))
		button.add_theme_stylebox_override("hover", _box(accent.lightened(0.22), 10, accent.lightened(0.46)))
		button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.22), 10, accent))
	else:
		button.add_theme_color_override("font_color", STEEL)
		button.add_theme_color_override("font_hover_color", IVORY)
		button.add_theme_stylebox_override("normal", _box(INK, 8))
		button.add_theme_stylebox_override("hover", _box(Color("#253336"), 8))
		button.add_theme_stylebox_override("pressed", _box(Color("#1b272b"), 8))
	button.pressed.connect(action)
	parent.add_child(button)


func _label(parent: Control, title: String, rect: Rect2, font_size: int, tint: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = title
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label


func _box(color: Color, radius: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(2)
	return box


func _format(n: int) -> String:
	var text := str(n)
	var suffix := ""
	while text.length() > 3:
		suffix = "." + text.substr(text.length() - 3) + suffix
		text = text.substr(0, text.length() - 3)
	return text + suffix
