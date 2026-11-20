extends Node2D
## Controla el ciclo de la bola: sacar bola al carril, drenaje, salvavidas
## y popups de puntaje. La mesa en sí (paredes, flippers, bumpers) vive en la
## escena y se edita en el editor.

const Ball := preload("res://scripts/table/ball.gd")
const ScorePopup := preload("res://scripts/fx/score_popup.gd")
const Screen := preload("res://scripts/util/screen.gd")

## Segundos de "bola salvada" después de lanzar cada bola nueva.
const BALL_SAVE_TIME := 8.0
const SERVE_DELAY := 0.7

@onready var _table: Node2D = $Table
@onready var _balls: Node2D = $Table/Balls
@onready var _fx: Node2D = $Table/FX
@onready var _plunger: Node2D = $Table/Plunger
@onready var _drain: Area2D = $Table/Drain

var _ball_save_left := 0.0
var _save_armed := false
var _serving := false


func _ready() -> void:
	_drain.body_entered.connect(_on_drain)
	_plunger.launched.connect(_on_launched)
	GameState.scored.connect(_on_scored)
	GameState.game_started.connect(_on_game_started)
	get_viewport().size_changed.connect(_layout)
	_layout()
	GameState.start_game()


func _process(delta: float) -> void:
	if _ball_save_left > 0.0:
		_ball_save_left = maxf(0.0, _ball_save_left - delta)


func ball_count() -> int:
	var n := 0
	for b in _balls.get_children():
		if not b.is_queued_for_deletion():
			n += 1
	return n


func serve_ball() -> void:
	_serving = false
	if not GameState.playing:
		return
	var ball := Ball.new()
	ball.position = _plunger.position + Vector2(0.0, -Ball.RADIUS - 1.0)
	_balls.add_child(ball)
	_save_armed = true


func _on_game_started() -> void:
	for b in _balls.get_children():
		b.queue_free()
	_ball_save_left = 0.0
	_serving = false
	GameState.say("BOLA 1")
	_schedule_serve()


func _schedule_serve() -> void:
	if _serving:
		return
	_serving = true
	get_tree().create_timer(SERVE_DELAY, false).timeout.connect(serve_ball)


func _on_launched(_power: float) -> void:
	if _save_armed:
		_save_armed = false
		_ball_save_left = BALL_SAVE_TIME


func _on_drain(body: Node2D) -> void:
	if not body is Ball:
		return
	body.queue_free()
	if ball_count() > 0 or not GameState.playing:
		return  # Multibola: sigue habiendo bolas en juego.
	if _ball_save_left > 0.0:
		_ball_save_left = 0.0
		GameState.say("¡BOLA SALVADA!")
		_schedule_serve()
		return
	if GameState.lose_ball():
		GameState.say("BOLA %d" % (GameState.BALLS_PER_GAME - GameState.balls_left + 1))
		_schedule_serve()


func _on_scored(points: int, world_position: Vector2) -> void:
	var popup := ScorePopup.new()
	var tint := Color(1.0, 0.85, 0.3) if points >= 100 else Color(0.7, 0.9, 1.0)
	popup.setup(points, _table.to_local(world_position), tint)
	_fx.add_child(popup)


func _layout() -> void:
	# La mesa baja lo que ocupe el notch para no quedar debajo del HUD.
	_table.position.y = Screen.safe_insets(get_viewport()).top
