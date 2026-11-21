@tool
extends Area2D
## Circuito impreso que suma al pasar por encima.

const Ball := preload("res://scripts/table/ball.gd")
const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")
const MIN_CROSS_SPEED := 90.0
## Brillo de los insertos mientras el carril está encendido.
const LIT_LEVEL := 0.75

## Se emite al cruzar el carril con puntaje (el manager de rollovers lo escucha).
signal crossed

@export var caption := "BOOT"
@export var points := 125
@export var tint := Color("#74eed0")

var lit := false
var _flash := 0.0
var _entry_sides := {}


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		set_process(false)
		set_physics_process(false)


func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		_entry_sides[body] = body.global_position.y < global_position.y
		set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	_entry_sides.erase(body)


func _physics_process(_delta: float) -> void:
	for ball in _entry_sides.keys():
		if not is_instance_valid(ball):
			_entry_sides.erase(ball)
			continue
		# Se puntúa al cruzar la línea, no al cargar una bola guardada sobre el inserto.
		if _entry_sides[ball] == (ball.global_position.y < global_position.y):
			continue
		_entry_sides.erase(ball)
		if GameState.playing and absf(ball.linear_velocity.y) >= MIN_CROSS_SPEED:
			GameState.add_score(points, global_position)
			lit = true
			_flash = 1.0
			set_process(true)
			queue_redraw()
			crossed.emit()
	if _entry_sides.is_empty():
		set_physics_process(false)


## Enciende o apaga el carril (lo usan el manager al rotar y al reiniciar).
func set_lit(value: bool) -> void:
	lit = value
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 2.2)
	queue_redraw()
	if _flash == 0.0:
		set_process(false)


func _draw() -> void:
	var shell := PackedVector2Array([
		Vector2(-26, 0), Vector2(-19, -9), Vector2(19, -9),
		Vector2(26, 0), Vector2(19, 9), Vector2(-19, 9),
	])
	var light := tint.lerp(Color.WHITE, _flash * 0.72)
	draw_colored_polygon(shell, Color("#132e38").lerp(tint, _flash * 0.45))
	shell.append(shell[0])
	draw_polyline(shell, Color(light, 0.63 + 0.35 * _flash), 1.7, true)
	for x in [-12, 0, 12]:
		InsertLamp.draw(self, Vector2(x, 0), 3.5, tint, maxf(_flash, LIT_LEVEL if lit else 0.0))
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, 30.0 + 10.0 * (1.0 - _flash),
			Color(tint, _flash * 0.30), false, 3.0, true)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var label := Vector2(-width / 2.0, 30.0)
	draw_string_outline(font, label, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color("#09161f"))
	draw_string(font, label, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, light)
