@tool
extends StaticBody2D
## Rotor circular. El contacto le transmite giro y devuelve la bola al campo.

signal struck(at: Vector2)

const BRASS := Color("#c59453")
const AQUA := Color("#69f5d5")
const ALERT := Color("#ffad69")

var _armed := false
var _angle := 0.0
var _spin := 0.0
var _flash := 0.0


func set_armed(armed: bool) -> void:
	_armed = armed
	queue_redraw()


func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	var normal := (state.transform.origin - global_position).normalized()
	var tangent := normal.orthogonal()
	var glancing := state.linear_velocity.dot(tangent)
	state.linear_velocity = normal * maxf(760.0, -state.linear_velocity.dot(normal) * 0.72) + tangent * glancing * 0.72
	_spin = clampf(glancing * 0.012, -16.0, 16.0)
	if absf(_spin) < 3.5:
		_spin = 7.0
	_flash = 1.0
	struck.emit.call_deferred(global_position)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_spin = move_toward(_spin, 0.0, delta * 7.0)
	_angle = fposmod(_angle + (_spin + (1.4 if _armed else 0.36)) * delta, TAU)
	_flash = move_toward(_flash, 0.0, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	var tint := ALERT if _armed else AQUA
	draw_circle(Vector2(5, 8), 65, Color(0.011, 0.035, 0.06, 0.78), true, -1, true)
	draw_circle(Vector2.ZERO, 64, Color("#061820"), true, -1, true)
	draw_circle(Vector2.ZERO, 60, Color("#423626"), true, -1, true)
	draw_circle(Vector2.ZERO, 57, Color("#0f3340"), true, -1, true)
	draw_circle(Vector2.ZERO, 62, BRASS, false, 2, true)
	draw_arc(Vector2.ZERO, 62, 3.8, 5.9, 24, Color("#ffe1a3"), 2.5, true)
	draw_circle(Vector2.ZERO, 54, Color(tint, 0.55 + 0.4 * _flash), false, 2, true)
	if _armed or _flash > 0.0:
		draw_circle(Vector2.ZERO, 68 + 14 * (1.0 - _flash), Color(tint, (0.13 if _armed else 0.0) + 0.3 * _flash), false, 9, true)
	for i in 8:
		var radial := Vector2.from_angle(TAU * i / 8.0)
		draw_circle(radial * 59.5, 1.8, BRASS.lightened(0.35), true, -1, true)
	_draw_rotor(tint)
	var font := ThemeDB.fallback_font
	var caption := "KRAKEN"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string_outline(font, Vector2(-width * 0.5, 92), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color("#071520"))
	draw_string(font, Vector2(-width * 0.5, 92), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint)


func _draw_rotor(tint: Color) -> void:
	for arm_index in 6:
		var arm := PackedVector2Array()
		for step in 11:
			var length := float(step) / 10
			var angle := _angle + TAU * arm_index / 6.0 + length * 1.06
			arm.append(Vector2.from_angle(angle) * lerpf(10, 47, length))
		draw_polyline(arm, Color("#08212d"), 13, true)
		draw_polyline(arm, Color("#935d58").lerp(tint, _flash * 0.76), 8, true)
		for step in range(4, 11, 3):
			draw_circle(arm[step], 2, Color("#ffd1a3"), true, -1, true)
	draw_circle(Vector2.ZERO, 17, Color("#2b5060"), true, -1, true)
	draw_circle(Vector2.ZERO, 15, tint, false, 1.6, true)
	draw_circle(Vector2.ZERO, 6, tint.lerp(Color.WHITE, 0.35), true, -1, true)
