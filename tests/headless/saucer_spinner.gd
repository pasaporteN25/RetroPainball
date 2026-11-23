extends SceneTree
## G-10: el saucer retiene la bola real y la devuelve con impulso; el spinner gira según la velocidad
## de la bola y da puntos por vuelta.
## Las escenas se cargan con load() ya corriendo: con preload se compilarían antes de registrar los autoloads.

const Ball := preload("res://scripts/table/ball.gd")
const SAUCER_PATH := "res://scenes/pieces/saucer.tscn"
const SPINNER_PATH := "res://scenes/pieces/spinner.tscn"

var _state: Node
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_state = root.get_node("GameState")
	_state.save_directory = ""
	_state.record_path = "user://test_saucer_%d.cfg" % OS.get_process_id()
	_state.start_game()
	var rules: TableRules = _state.active_rules()
	await _test_saucer(rules)
	await _test_spinner(rules)
	print("Saucer/spinner: %d controles / %d fallos" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _world() -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	return world


func _ball(world: Node2D, at: Vector2, velocity: Vector2) -> Ball:
	var ball := Ball.new()
	ball.position = at
	ball.gravity_scale = 0.0
	ball.linear_velocity = velocity
	world.add_child(ball)
	return ball


func _test_saucer(rules: TableRules) -> void:
	var world := _world()
	var saucer: Area2D = load(SAUCER_PATH).instantiate()
	saucer.position = Vector2(300, 500)
	saucer.kick_direction = Vector2.RIGHT
	world.add_child(saucer)
	var kicks := []
	saucer.kicked.connect(func(b: Ball) -> void: kicks.append(b))
	var score_before: int = _state.score
	var ball := _ball(world, Vector2(300, 400), Vector2(0, 300))
	for i in 60:
		await physics_frame
	_check(saucer.is_holding() and ball.freeze, "el saucer retiene la bola")
	_check(_state.score == score_before + rules.saucer_points, "el saucer suma sus puntos")
	# Se espera al aviso `kicked` (con tope) y se mide la bola justo al salir.
	for i in 600:
		if not kicks.is_empty():
			break
		await physics_frame
	_check(kicks.size() == 1 and not saucer.is_holding(), "el saucer devuelve la bola")
	_check(not ball.freeze and ball.linear_velocity.x > rules.saucer_kick_speed * 0.8 \
			and absf(ball.linear_velocity.y) < 100.0, "sale con el impulso configurado (%.0f px/s)" % ball.linear_velocity.x)
	_check(ball.position.x > saucer.position.x + 30.0, "la bola sale desplazada hacia la dirección de salida")
	for i in 30:
		await physics_frame
	_check(kicks.size() == 1 and _state.score == score_before + rules.saucer_points, "no recaptura la bola expulsada")
	world.queue_free()
	await physics_frame


func _test_spinner(rules: TableRules) -> void:
	var results := []
	for speed in [500.0, 1600.0]:
		var world := _world()
		var spinner: Area2D = load(SPINNER_PATH).instantiate()
		spinner.position = Vector2(300, 500)
		world.add_child(spinner)
		var score_before: int = _state.score
		_ball(world, Vector2(300, 700), Vector2(0, -speed))
		# Tiempo de sobra para que el giro frene del todo.
		for i in 900:
			await physics_frame
		results.append({"laps": spinner.laps, "score": _state.score - score_before})
		world.queue_free()
		await physics_frame
	_check(results[0]["laps"] > 0, "el spinner da vueltas con una bola lenta (%d)" % results[0]["laps"])
	_check(results[1]["laps"] > results[0]["laps"], "una bola más rápida da más vueltas (%d > %d)" % [results[1]["laps"], results[0]["laps"]])
	_check(results[1]["score"] == results[1]["laps"] * rules.spinner_lap_points, "puntos = vueltas x puntos por vuelta")


func _check(ok: bool, description: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", description])
