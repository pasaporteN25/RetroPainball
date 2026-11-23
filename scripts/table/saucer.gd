extends Area2D
## G-10: saucer / kicker genérico. Un agujero que retiene la bola un instante y la devuelve con un
## impulso configurable. Pensado para sumarse a cualquier mesa: se pone en el tablero (escena
## `res://scenes/pieces/saucer.tscn` o un Area2D con este script) y se ajusta desde el inspector.
## Puntos y tiempo de retención salen de TableRules (saucer_points / saucer_hold_seconds); la
## velocidad de salida es `kick_speed` si es > 0 y si no, TableRules.saucer_kick_speed.
## Si el Area2D no trae un CollisionShape2D, se crea uno circular de `radius`.

const Ball := preload("res://scripts/table/ball.gd")
const BRASS := Color("#bf8c55")
const GOLD := Color("#ffe0ac")

## Avisa cuando la bola sale disparada (no cuando entra).
signal kicked(ball: Ball)

## Dirección de salida (se normaliza). Por defecto, hacia arriba.
@export var kick_direction := Vector2.UP
## Velocidad de salida en px/s; 0 = usar TableRules.saucer_kick_speed.
@export var kick_speed := 0.0
## Distancia desde el centro a la que reaparece la bola, para no volver a caer adentro.
@export var exit_offset := 40.0
@export var radius := 28.0
## Una bola recién expulsada no se vuelve a capturar hasta que sale de la pieza.
@export var rearm_distance := 70.0

var _held_ball: Ball
var _hold_left := 0.0
var _spent: Array[Ball] = []
var _flash := 0.0


func _ready() -> void:
	collision_mask |= 2
	if find_children("*", "CollisionShape2D", false).is_empty():
		var shape := CircleShape2D.new()
		shape.radius = radius
		var owner_shape := CollisionShape2D.new()
		owner_shape.shape = shape
		add_child(owner_shape)
	body_entered.connect(_on_body_entered)
	set_physics_process(false)


func is_holding() -> bool:
	return is_instance_valid(_held_ball)


func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		_catch.call_deferred(body)


func _catch(ball: Ball) -> void:
	if not GameState.playing or not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	if ball in _spent or is_holding():
		return
	var rules := GameState.active_rules()
	_held_ball = ball
	_hold_left = rules.saucer_hold_seconds
	ball.freeze = true
	ball.global_position = global_position
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	ball.reset_physics_interpolation()
	GameState.add_score(rules.saucer_points, global_position)
	Sfx.play(&"bumper", 0.8)
	Settings.vibrate(12)
	set_physics_process(true)
	queue_redraw()


func _physics_process(delta: float) -> void:
	for ball in _spent.duplicate():
		if not is_instance_valid(ball) or ball.is_queued_for_deletion() \
				or ball.global_position.distance_to(global_position) > rearm_distance:
			_spent.erase(ball)
	if is_holding():
		if _held_ball.is_queued_for_deletion():
			_held_ball = null
		else:
			_hold_left -= delta
			if _hold_left <= 0.0:
				_kick()
	_flash = move_toward(_flash, 0.0, delta * 2.5)
	set_physics_process(is_holding() or not _spent.is_empty() or _flash > 0.0)
	queue_redraw()


func _kick() -> void:
	var ball := _held_ball
	_held_ball = null
	var dir := kick_direction.normalized()
	var speed := kick_speed if kick_speed > 0.0 else GameState.active_rules().saucer_kick_speed
	_spent.append(ball)
	ball.global_position = global_position + dir * exit_offset
	ball.freeze = false
	ball.linear_velocity = dir * speed
	ball.reset_physics_interpolation()
	_flash = 1.0
	Sfx.play(&"slingshot", 1.1)
	Settings.vibrate(22)
	kicked.emit(ball)


func _draw() -> void:
	var charge := 0.0
	if is_holding():
		charge = 1.0 - clampf(_hold_left / maxf(GameState.active_rules().saucer_hold_seconds, 0.01), 0.0, 1.0)
	var light := BRASS.lerp(GOLD, maxf(charge, _flash))
	draw_circle(Vector2(3, 5), radius + 4.0, Color(0.02, 0.05, 0.06, 0.7), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius + 3.0, BRASS.darkened(0.35), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius - 3.0, Color("#040c11"), true, -1.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, light, 3.0, true)
	var dir := kick_direction.normalized()
	var wing := dir.orthogonal() * 8.0
	var tip := dir * (radius + 14.0)
	draw_polyline(PackedVector2Array([tip - dir * 10.0 + wing, tip, tip - dir * 10.0 - wing]), light, 2.5, true)
	if charge > 0.0:
		draw_arc(Vector2.ZERO, radius - 7.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 24, GOLD, 3.0, true)
