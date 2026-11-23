extends CanvasLayer
## Marcador, avisos de partida y paneles del gabinete.

signal checkpoint_requested

const Arcade := preload("res://scripts/ui/arcade_style.gd")
const SevenSegment := preload("res://scripts/ui/seven_segment.gd")
const BallLamps := preload("res://scripts/ui/ball_lamps.gd")
const Records := preload("res://scripts/util/records.gd")
const BackNav := preload("res://scripts/util/back_nav.gd")
const Screen := preload("res://scripts/util/screen.gd")

var _t: TableTheme

@onready var _root: Control = $Root
@onready var _bar: Panel = $Root/Backbox
@onready var _display: SevenSegment = $Root/Backbox/ScoreWell/Glass/Display
@onready var _lamps: BallLamps = $Root/Backbox/BallWell/BallLamps
@onready var _record: Label = $Root/Backbox/RecordWell/Record
@onready var _toast: Panel = $Root/Status
@onready var _message: Label = $Root/Status/Message
@onready var _pause: CanvasLayer = $PauseMenu
@onready var _game_over: ColorRect = $Root/GameOver
@onready var _game_over_card: Panel = $Root/GameOver/Card
@onready var _go_score: Label = $Root/GameOver/Card/ScoreReadout/Score
@onready var _go_record: Label = $Root/GameOver/Card/Record
@onready var _go_bonus: Label = $Root/GameOver/Card/Bonus
@onready var _go_entry: Control = $Root/GameOver/Card/Initials
@onready var _go_save: Button = $Root/GameOver/Card/SaveInitials
@onready var _go_play: Button = $Root/GameOver/Card/PlayAgain
@onready var _go_tables: Button = $Root/GameOver/Card/Tables
@onready var _bar_top := _bar.offset_top
@onready var _toast_top := _toast.offset_top
@onready var _compact_card_height := _game_over_card.size.y
@onready var _play_top := _go_play.position.y
@onready var _tables_top := _go_tables.position.y
@onready var _record_font_size := _record.get_theme_font_size("font_size")

var _shown_score := 0.0
var _message_tween: Tween
var _message_queue: Array[Dictionary] = []
var _message_active := false
var _bonus_announcement := ""


func _enter_tree() -> void:
	# Los tests que aíslan récords también aíslan la configuración de la pista.
	if GameState.record_path != "user://records.cfg":
		$FirstRunHint.settings_path = GameState.record_path + ".hint.cfg"


func _ready() -> void:
	# La mesa termina de seleccionar su id después del _ready() del HUD.
	var parent_table = get_parent().get("table_id")
	_t = GameState.active_theme(parent_table if parent_table is String else "")
	_apply_theme()
	_toast.draw.connect(_draw_toast)
	_game_over_card.draw.connect(_draw_game_over_card)
	_go_entry.focus_next = _go_entry.get_path_to(_go_save)
	_go_save.focus_neighbor_top = _go_save.get_path_to(_go_entry)
	_go_save.focus_neighbor_bottom = _go_save.get_path_to(_go_play)
	_go_play.focus_neighbor_bottom = _go_play.get_path_to(_go_tables)
	_go_tables.focus_neighbor_top = _go_tables.get_path_to(_go_play)
	for button: Button in [_go_save, _go_play, _go_tables]:
		Arcade.enable_pad_accept(button)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("focus", Arcade.focus_ring(_t.text_color))
		button.focus_neighbor_left = NodePath(".")
		button.focus_neighbor_right = NodePath(".")
	_lamps.total = GameState.BALLS_PER_GAME
	_lamps.lit = GameState.balls_left
	var plunger := get_parent().get_node_or_null("Table/Plunger")
	if plunger:
		plunger.launched.connect($FirstRunHint.on_launched)
	GameState.balls_changed.connect(func(n: int) -> void: _lamps.lit = n)
	GameState.message.connect(show_message)
	GameState.bonus_awarded.connect(_on_bonus_awarded)
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
	# En el fin de partida solo Esc/B: la P (pausa) puede ser una letra de las iniciales.
	var back := BackNav.is_back_event(event) if GameState.playing else (_game_over.visible and event.is_action_pressed("ui_cancel"))
	if back:
		get_viewport().set_input_as_handled()
		go_back()


## Atrás en la mesa: abre la pausa; con la pausa abierta la cierra y sigue jugando (las opciones, si
## están abiertas, se cierran solas primero). En la pantalla de fin de partida vuelve al selector.
func go_back() -> void:
	if _pause.options_open() or not BackNav.claim():
		return
	if GameState.playing:
		toggle_pause()
	elif _game_over.visible:
		_open_tables.call_deferred()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			go_back()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if GameState.playing and not get_tree().paused:
				toggle_pause()


func _on_pause_pressed() -> void:
	if GameState.playing:
		toggle_pause()


func toggle_pause() -> void:
	var tree := get_tree()
	if not tree.paused:
		checkpoint_requested.emit()
	tree.paused = not tree.paused
	_pause.set_paused(tree.paused)


func show_message(text: String) -> void:
	# La señal de bonus viene seguida del mismo aviso textual de GameState.
	if text == _bonus_announcement and not text.is_empty():
		_bonus_announcement = ""
		return
	_enqueue_message({"text": text})


func _on_bonus_awarded(base: int, multiplier: int, total: int) -> void:
	_bonus_announcement = "BONUS %d X%d" % [base, multiplier]
	_clear_bonus_announcement.call_deferred()
	_enqueue_message({"text": _bonus_announcement, "base": base, "multiplier": multiplier, "total": total})


func _clear_bonus_announcement() -> void:
	_bonus_announcement = ""


func _enqueue_message(entry: Dictionary) -> void:
	_message_queue.append(entry)
	# Los avisos importantes pueden superar el límite si no hay descartables.
	while _message_queue.size() > 3:
		var discard := -1
		for i in _message_queue.size():
			var text: String = _message_queue[i]["text"]
			if not _important_message(text):
				discard = i
				break
		if discard < 0:
			break
		_message_queue.remove_at(discard)
	if not _message_active:
		_show_next_message()


func _important_message(text: String) -> bool:
	var upper := text.to_upper()
	return text.begins_with("¡") or upper.contains("BONUS") or upper.contains("JACKPOT")


func _show_next_message() -> void:
	if _message_queue.is_empty():
		_message_active = false
		_toast.hide()
		return
	_message_active = true
	var entry: Dictionary = _message_queue.pop_front()
	var text: String = entry["text"]
	_message.text = text
	_message.modulate.a = 1.0
	_toast.show()
	_root.move_child(_toast, -1)
	_toast.modulate.a = 1.0
	_toast.scale = Vector2(0.9, 0.9)
	_message_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_message_tween.tween_property(_toast, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)
	if entry.has("total"):
		_message_tween.tween_method(_update_bonus_text.bind(entry["multiplier"]), float(entry["base"]), float(entry["total"]), 0.8)
	else:
		if text.to_upper().contains("JACKPOT"):
			for i in 2:
				_message_tween.tween_property(_message, "modulate:a", 0.2, 0.09)
				_message_tween.tween_property(_message, "modulate:a", 1.0, 0.09)
			_message_tween.tween_interval(0.59)
		else:
			_message_tween.tween_interval(0.95)
	_message_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)
	_message_tween.tween_callback(_show_next_message)


func _update_bonus_text(value: float, multiplier: int) -> void:
	_message.text = "BONUS %s  X%d" % [_format(roundi(value)), multiplier]


func _on_game_started() -> void:
	_message_queue.clear()
	if _message_tween:
		_message_tween.kill()
	_message_active = false
	_toast.hide()
	_on_game_resumed()


func _on_game_resumed() -> void:
	_shown_score = float(GameState.score)
	_display.value = GameState.score
	_update_record()
	_game_over.hide()
	_pause.set_paused(false)
	get_tree().paused = false


func _on_game_ended(final_score: int, is_record: bool) -> void:
	_update_record()
	_go_score.text = _format(final_score)
	var bonus_total: int = GameState.last_result.get("bonus_total", 0)
	_go_bonus.text = "BONUS COBRADO  %s" % _format(bonus_total) if bonus_total > 0 else _t.no_bonus_text
	var rank: int = GameState.last_result.get("rank", 0)
	if rank > 0:
		_go_record.text = _t.new_record_text if is_record else "¡PUESTO %d DE %d!" % [rank, Records.MAX_ENTRIES]
		_go_entry.set_initials(GameState.pending_initials)
	else:
		_go_record.text = "RÉCORD  %s" % _format(GameState.high_score)
	_go_record.add_theme_color_override("font_color", _t.game_over_record_color if rank > 0 else _t.muted_color)
	_arrange_game_over(rank > 0)
	_game_over.show()
	if rank > 0:
		_go_entry.grab_focus()
	else:
		_go_play.grab_focus()


## Con puesto en el top 10 aparece el ingreso de iniciales y la tarjeta crece.
func _arrange_game_over(entering: bool) -> void:
	_go_entry.visible = entering
	_go_save.visible = entering
	var shift := 0.0
	if entering:
		_go_save.position.y = _go_entry.position.y + _go_entry.size.y + 10.0
		shift = _go_save.position.y + _go_save.size.y + 10.0 - _play_top
	_go_play.position.y = _play_top + shift
	_go_tables.position.y = _tables_top + shift
	_game_over_card.size.y = _compact_card_height + shift
	_go_play.focus_neighbor_top = _go_play.get_path_to(_go_save if entering else _go_tables)
	_go_tables.focus_neighbor_bottom = _go_tables.get_path_to(_go_entry if entering else _go_play)
	_game_over_card.queue_redraw()
	_layout()


func _on_initials_changed(initials: String) -> void:
	GameState.pending_initials = initials


func _save_initials() -> void:
	GameState.pending_initials = _go_entry.initials()
	var rank := GameState.commit_pending_record()
	if rank > 0:
		_go_record.text = "GUARDADO  PUESTO %d" % rank
	_go_entry.hide()
	_go_save.hide()
	_arrange_game_over(false)
	_go_play.grab_focus()
	_go_record.add_theme_color_override("font_color", _t.game_over_record_color)


func _play_again() -> void:
	GameState.commit_pending_record()
	GameState.start_game()


func _update_record() -> void:
	_record.text = _format(GameState.high_score)
	var font := _record.get_theme_font("font")
	var font_size := _record_font_size
	while font_size > 9 and font.get_string_size(_record.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _record.size.x:
		font_size -= 1
	_record.add_theme_font_size_override("font_size", font_size)


func _layout() -> void:
	var insets := Screen.safe_insets(get_viewport())
	var visible := _root.get_viewport_rect().size
	_bar.position.y = insets.top + _bar_top
	_toast.position.y = insets.top + _toast_top
	var safe_height: float = visible.y - insets.top - insets.bottom
	var half_card := _game_over_card.size.y * 0.5
	_game_over_card.position.y = insets.top + maxf(0.0, safe_height * 0.43 - half_card)


func _apply_theme() -> void:
	var ink := _t.panel_ink_color
	var frame := _t.panel_frame_color
	var score_color := _t.display_color
	var toast_color := _t.toast_accent
	_tint_panel(_bar, ink.lerp(frame, 0.22), frame)
	$Root/Backbox/TopEdge.color = frame.lightened(0.14)
	for well: Panel in [$Root/Backbox/ScoreWell, $Root/Backbox/RecordWell, $Root/Backbox/BallWell]:
		_tint_panel(well, ink.darkened(0.12), frame.darkened(0.32))
	_tint_panel($Root/Backbox/ScoreWell/Glass, ink.darkened(0.45).lerp(score_color, 0.09), score_color.lerp(ink, 0.73))
	_tint_button($Root/Backbox/PauseButton, ink.lerp(frame, 0.36), frame)
	$Root/Backbox/PauseButton/Icon.modulate = _t.menu_accent
	_tint_label($Root/Backbox/ScoreWell/Caption, _t.score_label_color)
	_tint_label($Root/Backbox/RecordWell/Caption, _t.record_label_color)
	_tint_label($Root/Backbox/BallWell/Caption, _t.balls_label_color)
	$Root/Backbox/RecordWell/Divider.color = frame.darkened(0.26)
	$Root/Backbox/BallWell/Divider.color = _t.balls_label_color.lerp(ink, 0.78)
	_tint_label(_record, _t.text_color)
	_display.on_color = score_color
	_lamps.on_color = _t.balls_label_color

	_tint_panel(_toast, ink.lerp(toast_color, 0.06), toast_color.lerp(frame, 0.28).darkened(0.38))
	_tint_label(_message, _t.text_color)
	_game_over.color = _t.backdrop_color
	_tint_panel(_game_over_card, ink, frame)
	_tint_panel($Root/GameOver/Card/ScoreReadout, ink.lerp(score_color, 0.08), score_color.lerp(ink, 0.72))
	var title: Label = $Root/GameOver/Card/Title
	title.text = _t.game_over_title
	_tint_label(title, _t.text_color)
	_tint_label($Root/GameOver/Card/ScoreReadout/Caption, _t.score_label_color)
	_tint_label(_go_score, _t.text_color)
	_tint_label(_go_bonus, _t.game_over_bonus_color)
	_tint_label(_go_record, _t.game_over_record_color)
	_tint_button(_go_play, toast_color, toast_color.lightened(0.32))
	for button: Button in [_go_save, _go_tables]:
		button.add_theme_color_override("font_color", _t.muted_color)
		button.add_theme_color_override("font_hover_color", _t.text_color)
		_tint_button(button, ink, frame)


func _tint_label(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


func _tint_panel(panel: Panel, ink: Color, frame: Color) -> void:
	panel.add_theme_stylebox_override("panel", _tinted_box(panel.get_theme_stylebox("panel"), ink, frame))


func _tint_button(button: Button, ink: Color, frame: Color) -> void:
	button.add_theme_stylebox_override("normal", _tinted_box(button.get_theme_stylebox("normal"), ink, frame))
	button.add_theme_stylebox_override("hover", _tinted_box(button.get_theme_stylebox("hover"), ink.lightened(0.14), frame.lightened(0.20)))
	button.add_theme_stylebox_override("pressed", _tinted_box(button.get_theme_stylebox("pressed"), ink.darkened(0.22), frame))


func _tinted_box(source: StyleBoxFlat, ink: Color, frame: Color) -> StyleBoxFlat:
	# Cada mesa pinta su copia y conserva los bordes y las sombras de la escena.
	var style := source.duplicate() as StyleBoxFlat
	style.bg_color = ink
	style.border_color = frame
	return style


func _draw_toast() -> void:
	for x: float in [17.0, _toast.size.x - 17.0]:
		var point := Vector2(x, _toast.size.y * 0.5)
		_toast.draw_circle(point, 7.0, Color(_t.toast_accent, 0.12), true, -1.0, true)
		_toast.draw_circle(point, 3.0, _t.toast_accent, true, -1.0, true)


func _draw_game_over_card() -> void:
	var end := _game_over_card.size
	var accent := _t.game_over_accent
	_game_over_card.draw_line(Vector2(28, 18), Vector2(end.x - 28, 18), accent.darkened(0.38), 2.0, true)
	_game_over_card.draw_line(Vector2(end.x * 0.5 - 52, 18), Vector2(end.x * 0.5 + 52, 18), accent, 4.0, true)
	for point: Vector2 in [Vector2(18, 42), Vector2(end.x - 18, 42), Vector2(18, end.y - 18), end - Vector2(18, 18)]:
		_game_over_card.draw_circle(point, 4.0, _t.panel_frame_color, true, -1.0, true)
		_game_over_card.draw_line(point - Vector2(2, 0), point + Vector2(2, 0), _t.muted_color, 1.0, true)


func _open_tables() -> void:
	GameState.commit_pending_record()
	checkpoint_requested.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/table_select.tscn")


func _format(n: int) -> String:
	var text := str(n)
	var suffix := ""
	while text.length() > 3:
		suffix = "." + text.substr(text.length() - 3) + suffix
		text = text.substr(0, text.length() - 3)
	return text + suffix
