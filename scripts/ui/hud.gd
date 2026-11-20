extends CanvasLayer
## HUD: barra superior (menú, display de 7 segmentos, vidas), mensajes,
## pausa y fin de partida. Por ahora se arma por código; cuando el diseño de
## las skins se asiente, conviene pasarlo a una escena editable.

const SevenSegment := preload("res://scripts/ui/seven_segment.gd")
const BallLamps := preload("res://scripts/ui/ball_lamps.gd")
const Screen := preload("res://scripts/util/screen.gd")

const BAR_HEIGHT := 112.0

var _root: Control
var _bar: Control
var _display: SevenSegment
var _lamps: BallLamps
var _message: Label
var _pause: Control
var _game_over: Control
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
	GameState.game_ended.connect(_on_game_ended)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	# Contador que "rueda" hasta el puntaje real.
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
	tree.paused = not tree.paused
	_pause.visible = tree.paused


func show_message(text: String) -> void:
	_message.text = text
	if _message_tween:
		_message_tween.kill()
	_message.modulate.a = 1.0
	_message.scale = Vector2(0.6, 0.6)
	_message_tween = create_tween()
	_message_tween.tween_property(_message, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_message_tween.tween_interval(1.2)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.4)


func _on_game_started() -> void:
	_shown_score = 0.0
	_game_over.visible = false
	_pause.visible = false
	get_tree().paused = false


func _on_game_ended(final_score: int, is_record: bool) -> void:
	_go_score.text = "Puntaje: %s" % _format(final_score)
	_go_record.text = "¡NUEVO RÉCORD!" if is_record else "Récord: %s" % _format(GameState.high_score)
	_game_over.visible = true


func _layout() -> void:
	var insets := Screen.safe_insets(get_viewport())
	_bar.position.y = insets.top
	_message.position.y = insets.top + BAR_HEIGHT + 24.0


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 36
	_root.theme = theme
	add_child(_root)

	# Barra superior tipo "backbox".
	_bar = Control.new()
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.size = Vector2(720.0, BAR_HEIGHT)
	_root.add_child(_bar)

	var menu := Button.new()
	menu.text = "II"
	menu.position = Vector2(14.0, 14.0)
	menu.size = Vector2(84.0, 84.0)
	menu.focus_mode = Control.FOCUS_NONE
	menu.add_theme_stylebox_override("normal", _box(Color(0.12, 0.13, 0.18), 18))
	menu.add_theme_stylebox_override("hover", _box(Color(0.18, 0.19, 0.26), 18))
	menu.add_theme_stylebox_override("pressed", _box(Color(0.25, 0.26, 0.34), 18))
	menu.pressed.connect(func() -> void:
		if GameState.playing:
			toggle_pause())
	_bar.add_child(menu)

	var display_panel := Panel.new()
	display_panel.position = Vector2(112.0, 12.0)
	display_panel.size = Vector2(440.0, 88.0)
	display_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display_panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.01, 0.01), 10, Color(0.3, 0.12, 0.05)))
	_bar.add_child(display_panel)

	_display = SevenSegment.new()
	_display.position = Vector2(14.0, 12.0)
	_display.size = Vector2(412.0, 64.0)
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display_panel.add_child(_display)

	_lamps = BallLamps.new()
	_lamps.position = Vector2(566.0, 30.0)
	_lamps.size = Vector2(140.0, 40.0)
	_lamps.total = GameState.BALLS_PER_GAME
	_lamps.lit = GameState.balls_left
	_lamps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_lamps)

	var balls_label := Label.new()
	balls_label.text = "BOLAS"
	balls_label.add_theme_font_size_override("font_size", 18)
	balls_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	balls_label.position = Vector2(566.0, 72.0)
	balls_label.size = Vector2(140.0, 24.0)
	balls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar.add_child(balls_label)

	# Mensajes grandes en el centro ("¡BOLA SALVADA!", "BOLA 2"...).
	_message = Label.new()
	_message.size = Vector2(720.0, 80.0)
	_message.pivot_offset = Vector2(360.0, 40.0)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 52)
	_message.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.add_theme_constant_override("outline_size", 10)
	_message.modulate.a = 0.0
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_message)

	_pause = _overlay("PAUSA")
	var pause_box: VBoxContainer = _pause.get_node("Box")
	pause_box.add_child(_button("Continuar", toggle_pause))
	pause_box.add_child(_button("Reiniciar", func() -> void: GameState.start_game()))

	_game_over = _overlay("FIN DEL JUEGO")
	var go_box: VBoxContainer = _game_over.get_node("Box")
	_go_score = Label.new()
	_go_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_box.add_child(_go_score)
	_go_record = Label.new()
	_go_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_record.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	go_box.add_child(_go_record)
	go_box.add_child(_button("Jugar de nuevo", func() -> void: GameState.start_game()))


func _overlay(title: String) -> Control:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	_root.add_child(shade)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size = Vector2(420.0, 0.0)
	box.add_theme_constant_override("separation", 24)
	shade.add_child(box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	box.add_child(label)
	# Que el centro quede más arriba que las zonas de los pulgares.
	box.position.y -= 160.0
	return shade


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420.0, 96.0)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _box(Color(0.15, 0.16, 0.22), 20))
	b.add_theme_stylebox_override("hover", _box(Color(0.2, 0.21, 0.29), 20))
	b.add_theme_stylebox_override("pressed", _box(Color(0.3, 0.31, 0.4), 20))
	b.pressed.connect(action)
	return b


func _box(color: Color, radius: int, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(3)
	return s


func _format(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
