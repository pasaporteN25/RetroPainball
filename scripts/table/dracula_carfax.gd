@tool
extends Node2D
## Órbita Carfax: carril de dos compuertas a la derecha. Entrar por GateIn y salir por GateOut
## en menos de TRAVEL_SECONDS completa una vuelta (el puntaje y la cuenta los lleva DraculaRules).

const Ball := preload("res://scripts/table/ball.gd")
const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")
const ENTRY_META := &"dracula_carfax_entry"
const TRAVEL_SECONDS := 3.0
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
	var limit := ceili(Engine.physics_ticks_per_second * TRAVEL_SECONDS)
	var started: int = body.get_meta(ENTRY_META, -limit - 1)
	body.remove_meta(ENTRY_META)
	if tick - started > limit:
		return
	_pulse = 1.0
	set_process(true)
	queue_redraw()
	Input.vibrate_handheld(12)
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
	draw_line(top, bottom, Color(MIDNIGHT_BLUE, 0.65), 46.0, true)
	draw_line(top, bottom, Color(CRIMSON, 0.22 + 0.3 * _pulse), 2.0, true)
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
	for i in 4:
		var at := top.lerp(bottom, fposmod(_flow + i * 0.25, 1.0))
		draw_line(at - wing - forward * 5.0, at + forward * 3.0, color, 2.0, true)
		draw_line(at + forward * 3.0, at + wing - forward * 5.0, color, 2.0, true)


func _draw_gate(gate: Area2D) -> void:
	var shape := (gate.get_node("Shape") as CollisionShape2D).shape as RectangleShape2D
	var rect := Rect2(gate.position - shape.size * 0.5, shape.size)
	draw_rect(rect, Color("#0b0a14"))
	draw_rect(rect, Color(GOLD, 0.64), false, 1.0)
	draw_rect(rect.grow(-3), FOG.lerp(CRIMSON, _pulse))


func _draw_caption() -> void:
	var font := ThemeDB.fallback_font
	var caption := "CARFAX"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_set_transform(Vector2(646, 560), PI * 0.5)
	var baseline := Vector2(-width * 0.5, 0)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color("#0b0a14"))
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BONE.lerp(CRIMSON, _pulse))
	draw_set_transform(Vector2.ZERO)
