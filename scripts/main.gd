extends Node2D
## Controla el ciclo de la bola: sacar bola al carril, drenaje, salvavidas
## y popups de puntaje. La mesa en sí (paredes, flippers, bumpers) vive en la
## escena y se edita en el editor.

const Ball := preload("res://scripts/table/ball.gd")
const DepthMission := preload("res://scripts/table/depth_mission.gd")
const ScorePopup := preload("res://scripts/fx/score_popup.gd")
const TableBurst := preload("res://scripts/fx/table_burst.gd")
const Screen := preload("res://scripts/util/screen.gd")
const GameSave := preload("res://scripts/util/game_save.gd")

const MINT := Color("#63e0c1")
const AMBER := Color("#ffb75b")
const CORAL := Color("#ff675f")

## Segundos de "bola salvada" después de lanzar cada bola nueva.
const BALL_SAVE_TIME := 8.0
const SERVE_DELAY := 0.7
const CHECKPOINT_INTERVAL := 4.0
## Empujón con el que se destraba una bola quieta (px/s).
const UNSTICK_SPEED := 520.0
## Desde esta altura (coordenadas de la mesa) la bola está en la zona de flippers.
const FLIPPER_ZONE_Y := 1000.0
## Franja de x donde un flipper puede sostener una bola; fuera de ella (el rincón junto
## al buje) una bola quieta está trabada aunque el jugador tenga el botón apretado.
const CRADLE_MIN_X := 225.0
const CRADLE_MAX_X := 447.0
## Desde esta x y y la bola está en el carril de saque, donde esperar es normal.
const LANE_X := 664.0
const LANE_Y := 430.0

@export var table_id := GameState.KERNEL_PANIC

@onready var _table: Node2D = $Table
@onready var _art: Node2D = $Table/PlayfieldArt
@onready var _balls: Node2D = $Table/Balls
@onready var _fx: Node2D = $Table/FX
@onready var _plunger: Node2D = $Table/Plunger
@onready var _drain: Area2D = $Table/Drain
@onready var _mission := get_node_or_null("Table/DepthMission") as DepthMission
@onready var _hud: CanvasLayer = $HUD

var _ball_save_left := 0.0
var _save_armed := false
var _serve_timer: Timer
var _checkpoint_left := CHECKPOINT_INTERVAL
var _last_saved_run := {}


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
	GameState.game_ended.connect(_on_game_ended)
	_hud.checkpoint_requested.connect(save_run)
	get_viewport().size_changed.connect(_layout)
	_layout()
	GameState.select_table(table_id)
	var saved := GameSave.load_run(table_id, GameState.save_directory) if not GameState.save_directory.is_empty() else {}
	if saved.is_empty():
		GameState.start_game()
	else:
		_restore_run(saved)


func _process(delta: float) -> void:
	if _ball_save_left > 0.0:
		_ball_save_left = maxf(0.0, _ball_save_left - delta)
		_art.set_ball_save_fraction(_ball_save_left / BALL_SAVE_TIME)
	if GameState.playing and not GameState.save_directory.is_empty():
		_checkpoint_left -= delta
		if _checkpoint_left <= 0.0:
			save_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		save_run()


func save_run() -> void:
	_checkpoint_left = CHECKPOINT_INTERVAL
	if GameState.save_directory.is_empty() or not GameState.playing or GameState.table_id != table_id:
		return
	var live_balls: Array[Dictionary] = []
	for ball: RigidBody2D in _balls.get_children():
		if not ball.is_queued_for_deletion():
			live_balls.append({
				"position": ball.position,
				"velocity": ball.linear_velocity,
				"spin": ball.angular_velocity,
				"rotation": ball.rotation,
			})
	var saved := {
		"table_id": table_id,
		"score": GameState.score,
		"balls_left": GameState.balls_left,
		"balls": live_balls,
		"serve_remaining": _serve_timer.time_left,
		"save_remaining": _ball_save_left,
		"save_armed": _save_armed,
		"sonar_mask": _mission.sonar_mask if _mission else 0,
		"depth": _mission.depth if _mission else 0,
		"bonus": GameState.bonus,
		"bonus_multiplier": GameState.bonus_multiplier,
	}
	if saved == _last_saved_run:
		return
	var result := GameSave.save_run(saved, GameState.save_directory)
	if result == OK:
		_last_saved_run = saved
	else:
		push_warning("No se pudo guardar la partida: %s" % error_string(result))


func _restore_run(saved: Dictionary) -> void:
	_last_saved_run = saved
	_ball_save_left = saved.save_remaining
	_save_armed = saved.save_armed
	_art.set_ball_save_fraction(_ball_save_left / BALL_SAVE_TIME)
	if _mission:
		_mission.restore(saved.sonar_mask, saved.depth)
	var probe := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	# Ignora el pequeño solapamiento del contacto normal con una goma o un rail.
	circle.radius = Ball.RADIUS - 2.0
	probe.shape = circle
	probe.collision_mask = 1
	var field: PackedVector2Array = $Table/OuterWall/Shape.polygon
	for snapshot: Dictionary in saved.balls:
		var at := _open_resume_position(snapshot.position, probe, field)
		_spawn_ball(at, snapshot.velocity, snapshot.spin, snapshot.rotation)
	if saved.balls.is_empty():
		_serve_timer.start(maxf(0.001, saved.serve_remaining))
	GameState.resume_game(saved.score, saved.balls_left, saved.get("bonus", 0), saved.get("bonus_multiplier", 1))
	GameState.say("PARTIDA REANUDADA")


func _open_resume_position(at: Vector2, probe: PhysicsShapeQueryParameters2D,
		field: PackedVector2Array) -> Vector2:
	var space := _table.get_world_2d().direct_space_state
	probe.transform = Transform2D(0, _table.to_global(at))
	if space.intersect_shape(probe, 1).is_empty():
		return at
	# Si una actualización puso una pieza donde estaba la bola, busca espacio cerca.
	for radius in [24.0, 48.0, 72.0, 108.0, 154.0]:
		for step in 8:
			var candidate := at + Vector2.DOWN.rotated(TAU * step / 8.0) * float(radius)
			if candidate.y > 1375.0 or not Geometry2D.is_point_in_polygon(candidate, field):
				continue
			probe.transform = Transform2D(0, _table.to_global(candidate))
			if space.intersect_shape(probe, 1).is_empty():
				return candidate
	return at


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
	save_run()


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
	save_run()


func _on_game_ended(_score: int, _is_record: bool) -> void:
	_last_saved_run.clear()
	if not GameState.save_directory.is_empty():
		var result := GameSave.clear_run(table_id, GameState.save_directory)
		if result != OK:
			push_warning("No se pudo borrar la partida terminada: %s" % error_string(result))


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
	if not body is Ball or body.is_queued_for_deletion():
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
		save_run.call_deferred()
		return
	_burst(Vector2(body.position.x, 1388.0), CORAL, 8.0, 7, Vector2.DOWN * 90.0)
	if GameState.lose_ball():
		# Si se cobró bonus, su aviso queda en pantalla en vez de "BOLA n".
		if GameState.last_bonus_award == 0:
			GameState.say("BOLA %d" % (GameState.BALLS_PER_GAME - GameState.balls_left + 1))
		_schedule_serve()
		save_run.call_deferred()


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
	if ball_count() == 1:
		var origin: Vector2 = $Table/Kraken.position
		_spawn_ball(origin + Vector2(-110, 0), Vector2(-300, -860))
		_spawn_ball(origin + Vector2(110, 0), Vector2(300, -860))
	save_run()


func _spawn_ball(at: Vector2, velocity: Vector2, spin := 0.0, angle := 0.0) -> void:
	var ball := Ball.new()
	ball.position = at
	ball.rotation = angle
	ball.linear_velocity = velocity
	ball.angular_velocity = spin
	ball.stuck.connect(_on_ball_stuck.bind(ball))
	_balls.add_child(ball)


## Una bola quieta es normal en el carril de saque, o apoyada un rato en un flipper
## que el jugador mantiene arriba (solo el primer aviso). Si no, está trabada.
func _on_ball_stuck(ball: Ball) -> void:
	if not GameState.playing or not is_instance_valid(ball) or ball.is_queued_for_deletion():
		return
	var at := _table.to_local(ball.global_position)
	if at.x > LANE_X and at.y > LANE_Y:
		return
	if ball.stuck_alerts <= 1 and at.y > FLIPPER_ZONE_Y and at.x > CRADLE_MIN_X and at.x < CRADLE_MAX_X and (Input.is_action_pressed("flipper_left") or Input.is_action_pressed("flipper_right")):
		return
	var side := -1.0 if at.x > 336.0 else 1.0
	ball.linear_velocity = Vector2(side * 0.35, -1.0).normalized() * UNSTICK_SPEED
	_burst(at, AMBER, 14.0, 6)
	GameState.say("BOLA DESTRABADA")


func _burst(at: Vector2, tint: Color, radius: float, count: int, direction := Vector2.ZERO) -> void:
	var burst := TableBurst.new()
	burst.setup(at, tint, radius, count, direction)
	_fx.add_child(burst)


func _layout() -> void:
	# La mesa baja lo que ocupe el notch para no quedar debajo del HUD.
	_table.position.y = Screen.safe_insets(get_viewport()).top
