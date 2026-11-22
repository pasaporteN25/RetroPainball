extends CanvasLayer
## Zonas táctiles para los dos pulgares. La mitad izquierda de la parte baja
## de la pantalla es el flipper izquierdo y la mitad derecha, el derecho.
## Si hay una bola esperando en el carril, la zona derecha pasa a ser el
## lanzador (mantener = cargar, soltar = disparar).
##
## Todo se traduce a las mismas acciones que usa el teclado (flipper_left,
## flipper_right, launch), así la mesa no sabe de dónde viene el input.

## Desde qué altura (proporción de la pantalla) empiezan las zonas.
@export_range(0.0, 1.0) var zone_top_ratio := 0.5
## Si es true, la altura sale de las opciones del jugador (U-07).
@export var use_settings := true
@export var pad_height := 78.0

## Gesto de nudge: deslizar el pulgar hacia arriba al menos esto (px) en menos de NUDGE_SWIPE_TIME.
@export var nudge_swipe_distance := 110.0
const NUDGE_SWIPE_TIME := 0.35

const Screen := preload("res://scripts/util/screen.gd")
const MINT := Color("#63e0c1")
const AMBER := Color("#ffb75b")

## índice de dedo -> acción que mantiene apretada
var _touches := {}
## índice de dedo -> {pos, time} donde empezó el gesto (se borra al disparar el nudge)
var _swipes := {}
var _canvas: Control
var _font: Font
var _bottom_inset := 0.0
var _last_state := Vector4(-1, -1, -1, -1)


func _ready() -> void:
	layer = 5
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_pads)
	add_child(_canvas)
	get_viewport().size_changed.connect(_layout)
	Settings.changed.connect(_sync_settings)
	_sync_settings()
	_layout()


func _sync_settings() -> void:
	if use_settings:
		zone_top_ratio = Settings.zone_top_ratio()


func _process(_delta: float) -> void:
	var action := &"launch" if GameState.ball_in_lane else &"flipper_right"
	var state := Vector4(
		float(GameState.playing),
		float(Input.is_action_pressed(&"flipper_left")),
		float(Input.is_action_pressed(action)),
		GameState.plunger_charge if GameState.ball_in_lane else -1.0
	)
	if state != _last_state:
		_last_state = state
		_canvas.queue_redraw()


func _layout() -> void:
	_bottom_inset = Screen.safe_insets(get_viewport()).bottom
	_canvas.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		release_all()


func _exit_tree() -> void:
	release_all()


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed:
			_press(touch.index, touch.position)
		else:
			_release(touch.index)
		return
	var drag := event as InputEventScreenDrag
	if drag and _touches.has(drag.index):
		_check_swipe(drag)
		# Si el dedo cruza al otro lado, cambia de flipper.
		var action := _action_for(drag.position)
		var current: StringName = _touches[drag.index]
		if action != &"" and action != current and current != &"launch":
			_release(drag.index)
			_press(drag.index, drag.position)


## Un deslizamiento rápido hacia arriba con un dedo de flipper da un empujón.
func _check_swipe(drag: InputEventScreenDrag) -> void:
	if not _swipes.has(drag.index) or _touches[drag.index] == &"launch":
		return
	var start: Dictionary = _swipes[drag.index]
	var moved: Vector2 = drag.position - start.pos
	var elapsed: float = (Time.get_ticks_msec() - int(start.time)) / 1000.0
	if elapsed > NUDGE_SWIPE_TIME:
		# Gesto lento: no es un empujón; vuelve a medir desde acá.
		_swipes[drag.index] = {"pos": drag.position, "time": Time.get_ticks_msec()}
	elif -moved.y >= nudge_swipe_distance and absf(moved.x) < -moved.y:
		_swipes.erase(drag.index)
		GameState.nudge(Vector2(moved.x, moved.y))


func release_all() -> void:
	for index in _touches.keys():
		_release(index)


func _action_for(pos: Vector2) -> StringName:
	var visible := _canvas.get_viewport_rect().size
	if pos.y < visible.y * zone_top_ratio:
		return &""
	if pos.x < visible.x * 0.5:
		return &"flipper_left"
	return &"launch" if GameState.ball_in_lane else &"flipper_right"


func _press(index: int, pos: Vector2) -> void:
	if not GameState.playing or get_tree().paused:
		return
	var action := _action_for(pos)
	if action == &"":
		return
	_touches[index] = action
	_swipes[index] = {"pos": pos, "time": Time.get_ticks_msec()}
	Input.action_press(action)


func _release(index: int) -> void:
	if not _touches.has(index):
		return
	var action: StringName = _touches[index]
	_touches.erase(index)
	_swipes.erase(index)
	if not _touches.values().has(action):
		Input.action_release(action)


func _draw_pads() -> void:
	if not GameState.playing:
		return
	var visible := _canvas.get_viewport_rect().size
	var top := visible.y - _bottom_inset - pad_height - 19.0
	var deck_top := top - 14.0
	_canvas.draw_rect(Rect2(0, deck_top, visible.x, visible.y - deck_top), Color("#0a1018"))
	_canvas.draw_line(Vector2(0, deck_top), Vector2(visible.x, deck_top), Color("#354855"), 2.0)
	_canvas.draw_line(Vector2(0, deck_top + 4), Vector2(visible.x, deck_top + 4), Color("#171f29"), 3.0)
	var width := visible.x * 0.5 - 28.0
	var left := Rect2(18.0, top, width, pad_height)
	var right := Rect2(visible.x * 0.5 + 10.0, top, width, pad_height)
	_draw_pad(left, "FLIPPER IZQ.", Vector2.LEFT, MINT, Input.is_action_pressed(&"flipper_left"))
	if GameState.ball_in_lane:
		var charging := Input.is_action_pressed(&"launch")
		var hint := "SOLTÁ PARA LANZAR" if charging else "MANTENÉ PARA CARGAR"
		_draw_pad(right, "LANZAR", Vector2.UP, AMBER, charging, hint, GameState.plunger_charge)
	else:
		_draw_pad(right, "FLIPPER DER.", Vector2.RIGHT, MINT, Input.is_action_pressed(&"flipper_right"))


func _draw_pad(rect: Rect2, label: String, direction: Vector2, accent: Color, pressed: bool,
		hint := "", charge := 0.0) -> void:
	var corner := 13.0
	var outline := PackedVector2Array([
		rect.position + Vector2(corner, 0), Vector2(rect.end.x - corner, rect.position.y),
		Vector2(rect.end.x, rect.position.y + corner), Vector2(rect.end.x, rect.end.y - corner),
		Vector2(rect.end.x - corner, rect.end.y), Vector2(rect.position.x + corner, rect.end.y),
		Vector2(rect.position.x, rect.end.y - corner), Vector2(rect.position.x, rect.position.y + corner),
	])
	_canvas.draw_colored_polygon(outline, Color("#151f2a").lerp(accent, 0.15 if pressed else 0.04))
	outline.append(outline[0])
	_canvas.draw_polyline(outline, Color(accent, 0.84 if pressed else 0.32), 2.0, true)
	var icon := rect.position + Vector2(37.0, rect.size.y * 0.5)
	var cross := direction.orthogonal() * 9.0
	_canvas.draw_circle(icon, 19.0, Color(accent, 0.25 if pressed else 0.12), true, -1.0, true)
	_canvas.draw_polyline(PackedVector2Array([
		icon - direction * 3.0 + cross, icon + direction * 7.0, icon - direction * 3.0 - cross,
	]), accent, 3.0, true)
	var title_y := 47.0 if hint.is_empty() else 34.0
	_canvas.draw_string(_font, rect.position + Vector2(67, title_y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#e1edea"))
	if hint.is_empty():
		return
	_canvas.draw_string(_font, rect.position + Vector2(67, 54), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(accent, 0.87))
	var bar := Rect2(rect.position + Vector2(68, 62), Vector2(rect.size.x - 88, 4))
	_canvas.draw_rect(bar, Color(accent, 0.15))
	if charge > 0.0:
		_canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * charge, bar.size.y)), accent)
