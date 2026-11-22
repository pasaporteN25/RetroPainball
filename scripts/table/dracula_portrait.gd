@tool
extends StaticBody2D
## Retrato del Conde: blanco circular grande. En Medianoche paga el jackpot (lo decide DraculaRules).

## La bola golpeó el retrato.
signal struck(at: Vector2)

const BONE := Color("#e9e1cf")
const GOLD := Color("#c9a35a")
const CRIMSON := Color("#c0314d")
const NIGHT := Color("#0b0a14")
const MIDNIGHT_BLUE := Color("#1b2140")
const FOG := Color("#3a4468")
const RADIUS := 55.0
const MIN_KICK := 620.0

## Lo enciende DraculaRules mientras dura la Medianoche.
var jackpot_ready := false:
	set(value):
		jackpot_ready = value
		set_process(not Engine.is_editor_hint())
		queue_redraw()

var _flash := 0.0
var _breath := 0.0


func _ready() -> void:
	set_process(false)
	if not Engine.is_editor_hint():
		var mat := PhysicsMaterial.new()
		mat.bounce = 0.0
		physics_material_override = mat


func on_ball_contact(_ball: RigidBody2D, state: PhysicsDirectBodyState2D, _point: Vector2) -> void:
	var normal := (state.transform.origin - global_position).normalized()
	var tangent := normal.orthogonal()
	var glancing := state.linear_velocity.dot(tangent)
	state.linear_velocity = normal * maxf(MIN_KICK, -state.linear_velocity.dot(normal) * 0.6) + tangent * glancing * 0.7
	_flash = 1.0
	set_process(true)
	struck.emit.call_deferred(global_position)


func _process(delta: float) -> void:
	_breath = fposmod(_breath + delta, TAU)
	_flash = move_toward(_flash, 0.0, delta * 3.0)
	queue_redraw()
	if not jackpot_ready and _flash == 0.0:
		set_process(false)


func _draw() -> void:
	var glow := 0.5 + 0.5 * sin(_breath * 4.0) if jackpot_ready else 0.0
	var tint := CRIMSON.lerp(Color.WHITE, _flash * 0.6)
	_draw_frame(tint, glow)
	_draw_figure(tint, glow)
	_draw_caption(tint)


func _draw_frame(tint: Color, glow: float) -> void:
	draw_circle(Vector2(4, 6), RADIUS + 5.0, Color(0, 0, 0, 0.5), true, -1.0, true)
	# Marco dorado ornamentado: aro grueso, filete, tachuelas y destello superior.
	draw_circle(Vector2.ZERO, RADIUS, GOLD.darkened(0.55), true, -1.0, true)
	draw_arc(Vector2.ZERO, RADIUS - 3.5, 0.0, TAU, 48, GOLD.darkened(0.2), 7.0, true)
	draw_arc(Vector2.ZERO, RADIUS - 3.5, PI * 1.05, PI * 1.6, 16, GOLD.lightened(0.4), 2.0, true)
	draw_arc(Vector2.ZERO, RADIUS - 8.0, 0.0, TAU, 48, GOLD.darkened(0.5), 1.0, true)
	draw_circle(Vector2.ZERO, RADIUS - 8.0, MIDNIGHT_BLUE.darkened(0.15), true, -1.0, true)
	draw_circle(Vector2(0, -6), 36.0, Color(FOG, 0.34), true, -1.0, true)
	draw_circle(Vector2(0, -6), 24.0, Color(FOG, 0.2), true, -1.0, true)
	for i in 12:
		var a := i * TAU / 12.0
		draw_circle(Vector2.from_angle(a) * (RADIUS - 3.5), 1.6, GOLD.lightened(0.3), true, -1.0, true)
	if jackpot_ready or _flash > 0.0:
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0.0, TAU, 48, Color(tint, 0.35 + 0.4 * maxf(glow, _flash)), 3.0, true)
		draw_arc(Vector2.ZERO, RADIUS + 9.0, 0.0, TAU, 48, Color(tint, 0.12 + 0.12 * maxf(glow, _flash)), 5.0, true)


func _draw_figure(tint: Color, glow: float) -> void:
	# Capa con cuello alto, forro carmesí, rostro pálido con pico de viuda y ojos que brillan en Medianoche.
	var cape := PackedVector2Array([Vector2(-30, 38), Vector2(-33, 14), Vector2(-24, -4), Vector2(-9, -9),
		Vector2(0, 4), Vector2(9, -9), Vector2(24, -4), Vector2(33, 14), Vector2(30, 38)])
	draw_colored_polygon(cape, NIGHT)
	draw_polyline(cape, FOG, 1.2, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -9), Vector2(0, 26), Vector2(9, -9), Vector2(0, 4)]), tint.darkened(0.35))
	for side in [-1.0, 1.0]:
		var collar := PackedVector2Array([Vector2(side * 8.0, -8), Vector2(side * 24.0, -17), Vector2(side * 27.0, -3),
			Vector2(side * 14.0, 2)])
		draw_colored_polygon(collar, Color("#15172b"))
		draw_polyline(collar, Color(FOG, 0.9), 1.2, true)
	draw_circle(Vector2(0, 17), 2.4, GOLD, true, -1.0, true)
	var face := PackedVector2Array([Vector2(-11, -28), Vector2(11, -28), Vector2(12, -16), Vector2(7, -6),
		Vector2(0, -2), Vector2(-7, -6), Vector2(-12, -16)])
	draw_colored_polygon(face, BONE)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(side * 11.0, -20), Vector2(side * 17.0, -27), Vector2(side * 12.0, -14)]), BONE.darkened(0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -26), Vector2(-11, -35), Vector2(0, -38), Vector2(11, -35),
		Vector2(13, -26), Vector2(7, -29), Vector2(0, -22), Vector2(-7, -29)]), NIGHT)
	var eye := 0.3 + 0.7 * maxf(glow, _flash)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 8.0, -21.5), Vector2(side * 3.0, -19.5), NIGHT, 1.4, true)
		if eye > 0.5:
			draw_circle(Vector2(side * 5.0, -17.0), 5.0, Color(tint, 0.25 * eye), true, -1.0, true)
		draw_circle(Vector2(side * 5.0, -17.0), 1.5 + 1.2 * maxf(glow, _flash), Color(tint, eye).lerp(Color("#ff8b94"), maxf(glow, _flash) * 0.5), true, -1.0, true)
	draw_line(Vector2(-3, -9), Vector2(3, -9), CRIMSON.darkened(0.3), 1.2, true)
	if jackpot_ready:
		for side in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(side * 2.5, -9), Vector2(side * 1.0, -9), Vector2(side * 1.6, -6)]), Color.WHITE)


func _draw_caption(tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var caption := "JACKPOT 5000" if jackpot_ready else "EL CONDE"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var baseline := Vector2(-width * 0.5, RADIUS + 20.0)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, NIGHT)
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint.lightened(0.2) if jackpot_ready else BONE)
