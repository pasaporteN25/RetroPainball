extends Node2D
## G-12: kickback (salvador de outlane). Cuando una bola baja por el outlane izquierdo y el
## kickback está listo, se la devuelve al tablero con un empujón. Se gasta una vez por bola y
## se rearma al perder la bola (GameState.rearm_kickback). El estado vive en GameState para que
## se guarde al reanudar. En la mesa, el outlane es un pozo cerrado por el deflector, así que
## la bola reaparece sobre el pozo en vez de subir por el carril.

const Ball := preload("res://scripts/table/ball.gd")
const AMBER := Color("#ffb75b")

@export var outlane_path := NodePath("../LowerLanes/LeftOutlane")
## Dónde reaparece la bola (coordenadas de la mesa) y con qué velocidad sale.
@export var pop_position := Vector2(150.0, 860.0)
@export var pop_velocity := Vector2(230.0, -850.0)

var _flash := 0.0
var _clock := 0.0


func _ready() -> void:
	var lane := get_node_or_null(outlane_path) as Area2D
	if lane != null:
		lane.body_entered.connect(_on_outlane_entered)
	GameState.kickback_changed.connect(func(_ready_now: bool) -> void: queue_redraw())
	GameState.game_started.connect(queue_redraw)


func _on_outlane_entered(body: Node2D) -> void:
	var ball := body as Ball
	if ball == null or ball.linear_velocity.y < 50.0:
		return
	if not GameState.use_kickback():
		return
	# Se difiere para no mover cuerpos dentro del paso de física que detectó el cruce.
	_pop.call_deferred(ball)


func _pop(ball: Ball) -> void:
	if not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	ball.position = pop_position
	ball.linear_velocity = pop_velocity
	ball.angular_velocity = 0.0
	_flash = 1.0
	GameState.say("¡KICKBACK!")


func _process(delta: float) -> void:
	_clock += delta
	_flash = maxf(0.0, _flash - delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var lane := get_node_or_null(outlane_path) as Node2D
	if lane == null:
		return
	var at := to_local(lane.global_position) + Vector2(0.0, -62.0)
	var lit := GameState.kickback_ready
	var a := 0.95 if lit else 0.25
	if lit:
		a = 0.65 + 0.3 * sin(_clock * 4.0)
	a = maxf(a, _flash)
	var tint := Color(AMBER, a)
	draw_circle(at, 7.0, Color(tint, a * 0.35))
	draw_arc(at, 7.0, 0.0, TAU, 16, tint, 1.5, true)
	draw_polyline(PackedVector2Array([at + Vector2(-4.0, 2.0), at + Vector2(0.0, -3.0), at + Vector2(4.0, 2.0)]), tint, 2.0, true)
