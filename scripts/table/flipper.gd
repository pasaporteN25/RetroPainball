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
@export var color := Color(0.92, 0.92, 0.95)
@export var rubber_color := Color(0.85, 0.2, 0.25)

var _action := &"flipper_left"
var _rest := 0.0
var _up := 0.0
var _points := PackedVector2Array()
var _shape_node: CollisionShape2D
var _was_pressed := false


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
	var pressed := Input.is_action_pressed(_action)
	if pressed and not _was_pressed:
		Input.vibrate_handheld(12)
	_was_pressed = pressed
	var target := _up if pressed else _rest
	var speed := up_speed if pressed else down_speed
	rotation = move_toward(rotation, target, speed * delta)


func _draw() -> void:
	if _points.size() < 3:
		return
	draw_colored_polygon(_points, color)
	var outline := _points.duplicate()
	outline.append(_points[0])
	draw_polyline(outline, rubber_color, 4.0, true)
	draw_circle(Vector2.ZERO, base_radius * 0.35, rubber_color.darkened(0.3))
