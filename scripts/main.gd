extends Node2D
## Controla el ciclo de la bola: sacar bola al carril, drenaje, salvavidas
## y popups de puntaje. La mesa en sí (paredes, flippers, bumpers) vive en la
## escena y se edita en el editor.

const Ball := preload("res://scripts/table/ball.gd")
const DepthMission := preload("res://scripts/table/depth_mission.gd")
const ScorePopup := preload("res://scripts/fx/score_popup.gd")
const TableBurst := preload("res://scripts/fx/table_burst.gd")
const Screen := preload("res://scripts/util/screen.gd")

const MINT := Color("#63e0c1")
const AMBER := Color("#ffb75b")
const CORAL := Color("#ff675f")

## Segundos de "bola salvada" después de lanzar cada bola nueva.
const BALL_SAVE_TIME := 8.0
const SERVE_DELAY := 0.7

@export var table_id := GameState.KERNEL_PANIC

@onready var _table: Node2D = $Table
@onready var _art: Node2D = $Table/PlayfieldArt
@onready var _balls: Node2D = $Table/Balls
@onready var _fx: Node2D = $Table/FX
@onready var _plunger: Node2D = $Table/Plunger
@onready var _drain: Area2D = $Table/Drain
@onready var _mission := get_node_or_null("Table/DepthMission") as DepthMission

var _ball_save_left := 0.0
var _save_armed := false
var _serve_timer: Timer


func _ready() -> void:
	_serve_timer = Timer.new()
	_serve_timer.one_shot = true
	_serve_timer.timeout.connect(serve_ball)
	add_child(_serve_timer)
	if _mission:
		_connect_mission()
	_drain.body_entered.connect(_on_drain)
	_plunger.launched.connect(_on_launched)
	GameState.scored.connect(_on_scored)
	GameState.game_started.connect(_on_game_started)
	get_viewport().size_changed.connect(_layout)
	_layout()
	GameState.select_table(table_id)
	GameState.start_game()


func _process(delta: float) -> void:
	if _ball_save_left > 0.0:
		_ball_save_left = maxf(0.0, _ball_save_left - delta)
		_art.set_ball_save_fraction(_ball_save_left / BALL_SAVE_TIME)


func ball_count() -> int:
	var n := 0
	for b in _balls.get_children():
		if not b.is_queued_for_deletion():
			n += 1
	return n


func serve_ball() -> void:
	_serve_timer.stop()
	if not GameState.playing:
		return
	_spawn_ball(_plunger.position + Vector2(0.0, -Ball.RADIUS - 1.0), Vector2.ZERO)
	_save_armed = true


func _on_game_started() -> void:
	for b in _balls.get_children():
		b.queue_free()
	for effect in _fx.get_children():
		effect.queue_free()
	_ball_save_left = 0.0
	_save_armed = false
	_serve_timer.stop()
	_art.set_ball_save_fraction(0.0)
	if _mission:
		_mission.reset()
	GameState.say("BOLA 1")
	_schedule_serve()


func _schedule_serve() -> void:
	if _serve_timer.is_stopped():
		_serve_timer.start(SERVE_DELAY)


func _on_launched(power: float) -> void:
	var release_position := _plunger.position - Vector2(0.0, Ball.RADIUS)
	_burst(release_position, AMBER, 6.0, 5, Vector2.UP * lerpf(240.0, 410.0, power))
	if _save_armed:
		_save_armed = false
		_ball_save_left = BALL_SAVE_TIME
		_art.set_ball_save_fraction(1.0)


func _on_drain(body: Node2D) -> void:
	if not body is Ball:
		return
	body.queue_free()
	if ball_count() > 0 or not GameState.playing:
		return  # Multibola: sigue habiendo bolas en juego.
	if _ball_save_left > 0.0:
		_ball_save_left = 0.0
		_art.set_ball_save_fraction(0.0)
		_burst(Vector2(336.0, 1368.0), MINT, 25.0, 12)
		GameState.say("¡BOLA SALVADA!")
		_schedule_serve()
		return
	_burst(Vector2(body.position.x, 1388.0), CORAL, 8.0, 7, Vector2.DOWN * 90.0)
	if GameState.lose_ball():
		GameState.say("BOLA %d" % (GameState.BALLS_PER_GAME - GameState.balls_left + 1))
		_schedule_serve()


func _on_scored(points: int, world_position: Vector2) -> void:
	_art.pulse_score()
	var at := _table.to_local(world_position)
	var is_bumper := points >= 100
	var tint := AMBER if is_bumper else MINT
	_burst(at, tint, 28.0 if is_bumper else 10.0, 12 if is_bumper else 6)
	var popup := ScorePopup.new()
	popup.setup(points, at, tint)
	_fx.add_child(popup)


func _connect_mission() -> void:
	for sonar in $Table/Sonars.get_children():
		sonar.crossed.connect(_mission.on_sonar)
	$Table/Kraken.struck.connect(_mission.on_kraken)
	_mission.changed.connect(_refresh_mission)
	_mission.jackpot.connect(_on_jackpot)


func _refresh_mission() -> void:
	for sonar in $Table/Sonars.get_children():
		sonar.set_lit(bool(_mission.sonar_mask & (1 << sonar.index)))
	$Table/Kraken.set_armed(_mission.is_kraken_active())
	_art.set_mission_status(_mission.sonar_mask, _mission.depth, _mission.is_kraken_active())


func _on_jackpot() -> void:
	_art.flash_jackpot()
	if ball_count() != 1:
		return
	var origin: Vector2 = $Table/Kraken.position
	_spawn_ball(origin + Vector2(-110, 0), Vector2(-300, -860))
	_spawn_ball(origin + Vector2(110, 0), Vector2(300, -860))


func _spawn_ball(at: Vector2, velocity: Vector2) -> void:
	var ball := Ball.new()
	ball.position = at
	ball.linear_velocity = velocity
	_balls.add_child(ball)


func _burst(at: Vector2, tint: Color, radius: float, count: int, direction := Vector2.ZERO) -> void:
	var burst := TableBurst.new()
	burst.setup(at, tint, radius, count, direction)
	_fx.add_child(burst)


func _layout() -> void:
	# La mesa baja lo que ocupe el notch para no quedar debajo del HUD.
	_table.position.y = Screen.safe_insets(get_viewport()).top
