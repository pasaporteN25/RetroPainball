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
	draw_circle(Vector2.ZERO, RADIUS, GOLD.darkened(0.45), true, -1.0, true)
	draw_circle(Vector2.ZERO, RADIUS - 4.0, MIDNIGHT_BLUE, true, -1.0, true)
	draw_arc(Vector2.ZERO, RADIUS - 1.0, 0.0, TAU, 40, GOLD, 2.5, true)
	if jackpot_ready or _flash > 0.0:
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0.0, TAU, 40, Color(tint, 0.35 + 0.4 * maxf(glow, _flash)), 3.0, true)


func _draw_figure(tint: Color, glow: float) -> void:
	# Capa, cara pálida y ojos rojos (silueta original, sin parecido a ninguna película).
	var cape := PackedVector2Array([Vector2(-34, 38), Vector2(-24, 6), Vector2(-12, -12),
		Vector2(12, -12), Vector2(24, 6), Vector2(34, 38)])
	draw_colored_polygon(cape, NIGHT)
	draw_polyline(cape, FOG, 1.5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -12), Vector2(0, 8), Vector2(8, -12)]), tint.darkened(0.3))
	draw_circle(Vector2(0, -20), 15.0, BONE, true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -22), Vector2(-9, -37), Vector2(0, -32),
		Vector2(9, -37), Vector2(15, -22), Vector2(0, -28)]), NIGHT)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 5.5, -20), 2.2 + glow, tint, true, -1.0, true)


func _draw_caption(tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var caption := "JACKPOT 5000" if jackpot_ready else "EL CONDE"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var baseline := Vector2(-width * 0.5, RADIUS + 20.0)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, NIGHT)
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint.lightened(0.2) if jackpot_ready else BONE)
