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
@export var pad_height := 116.0

const Screen := preload("res://scripts/util/screen.gd")

## índice de dedo -> acción que mantiene apretada
var _touches := {}
var _canvas: Control
var _font: Font


func _ready() -> void:
	layer = 5
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_pads)
	add_child(_canvas)


func _process(_delta: float) -> void:
	_canvas.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
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
		# Si el dedo cruza al otro lado, cambia de flipper.
		var action := _action_for(drag.position)
		var current: StringName = _touches[drag.index]
		if action != &"" and action != current and current != &"launch":
			_release(drag.index)
			_press(drag.index, drag.position)


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
	Input.action_press(action)


func _release(index: int) -> void:
	if not _touches.has(index):
		return
	var action: StringName = _touches[index]
	_touches.erase(index)
	if not _touches.values().has(action):
		Input.action_release(action)


func _draw_pads() -> void:
	if not GameState.playing:
		return
	var visible := _canvas.get_viewport_rect().size
	var bottom: float = visible.y - Screen.safe_insets(get_viewport()).bottom - 14.0
	var w := visible.x * 0.5 - 24.0
	var left := Rect2(16.0, bottom - pad_height, w, pad_height)
	var right := Rect2(visible.x * 0.5 + 8.0, bottom - pad_height, w, pad_height)
	var right_label := "LANZAR" if GameState.ball_in_lane else "▶"
	var right_action := &"launch" if GameState.ball_in_lane else &"flipper_right"
	_draw_pad(left, "◀", Input.is_action_pressed(&"flipper_left"))
	var charge := GameState.plunger_charge if GameState.ball_in_lane else 0.0
	_draw_pad(right, right_label, Input.is_action_pressed(right_action), charge)


## fill: 0..1, el botón se llena de izquierda a derecha (carga del lanzador).
func _draw_pad(rect: Rect2, label: String, pressed: bool, fill := 0.0) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.16 if pressed else 0.05)
	box.border_color = Color(1, 1, 1, 0.35 if pressed else 0.14)
	box.set_border_width_all(2)
	box.set_corner_radius_all(28)
	_canvas.draw_style_box(box, rect)
	if fill > 0.0:
		var bar := StyleBoxFlat.new()
		bar.bg_color = Color(1.0, 0.45, 0.1, 0.45)
		bar.set_corner_radius_all(28)
		_canvas.draw_style_box(bar, Rect2(rect.position, Vector2(maxf(56.0, rect.size.x * fill), rect.size.y)))
	var size := 34
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := rect.get_center() + Vector2(-w * 0.5, size * 0.35)
	_canvas.draw_string(_font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 1, 1, 0.55 if pressed else 0.3))
