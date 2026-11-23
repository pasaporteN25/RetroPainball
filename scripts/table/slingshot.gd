@tool
extends StaticBody2D
## Slingshot: triángulo con una cara de goma que patea la bola.
## Necesita un hijo CollisionPolygon2D llamado "Shape". La cara que patea es
## la que va del punto 0 al punto 1 del polígono; los otros lados son pared.

signal impact(strength: float, direction: Vector2)

const ScreenShake := preload("res://scripts/fx/screen_shake.gd")
const RECHARGE_SECONDS := 0.55
const NEXT_KICK_FRAME := &"_next_slingshot_kick_frame"

@export var kick_speed := 1000.0
## Puntos de la goma; -1 = los de TableRules.slingshot_points.
@export var points := -1
@export var color := Color("#314b52")
@export var rubber_color := Color("#ffc06b")

var _flash := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var mat := PhysicsMaterial.new()
	var phys := TablePhysics.active()
	mat.bounce = phys.slingshot_bounce
	kick_speed = phys.slingshot_kick_speed
	physics_material_override = mat


func _polygon() -> PackedVector2Array:
	var shape := get_node_or_null("Shape") as CollisionPolygon2D
	if shape == null:
		return PackedVector2Array()
	var poly := PackedVector2Array()
	for p in shape.polygon:
		poly.append(shape.position + p)
	return poly


func on_ball_contact(ball: RigidBody2D, state: PhysicsDirectBodyState2D, point: Vector2) -> void:
	var frame := Engine.get_physics_frames()
	if frame < int(ball.get_meta(NEXT_KICK_FRAME, 0)):
		return
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
	# Durante el cruce hacia la goma opuesta, ambas caras rebotan sin motorizar
	# esta bola. Cada bola tiene su propia recarga y conserva el rebote pasivo.
	ball.set_meta(NEXT_KICK_FRAME, frame + ceili(RECHARGE_SECONDS * Engine.physics_ticks_per_second))
	_flash = 1.0
	GameState.add_score.call_deferred(points if points >= 0 else GameState.active_rules().slingshot_points, (a + b) * 0.5)
	impact.emit.call_deferred(ScreenShake.contact_strength(state, self, n), n)
	Sfx.play(&"slingshot", randf_range(0.95, 1.05))
	Settings.vibrate(8)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	elif _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 4.5)
		queue_redraw()


func _draw() -> void:
	var poly := _polygon()
	if poly.size() < 3:
		return
	var center := Vector2.ZERO
	for p in poly:
		center += p
	center /= poly.size()

	var shadow := PackedVector2Array()
	var bevel := PackedVector2Array()
	var surface := PackedVector2Array()
	for p in poly:
		shadow.append(p + Vector2(4.0, 7.0))
		bevel.append(center.lerp(p, 0.90))
		surface.append(center.lerp(p, 0.72))
	draw_colored_polygon(shadow, Color(0.02, 0.04, 0.06, 0.63))
	draw_colored_polygon(poly, Color("#121c22"))
	draw_colored_polygon(bevel, color.lightened(0.19))
	draw_colored_polygon(surface, color.darkened(0.19))
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, Color("#080e13"), 2.4, true)

	var a := poly[0]
	var b := poly[1]
	var light := rubber_color.lightened(_flash * 0.78)
	draw_line(a, b, Color("#141117"), 8.0, true)
	draw_line(a, b, rubber_color.darkened(0.54), 5.5, true)
	draw_line(a.lerp(b, 0.03), a.lerp(b, 0.97), light, 2.5 + 1.4 * _flash, true)
	if _flash > 0.0:
		draw_line(a, b, Color(light, _flash * 0.30), 9.0 + 10.0 * (1.0 - _flash), true)
	for i in 4:
		var outer := a.lerp(b, 0.43 + i * 0.10)
		var inner := outer.lerp(center, 0.77)
		draw_line(outer.lerp(inner, 0.27), inner, Color(light, 0.43 + _flash * 0.5), 2.1, true)
	for p in poly:
		var inset := p.move_toward(center, 14.0)
		draw_circle(inset, 3.5, Color("#0f2027"), true, -1.0, true)
		draw_circle(inset, 1.7, color.lightened(0.54), true, -1.0, true)
