@tool
extends Area2D
## Inserto de sonar. Se activa cuando la bola pasa por encima.

signal crossed(index: int, at: Vector2)

const Ball := preload("res://scripts/table/ball.gd")
const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")
const BRASS := Color("#c39257")
const AQUA := Color("#75ffe2")

@export_range(0, 2) var index := 0
var _lit := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func set_lit(lit: bool) -> void:
	_lit = lit
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		crossed.emit(index, global_position)


func _draw() -> void:
	var accent := AQUA if _lit else BRASS
	draw_circle(Vector2(3, 5), 33, Color("#071b23"), true, -1, true)
	draw_circle(Vector2.ZERO, 31, Color("#102c38"), true, -1, true)
	draw_circle(Vector2.ZERO, 30, BRASS.darkened(0.4), false, 2.5, true)
	draw_arc(Vector2.ZERO, 26, PI + 0.2, TAU - 0.2, 24, accent, 2, true)
	InsertLamp.draw(self, Vector2.ZERO, 20, AQUA, 1.0 if _lit else 0.0)
	if _lit:
		draw_circle(Vector2.ZERO, 35, Color(AQUA, 0.14), false, 6, true)
	for side in [-1, 1]:
		var screw := Vector2(side * 25, 7)
		draw_circle(screw, 2.3, BRASS.lightened(0.25), true, -1, true)
		draw_line(screw - Vector2(1.4, 0), screw + Vector2(1.4, 0), Color("#2f2920"), 1)
	var font := ThemeDB.fallback_font
	var caption := str(index + 1)
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
	var text_color := Color("#073039") if _lit else accent.lightened(0.22)
	draw_string(font, Vector2(-width * 0.5, 8), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, text_color)
