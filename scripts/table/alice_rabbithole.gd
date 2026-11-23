@tool
extends Area2D
## Madriguera: retiene la bola un rato y la devuelve hacia abajo. Con LOCK encendido y tamaño CHICA
## (`lock_armed`, lo decide AliceRules) la bola queda encerrada y congelada hasta que se la libera.

const Ball := preload("res://scripts/table/ball.gd")

## La bola quedó encerrada (la recibe AliceRules).
signal ball_locked(ball: Ball)
## La bola retenida volvió al juego (AliceRules paga el premio).
signal released(at: Vector2)

## Respaldo para el editor (en juego manda TableRules.rabbithole_hold_seconds).
const HOLD_TIME := 1.0
const EXIT_DIRECTION := Vector2(-0.3, 0.95)
const EXIT_OFFSET := 40.0
const EXIT_SPEED := 760.0
## Una bola expulsada no se vuelve a capturar hasta que baja de esta altura (pasada la zona de hongos).
const REARM_Y := 700.0
## Lugar de cada bola encerrada dentro de la madriguera.
const SLOTS := [Vector2(-7, -4), Vector2(7, 4)]
## Marca que main.gd usa para no contar las bolas encerradas como bolas libres.
const LOCKED_META := &"alice_locked"
const RADIUS := 28.0

@onready var _release_timer: Timer = $ReleaseTimer

## Lo enciende AliceRules (solo dibujo): hay LOCK.
var lock_lit := false:
	set(value):
		lock_lit = value
		queue_redraw()
## Lo enciende AliceRules: la próxima bola que entre queda encerrada.
var lock_armed := false

var _held_ball: Ball
var _spent: Array[Ball] = []
var _locked: Array[Ball] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	_release_timer.timeout.connect(_launch)
	set_physics_process(false)


func locked_count() -> int:
	return _locked.size()


## Vuelve al estado inicial (partida nueva): las bolas las borra main.gd.
func reset() -> void:
	_release_timer.stop()
	_held_ball = null
	_spent.clear()
	_locked.clear()
	lock_lit = false
	lock_armed = false
	set_physics_process(false)
	queue_redraw()


## Libera las bolas encerradas hacia abajo, en abanico. Devuelve cuántas salieron.
func release_locked() -> int:
	var released_count := 0
	for ball in _locked:
		if not is_instance_valid(ball) or ball.is_queued_for_deletion():
			continue
		var direction := EXIT_DIRECTION.normalized().rotated((released_count - 0.5) * 0.7)
		ball.remove_meta(LOCKED_META)
		ball.collision_layer = 2
		ball.global_position = global_position + direction * EXIT_OFFSET
		ball.freeze = false
		ball.linear_velocity = direction * EXIT_SPEED
		ball.angular_velocity = 0.0
		ball.reset_physics_interpolation()
		_spent.append(ball)
		released_count += 1
	_locked.clear()
	if released_count > 0:
		set_physics_process(true)
	queue_redraw()
	return released_count


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
	if ball in _spent or ball in _locked:
		return
	if is_instance_valid(_held_ball) and not _held_ball.is_queued_for_deletion():
		return
	if lock_armed and _locked.size() < SLOTS.size():
		_lock(ball)
		return
	_held_ball = ball
	_freeze_at(ball, global_position)
	_release_timer.start(_hold_time())
	Settings.vibrate(12)
	queue_redraw()


func _lock(ball: Ball) -> void:
	_freeze_at(ball, global_position + SLOTS[_locked.size()])
	# Sin capa la bola encerrada no choca ni activa otras áreas; se restaura al liberarla.
	ball.collision_layer = 0
	ball.set_meta(LOCKED_META, true)
	_locked.append(ball)
	Settings.vibrate(30)
	queue_redraw()
	ball_locked.emit(ball)


func _freeze_at(ball: Ball, at: Vector2) -> void:
	ball.freeze = true
	ball.global_position = at
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	ball.reset_physics_interpolation()


func _hold_time() -> float:
	return HOLD_TIME if Engine.is_editor_hint() else GameState.active_rules().rabbithole_hold_seconds


func _launch() -> void:
	var ball := _held_ball
	_held_ball = null
	if not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	var direction := EXIT_DIRECTION.normalized()
	_spent.append(ball)
	set_physics_process(true)
	ball.global_position = global_position + direction * EXIT_OFFSET
	ball.freeze = false
	ball.linear_velocity = direction * EXIT_SPEED
	ball.reset_physics_interpolation()
	Settings.vibrate(22)
	queue_redraw()
	released.emit(global_position)


func _draw() -> void:
	AliceVisuals.draw_rabbithole(self, RADIUS, lock_lit)
