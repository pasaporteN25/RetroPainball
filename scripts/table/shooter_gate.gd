@tool
extends Area2D
## El carril lanza hacia arriba. La compuerta desvía una bola que vuelve desde el arco.

const Ball := preload("res://scripts/table/ball.gd")
const ACCENT := Color("#e9bc7d")

var _flash := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_crossed)
	set_process(false)


func _on_crossed(body: Node2D) -> void:
	var ball := body as Ball
	if not ball or ball.global_position.x < global_position.x - 14.0 or ball.linear_velocity.y < 90.0:
		return
	var speed := ball.linear_velocity.y
	ball.linear_velocity = Vector2(-clampf(speed * 0.95, 640.0, 1550.0), clampf(speed * 0.36, 150.0, 455.0))
	_flash = 1.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_flash = move_toward(_flash, 0.0, delta * 4.0)
	queue_redraw()
	if _flash == 0.0:
		set_process(false)


func _draw() -> void:
	var pivot := Vector2(12, -10)
	var tip := Vector2(-16, 10 - _flash * 10.0)
	draw_line(pivot, tip, Color("#09121b"), 7.0, true)
	draw_line(pivot, tip, ACCENT.darkened(0.4 - _flash * 0.3), 4.0, true)
	draw_line(pivot, tip, Color(ACCENT, 0.6 + _flash * 0.4), 1.4, true)
	draw_circle(pivot, 4, Color("#253238"), true, -1, true)
	draw_circle(pivot, 2.2, ACCENT, true, -1, true)
