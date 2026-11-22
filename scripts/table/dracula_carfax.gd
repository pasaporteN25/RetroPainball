@tool
extends Node2D
## Órbita Carfax: carril de dos compuertas a la derecha. Entrar por GateIn y salir por GateOut
## en menos de carfax_travel_seconds (TableRules) completa una vuelta (el puntaje y la cuenta los lleva DraculaRules).

const Ball := preload("res://scripts/table/ball.gd")
const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")
const ENTRY_META := &"dracula_carfax_entry"
const BONE := Color("#e9e1cf")
const GOLD := Color("#c9a35a")
const CRIMSON := Color("#c0314d")
const MIDNIGHT_BLUE := Color("#1b2140")
const FOG := Color("#3a4468")
const LAMP_SPOTS := [Vector2(522, 560), Vector2(522, 590), Vector2(522, 620)]

## Se emite al completar una vuelta (de GateIn a GateOut a tiempo).
signal completed(at: Vector2)

@onready var _gate_in: Area2D = $GateIn
@onready var _gate_out: Area2D = $GateOut

## Vueltas ya cumplidas del ciclo (0..2); las enciende DraculaRules.
var stage := 0
var _pulse := 0.0
var _flow := 0.0


func _ready() -> void:
	set_process(not Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return
	_gate_in.body_entered.connect(_crossed.bind(0))
	_gate_out.body_entered.connect(_crossed.bind(1))


func set_stage(value: int) -> void:
	stage = value
	queue_redraw()


func _crossed(body: Node2D, gate: int) -> void:
	if not GameState.playing or not body is Ball or body.is_queued_for_deletion():
		return
	# El carril solo cuenta de arriba hacia abajo.
	if body.linear_velocity.y < 20.0:
		return
	var tick := Engine.get_physics_frames()
	if gate == 0:
		body.set_meta(ENTRY_META, tick)
		return
	var limit := ceili(Engine.physics_ticks_per_second * GameState.active_rules().carfax_travel_seconds)
	var started: int = body.get_meta(ENTRY_META, -limit - 1)
	body.remove_meta(ENTRY_META)
	if tick - started > limit:
		return
	_pulse = 1.0
	set_process(true)
	queue_redraw()
	Settings.vibrate(12)
	completed.emit(_gate_out.global_position)


func _process(delta: float) -> void:
	_flow = fposmod(_flow + delta * 0.3, 1.0)
	_pulse = move_toward(_pulse, 0.0, delta * 1.9)
	queue_redraw()


func _draw() -> void:
	if not is_node_ready():
		return
	var top := _gate_in.position
	var bottom := _gate_out.position
	var forward := (bottom - top).normalized()
	var side := forward.orthogonal()
	# Canal de piedra con rieles dorados y borde carmesí al completar una vuelta.
	draw_line(top, bottom, Color("#060510", 0.55), 52.0, true)
	draw_line(top, bottom, Color(MIDNIGHT_BLUE, 0.75), 46.0, true)
	draw_line(top, bottom, Color(CRIMSON, 0.1 + 0.22 * _pulse), 18.0, true)
	for sign in [-1.0, 1.0]:
		draw_line(top + side * sign * 23.0, bottom + side * sign * 23.0, GOLD.lerp(CRIMSON, _pulse), 1.5, true)
	_draw_chevrons(top, bottom)
	_draw_gate(_gate_in)
	_draw_gate(_gate_out)
	for i in LAMP_SPOTS.size():
		InsertLamp.draw(self, LAMP_SPOTS[i], 5.0, GOLD, 1.0 if stage > i else 0.0)
	_draw_caption()


func _draw_chevrons(top: Vector2, bottom: Vector2) -> void:
	var forward := (bottom - top).normalized()
	var wing := forward.orthogonal() * 9.0
	var color := GOLD.lerp(CRIMSON, _pulse)
	color.a = 0.8
	for i in 4:
		var at := top.lerp(bottom, fposmod(_flow + i * 0.25, 1.0))
		draw_line(at - wing - forward * 5.0, at + forward * 3.0, color, 2.0, true)
		draw_line(at + forward * 3.0, at + wing - forward * 5.0, color, 2.0, true)


func _draw_gate(gate: Area2D) -> void:
	# Reja con barrotes y pilares de piedra; los barrotes se tiñen al completar la vuelta.
	var shape := (gate.get_node("Shape") as CollisionShape2D).shape as RectangleShape2D
	var rect := Rect2(gate.position - shape.size * 0.5, shape.size)
	var iron := GOLD.lerp(CRIMSON, _pulse)
	draw_rect(rect, Color("#0b0a14"))
	var x := rect.position.x + 5.0
	while x < rect.end.x - 3.0:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y + 3.0), Color(iron, 0.85), 1.5, true)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2.0, rect.end.y + 3.0), Vector2(x + 2.0, rect.end.y + 3.0),
			Vector2(x, rect.end.y + 7.0)]), Color(iron, 0.85))
		x += 8.0
	draw_rect(rect, Color(GOLD, 0.7), false, 1.5)
	for px in [rect.position.x - 6.0, rect.end.x]:
		draw_rect(Rect2(px, rect.position.y - 5.0, 6.0, rect.size.y + 10.0), Color("#171426"))
		draw_rect(Rect2(px, rect.position.y - 5.0, 6.0, rect.size.y + 10.0), Color(GOLD, 0.55), false, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(px, rect.position.y - 5.0), Vector2(px + 3.0, rect.position.y - 10.0),
			Vector2(px + 6.0, rect.position.y - 5.0)]), Color(GOLD, 0.7))


func _draw_caption() -> void:
	var font := ThemeDB.fallback_font
	var caption := "CARFAX"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_set_transform(Vector2(637, 560), PI * 0.5)
	# Cartel de madera con filete dorado y clavos.
	var plate := Rect2(-width * 0.5 - 12.0, -18.0, width + 24.0, 25.0)
	draw_rect(plate, Color("#10101d", 0.92))
	draw_rect(plate, Color(GOLD, 0.7), false, 1.5)
	for px in [plate.position.x + 4.0, plate.end.x - 4.0]:
		draw_circle(Vector2(px, plate.get_center().y), 1.3, GOLD, true, -1.0, true)
	var baseline := Vector2(-width * 0.5, 0)
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BONE.lerp(CRIMSON, _pulse))
	draw_set_transform(Vector2.ZERO)
