@tool
extends Area2D
## Ataúd: retiene la bola un instante y la devuelve (anti-recaptura como la cámara de Nautilus).
## Con el LOCK encendido la bola queda encerrada y congelada dentro hasta que se la libera.

const Ball := preload("res://scripts/table/ball.gd")
const InsertLamp := preload("res://scripts/fx/insert_lamp.gd")

## La bola quedó encerrada (la recibe DraculaRules).
signal ball_locked(ball: Ball)

const HOLD_TIME := 0.6
const EXIT_DIRECTION := Vector2(0.42, -0.91)
const EXIT_OFFSET := 40.0
const EXIT_SPEED := 960.0
## Una bola expulsada no se vuelve a capturar hasta que baja de esta altura (zona de flippers).
const REARM_Y := 1000.0
const POINTS := 300
## Lugar de cada bola encerrada dentro del ataúd.
const SLOTS := [Vector2(-8, -5), Vector2(8, 5)]
## Marca que main.gd usa para no contar las bolas encerradas como bolas libres.
const LOCKED_META := &"dracula_locked"
const BONE := Color("#e9e1cf")
const GOLD := Color("#c9a35a")
const CRIMSON := Color("#c0314d")
const NIGHT := Color("#0b0a14")
const MIDNIGHT_BLUE := Color("#1b2140")

@onready var _release_timer: Timer = $ReleaseTimer

## Lo enciende DraculaRules: la próxima bola que entre queda encerrada.
var lock_lit := false:
	set(value):
		lock_lit = value
		queue_redraw()

var _held_ball: Ball
var _spent: Array[Ball] = []
var _locked: Array[Ball] = []
var _flash := 0.0


func _ready() -> void:
	set_process(false)
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
	_flash = 0.0
	set_physics_process(false)
	queue_redraw()


## Libera las bolas encerradas hacia afuera, en abanico. Devuelve cuántas salieron.
func release_locked() -> int:
	var released := 0
	for ball in _locked:
		if not is_instance_valid(ball) or ball.is_queued_for_deletion():
			continue
		var direction := EXIT_DIRECTION.normalized().rotated((released - 0.5) * 0.7)
		ball.remove_meta(LOCKED_META)
		ball.collision_layer = 2
		ball.global_position = global_position + direction * EXIT_OFFSET
		ball.freeze = false
		ball.linear_velocity = direction * EXIT_SPEED
		ball.angular_velocity = 0.0
		ball.reset_physics_interpolation()
		_spent.append(ball)
		released += 1
	_locked.clear()
	if released > 0:
		_flash = 1.0
		set_physics_process(true)
		set_process(true)
	queue_redraw()
	return released


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
	if lock_lit and _locked.size() < SLOTS.size():
		_lock(ball)
		return
	_held_ball = ball
	_freeze_at(ball, global_position)
	_release_timer.start(HOLD_TIME)
	Input.vibrate_handheld(12)
	set_process(true)
	queue_redraw()


func _lock(ball: Ball) -> void:
	_freeze_at(ball, global_position + SLOTS[_locked.size()])
	# Sin capa la bola encerrada no choca ni activa otras áreas; se restaura al liberarla.
	ball.collision_layer = 0
	ball.set_meta(LOCKED_META, true)
	_locked.append(ball)
	_flash = 1.0
	Input.vibrate_handheld(30)
	set_process(true)
	queue_redraw()
	ball_locked.emit(ball)


func _freeze_at(ball: Ball, at: Vector2) -> void:
	ball.freeze = true
	ball.global_position = at
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0
	ball.reset_physics_interpolation()


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
	if is_instance_valid(_held_ball) and not Engine.is_editor_hint():
		charge = 1.0 - _release_timer.time_left / HOLD_TIME
	_draw_coffin(maxf(charge, _flash), charge)
	_draw_lamps()
	_draw_caption(maxf(charge, _flash))


static var _outer := PackedVector2Array([Vector2(-15, -44), Vector2(15, -44), Vector2(29, -11),
	Vector2(19, 44), Vector2(-19, 44), Vector2(-29, -11)])
static var _inner := PackedVector2Array([Vector2(-12, -39), Vector2(12, -39), Vector2(25, -10),
	Vector2(16, 39), Vector2(-16, 39), Vector2(-25, -10)])


func _draw_coffin(glow: float, charge: float) -> void:
	var edge := GOLD.lerp(CRIMSON, glow)
	var lit := 1.0 if lock_lit else 0.0
	draw_set_transform(Vector2(4, 6))
	draw_colored_polygon(_outer, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	# Madera oscura con bisel y filo dorado; con LOCK encendido la tapa irradia carmesí.
	draw_colored_polygon(_outer, Color("#241622").lerp(Color("#3a1522"), lit))
	draw_colored_polygon(_inner, Color("#2d1d33").lerp(Color("#44192b"), lit * 0.8))
	draw_polyline(_outer + PackedVector2Array([_outer[0]]), edge, 3.0, true)
	draw_polyline(_inner + PackedVector2Array([_inner[0]]), Color(GOLD, 0.35), 1.0, true)
	# Vetas de la tapa y herrajes laterales.
	for y in [-24.0, 24.0]:
		draw_line(Vector2(-14, y), Vector2(14, y), Color(GOLD, 0.28), 1.0, true)
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 27.0, -9), Vector2(side * 31.0, -9), GOLD, 2.0, true)
		draw_line(Vector2(side * 22.0, 17), Vector2(side * 26.0, 17), GOLD, 2.0, true)
	# Cruz en la cabecera y rombo a los pies.
	draw_line(Vector2(0, -38), Vector2(0, -28), BONE, 2.0, true)
	draw_line(Vector2(-3.5, -34), Vector2(3.5, -34), BONE, 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 31), Vector2(4, 35), Vector2(0, 39), Vector2(-4, 35)]), Color(GOLD, 0.8))
	# Boca donde queda la bola: pozo oscuro con aro.
	if lock_lit or glow > 0.0:
		draw_circle(Vector2.ZERO, 29.0, Color(CRIMSON, 0.12 + 0.2 * maxf(lit * 0.6, glow)), true, -1.0, true)
	draw_circle(Vector2.ZERO, 23.0, NIGHT, true, -1.0, true)
	draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 28, edge, 2.0, true)
	if charge > 0.0:
		draw_arc(Vector2.ZERO, 25.5, -PI * 0.5, -PI * 0.5 + TAU * charge, 24, CRIMSON, 3.0, true)


func _draw_lamps() -> void:
	# LOCK arriba y una lámpara por bola encerrada abajo.
	InsertLamp.draw(self, Vector2(0, -50), 5.0, CRIMSON, 1.0 if lock_lit else 0.0)
	for i in SLOTS.size():
		InsertLamp.draw(self, Vector2(-10 + i * 20, 48), 4.0, BONE, 1.0 if i < _locked.size() else 0.0)


func _draw_caption(glow: float) -> void:
	var font := ThemeDB.fallback_font
	var caption := "ATAÚD"
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var baseline := Vector2(-width * 0.5, 70)
	draw_string_outline(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, NIGHT)
	draw_string(font, baseline, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BONE.lerp(CRIMSON, glow))
