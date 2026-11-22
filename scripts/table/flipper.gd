@tool
extends AnimatableBody2D
## Flipper. Es un cuerpo cinemático que giramos a mano en cada paso de física:
## el motor calcula su velocidad a partir del giro, y esa velocidad es la que
## le da fuerza al golpe contra la bola.
##
## El nodo se ubica en el pivote. El flipper izquierdo apunta hacia +x y el
## derecho hacia -x (no se usa escala negativa: rompe la física).

enum FlipperSide { LEFT, RIGHT }

@export var side: FlipperSide = FlipperSide.LEFT:
	set(value):
		side = value
		_rebuild()
@export var length := 110.0:
	set(value):
		length = value
		_rebuild()
@export var base_radius := 15.0
@export var tip_radius := 7.0
## Grados que baja la punta en reposo.
@export_range(0.0, 60.0) var rest_angle_deg := 30.0
## Grados que sube la punta al apretar.
@export_range(0.0, 60.0) var up_angle_deg := 28.0
## Velocidad de subida y bajada, en radianes por segundo.
@export var up_speed := 26.0
@export var down_speed := 16.0
@export var color := Color("#a6bdc0"):
	set(value):
		color = value
		queue_redraw()
@export var rubber_color := Color("#f58064"):
	set(value):
		rubber_color = value
		queue_redraw()

var _action := &"flipper_left"
var _rest := 0.0
var _up := 0.0
var _points := PackedVector2Array()
var _shape_node: CollisionShape2D
var _was_pressed := false
var _light := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		sync_to_physics = false
		var mat := PhysicsMaterial.new()
		mat.bounce = 0.0
		mat.friction = 0.8
		physics_material_override = mat
	_rebuild()
	rotation = _rest


func _rebuild() -> void:
	var dir := 1.0 if side == FlipperSide.LEFT else -1.0
	_rest = deg_to_rad(rest_angle_deg) * dir
	_up = -deg_to_rad(up_angle_deg) * dir
	_action = &"flipper_left" if side == FlipperSide.LEFT else &"flipper_right"
	_points = _outline(dir)
	if not is_inside_tree():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)
	var convex := ConvexPolygonShape2D.new()
	convex.points = _points
	_shape_node.shape = convex
	if Engine.is_editor_hint():
		rotation = _rest
	queue_redraw()


## Contorno de cápsula afinada: envolvente convexa de los dos círculos.
func _outline(dir: float) -> PackedVector2Array:
	var raw := PackedVector2Array()
	var tip := Vector2(length * dir, 0.0)
	for i in 20:
		var a := TAU * i / 20.0
		var u := Vector2(cos(a), sin(a))
		raw.append(u * base_radius)
		raw.append(tip + u * tip_radius)
	var hull := Geometry2D.convex_hull(raw)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	return hull


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# En TILT el flipper no responde (cae a reposo aunque el botón siga apretado).
	var pressed := Input.is_action_pressed(_action) and not GameState.tilted
	if pressed and not _was_pressed:
		Input.vibrate_handheld(12)
	_was_pressed = pressed
	var target := _up if pressed else _rest
	var speed := up_speed if pressed else down_speed
	rotation = move_toward(rotation, target, speed * delta)


func _process(delta: float) -> void:
	var next := move_toward(_light, float(_was_pressed), delta * 10.0)
	if not is_equal_approx(next, _light):
		_light = next
		queue_redraw()


func _draw() -> void:
	if _points.size() < 3:
		return
	var dir := 1.0 if side == FlipperSide.LEFT else -1.0
	var light := rubber_color.lerp(Color("#fff1c4"), _light * 0.8)
	var shadow := PackedVector2Array()
	var bevel := PackedVector2Array()
	var face := PackedVector2Array()
	var center := Vector2(length * dir * 0.5, 0.0)
	for p in _points:
		shadow.append(p + Vector2(2.0, 6.0).rotated(-rotation))
		bevel.append(center + (p - center) * Vector2(0.945, 0.75))
		face.append(center + (p - center) * Vector2(0.905, 0.53) - Vector2(0.0, 1.2))
	draw_colored_polygon(shadow, Color(0.015, 0.022, 0.028, 0.66))
	draw_colored_polygon(_points, Color("#162028"))
	var outline := _points.duplicate()
	outline.append(_points[0])
	draw_polyline(outline, Color("#080f15"), 4.0, true)
	draw_polyline(outline, Color(light, 0.72 + 0.28 * _light), 1.8, true)
	draw_colored_polygon(bevel, color.darkened(0.60))
	draw_colored_polygon(face, color.darkened(0.27))

	var end := Vector2(length * dir * 0.98, -tip_radius * 0.34)
	draw_line(Vector2(0.0, -base_radius * 0.48), end, color.lightened(0.48), 1.4, true)
	draw_line(Vector2(length * dir * 0.20, 0.7), Vector2(length * dir * 0.9, -0.4), Color("#1c373d"), 3.7, true)
	draw_line(Vector2(length * dir * 0.30, 0.3), Vector2(length * dir * 0.86, -0.4), light, 1.5 + _light * 1.2, true)
	draw_circle(Vector2.ZERO, base_radius * 0.67, Color("#0c1c25"), true, -1.0, true)
	draw_arc(Vector2.ZERO, base_radius * 0.55, PI, TAU, 16, color.lightened(0.38), 1.2, true)
	draw_circle(Vector2.ZERO, base_radius * 0.29, color, true, -1.0, true)
	draw_line(Vector2(-2.4, -0.7), Vector2(2.4, 0.7), Color("#293a40"), 1.1, true)
