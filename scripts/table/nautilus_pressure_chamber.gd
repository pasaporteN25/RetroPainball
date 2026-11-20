@tool
extends Area2D
## La cámara contiene la bola un instante y la devuelve al sonar de estribor.

const Ball := preload("res://scripts/table/ball.gd")
const HOLD_TIME := 0.58
const EXIT_DIRECTION := Vector2(0.204, -0.979)
const EXIT_OFFSET := 43.0
const EXIT_SPEED := 995.0
## Una bola expulsada no se vuelve a capturar hasta que baja de esta altura
## (zona de los flippers). Sin esto cae de nuevo en la cámara y no termina nunca.
const REARM_Y := 1000.0
const POINTS := 480
const BRASS := Color("#bf8c55")
const GOLD := Color("#ffe0ac")
const AQUA := Color("#82ffe5")

@onready var _release_timer: Timer = $ReleaseTimer

var _held_ball: Ball
var _spent: Array[Ball] = []
var _flash := 0.0


func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	_release_timer.timeout.connect(_launch)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	for ball in _spent.duplicate():
		if not is_instance_valid(ball) or ball.is_queued_for_deletion() or get_parent().to_local(ball.global_position).y > REARM_Y:
			_spent.erase(ball)
	set_physics_process(not _spent.is_empty())


func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		_catch.call_deferred(body)


func _catch(ball: Ball) -> void:
	if not GameState.playing or not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	if ball in _spent:
		return
	if is_instance_valid(_held_ball) and not _held_ball.is_queued_for_deletion():
		return
	_held_ball = ball
	ball.freeze = true
	ball.global_position = global_position
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	ball.reset_physics_interpolation()
	_release_timer.start(HOLD_TIME)
	Input.vibrate_handheld(12)
	set_process(true)
	queue_redraw()


func _launch() -> void:
	var ball := _held_ball
	_held_ball = null
	if not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	_spent.append(ball)
	set_physics_process(true)
	ball.global_position = global_position + EXIT_DIRECTION * EXIT_OFFSET
	ball.freeze = false
	ball.linear_velocity = EXIT_DIRECTION * EXIT_SPEED
	ball.reset_physics_interpolation()
	# La bola detenida puede volver a entrar desde un guardado sin duplicar puntos.
	GameState.add_score(POINTS, global_position)
	Input.vibrate_handheld(22)
	_flash = 1.0
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_flash = move_toward(_flash, 0.0, delta * 2.2)
	set_process(is_instance_valid(_held_ball) or _flash > 0.0)
	queue_redraw()


func _draw() -> void:
	var charge := 0.0
	if is_instance_valid(_held_ball):
		charge = 1.0 - _release_timer.time_left / HOLD_TIME
	var light := BRASS.lerp(AQUA, maxf(charge, _flash))
	var arrow := EXIT_DIRECTION * 53.0
	var wing := arrow.orthogonal().normalized() * 9.0
	draw_polyline(PackedVector2Array([arrow - EXIT_DIRECTION * 12.0 + wing, arrow,
		arrow - EXIT_DIRECTION * 12.0 - wing]), light, 2.8, true)
	draw_circle(Vector2(4, 6), 34.0, Color("#061719"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 33.0, Color("#634d39"), true, -1.0, true)
	draw_circle(Vector2.ZERO, 29.0, BRASS.darkened(0.23), false, 5.0, true)
	draw_arc(Vector2.ZERO, 29.0, 3.65, 5.54, 14, GOLD, 3.0, true)
	draw_circle(Vector2.ZERO, 24.0, Color("#081a20"), true, -1.0, true)
	draw_circle(Vector2(1.5, 2.5), 18.0, Color("#040c11"), true, -1.0, true)
	for angle in [0.22, 2.32, 4.39]:
		var bolt := Vector2.from_angle(angle) * 29.5
		draw_circle(bolt, 2.1, GOLD, true, -1.0, true)
		draw_line(bolt - Vector2(1.2, 0), bolt + Vector2(1.2, 0), Color("#332419"), 1.0, true)
	if charge > 0.0:
		draw_arc(Vector2.ZERO, 25.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 24, AQUA, 3.5, true)
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, 34.0 + 22.0 * (1.0 - _flash), Color(AQUA, 0.68 * _flash), false, 2.5, true)
	var font := ThemeDB.fallback_font
	var caption := "CÁMARA"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var baseline := Vector2(-width * 0.5, 54)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 5, Color("#071318"))
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, light.lightened(0.18))
