extends Node
## Modo de pruebas (Q-02). Solo para desarrollo: se activa con el flag `--test-mode` en una build de
## debug (`godot --path . -- --test-mode`) y nunca en un build exportado de release.
## main.gd lo agrega a la mesa activa; el resto del juego no sabe que existe.
##
## F1 multibola · F2 bola infinita · F3 colisiones · F4 velocidad (0.25x, 0.5x, 1x, 2x)

const Ball := preload("res://scripts/table/ball.gd")
const FLAG := "--test-mode"
const SPEEDS: Array[float] = [0.25, 0.5, 1.0, 2.0]
const NORMAL_SPEED_INDEX := 2
const COLLISION_COLOR := Color(1.0, 0.25, 0.85, 0.85)
const SENSOR_COLOR := Color(0.3, 1.0, 0.5, 0.7)

## Los tests lo prenden sin pasar por la línea de comandos.
static var force_enabled := false

var infinite_balls := false
var show_collisions := false
var speed_index := NORMAL_SPEED_INDEX

var _main: Node
var _overlay: Node2D
var _label: Label


static func is_enabled() -> bool:
	if force_enabled:
		return true
	if not OS.is_debug_build():
		return false
	return FLAG in OS.get_cmdline_user_args() or FLAG in OS.get_cmdline_args()


func _ready() -> void:
	_main = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_label()
	_refresh()
	GameState.say("MODO DE PRUEBAS")


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if handle_key(key.keycode):
		get_viewport().set_input_as_handled()


## Devuelve true si la tecla es de este modo.
func handle_key(keycode: Key) -> bool:
	match keycode:
		KEY_F1:
			jump_to_multiball()
		KEY_F2:
			set_infinite_balls(not infinite_balls)
		KEY_F3:
			set_show_collisions(not show_collisions)
		KEY_F4:
			set_speed_index((speed_index + 1) % SPEEDS.size())
		_:
			return false
	return true


func set_infinite_balls(on: bool) -> void:
	infinite_balls = on
	_main.infinite_balls = on
	_refresh()


func set_show_collisions(on: bool) -> void:
	show_collisions = on
	if on and _overlay == null:
		_overlay = _CollisionOverlay.new()
		_main.get_node("Table").add_child(_overlay)
	if _overlay:
		_overlay.visible = on
	_refresh()


func set_speed_index(index: int) -> void:
	speed_index = clampi(index, 0, SPEEDS.size() - 1)
	Engine.time_scale = SPEEDS[speed_index]
	_refresh()


## Dispara la multibola propia de la mesa activa con las señales y reglas que ya existen.
## Devuelve true si la mesa tiene multibola propia, false si hubo que usar el reemplazo genérico.
func jump_to_multiball() -> bool:
	if not GameState.playing:
		return false
	if _main.ball_count() == 0:
		_main.serve_ball()
	var table := _main.get_node("Table")
	var rules := table.get_node_or_null("DraculaRules")
	if rules:
		# Medianoche termina sola con una bola en juego, así que primero hay que tener varias.
		_ensure_balls(2)
		rules.start_midnight()
		GameState.say("MULTIBOLA (PRUEBAS)")
		return true
	var mission := table.get_node_or_null("DepthMission")
	if mission:
		# El jackpot de 20.000 Leguas suelta dos bolas desde el kraken si hay una sola en juego.
		mission.jackpot.emit()
		GameState.say("MULTIBOLA (PRUEBAS)")
		return true
	# Kernel Panic todavía no tiene multibola propia: se sueltan bolas hasta tener tres.
	_ensure_balls(3)
	GameState.say("MULTIBOLA (PRUEBAS)")
	return false


func _ensure_balls(total: int) -> void:
	var extra := 0
	while _main.ball_count() < total:
		var side := -1.0 if extra % 2 == 0 else 1.0
		_main._spawn_ball(Vector2(336.0 + side * 90.0, 620.0), Vector2(side * 140.0, 200.0))
		extra += 1


func status_text() -> String:
	return "TEST  F1 multibola\nF2 infinita %s\nF3 colisiones %s\nF4 velocidad %sx" % [
		"SI" if infinite_balls else "no", "SI" if show_collisions else "no", str(SPEEDS[speed_index])]


func _refresh() -> void:
	if _label:
		_label.text = status_text()


## Texto chico en el borde izquierdo, a media mesa: lejos del HUD (arriba) y de las zonas táctiles (mitad inferior).
func _build_label() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("#ffe27a"))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.position = Vector2(10.0, 560.0)
	layer.add_child(_label)


## Dibuja las formas de colisión de todas las piezas de la mesa (se redibuja cada cuadro).
class _CollisionOverlay extends Node2D:
	func _init() -> void:
		z_index = 100
		name = "CollisionOverlay"

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		var table := get_parent()
		for node in table.find_children("*", "CollisionShape2D", true, false):
			var shape_node := node as CollisionShape2D
			if shape_node.shape == null or shape_node.disabled:
				continue
			draw_set_transform_matrix(global_transform.affine_inverse() * shape_node.global_transform)
			shape_node.shape.draw(get_canvas_item(), _tint(shape_node))
		for node in table.find_children("*", "CollisionPolygon2D", true, false):
			var poly := node as CollisionPolygon2D
			if poly.disabled or poly.polygon.size() < 2:
				continue
			draw_set_transform_matrix(global_transform.affine_inverse() * poly.global_transform)
			var points := poly.polygon.duplicate()
			points.append(points[0])
			draw_polyline(points, _tint(poly), 2.0)

	func _tint(shape_node: Node) -> Color:
		return SENSOR_COLOR if shape_node.get_parent() is Area2D else COLLISION_COLOR
