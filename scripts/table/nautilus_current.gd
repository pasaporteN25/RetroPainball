@tool
extends Node2D
## La corriente se completa al cruzar las dos compuertas del carril físico.

const Ball := preload("res://scripts/table/ball.gd")
const ENTRY_META := &"nautilus_current_entry"
const POINTS := 360
const TRAVEL_SECONDS := 3.0
const BRASS := Color("#cba370")
const LIGHT := Color("#8bffe5")
var _channel := PackedVector2Array([Vector2(113, 364), Vector2(95, 393),
	Vector2(79, 427), Vector2(66, 462), Vector2(58, 499), Vector2(54, 538),
	Vector2(54, 577), Vector2(62, 616), Vector2(73, 654)])

@onready var _upper_gate: Area2D = $UpperGate
@onready var _lower_gate: Area2D = $LowerGate

var _pulse := 0.0
var _flow := 0.0


func _ready() -> void:
	set_process(not Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return
	_upper_gate.body_entered.connect(_crossed.bind(0))
	_lower_gate.body_entered.connect(_crossed.bind(1))


func _crossed(body: Node2D, gate: int) -> void:
	if not GameState.playing or not body is Ball or body.is_queued_for_deletion():
		return
	var vertical_speed: float = body.linear_velocity.y
	if absf(vertical_speed) < 20.0:
		return
	var tick := Engine.get_physics_frames()
	var entering := vertical_speed > 0.0 if gate == 0 else vertical_speed < 0.0
	if entering:
		body.set_meta(ENTRY_META, Vector2i(gate, tick))
		return
	var time_limit := ceili(Engine.physics_ticks_per_second * TRAVEL_SECONDS)
	var first: Vector2i = body.get_meta(ENTRY_META, Vector2i(-1, -time_limit - 1))
	body.remove_meta(ENTRY_META)
	if first.x != 1 - gate or tick - first.y > time_limit:
		return
	var exit_gate := _upper_gate if gate == 0 else _lower_gate
	GameState.add_score(POINTS, exit_gate.global_position)
	Input.vibrate_handheld(12)
	_pulse = 1.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_flow = fposmod(_flow + delta * 0.3, 1.0)
	_pulse = move_toward(_pulse, 0.0, delta * 1.9)
	queue_redraw()


func _draw() -> void:
	if not is_node_ready():
		return
	var channel := _channel
	draw_polyline(channel, Color(0.019, 0.15, 0.19, 0.65), 46.0, true)
	draw_polyline(channel, Color(LIGHT, 0.22 + 0.25 * _pulse), 2.0, true)
	for index in range(1, channel.size() - 1):
		var forward := (channel[index + 1] - channel[index]).normalized()
		var wing := forward.orthogonal() * 9.0
		var at := channel[index].lerp(channel[index + 1], _flow)
		var tip := at + forward * 5.0
		var color := BRASS.lerp(LIGHT, _pulse * 0.9)
		draw_line(at + wing - forward * 4.0, tip, color, 2.0, true)
		draw_line(tip, at - wing - forward * 4.0, color, 2.0, true)
	_draw_gate(_upper_gate)
	_draw_gate(_lower_gate)
	var font := ThemeDB.fallback_font
	var caption := "CORRIENTE"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_set_transform(Vector2(46, 515), -PI * 0.5)
	var baseline := Vector2(-width * 0.5, 0)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color("#071a20"))
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BRASS.lerp(LIGHT, _pulse))
	draw_set_transform(Vector2.ZERO)


func _draw_gate(gate: Area2D) -> void:
	var collision := gate.get_node("Shape") as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	var rect := Rect2(gate.position - shape.size * 0.5, shape.size)
	var light := Color("#35736c").lerp(LIGHT, _pulse)
	draw_rect(rect, Color("#10272b"))
	draw_rect(rect, Color(BRASS, 0.64), false, 1.0)
	for offset in range(7, int(shape.size.x) - 3, 10):
		var at := rect.position + Vector2(offset, shape.size.y * 0.5)
		draw_line(at - Vector2(2, 2), at + Vector2(2, 2), light, 2.0, true)
