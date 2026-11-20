@tool
extends Area2D
## El carril lanza hacia arriba. La compuerta desvía una bola que vuelve desde el arco.

const Ball := preload("res://scripts/table/ball.gd")
const ACCENT := Color("#e9bc7d")
## Una bola que baja más lento que esto sigue siendo devuelta a la mesa.
const MIN_FALL_SPEED := 20.0

var _flash := 0.0


func _ready() -> void:
	set_process(false)
	set_physics_process(not Engine.is_editor_hint())


## Se revisa cada cuadro mientras la bola esté sobre la boca del carril: así no
## importa que entre despacio, por el borde o tan rápido que salte la zona.
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_deflect(body)


func _deflect(body: Node2D) -> void:
	var ball := body as Ball
	if not ball or ball.freeze or ball.linear_velocity.y < MIN_FALL_SPEED:
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
