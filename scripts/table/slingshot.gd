@tool
extends StaticBody2D
## Slingshot: triángulo con una cara de goma que patea la bola.
## Necesita un hijo CollisionPolygon2D llamado "Shape". La cara que patea es
## la que va del punto 0 al punto 1 del polígono; los otros lados son pared.

@export var kick_speed := 1000.0
@export var points := 10
@export var color := Color(0.25, 0.28, 0.36)
@export var rubber_color := Color(0.95, 0.85, 0.3)

var _flash := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.25
	physics_material_override = mat


func _polygon() -> PackedVector2Array:
	var shape := get_node_or_null("Shape") as CollisionPolygon2D
	if shape == null:
		return PackedVector2Array()
	var poly := PackedVector2Array()
	for p in shape.polygon:
		poly.append(shape.position + p)
	return poly


func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, point: Vector2) -> void:
	var poly := _polygon()
	if poly.size() < 3:
		return
	var a := to_global(poly[0])
	var b := to_global(poly[1])
	var closest := Geometry2D.get_closest_point_to_segment(point, a, b)
	if closest.distance_to(point) > 4.0:
		return  # Tocó un lado que no es la goma.
	var centroid := Vector2.ZERO
	for p in poly:
		centroid += to_global(p)
	centroid /= poly.size()
	var n := (b - a).orthogonal().normalized()
	if n.dot(a - centroid) < 0.0:
		n = -n
	var v := state.linear_velocity
	v -= n * v.dot(n)
	state.linear_velocity = v * 0.8 + n * kick_speed
	_flash = 1.0
	GameState.add_score.call_deferred(points, (a + b) * 0.5)
	Input.vibrate_handheld(8)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	elif _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		queue_redraw()


func _draw() -> void:
	var poly := _polygon()
	if poly.size() < 3:
		return
	draw_colored_polygon(poly, color.lerp(Color.WHITE, 0.25 * _flash))
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, color.lightened(0.3), 3.0, true)
	draw_line(poly[0], poly[1], rubber_color.lerp(Color.WHITE, _flash), 7.0 + 3.0 * _flash, true)
