@tool
extends StaticBody2D
## Pop bumper: cuando la bola lo toca la despide hacia afuera y suma puntos.

signal impact(strength: float, direction: Vector2)

const ScreenShake := preload("res://scripts/fx/screen_shake.gd")

@export var radius := 32.0:
	set(value):
		radius = value
		_rebuild()
@export var kick_speed := 1300.0
@export var points := 100
@export var color := Color("#ff6e5f"):
	set(value):
		color = value
		queue_redraw()
@export var cap_color := Color("#182830"):
	set(value):
		cap_color = value
		queue_redraw()

var _shape_node: CollisionShape2D
var _flash := 0.0
var _blink_time := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		var mat := PhysicsMaterial.new()
		mat.bounce = 0.0
		physics_material_override = mat
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape_node.shape = circle
	queue_redraw()


## Lo llama la bola desde su paso de física, al empezar el contacto.
func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	var dir := (state.transform.origin - global_position).normalized()
	var v := state.linear_velocity
	var tangent := v - dir * v.dot(dir)
	state.linear_velocity = tangent * 0.5 + dir * kick_speed
	_flash = 1.0
	GameState.add_score.call_deferred(points, global_position)
	impact.emit.call_deferred(ScreenShake.contact_strength(state, self, dir), dir)
	Input.vibrate_handheld(8)


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and GameState.table_id == GameState.KERNEL_PANIC:
		var was_blinking := fmod(_blink_time, 5.1) < 0.15
		_blink_time += delta
		if was_blinking != (fmod(_blink_time, 5.1) < 0.15):
			queue_redraw()
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.5)
		queue_redraw()


func _draw() -> void:
	var light := color.lightened(0.14 + 0.64 * _flash)
	var bright_radius := radius * 0.85
	draw_circle(Vector2(4, 7), radius + 6.0, Color(0.01, 0.02, 0.03, 0.43), true, -1.0, true)
	draw_circle(Vector2(2, 3), radius + 3.0, Color("#101820"), true, -1.0, true)
	if _flash > 0.0:
		var wave_radius := radius + lerpf(4.0, 40.0, 1.0 - _flash)
		draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 52, Color(light, 0.14 * _flash), 8.0, true)
		draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 52, Color(light, 0.85 * _flash), 2.0, true)
	draw_circle(Vector2.ZERO, radius, Color("#081116"), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius * 0.95, Color("#556b73"), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius * 0.91, Color("#1b2c34"), true, -1.0, true)
	draw_circle(Vector2.ZERO, bright_radius, color.darkened(0.63), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius * 0.68, Color("#0a171c"), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius * 0.59, cap_color.lerp(color, _flash * 0.31), true, -1.0, true)
	draw_arc(Vector2.ZERO, radius * 0.94, 3.65, 5.68, 24, Color("#b2c6cc"), 1.7, true)
	for i in 6:
		var a := i * TAU / 6.0
		draw_arc(Vector2.ZERO, radius * 0.77, a - 0.35, a + 0.35, 9, Color(color, 0.25 + _flash * 0.55), radius * 0.18, true)
		draw_arc(Vector2.ZERO, radius * 0.78, a - 0.32, a + 0.32, 9, light, radius * 0.065, true)
	for i in 3:
		var angle := PI * 0.5 + i * TAU / 3.0
		var screw := Vector2.from_angle(angle) * (radius * 1.015)
		draw_circle(screw, 2.7, Color("#0d161c"), true, -1.0, true)
		draw_line(screw + Vector2(-1.2, -0.5), screw + Vector2(1.2, 0.5), Color("#adbdc1"), 1.0, true)

	if not Engine.is_editor_hint() and GameState.table_id == GameState.KERNEL_PANIC:
		_draw_daemon(light)
		return
	var font := ThemeDB.fallback_font
	var font_size := maxi(8, roundi(radius * 0.47))
	var label := str(points)
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := Vector2(-width * 0.5, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5 - 1.0)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, light)
	draw_line(Vector2(-5.0, radius * 0.32), Vector2(5.0, radius * 0.32), Color(light, 0.7), 1.0, true)


func _draw_daemon(light: Color) -> void:
	var bounce := -sin((1.0 - _flash) * PI) * radius * 0.12 if _flash > 0.0 else 0.0
	var c := Vector2(0, bounce)
	var ink := Color("#102d2c")
	var edge := Color("#69e4bc").lerp(light, _flash * 0.5)
	# A compact terminal creature inside the original bumper hardware.
	draw_circle(c, radius * 0.46, ink, true, -1.0, true)
	draw_arc(c, radius * 0.46, 0, TAU, 24, edge, 1.5, true)
	for side in [-1.0, 1.0]:
		draw_line(c + Vector2(side * radius * 0.27, -radius * 0.30), c + Vector2(side * radius * 0.40, -radius * 0.53), edge, 2.0, true)
		draw_circle(c + Vector2(side * radius * 0.40, -radius * 0.53), 2.0, edge)
		var h := 1.5 if fmod(_blink_time, 5.1) < 0.15 else 4.0 + _flash * 3.0
		draw_rect(Rect2(c + Vector2(side * radius * 0.18 - 2.0, -h * 0.5), Vector2(4.0 + _flash * 2.0, h)), edge)
	draw_line(c + Vector2(-4, radius * 0.23), c + Vector2(4, radius * 0.23), edge, 1.5)
